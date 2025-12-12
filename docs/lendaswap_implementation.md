# LendaSwap Mobile Implementation Guide

## Overview

This document outlines the step-by-step implementation of LendaSwap (Bitcoin ↔ Stablecoin swaps) in the mobile app. LendaSwap enables atomic swaps between:

- **BTC (Arkade/Lightning)** ↔ **USDC (Polygon/Ethereum)**
- **BTC (Arkade/Lightning)** ↔ **USDT (Polygon/Ethereum)**
- **BTC (Arkade/Lightning)** ↔ **XAUT (Ethereum)** (Gold token)

## Prerequisites

- Complete the [Wallet Mnemonic Migration](./wallet_mnemonic_migration.md) first
- Same mnemonic is used for both Ark wallet and LendaSwap

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Flutter UI                            │
│   SwapScreen → AssetSelector → SwapWizard → Success     │
└─────────────────────┬───────────────────────────────────┘
                      │ flutter_rust_bridge
┌─────────────────────▼───────────────────────────────────┐
│                  Rust Layer                              │
│  ┌─────────────┐    ┌──────────────────┐                │
│  │  Ark Client │    │ LendaSwap Client │                │
│  │  (funds)    │    │ (swap keys)      │                │
│  └──────┬──────┘    └────────┬─────────┘                │
│         │                    │                          │
│         └────────┬───────────┘                          │
│                  │                                      │
│         ┌───────▼────────┐                             │
│         │    Mnemonic    │                             │
│         │  (shared key)  │                             │
│         └────────────────┘                             │
└─────────────────────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   Ark Server    LendaSwap API   EVM Networks
```

## Implementation Steps

### Phase 1: Add LendaSwap SDK to Rust

#### Step 1.1: Update Cargo.toml

```toml
[dependencies]
# Existing dependencies...

# Add LendaSwap SDK
lendaswap-core = { git = "https://github.com/lendasat/lendaswap", path = "client-sdk/core" }

# OR use local path during development
# lendaswap-core = { path = "../../lendasat/lendaswap/client-sdk/core" }

# Additional dependencies needed
rust_decimal = "1.33"
```

#### Step 1.2: Create LendaSwap module (`rust/src/lendaswap/mod.rs`)

```rust
pub mod client;
pub mod storage;
pub mod types;

pub use client::*;
pub use types::*;
```

#### Step 1.3: Create storage implementation (`rust/src/lendaswap/storage.rs`)

```rust
use anyhow::Result;
use lendaswap_core::storage::{SwapStorage, WalletStorage};
use lendaswap_core::client::ExtendedSwapStorageData;
use std::path::Path;
use std::sync::Arc;
use tokio::sync::RwLock;
use std::collections::HashMap;

/// File-based wallet storage for LendaSwap
pub struct FileWalletStorage {
    data_dir: String,
}

impl FileWalletStorage {
    pub fn new(data_dir: String) -> Self {
        Self { data_dir }
    }
}

#[async_trait::async_trait]
impl WalletStorage for FileWalletStorage {
    async fn get_mnemonic(&self) -> Result<Option<String>> {
        // Read from the shared mnemonic file (same as Ark wallet)
        crate::ark::mnemonic_file::read_mnemonic_file(&self.data_dir)
    }

    async fn set_mnemonic(&self, mnemonic: &str) -> Result<()> {
        // Write to shared mnemonic file
        crate::ark::mnemonic_file::write_mnemonic_file(mnemonic, &self.data_dir)
    }

    async fn get_key_index(&self) -> Result<u32> {
        let path = Path::new(&self.data_dir).join("lendaswap_key_index");
        if path.exists() {
            let content = std::fs::read_to_string(&path)?;
            Ok(content.trim().parse().unwrap_or(0))
        } else {
            Ok(0)
        }
    }

    async fn set_key_index(&self, index: u32) -> Result<()> {
        let path = Path::new(&self.data_dir).join("lendaswap_key_index");
        std::fs::write(&path, index.to_string())?;
        Ok(())
    }
}

