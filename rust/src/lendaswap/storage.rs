//! Storage implementations for LendaSwap SDK.
//!
//! This module provides file-based storage adapters that integrate with the
//! existing Ark wallet mnemonic storage.

use crate::ark::mnemonic_file;
use anyhow::Result;
use lendaswap_core::client::ExtendedSwapStorageData;
use lendaswap_core::storage::{StorageFuture, SwapStorage, WalletStorage};
use parking_lot::RwLock;
use std::collections::HashMap;
use std::fs;
use std::path::Path;
use std::sync::Arc;

/// File-based wallet storage for LendaSwap.
///
/// This implementation shares the mnemonic with the Ark wallet by reading from
/// the same mnemonic file, ensuring both wallets derive keys from the same seed.
pub struct FileWalletStorage {
    data_dir: String,
}

impl FileWalletStorage {
    pub fn new(data_dir: String) -> Self {
        Self { data_dir }
    }

    fn key_index_path(&self) -> std::path::PathBuf {
        Path::new(&self.data_dir).join("lendaswap_key_index")
    }
}

impl WalletStorage for FileWalletStorage {
    fn get_mnemonic(&self) -> StorageFuture<'_, Option<String>> {
        Box::pin(async move {
            // Read from the shared mnemonic file (same as Ark wallet)
            let mnemonic = mnemonic_file::read_mnemonic_file(&self.data_dir).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to read mnemonic: {e}"))
            })?;

            Ok(mnemonic.map(|m| m.to_string()))
        })
    }

    fn set_mnemonic(&self, mnemonic: &str) -> StorageFuture<'_, ()> {
        let mnemonic = mnemonic.to_string();
        Box::pin(async move {
            // Parse and write to shared mnemonic file
            let parsed = mnemonic_file::parse_mnemonic(&mnemonic)
                .map_err(|e| lendaswap_core::Error::Other(format!("Invalid mnemonic: {e}")))?;

            mnemonic_file::write_mnemonic_file(&parsed, &self.data_dir).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to write mnemonic: {e}"))
            })?;

            Ok(())
        })
    }

    fn get_key_index(&self) -> StorageFuture<'_, u32> {
        let path = self.key_index_path();
        Box::pin(async move {
            if path.exists() {
                let content = fs::read_to_string(&path).map_err(|e| {
                    lendaswap_core::Error::Other(format!("Failed to read key index: {e}"))
                })?;
                Ok(content.trim().parse().unwrap_or(0))
            } else {
                Ok(0)
            }
        })
    }

    fn set_key_index(&self, index: u32) -> StorageFuture<'_, ()> {
        let path = self.key_index_path();
        Box::pin(async move {
            fs::write(&path, index.to_string()).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to write key index: {e}"))
            })?;
            Ok(())
        })
    }
}

/// File-based swap storage for LendaSwap.
///
/// Stores swap data as JSON files in the data directory. Uses an in-memory cache
/// for fast access and persists to disk for durability.
pub struct FileSwapStorage {
    data_dir: String,
    cache: Arc<RwLock<HashMap<String, ExtendedSwapStorageData>>>,
}

impl FileSwapStorage {
    pub fn new(data_dir: String) -> Result<Self> {
        let swaps_dir = Path::new(&data_dir).join("lendaswap_swaps");
        fs::create_dir_all(&swaps_dir)?;

        // Load existing swaps into cache
        let mut cache = HashMap::new();
        if let Ok(entries) = fs::read_dir(&swaps_dir) {
            for entry in entries.flatten() {
                if let Some(filename) = entry.file_name().to_str() {
                    if filename.ends_with(".json") {
                        let swap_id = filename.trim_end_matches(".json");
                        if let Ok(content) = fs::read_to_string(entry.path()) {
                            if let Ok(data) =
                                serde_json::from_str::<ExtendedSwapStorageData>(&content)
                            {
                                cache.insert(swap_id.to_string(), data);
                            }
                        }
                    }
                }
            }
        }

        tracing::info!(
            swap_count = cache.len(),
            "Loaded existing swaps from storage"
        );

        Ok(Self {
            data_dir,
            cache: Arc::new(RwLock::new(cache)),
        })
    }

    fn swap_file_path(&self, swap_id: &str) -> std::path::PathBuf {
        Path::new(&self.data_dir)
            .join("lendaswap_swaps")
            .join(format!("{}.json", swap_id))
    }
}

impl SwapStorage for FileSwapStorage {
    fn get(&self, swap_id: &str) -> StorageFuture<'_, Option<ExtendedSwapStorageData>> {
        let swap_id = swap_id.to_string();
        Box::pin(async move {
            let cache = self.cache.read();
            Ok(cache.get(&swap_id).cloned())
        })
    }

    fn store(&self, swap_id: &str, data: &ExtendedSwapStorageData) -> StorageFuture<'_, ()> {
        let swap_id = swap_id.to_string();
        let data = data.clone();
        Box::pin(async move {
            // Update cache
            {
                let mut cache = self.cache.write();
                cache.insert(swap_id.clone(), data.clone());
            }

            // Persist to file
            let path = self.swap_file_path(&swap_id);
            let json = serde_json::to_string_pretty(&data).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to serialize swap: {e}"))
            })?;
            fs::write(&path, json).map_err(|e| {
                lendaswap_core::Error::Other(format!("Failed to write swap file: {e}"))
            })?;

            tracing::debug!(swap_id = %swap_id, "Stored swap to disk");
            Ok(())
        })
    }

    fn delete(&self, swap_id: &str) -> StorageFuture<'_, ()> {
        let swap_id = swap_id.to_string();
        Box::pin(async move {
            // Remove from cache
            {
                let mut cache = self.cache.write();
                cache.remove(&swap_id);
            }

            // Remove file
            let path = self.swap_file_path(&swap_id);
            if path.exists() {
                fs::remove_file(&path).map_err(|e| {
                    lendaswap_core::Error::Other(format!("Failed to delete swap file: {e}"))
                })?;
            }

            tracing::debug!(swap_id = %swap_id, "Deleted swap from storage");
            Ok(())
        })
    }

    fn list(&self) -> StorageFuture<'_, Vec<String>> {
        Box::pin(async move {
            let cache = self.cache.read();
            Ok(cache.keys().cloned().collect())
        })
    }

    fn get_all(&self) -> StorageFuture<'_, Vec<ExtendedSwapStorageData>> {
        Box::pin(async move {
            let cache = self.cache.read();
            Ok(cache.values().cloned().collect())
        })
    }
}
