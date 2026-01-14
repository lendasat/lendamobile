//! LendaSwap integration module.
//!
//! This module provides the integration with the LendaSwap SDK for atomic swaps
//! between BTC (Arkade/Lightning) and stablecoins (USDC/USDT) on EVM chains.
//!
//! The module uses the same mnemonic as the Ark wallet, sharing key derivation
//! for seamless integration.

pub mod storage;
pub mod vtxo_swap_db;

use crate::lendaswap::storage::{FileSwapStorage, FileWalletStorage};
use crate::lendaswap::vtxo_swap_db::VtxoSwapDb;
use anyhow::{Result, anyhow};
use lendaswap_core::api::{
    AssetPair, BtcToEvmSwapResponse, EvmChain, EvmToBtcSwapResponse, GetSwapResponse, QuoteRequest,
    QuoteResponse, SwapStatus as ApiSwapStatus, TokenId,
};
use lendaswap_core::client::ExtendedSwapStorageData;
use lendaswap_core::{Client, Network};
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use std::sync::OnceLock;
use std::sync::atomic::{AtomicBool, Ordering};
use tokio::sync::RwLock;

/// Type alias for the LendaSwap client with our storage implementations.
type LendaSwapClient = Client<FileWalletStorage, FileSwapStorage, VtxoSwapDb>;

/// Atomic flag to track initialization state (for sync access).
static LENDASWAP_INITIALIZED: AtomicBool = AtomicBool::new(false);

/// Global LendaSwap client state
static LENDASWAP_CLIENT: OnceLock<RwLock<Option<LendaSwapClient>>> = OnceLock::new();

/// Stored initialization parameters for re-initialization after clearing storage.
#[derive(Clone)]
struct InitParams {
    data_dir: String,
    network: Network,
    api_url: String,
    arkade_url: String,
    esplora_url: String,
}

/// Global storage for init params
static INIT_PARAMS: OnceLock<RwLock<Option<InitParams>>> = OnceLock::new();

fn get_client_lock() -> &'static RwLock<Option<LendaSwapClient>> {
    LENDASWAP_CLIENT.get_or_init(|| RwLock::new(None))
}

fn get_init_params_lock() -> &'static RwLock<Option<InitParams>> {
    INIT_PARAMS.get_or_init(|| RwLock::new(None))
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
    esplora_url: String,
) -> Result<()> {
    // Store init params for potential re-initialization
    {
        let params_lock = get_init_params_lock();
        let mut params_guard = params_lock.write().await;
        *params_guard = Some(InitParams {
            data_dir: data_dir.clone(),
            network,
            api_url: api_url.clone(),
            arkade_url: arkade_url.clone(),
            esplora_url: esplora_url.clone(),
        });
    }

    let wallet_storage = FileWalletStorage::new(data_dir.clone());
    let swap_storage = FileSwapStorage::new(data_dir.clone())?;
    let vtxo_swap_storage = VtxoSwapDb::new(data_dir)
        .await
        .map_err(|e| anyhow!("Failed to create VtxoSwapDb: {}", e))?;

    let client = Client::new(
        api_url,
        wallet_storage,
        swap_storage,
        vtxo_swap_storage,
        network,
        arkade_url,
        esplora_url,
    );

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
    tracing::info!(
        "[LendaSwap] create_btc_to_evm_swap - target_address: {}, amount: {}, token: {:?}, chain: {:?}",
        target_address,
        target_amount,
        target_token,
        target_chain
    );

    let lock = get_client_lock();
    tracing::debug!("[LendaSwap] acquired client lock");
    let guard = lock.read().await;
    let client = guard.as_ref().ok_or_else(|| {
        tracing::error!("[LendaSwap] client not initialized!");
        anyhow!("LendaSwap client not initialized")
    })?;

    tracing::info!("[LendaSwap] calling SDK create_arkade_to_evm_swap...");
    let result = client
        .create_arkade_to_evm_swap(
            target_address.clone(),
            target_amount,
            target_token.clone(),
            target_chain,
            referral_code,
        )
        .await;

    match &result {
        Ok(response) => {
            tracing::info!("[LendaSwap] SDK create_arkade_to_evm_swap SUCCESS");
            tracing::info!("[LendaSwap] response.common.id: {}", response.common.id);
            tracing::info!(
                "[LendaSwap] response.common.status: {:?}",
                response.common.status
            );
            tracing::info!(
                "[LendaSwap] response.ln_invoice length: {}",
                response.ln_invoice.len()
            );
            tracing::info!(
                "[LendaSwap] response.htlc_address_arkade: {}",
                response.htlc_address_arkade
            );
        }
        Err(e) => {
            tracing::error!("[LendaSwap] SDK create_arkade_to_evm_swap FAILED: {:?}", e);
        }
    }

    result.map_err(|e| anyhow!("Failed to create BTC to EVM swap: {}", e))
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
    tracing::info!("[LendaSwap] get_swap called - swap_id: {}", swap_id);

    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard.as_ref().ok_or_else(|| {
        tracing::error!("[LendaSwap] get_swap - client not initialized!");
        anyhow!("LendaSwap client not initialized")
    })?;

    tracing::debug!("[LendaSwap] calling SDK get_swap...");
    let result = client.get_swap(swap_id).await;

    match &result {
        Ok(data) => {
            let status = match &data.response {
                GetSwapResponse::BtcToEvm(r) => format!("{:?}", r.common.status),
                GetSwapResponse::EvmToBtc(r) => format!("{:?}", r.common.status),
                GetSwapResponse::BtcToArkade(r) => format!("{:?}", r.status),
            };
            tracing::info!(
                "[LendaSwap] get_swap SUCCESS - swap_id: {}, status: {}",
                swap_id,
                status
            );
        }
        Err(e) => {
            tracing::error!("[LendaSwap] get_swap FAILED: {:?}", e);
        }
    }

    result.map_err(|e| anyhow!("Failed to get swap: {}", e))
}