/// SQLite-based swap storage
pub struct SqliteSwapStorage {
    db_path: String,
    // In-memory cache for quick access
    cache: Arc<RwLock<HashMap<String, ExtendedSwapStorageData>>>,
}

impl SqliteSwapStorage {
    pub async fn new(data_dir: &str) -> Result<Self> {
        let db_path = Path::new(data_dir)
            .join("lendaswap_swaps.sqlite")
            .to_string_lossy()
            .to_string();

        // TODO: Initialize SQLite database
        // CREATE TABLE IF NOT EXISTS swaps (
        //     id TEXT PRIMARY KEY,
        //     data TEXT NOT NULL,
        //     created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
        // )

        Ok(Self {
            db_path,
            cache: Arc::new(RwLock::new(HashMap::new())),
        })
    }
}

#[async_trait::async_trait]
impl SwapStorage for SqliteSwapStorage {
    async fn get(&self, swap_id: &str) -> Result<Option<ExtendedSwapStorageData>> {
        let cache = self.cache.read().await;
        Ok(cache.get(swap_id).cloned())
        // TODO: Also check SQLite if not in cache
    }

    async fn store(&self, swap_id: &str, data: &ExtendedSwapStorageData) -> Result<()> {
        let mut cache = self.cache.write().await;
        cache.insert(swap_id.to_string(), data.clone());
        // TODO: Also persist to SQLite
        Ok(())
    }

    async fn delete(&self, swap_id: &str) -> Result<()> {
        let mut cache = self.cache.write().await;
        cache.remove(swap_id);
        // TODO: Also delete from SQLite
        Ok(())
    }

    async fn list(&self) -> Result<Vec<String>> {
        let cache = self.cache.read().await;
        Ok(cache.keys().cloned().collect())
    }

    async fn get_all(&self) -> Result<Vec<ExtendedSwapStorageData>> {
        let cache = self.cache.read().await;
        Ok(cache.values().cloned().collect())
    }
}
```

#### Step 1.4: Create LendaSwap client wrapper (`rust/src/lendaswap/client.rs`)

```rust
use anyhow::{Result, anyhow, bail};
use lendaswap_core::{Client, Network};
use lendaswap_core::api::{
    AssetPair, BtcToEvmSwapResponse, EvmToBtcSwapResponse,
    QuoteRequest, QuoteResponse, TokenId, EvmChain,
};
use rust_decimal::Decimal;
use std::sync::Arc;
use parking_lot::RwLock;
use crate::lendaswap::storage::{FileWalletStorage, SqliteSwapStorage};

// Global LendaSwap client state
use state::InitCell;
pub static LENDASWAP_CLIENT: InitCell<RwLock<Arc<LendaSwapClient>>> = InitCell::new();

pub struct LendaSwapClient {
    client: Client<FileWalletStorage, SqliteSwapStorage>,
}

impl LendaSwapClient {
    pub fn client(&self) -> &Client<FileWalletStorage, SqliteSwapStorage> {
        &self.client
    }
}

/// Initialize LendaSwap client
pub async fn init_lendaswap(
    data_dir: String,
    network: Network,
    api_url: String,
    arkade_url: String,
) -> Result<()> {
    let wallet_storage = FileWalletStorage::new(data_dir.clone());
    let swap_storage = SqliteSwapStorage::new(&data_dir).await?;

    let client = Client::new(
        api_url,
        wallet_storage,
        swap_storage,
        network,
        arkade_url,
    );

    // Initialize with existing mnemonic (shared with Ark wallet)
    client.init(None).await?;

    let lendaswap_client = LendaSwapClient { client };
    LENDASWAP_CLIENT.set(RwLock::new(Arc::new(lendaswap_client)));

    tracing::info!("LendaSwap client initialized");
    Ok(())
}

/// Get available asset pairs
pub async fn get_asset_pairs() -> Result<Vec<AssetPair>> {
    let client = get_client()?;
    client.client().get_asset_pairs().await
}

