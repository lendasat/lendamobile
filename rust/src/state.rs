use crate::ark::esplora::EsploraClient;
use crate::ark::storage::InMemoryDb;
use crate::frb_generated::StreamSink;
use crate::logger::LogEntry;
use ark_bdk_wallet::Wallet;
use ark_client::{Bip32KeyProvider, Client, Error, KeyProvider, SqliteSwapStorage, StaticKeyProvider};
use bitcoin::key::Keypair;
use bitcoin::XOnlyPublicKey;
use parking_lot::RwLock;
use state::InitCell;
use std::sync::Arc;

pub static LOG_STREAM_SINK: InitCell<RwLock<Arc<StreamSink<LogEntry>>>> = InitCell::new();

/// Unified key provider that supports both HD wallets (Bip32KeyProvider) and
/// legacy wallets (StaticKeyProvider)
pub enum UnifiedKeyProvider {
    Hd(Bip32KeyProvider),
    Legacy(StaticKeyProvider),
}

// Manual implementation of KeyProvider trait
// We use a macro-style delegation since KeypairIndex is not publicly exported
impl KeyProvider for UnifiedKeyProvider {
    fn get_next_keypair(
        &self,
        keypair_index: ark_client::key_provider::KeypairIndex,
    ) -> Result<Keypair, Error> {
        match self {
            UnifiedKeyProvider::Hd(kp) => kp.get_next_keypair(keypair_index),
            UnifiedKeyProvider::Legacy(kp) => kp.get_next_keypair(keypair_index),
        }
    }

    fn get_keypair_for_path(&self, path: &[u32]) -> Result<Keypair, Error> {
        match self {
            UnifiedKeyProvider::Hd(kp) => kp.get_keypair_for_path(path),
            UnifiedKeyProvider::Legacy(kp) => kp.get_keypair_for_path(path),
        }
    }

    fn get_keypair_for_pk(&self, pk: &XOnlyPublicKey) -> Result<Keypair, Error> {
        match self {
            UnifiedKeyProvider::Hd(kp) => kp.get_keypair_for_pk(pk),
            UnifiedKeyProvider::Legacy(kp) => kp.get_keypair_for_pk(pk),
        }
    }

    fn get_cached_pks(&self) -> Result<Vec<XOnlyPublicKey>, Error> {
        match self {
            UnifiedKeyProvider::Hd(kp) => kp.get_cached_pks(),
            UnifiedKeyProvider::Legacy(kp) => kp.get_cached_pks(),
        }
    }

    fn supports_discovery(&self) -> bool {
        match self {
            UnifiedKeyProvider::Hd(kp) => kp.supports_discovery(),
            UnifiedKeyProvider::Legacy(kp) => kp.supports_discovery(),
        }
    }

    fn derive_at_discovery_index(&self, index: u32) -> Result<Option<Keypair>, Error> {
        match self {
            UnifiedKeyProvider::Hd(kp) => kp.derive_at_discovery_index(index),
            UnifiedKeyProvider::Legacy(kp) => kp.derive_at_discovery_index(index),
        }
    }

    fn cache_discovered_keypair(&self, index: u32, kp: Keypair) -> Result<(), Error> {
        match self {
            UnifiedKeyProvider::Hd(provider) => provider.cache_discovered_keypair(index, kp),
            UnifiedKeyProvider::Legacy(provider) => provider.cache_discovered_keypair(index, kp),
        }
    }

    fn mark_as_used(&self, pk: &XOnlyPublicKey) -> Result<(), Error> {
        match self {
            UnifiedKeyProvider::Hd(kp) => kp.mark_as_used(pk),
            UnifiedKeyProvider::Legacy(kp) => kp.mark_as_used(pk),
        }
    }
}

/// Type alias for the Ark client with unified key provider
/// Supports both HD wallets (mnemonic-based) and legacy wallets (raw seed)
#[allow(clippy::type_complexity)]
pub type ArkClient = Client<
    EsploraClient,
    Wallet<InMemoryDb>,
    SqliteSwapStorage,
    UnifiedKeyProvider,
>;

#[allow(clippy::type_complexity)]
pub static ARK_CLIENT: InitCell<RwLock<Arc<ArkClient>>> = InitCell::new();