/// List all swaps.
pub async fn list_swaps() -> Result<Vec<ExtendedSwapStorageData>> {
    tracing::info!("[LendaSwap] list_swaps called");

    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard.as_ref().ok_or_else(|| {
        tracing::error!("[LendaSwap] list_swaps - client not initialized!");
        anyhow!("LendaSwap client not initialized")
    })?;

    let result = client.list_all().await;

    match &result {
        Ok(swaps) => {
            tracing::info!(
                "[LendaSwap] list_swaps SUCCESS - found {} swaps",
                swaps.len()
            );
            for s in swaps.iter() {
                let (id, status) = match &s.response {
                    GetSwapResponse::BtcToEvm(r) => {
                        (r.common.id.to_string(), format!("{:?}", r.common.status))
                    }
                    GetSwapResponse::EvmToBtc(r) => {
                        (r.common.id.to_string(), format!("{:?}", r.common.status))
                    }
                    GetSwapResponse::BtcToArkade(r) => {
                        (r.id.to_string(), format!("{:?}", r.status))
                    }
                };
                tracing::debug!("[LendaSwap] - swap {} status: {}", id, status);
            }
        }
        Err(e) => {
            tracing::error!("[LendaSwap] list_swaps FAILED: {:?}", e);
        }
    }

    result.map_err(|e| anyhow!("Failed to list swaps: {}", e))
}

/// Claim a swap via Gelato (gasless).
pub async fn claim_gelato(swap_id: &str, secret: Option<String>) -> Result<()> {
    tracing::info!(
        "[LendaSwap] claim_gelato called - swap_id: {}, has_secret: {}",
        swap_id,
        secret.is_some()
    );

    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard.as_ref().ok_or_else(|| {
        tracing::error!("[LendaSwap] claim_gelato - client not initialized!");
        anyhow!("LendaSwap client not initialized")
    })?;

    tracing::info!("[LendaSwap] calling SDK claim_gelato...");
    let result = client.claim_gelato(swap_id, secret).await;

    match &result {
        Ok(_) => {
            tracing::info!("[LendaSwap] claim_gelato SUCCESS for {}", swap_id);
        }
        Err(e) => {
            tracing::error!("[LendaSwap] claim_gelato FAILED for {}: {:?}", swap_id, e);
        }
    }

    result.map_err(|e| anyhow!("Failed to claim via Gelato: {}", e))
}