/// Get quote for a swap
pub async fn get_quote(
    from_token: TokenId,
    to_token: TokenId,
    amount_sats: u64,
) -> Result<QuoteResponse> {
    let client = get_client()?;
    let request = QuoteRequest {
        from: from_token,
        to: to_token,
        base_amount: amount_sats,
    };
    client.client().get_quote(&request).await
}

/// Create BTC → EVM swap (sell BTC for stablecoins)
pub async fn create_btc_to_evm_swap(
    target_address: String,      // User's EVM address to receive tokens
    target_amount: f64,          // Amount of tokens to receive (e.g., 100.0 USDC)
    target_token: TokenId,       // e.g., TokenId::UsdcPol
    target_chain: EvmChain,      // e.g., EvmChain::Polygon
) -> Result<BtcToEvmSwapResponse> {
    let client = get_client()?;
    let amount = Decimal::try_from(target_amount)
        .map_err(|e| anyhow!("Invalid amount: {}", e))?;

    client.client().create_arkade_to_evm_swap(
        target_address,
        amount,
        target_token,
        target_chain,
        None, // referral_code
    ).await
}

/// Create EVM → BTC swap (buy BTC with stablecoins)
pub async fn create_evm_to_btc_swap(
    target_address: String,      // User's Ark address to receive BTC
    user_evm_address: String,    // User's EVM address (source of funds)
    source_amount: f64,          // Amount of tokens to spend
    source_token: TokenId,       // e.g., TokenId::UsdcPol
    source_chain: EvmChain,      // e.g., EvmChain::Polygon
) -> Result<EvmToBtcSwapResponse> {
    let client = get_client()?;
    let amount = Decimal::try_from(source_amount)
        .map_err(|e| anyhow!("Invalid amount: {}", e))?;

    client.client().create_evm_to_arkade_swap(
        target_address,
        user_evm_address,
        amount,
        source_token,
        source_chain,
        None, // referral_code
    ).await
}

/// Create EVM → Lightning swap (pay Lightning invoice with stablecoins)
pub async fn create_evm_to_lightning_swap(
    bolt11_invoice: String,
    user_evm_address: String,
    source_token: TokenId,
    source_chain: EvmChain,
) -> Result<EvmToBtcSwapResponse> {
    let client = get_client()?;

    client.client().create_evm_to_lightning_swap(
        bolt11_invoice,
        user_evm_address,
        source_token,
        source_chain,
        None, // referral_code
    ).await
}

/// Get swap status by ID
pub async fn get_swap(swap_id: String) -> Result<ExtendedSwapStorageData> {
    let client = get_client()?;
    client.client().get_swap(&swap_id).await
}

/// List all swaps
pub async fn list_swaps() -> Result<Vec<ExtendedSwapStorageData>> {
    let client = get_client()?;
    client.client().list_all().await
}

/// Claim swap via Gelato (gasless)
pub async fn claim_gelato(swap_id: String) -> Result<()> {
    let client = get_client()?;
    client.client().claim_gelato(&swap_id, None).await
}

/// Claim VHTLC (for EVM → BTC swaps)
pub async fn claim_vhtlc(swap_id: String) -> Result<String> {
    let client = get_client()?;
    client.client().claim_vhtlc(&swap_id).await
}

/// Refund VHTLC (for failed BTC → EVM swaps)
pub async fn refund_vhtlc(swap_id: String, refund_address: String) -> Result<String> {
    let client = get_client()?;
    client.client().refund_vhtlc(&swap_id, &refund_address).await
}

/// Recover swaps from server (after mnemonic restore)
pub async fn recover_swaps() -> Result<Vec<ExtendedSwapStorageData>> {
    let client = get_client()?;
    client.client().recover_swaps().await
}

// Helper to get client
fn get_client() -> Result<Arc<LendaSwapClient>> {
    LENDASWAP_CLIENT
        .try_get()
        .map(|c| Arc::clone(&c.read()))
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))
}
```

#### Step 1.5: Create types (`rust/src/lendaswap/types.rs`)

```rust
use serde::{Deserialize, Serialize};

