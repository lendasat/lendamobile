//! LendaSwap integration module.
//!
//! This module provides the integration with the LendaSwap SDK for atomic swaps
//! between BTC (Arkade/Lightning) and stablecoins (USDC/USDT) on EVM chains.
//!
//! The module uses the same mnemonic as the Ark wallet, sharing key derivation
//! for seamless integration.

pub mod storage;

use crate::lendaswap::storage::{FileSwapStorage, FileWalletStorage};
use anyhow::{anyhow, Result};
use lendaswap_core::api::{
    AssetPair, BtcToEvmSwapResponse, EvmChain, EvmToBtcSwapResponse, GetSwapResponse,
    QuoteRequest, QuoteResponse, SwapStatus as ApiSwapStatus, TokenId,
};
use lendaswap_core::client::ExtendedSwapStorageData;
use lendaswap_core::{Client, Network};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::OnceLock;
use tokio::sync::RwLock;

/// Type alias for the LendaSwap client with our storage implementations.
type LendaSwapClient = Client<FileWalletStorage, FileSwapStorage>;

/// Atomic flag to track initialization state (for sync access).
static LENDASWAP_INITIALIZED: AtomicBool = AtomicBool::new(false);

/// Global LendaSwap client state
static LENDASWAP_CLIENT: OnceLock<RwLock<Option<LendaSwapClient>>> = OnceLock::new();

fn get_client_lock() -> &'static RwLock<Option<LendaSwapClient>> {
    LENDASWAP_CLIENT.get_or_init(|| RwLock::new(None))
}

/// Reset the LendaSwap client.
/// This MUST be called when the wallet is reset to ensure a new client
/// is created with the new mnemonic.
pub async fn reset_client() {
    let lock = get_client_lock();
    let mut guard = lock.write().await;
    *guard = None;
    LENDASWAP_INITIALIZED.store(false, Ordering::SeqCst);
    tracing::info!("LendaSwap client reset");
}

/// Initialize the LendaSwap client.
///
/// This should be called after the Ark wallet is initialized and the mnemonic exists.
pub async fn init_client(
    data_dir: String,
    network: Network,
    api_url: String,
    arkade_url: String,
) -> Result<()> {
    let wallet_storage = FileWalletStorage::new(data_dir.clone());
    let swap_storage = FileSwapStorage::new(data_dir)?;

    let client = Client::new(api_url, wallet_storage, swap_storage, network, arkade_url);

    // Initialize with existing mnemonic (shared with Ark wallet)
    client
        .init(None)
        .await
        .map_err(|e| anyhow!("Failed to initialize LendaSwap: {}", e))?;

    // Store in global state
    let lock = get_client_lock();
    let mut guard = lock.write().await;
    *guard = Some(client);

    // Set the atomic flag for sync access
    LENDASWAP_INITIALIZED.store(true, Ordering::SeqCst);

    tracing::info!("LendaSwap client initialized");
    Ok(())
}

/// Check if LendaSwap client is initialized (sync for UI checks).
pub fn is_initialized() -> bool {
    LENDASWAP_INITIALIZED.load(Ordering::SeqCst)
}

// ============================================================================
// Public API Functions
// ============================================================================

/// Get available asset pairs for swapping.
pub async fn get_asset_pairs() -> Result<Vec<AssetPair>> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .get_asset_pairs()
        .await
        .map_err(|e| anyhow!("Failed to get asset pairs: {}", e))
}

/// Get a quote for a swap.
pub async fn get_quote(from: TokenId, to: TokenId, base_amount_sats: u64) -> Result<QuoteResponse> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    let request = QuoteRequest {
        from,
        to,
        base_amount: base_amount_sats,
    };
    client
        .get_quote(&request)
        .await
        .map_err(|e| anyhow!("Failed to get quote: {}", e))
}

/// Create a BTC to EVM swap (sell BTC for stablecoins).
pub async fn create_btc_to_evm_swap(
    target_address: String,
    target_amount: Decimal,
    target_token: TokenId,
    target_chain: EvmChain,
    referral_code: Option<String>,
) -> Result<BtcToEvmSwapResponse> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .create_arkade_to_evm_swap(
            target_address,
            target_amount,
            target_token,
            target_chain,
            referral_code,
        )
        .await
        .map_err(|e| anyhow!("Failed to create BTC to EVM swap: {}", e))
}

/// Create an EVM to BTC swap (buy BTC with stablecoins).
pub async fn create_evm_to_btc_swap(
    target_address: String,
    user_evm_address: String,
    source_amount: Decimal,
    source_token: TokenId,
    source_chain: EvmChain,
    referral_code: Option<String>,
) -> Result<EvmToBtcSwapResponse> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .create_evm_to_arkade_swap(
            target_address,
            user_evm_address,
            source_amount,
            source_token,
            source_chain,
            referral_code,
        )
        .await
        .map_err(|e| anyhow!("Failed to create EVM to BTC swap: {}", e))
}