/// Claim VHTLC for an EVM to BTC swap.
pub async fn claim_vhtlc(swap_id: &str) -> Result<String> {
    tracing::info!("[LendaSwap] claim_vhtlc called - swap_id: {}", swap_id);

    let lock = get_client_lock();
    let guard = lock.read().await;
    let client = guard.as_ref().ok_or_else(|| {
        tracing::error!("[LendaSwap] claim_vhtlc - client not initialized!");
        anyhow!("LendaSwap client not initialized")
    })?;

    tracing::info!("[LendaSwap] calling SDK claim_vhtlc...");
    let result = client.claim_vhtlc(swap_id).await;

    match &result {
        Ok(txid) => {
            tracing::info!(
                "[LendaSwap] claim_vhtlc SUCCESS for {} - txid: {}",
                swap_id,
                txid
            );
        }
        Err(e) => {
            tracing::error!("[LendaSwap] claim_vhtlc FAILED for {}: {:?}", swap_id, e);
        }
    }

    result.map_err(|e| anyhow!("Failed to claim VHTLC: {}", e))
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

/// Clear all local swap storage.
/// This deletes all locally stored swaps and resets the client.
/// Call recover_swaps() after this to fetch swaps from the server.
pub async fn clear_local_storage() -> Result<()> {
    use std::fs;
    use std::path::Path;

    // Get the stored initialization parameters
    let params = {
        let params_lock = get_init_params_lock();
        let params_guard = params_lock.read().await;
        params_guard
            .clone()
            .ok_or_else(|| anyhow!("LendaSwap was never initialized - no init params stored"))?
    };

    // Reset the client first to release any file handles
    reset_client().await;

    // Delete the swaps directory (FileSwapStorage)
    let swaps_dir = Path::new(&params.data_dir).join("lendaswap_swaps");
    if swaps_dir.exists() {
        fs::remove_dir_all(&swaps_dir)
            .map_err(|e| anyhow!("Failed to delete lendaswap_swaps directory: {}", e))?;
        tracing::info!("Cleared lendaswap_swaps directory");
    }

    // Delete the VTXO swaps SQLite database
    let vtxo_db_path = Path::new(&params.data_dir).join("lendaswap_vtxo_swaps.sqlite");
    if vtxo_db_path.exists() {
        fs::remove_file(&vtxo_db_path)
            .map_err(|e| anyhow!("Failed to delete lendaswap_vtxo_swaps.sqlite: {}", e))?;
        tracing::info!("Cleared lendaswap_vtxo_swaps.sqlite");
    }

    // Re-initialize the client with stored parameters
    init_client(
        params.data_dir,
        params.network,
        params.api_url,
        params.arkade_url,
        params.esplora_url,
    )
    .await?;

    tracing::info!("LendaSwap local storage cleared and client re-initialized");
    Ok(())
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
            ApiSwapStatus::ClientFundingSeen => SwapStatusSimple::Processing,
            ApiSwapStatus::ClientFunded => SwapStatusSimple::Processing,
            ApiSwapStatus::ServerFunded => SwapStatusSimple::Processing,
            ApiSwapStatus::ClientRedeeming => SwapStatusSimple::Processing,
            // ClientRedeemed means the user has successfully claimed their funds
            // This should be treated as completed (matches web frontend behavior)
            ApiSwapStatus::ClientRedeemed => SwapStatusSimple::Completed,
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
    /// EVM HTLC claim transaction ID (Polygon/Ethereum tx hash)
    /// This is set when the swap completes and the EVM side is claimed.
    /// Used for loan repayment verification.
    pub evm_htlc_claim_txid: Option<String>,
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
                    evm_htlc_claim_txid: r.evm_htlc_claim_txid.clone(),
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
                    evm_htlc_claim_txid: r.evm_htlc_claim_txid.clone(),
                }
            }
            GetSwapResponse::BtcToArkade(_) => {
                unimplemented!("not supported at the moment")
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