/// Supported tokens for swaps
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SwapToken {
    // Bitcoin
    BtcArkade,
    BtcLightning,
    // Polygon
    UsdcPolygon,
    UsdtPolygon,
    // Ethereum
    UsdcEthereum,
    UsdtEthereum,
    XautEthereum,
}

impl SwapToken {
    pub fn to_token_id(&self) -> lendaswap_core::api::TokenId {
        match self {
            SwapToken::BtcArkade => lendaswap_core::api::TokenId::BtcArkade,
            SwapToken::BtcLightning => lendaswap_core::api::TokenId::BtcLightning,
            SwapToken::UsdcPolygon => lendaswap_core::api::TokenId::UsdcPol,
            SwapToken::UsdtPolygon => lendaswap_core::api::TokenId::Usdt0Pol,
            SwapToken::UsdcEthereum => lendaswap_core::api::TokenId::UsdcEth,
            SwapToken::UsdtEthereum => lendaswap_core::api::TokenId::UsdtEth,
            SwapToken::XautEthereum => lendaswap_core::api::TokenId::XautEth,
        }
    }

    pub fn symbol(&self) -> &str {
        match self {
            SwapToken::BtcArkade | SwapToken::BtcLightning => "BTC",
            SwapToken::UsdcPolygon | SwapToken::UsdcEthereum => "USDC",
            SwapToken::UsdtPolygon | SwapToken::UsdtEthereum => "USDT",
            SwapToken::XautEthereum => "XAUT",
        }
    }

    pub fn network(&self) -> &str {
        match self {
            SwapToken::BtcArkade => "Arkade",
            SwapToken::BtcLightning => "Lightning",
            SwapToken::UsdcPolygon | SwapToken::UsdtPolygon => "Polygon",
            SwapToken::UsdcEthereum | SwapToken::UsdtEthereum | SwapToken::XautEthereum => "Ethereum",
        }
    }

    pub fn is_btc(&self) -> bool {
        matches!(self, SwapToken::BtcArkade | SwapToken::BtcLightning)
    }

    pub fn is_evm(&self) -> bool {
        !self.is_btc()
    }
}

/// Swap status for UI display
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SwapStatus {
    /// Waiting for user to deposit
    WaitingForDeposit,
    /// User deposited, waiting for server
    Processing,
    /// Swap completed successfully
    Completed,
    /// Swap expired (no deposit)
    Expired,
    /// Swap can be refunded
    Refundable,
    /// Swap has been refunded
    Refunded,
    /// Error state
    Failed(String),
}

/// Simplified swap info for Flutter UI
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SwapInfo {
    pub id: String,
    pub status: SwapStatus,
    pub source_token: SwapToken,
    pub target_token: SwapToken,
    pub source_amount: f64,
    pub target_amount: f64,
    pub created_at: String,
    /// For BTC→EVM: Lightning invoice or Ark HTLC address to pay
    pub deposit_address: Option<String>,
    /// For EVM→BTC: EVM HTLC address to deposit to
    pub evm_htlc_address: Option<String>,
}
```

### Phase 2: Expose API to Flutter

#### Step 2.1: Create API module (`rust/src/api/lendaswap_api.rs`)

```rust
use crate::lendaswap::{self, SwapToken, SwapInfo, SwapStatus};
use anyhow::Result;

/// Initialize LendaSwap (call after wallet is loaded)
pub async fn init_lendaswap(
    data_dir: String,
    network: String,  // "bitcoin", "testnet", "regtest"
    api_url: String,  // "https://api.lendaswap.com" or testnet URL
    arkade_url: String,
) -> Result<()> {
    let network = match network.as_str() {
        "bitcoin" | "mainnet" => lendaswap_core::Network::Bitcoin,
        "testnet" => lendaswap_core::Network::Testnet,
        "regtest" => lendaswap_core::Network::Regtest,
        _ => return Err(anyhow::anyhow!("Invalid network: {}", network)),
    };

    lendaswap::init_lendaswap(data_dir, network, api_url, arkade_url).await
}