/// Create an EVM to Lightning swap.
pub async fn create_evm_to_lightning_swap(
    bolt11_invoice: String,
    user_evm_address: String,
    source_token: TokenId,
    source_chain: EvmChain,
    referral_code: Option<String>,
) -> Result<EvmToBtcSwapResponse> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .create_evm_to_lightning_swap(
            bolt11_invoice,
            user_evm_address,
            source_token,
            source_chain,
            referral_code,
        )
        .await
        .map_err(|e| anyhow!("Failed to create EVM to Lightning swap: {}", e))
}

/// Get swap details by ID.
pub async fn get_swap(swap_id: &str) -> Result<ExtendedSwapStorageData> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .get_swap(swap_id)
        .await
        .map_err(|e| anyhow!("Failed to get swap: {}", e))
}

/// List all swaps.
pub async fn list_swaps() -> Result<Vec<ExtendedSwapStorageData>> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .list_all()
        .await
        .map_err(|e| anyhow!("Failed to list swaps: {}", e))
}

/// Claim a swap via Gelato (gasless).
pub async fn claim_gelato(swap_id: &str, secret: Option<String>) -> Result<()> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .claim_gelato(swap_id, secret)
        .await
        .map_err(|e| anyhow!("Failed to claim via Gelato: {}", e))
}

/// Claim VHTLC for an EVM to BTC swap.
pub async fn claim_vhtlc(swap_id: &str) -> Result<String> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .claim_vhtlc(swap_id)
        .await
        .map_err(|e| anyhow!("Failed to claim VHTLC: {}", e))
}

/// Refund VHTLC for a failed BTC to EVM swap.
pub async fn refund_vhtlc(swap_id: &str, refund_address: &str) -> Result<String> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .refund_vhtlc(swap_id, refund_address)
        .await
        .map_err(|e| anyhow!("Failed to refund VHTLC: {}", e))
}

/// Recover swaps from server (after mnemonic restore).
pub async fn recover_swaps() -> Result<Vec<ExtendedSwapStorageData>> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .recover_swaps()
        .await
        .map_err(|e| anyhow!("Failed to recover swaps: {}", e))
}

/// Delete a swap from local storage.
pub async fn delete_swap(swap_id: &str) -> Result<()> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .delete_swap(swap_id.to_string())
        .await
        .map_err(|e| anyhow!("Failed to delete swap: {}", e))
}

/// Get the user's mnemonic.
pub async fn get_mnemonic() -> Result<String> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .get_mnemonic()
        .await
        .map_err(|e| anyhow!("Failed to get mnemonic: {}", e))
}

/// Get the user ID xpub for swap recovery.
pub async fn get_user_id_xpub() -> Result<String> {
    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard
        .as_ref()
        .ok_or_else(|| anyhow!("LendaSwap client not initialized"))?;

    client
        .get_user_id_xpub()
        .await
        .map_err(|e| anyhow!("Failed to get user ID xpub: {}", e))
}

// ============================================================================
// Flutter-friendly types
// ============================================================================

/// Simplified swap status for Flutter UI.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum SwapStatusSimple {
    /// Waiting for user to deposit funds
    WaitingForDeposit,
    /// User deposited, swap is processing
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
    Failed,
}

impl From<ApiSwapStatus> for SwapStatusSimple {
    fn from(status: ApiSwapStatus) -> Self {
        match status {
            ApiSwapStatus::Pending => SwapStatusSimple::WaitingForDeposit,
            ApiSwapStatus::ClientFunded => SwapStatusSimple::Processing,
            ApiSwapStatus::ServerFunded => SwapStatusSimple::Processing,
            ApiSwapStatus::ClientRedeeming => SwapStatusSimple::Processing,
            ApiSwapStatus::ClientRedeemed => SwapStatusSimple::Processing,
            ApiSwapStatus::ServerRedeemed => SwapStatusSimple::Completed,
            ApiSwapStatus::Expired => SwapStatusSimple::Expired,
            ApiSwapStatus::ClientRefunded => SwapStatusSimple::Refunded,
            ApiSwapStatus::ClientFundedServerRefunded => SwapStatusSimple::Refunded,
            ApiSwapStatus::ClientRefundedServerFunded => SwapStatusSimple::Refundable,
            ApiSwapStatus::ClientRefundedServerRefunded => SwapStatusSimple::Refunded,
            ApiSwapStatus::ClientInvalidFunded => SwapStatusSimple::Refundable,
            ApiSwapStatus::ClientFundedTooLate => SwapStatusSimple::Refundable,
            ApiSwapStatus::ClientRedeemedAndClientRefunded => SwapStatusSimple::Failed,
        }
    }
}