/// Get exchange rate quote
pub async fn get_swap_quote(
    from_token: String,  // "btc_arkade", "usdc_pol", etc.
    to_token: String,
    amount_sats: u64,
) -> Result<SwapQuote> {
    let from = parse_token(&from_token)?;
    let to = parse_token(&to_token)?;

    let quote = lendaswap::get_quote(
        from.to_token_id(),
        to.to_token_id(),
        amount_sats,
    ).await?;

    Ok(SwapQuote {
        exchange_rate: quote.exchange_rate.parse().unwrap_or(0.0),
        network_fee_sats: quote.network_fee,
        protocol_fee_sats: quote.protocol_fee,
        min_amount_sats: quote.min_amount,
        max_amount_sats: quote.max_amount,
    })
}

#[derive(Debug, Clone)]
pub struct SwapQuote {
    pub exchange_rate: f64,
    pub network_fee_sats: u64,
    pub protocol_fee_sats: u64,
    pub min_amount_sats: u64,
    pub max_amount_sats: u64,
}

/// Create swap: BTC → Stablecoin
pub async fn create_sell_btc_swap(
    target_evm_address: String,
    usd_amount: f64,
    target_token: String,  // "usdc_pol", "usdt_eth", etc.
) -> Result<SwapInfo> {
    let token = parse_token(&target_token)?;
    let chain = get_evm_chain(&token)?;

    let response = lendaswap::create_btc_to_evm_swap(
        target_evm_address,
        usd_amount,
        token.to_token_id(),
        chain,
    ).await?;

    // Convert to SwapInfo for Flutter
    Ok(SwapInfo {
        id: response.common.id.to_string(),
        status: SwapStatus::WaitingForDeposit,
        source_token: SwapToken::BtcArkade,
        target_token: token,
        source_amount: response.sats_receive as f64 / 100_000_000.0,
        target_amount: usd_amount,
        created_at: response.common.created_at,
        deposit_address: Some(response.htlc_address_arkade),
        evm_htlc_address: None,
    })
}

/// Create swap: Stablecoin → BTC
pub async fn create_buy_btc_swap(
    target_ark_address: String,
    user_evm_address: String,
    usd_amount: f64,
    source_token: String,
) -> Result<SwapInfo> {
    let token = parse_token(&source_token)?;
    let chain = get_evm_chain(&token)?;

    let response = lendaswap::create_evm_to_btc_swap(
        target_ark_address,
        user_evm_address,
        usd_amount,
        token.to_token_id(),
        chain,
    ).await?;

    Ok(SwapInfo {
        id: response.common.id.to_string(),
        status: SwapStatus::WaitingForDeposit,
        source_token: token,
        target_token: SwapToken::BtcArkade,
        source_amount: usd_amount,
        target_amount: response.sats_receive as f64 / 100_000_000.0,
        created_at: response.common.created_at,
        deposit_address: None,
        evm_htlc_address: Some(response.htlc_address_evm),
    })
}

/// Get swap by ID
pub async fn get_swap(swap_id: String) -> Result<SwapInfo> {
    let data = lendaswap::get_swap(swap_id).await?;
    convert_to_swap_info(data)
}

/// List all swaps
pub async fn list_swaps() -> Result<Vec<SwapInfo>> {
    let swaps = lendaswap::list_swaps().await?;
    swaps.into_iter().map(convert_to_swap_info).collect()
}

/// Claim completed swap
pub async fn claim_swap(swap_id: String) -> Result<()> {
    lendaswap::claim_gelato(swap_id).await
}

/// Refund failed swap
pub async fn refund_swap(swap_id: String, refund_address: String) -> Result<String> {
    lendaswap::refund_vhtlc(swap_id, refund_address).await
}

// Helper functions
fn parse_token(token: &str) -> Result<SwapToken> {
    match token {
        "btc_arkade" => Ok(SwapToken::BtcArkade),
        "btc_lightning" => Ok(SwapToken::BtcLightning),
        "usdc_pol" => Ok(SwapToken::UsdcPolygon),
        "usdt0_pol" | "usdt_pol" => Ok(SwapToken::UsdtPolygon),
        "usdc_eth" => Ok(SwapToken::UsdcEthereum),
        "usdt_eth" => Ok(SwapToken::UsdtEthereum),
        "xaut_eth" => Ok(SwapToken::XautEthereum),
        _ => Err(anyhow::anyhow!("Unknown token: {}", token)),
    }
}

fn get_evm_chain(token: &SwapToken) -> Result<lendaswap_core::api::EvmChain> {
    match token {
        SwapToken::UsdcPolygon | SwapToken::UsdtPolygon => Ok(lendaswap_core::api::EvmChain::Polygon),
        SwapToken::UsdcEthereum | SwapToken::UsdtEthereum | SwapToken::XautEthereum => {
            Ok(lendaswap_core::api::EvmChain::Ethereum)
        }
        _ => Err(anyhow::anyhow!("Not an EVM token")),
    }
}

fn convert_to_swap_info(data: lendaswap_core::client::ExtendedSwapStorageData) -> Result<SwapInfo> {
    // Convert ExtendedSwapStorageData to SwapInfo
    // Implementation depends on the response type (BtcToEvm or EvmToBtc)
    todo!("Implement conversion")
}
```

#### Step 2.2: Update mod.rs to export

```rust
// rust/src/api/mod.rs
pub mod ark_api;
pub mod bitcoin_api;
pub mod mempool_api;
pub mod mempool_block_tracker;
pub mod mempool_ws;
pub mod moonpay_api;
pub mod lendaswap_api;  // Add this
```

### Phase 3: Flutter UI Implementation

#### Step 3.1: Update swap_screen.dart

The existing `swap_screen.dart` needs to be updated to support LendaSwap tokens:

```dart
// lib/src/ui/screens/swap_screen.dart

enum SwapToken {
  btcArkade,
  btcLightning,
  usdcPolygon,
  usdtPolygon,
  usdcEthereum,
  usdtEthereum,
  xautEthereum,
}

extension SwapTokenExtension on SwapToken {
  String get symbol {
    switch (this) {
      case SwapToken.btcArkade:
      case SwapToken.btcLightning:
        return 'BTC';
      case SwapToken.usdcPolygon:
      case SwapToken.usdcEthereum:
        return 'USDC';
      case SwapToken.usdtPolygon:
      case SwapToken.usdtEthereum:
        return 'USDT';
      case SwapToken.xautEthereum:
        return 'XAUT';
    }
  }

  String get network {
    switch (this) {
      case SwapToken.btcArkade:
        return 'Arkade';
      case SwapToken.btcLightning:
        return 'Lightning';
      case SwapToken.usdcPolygon:
      case SwapToken.usdtPolygon:
        return 'Polygon';
      case SwapToken.usdcEthereum:
      case SwapToken.usdtEthereum:
      case SwapToken.xautEthereum:
        return 'Ethereum';
    }
  }

  String get apiId {
    switch (this) {
      case SwapToken.btcArkade:
        return 'btc_arkade';
      case SwapToken.btcLightning:
        return 'btc_lightning';
      case SwapToken.usdcPolygon:
        return 'usdc_pol';
      case SwapToken.usdtPolygon:
        return 'usdt0_pol';
      case SwapToken.usdcEthereum:
        return 'usdc_eth';
      case SwapToken.usdtEthereum:
        return 'usdt_eth';
      case SwapToken.xautEthereum:
        return 'xaut_eth';
    }
  }