/// Simplified swap info for Flutter UI.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SwapInfo {
    pub id: String,
    pub status: SwapStatusSimple,
    pub direction: String, // "btc_to_evm" or "evm_to_btc"
    pub source_token: String,
    pub target_token: String,
    pub source_amount_sats: i64,
    pub target_amount_usd: f64,
    pub created_at: String,
    /// For BTC→EVM: Lightning invoice to pay
    pub ln_invoice: Option<String>,
    /// For BTC→EVM: Arkade HTLC address
    pub arkade_htlc_address: Option<String>,
    /// For EVM→BTC: EVM HTLC address to deposit to
    pub evm_htlc_address: Option<String>,
    /// Fee in satoshis
    pub fee_sats: i64,
    /// True when BTC→EVM swap can be claimed via Gelato (server has funded)
    pub can_claim_gelato: bool,
    /// True when EVM→BTC swap can claim the VHTLC (server has funded)
    pub can_claim_vhtlc: bool,
    /// True when swap can be refunded
    pub can_refund: bool,
    /// Detailed status string for debugging
    pub detailed_status: String,
}

impl SwapInfo {
    /// Convert from SDK response to simplified SwapInfo.
    pub fn from_extended_data(data: &ExtendedSwapStorageData) -> Self {
        match &data.response {
            GetSwapResponse::BtcToEvm(r) => {
                // For BTC→EVM: can claim via Gelato when server has funded
                let can_claim = matches!(r.common.status, ApiSwapStatus::ServerFunded);
                // Can refund if in refundable state
                let can_refund = matches!(
                    r.common.status,
                    ApiSwapStatus::ClientRefundedServerFunded
                        | ApiSwapStatus::ClientInvalidFunded
                        | ApiSwapStatus::ClientFundedTooLate
                );

                SwapInfo {
                    id: r.common.id.to_string(),
                    status: r.common.status.into(),
                    direction: "btc_to_evm".to_string(),
                    source_token: r.source_token.as_str().to_string(),
                    target_token: r.target_token.as_str().to_string(),
                    source_amount_sats: r.sats_receive,
                    target_amount_usd: r.common.asset_amount,
                    created_at: r.common.created_at.to_string(),
                    ln_invoice: Some(r.ln_invoice.clone()),
                    arkade_htlc_address: Some(r.htlc_address_arkade.clone()),
                    evm_htlc_address: None,
                    fee_sats: r.common.fee_sats,
                    can_claim_gelato: can_claim,
                    can_claim_vhtlc: false,
                    can_refund,
                    detailed_status: format!("{:?}", r.common.status),
                }
            }
            GetSwapResponse::EvmToBtc(r) => {
                // For EVM→BTC: can claim VHTLC when server has funded
                let can_claim = matches!(r.common.status, ApiSwapStatus::ServerFunded);
                // Can refund if in refundable state
                let can_refund = matches!(
                    r.common.status,
                    ApiSwapStatus::ClientRefundedServerFunded
                        | ApiSwapStatus::ClientInvalidFunded
                        | ApiSwapStatus::ClientFundedTooLate
                );

                SwapInfo {
                    id: r.common.id.to_string(),
                    status: r.common.status.into(),
                    direction: "evm_to_btc".to_string(),
                    source_token: r.source_token.as_str().to_string(),
                    target_token: r.target_token.as_str().to_string(),
                    source_amount_sats: r.sats_receive,
                    target_amount_usd: r.common.asset_amount,
                    created_at: r.common.created_at.to_string(),
                    ln_invoice: None,
                    arkade_htlc_address: None,
                    evm_htlc_address: Some(r.htlc_address_evm.clone()),
                    fee_sats: r.common.fee_sats,
                    can_claim_gelato: false,
                    can_claim_vhtlc: can_claim,
                    can_refund,
                    detailed_status: format!("{:?}", r.common.status),
                }
            }
        }
    }
}

/// Parse a network string into a Network enum.
pub fn parse_network(network: &str) -> Result<Network> {
    match network.to_lowercase().as_str() {
        "bitcoin" | "mainnet" => Ok(Network::Bitcoin),
        "testnet" | "testnet3" => Ok(Network::Testnet),
        "regtest" => Ok(Network::Regtest),
        _ => Err(anyhow!("Unknown network: {}", network)),
    }
}

/// Parse a token ID string into a TokenId enum.
pub fn parse_token_id(token: &str) -> Result<TokenId> {
    match token.to_lowercase().as_str() {
        "btc_lightning" => Ok(TokenId::BtcLightning),
        "btc_arkade" => Ok(TokenId::BtcArkade),
        _ => Ok(TokenId::Coin(token.to_string())),
    }
}

/// Parse an EVM chain string into an EvmChain enum.
pub fn parse_evm_chain(chain: &str) -> Result<EvmChain> {
    EvmChain::from_str(chain).map_err(|e| anyhow!("Invalid EVM chain: {}", e))
}