  bool get isBtc => this == SwapToken.btcArkade || this == SwapToken.btcLightning;
  bool get isEvm => !isBtc;
}
```

#### Step 3.2: Create swap wizard flow

```
lib/src/ui/screens/swap/
├── swap_screen.dart           # Main swap entry (amount + asset selection)
├── swap_address_screen.dart   # Enter target address (EVM or Ark)
├── swap_confirm_screen.dart   # Review swap details
├── swap_deposit_screen.dart   # Show deposit address/QR (for BTC→EVM)
├── swap_processing_screen.dart # Waiting for swap completion
├── swap_success_screen.dart   # Swap completed
└── swap_history_screen.dart   # List past swaps
```

#### Step 3.3: Initialize LendaSwap on app start

```dart
// In your app initialization
Future<void> initLendaSwap() async {
  final dataDir = await getApplicationDocumentsDirectory();

  await api.initLendaswap(
    dataDir: dataDir.path,
    network: 'bitcoin',  // or 'testnet' for testing
    apiUrl: 'https://api.lendaswap.com',
    arkadeUrl: 'https://arkade.computer',
  );
}
```

### Phase 4: Swap Flow Implementation

#### Flow 1: Sell BTC for USDC

```
1. User selects: BTC (Arkade) → USDC (Polygon)
2. User enters amount in USD or BTC
3. App fetches quote (exchange rate, fees)
4. User enters their Polygon wallet address
5. User confirms swap
6. App creates swap → gets Ark HTLC address
7. User sends BTC to HTLC address (from Ark wallet)
8. App polls swap status
9. When server deposits USDC → user claims via Gelato (gasless)
10. Success!
```

#### Flow 2: Buy BTC with USDC

```
1. User selects: USDC (Polygon) → BTC (Arkade)
2. User enters amount
3. App fetches quote
4. User's Ark address is auto-filled
5. User enters their Polygon wallet address (source)
6. User confirms swap
7. App creates swap → gets EVM HTLC address
8. User deposits USDC to HTLC (external wallet or WalletConnect)
9. App polls swap status
10. When swap completes → BTC arrives in Ark wallet
11. Success!
```

## Configuration

### Environment Variables

```dart
// lib/src/config/lendaswap_config.dart

class LendaSwapConfig {
  static const String mainnetApiUrl = 'https://api.lendaswap.com';
  static const String testnetApiUrl = 'https://api-testnet.lendaswap.com';

  static const String mainnetArkadeUrl = 'https://arkade.computer';
  static const String testnetArkadeUrl = 'https://testnet.arkade.computer';

  static String get apiUrl => isMainnet ? mainnetApiUrl : testnetApiUrl;
  static String get arkadeUrl => isMainnet ? mainnetArkadeUrl : testnetArkadeUrl;
}
```

## Testing Checklist

### Unit Tests
- [ ] Token parsing works correctly
- [ ] Quote fetching returns valid data
- [ ] Swap creation returns expected response
- [ ] Status polling works
- [ ] Claim/refund operations work

### Integration Tests
- [ ] Full BTC → USDC swap flow on testnet
- [ ] Full USDC → BTC swap flow on testnet
- [ ] Swap recovery after app restart
- [ ] Same mnemonic on web shows same swaps

### UI Tests
- [ ] Asset selector shows all tokens
- [ ] Amount input validates correctly
- [ ] Address input validates EVM/Ark addresses
- [ ] Swap status updates in real-time
- [ ] Error states handled gracefully

## Security Considerations

1. **EVM Address Validation** - Validate checksum before creating swap
2. **Amount Limits** - Enforce min/max from quote response
3. **Timeout Handling** - Handle swap expiration gracefully
4. **Refund Path** - Always show refund option for stuck swaps
5. **No Preimage Exposure** - Preimage only revealed after server deposits

## Future Enhancements

1. **WalletConnect Integration** - Connect external EVM wallets
2. **Push Notifications** - Notify when swap status changes
3. **Price Alerts** - Notify when rate is favorable
4. **Recurring Swaps** - DCA into BTC
5. **Swap Analytics** - Show total volume, savings, etc.
