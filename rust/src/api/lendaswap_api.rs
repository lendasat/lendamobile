//! LendaSwap API for Flutter.
//!
//! This module exposes the LendaSwap functionality to Flutter via flutter_rust_bridge.
//! All functions use simple types that can be easily marshalled across the FFI boundary.

use crate::lendaswap::{self, SwapInfo};
use anyhow::Result;
use lendaswap_core::api::GetSwapResponse;
use rust_decimal::Decimal;
use serde::{Deserialize, Serialize};
use std::str::FromStr;

// ============================================================================
// Initialization
// ============================================================================

/// Initialize the LendaSwap client.
///
/// Call this after the Ark wallet is initialized and the mnemonic exists.
///
/// # Arguments
/// * `data_dir` - Path to the app's data directory
/// * `network` - Bitcoin network: "bitcoin", "testnet", "signet", or "regtest"
/// * `api_url` - LendaSwap API URL (e.g., "https://api.lendaswap.com")
/// * `arkade_url` - Arkade server URL (e.g., "https://arkade.computer")
/// * `esplora_url` - Esplora API URL (e.g., "https://mutinynet.com/api")
pub async fn lendaswap_init(
    data_dir: String,
    network: String,
    api_url: String,
    arkade_url: String,
    esplora_url: String,
) -> Result<()> {
    tracing::info!(
        "[LendaSwap API] init called - data_dir: {}, network: {}, api_url: {}, arkade_url: {}, esplora_url: {}",
        data_dir,
        network,
        api_url,
        arkade_url,
        esplora_url
    );
    let network = lendaswap::parse_network(&network)?;
    let result = lendaswap::init_client(data_dir, network, api_url, arkade_url, esplora_url).await;
    match &result {
        Ok(_) => tracing::info!("[LendaSwap API] init SUCCESS"),
        Err(e) => tracing::error!("[LendaSwap API] init FAILED: {:?}", e),
    }
    result
}

/// Check if LendaSwap is initialized.
#[flutter_rust_bridge::frb(sync)]
pub fn lendaswap_is_initialized() -> bool {
    lendaswap::is_initialized()
}

// ============================================================================
// Asset Pairs and Quotes
// ============================================================================

/// Information about a tradeable asset.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AssetInfo {
    pub token_id: String,
    pub symbol: String,
    pub name: String,
    pub chain: String,
    pub decimals: u8,
}

/// A trading pair of assets.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TradingPair {
    pub source: AssetInfo,
    pub target: AssetInfo,
}

/// Get all available trading pairs.
pub async fn lendaswap_get_asset_pairs() -> Result<Vec<TradingPair>> {
    let pairs = lendaswap::get_asset_pairs().await?;

    Ok(pairs
        .into_iter()
        .map(|p| TradingPair {
            source: AssetInfo {
                token_id: p.source.token_id.as_str().to_string(),
                symbol: p.source.symbol,
                name: p.source.name,
                chain: format!("{:?}", p.source.chain),
                decimals: p.source.decimals,
            },
            target: AssetInfo {
                token_id: p.target.token_id.as_str().to_string(),
                symbol: p.target.symbol,
                name: p.target.name,
                chain: format!("{:?}", p.target.chain),
                decimals: p.target.decimals,
            },
        })
        .collect())
}

/// Quote response for a swap.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SwapQuote {
    /// Exchange rate as a string (e.g., "42000.50")
    pub exchange_rate: String,
    /// Network fee in satoshis
    pub network_fee_sats: u64,
    /// Protocol fee in satoshis
    pub protocol_fee_sats: u64,
    /// Protocol fee rate as percentage (e.g., 0.25 for 0.25%)
    pub protocol_fee_percent: f64,
    /// Minimum swap amount in satoshis
    pub min_amount_sats: u64,
    /// Maximum swap amount in satoshis
    pub max_amount_sats: u64,
}

/// Get a quote for a swap.
///
/// # Arguments
/// * `from_token` - Source token ID (e.g., "btc_arkade", "usdc_pol")
/// * `to_token` - Target token ID
/// * `amount_sats` - Amount in satoshis (for BTC) or smallest unit (for tokens)
pub async fn lendaswap_get_quote(
    from_token: String,
    to_token: String,
    amount_sats: u64,
) -> Result<SwapQuote> {
    let from = lendaswap::parse_token_id(&from_token)?;
    let to = lendaswap::parse_token_id(&to_token)?;

    let quote = lendaswap::get_quote(from, to, amount_sats).await?;

    Ok(SwapQuote {
        exchange_rate: quote.exchange_rate,
        network_fee_sats: quote.network_fee,
        protocol_fee_sats: quote.protocol_fee,
        protocol_fee_percent: quote.protocol_fee_rate * 100.0,
        min_amount_sats: quote.min_amount,
        max_amount_sats: quote.max_amount,
    })
}

// ============================================================================
// Swap Creation
// ============================================================================

/// Response when creating a BTC to EVM swap.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BtcToEvmSwapResult {
    pub swap_id: String,
    /// Lightning invoice to pay
    pub ln_invoice: String,
    /// Arkade HTLC address (alternative to Lightning)
    pub arkade_htlc_address: String,
    /// Amount in satoshis to send
    pub sats_to_send: i64,
    /// Target token amount (e.g., USDC amount)
    pub target_amount_usd: f64,
    /// Fee in satoshis
    pub fee_sats: i64,
}

/// Create a BTC to EVM swap (sell BTC for stablecoins).
///
/// # Arguments
/// * `target_evm_address` - User's EVM address to receive tokens
/// * `target_amount_usd` - Amount of USD-equivalent to receive
/// * `target_token` - Target token ID (e.g., "usdc_pol", "usdt_eth")
/// * `target_chain` - EVM chain: "polygon" or "ethereum"
/// * `referral_code` - Optional referral code
pub async fn lendaswap_create_btc_to_evm_swap(
    target_evm_address: String,
    target_amount_usd: f64,
    target_token: String,
    target_chain: String,
    referral_code: Option<String>,
) -> Result<BtcToEvmSwapResult> {
    tracing::info!(
        "[LendaSwap API] create_btc_to_evm_swap called - target_evm_address: {}, target_amount_usd: {}, target_token: {}, target_chain: {}, referral_code: {:?}",
        target_evm_address,
        target_amount_usd,
        target_token,
        target_chain,
        referral_code
    );

    let token = lendaswap::parse_token_id(&target_token)?;
    tracing::debug!("[LendaSwap API] parsed token: {:?}", token);

    let chain = lendaswap::parse_evm_chain(&target_chain)?;
    tracing::debug!("[LendaSwap API] parsed chain: {:?}", chain);

    let amount = Decimal::from_str(&target_amount_usd.to_string())
        .map_err(|e| anyhow::anyhow!("Invalid amount: {}", e))?;
    tracing::debug!("[LendaSwap API] parsed amount: {}", amount);

    tracing::info!("[LendaSwap API] calling lendaswap::create_btc_to_evm_swap...");
    let response = match lendaswap::create_btc_to_evm_swap(
        target_evm_address.clone(),
        amount,
        token,
        chain,
        referral_code,
    )
    .await
    {
        Ok(r) => {
            tracing::info!("[LendaSwap API] create_btc_to_evm_swap SDK call SUCCESS");
            tracing::info!("[LendaSwap API] swap_id: {}", r.common.id);
            tracing::info!("[LendaSwap API] status: {:?}", r.common.status);
            tracing::info!(
                "[LendaSwap API] ln_invoice: {}...",
                &r.ln_invoice[..50.min(r.ln_invoice.len())]
            );
            tracing::info!(
                "[LendaSwap API] htlc_address_arkade: {}",
                r.htlc_address_arkade
            );
            tracing::info!("[LendaSwap API] sats_receive: {}", r.sats_receive);
            tracing::info!("[LendaSwap API] asset_amount: {}", r.common.asset_amount);
            tracing::info!("[LendaSwap API] fee_sats: {}", r.common.fee_sats);
            r
        }
        Err(e) => {
            tracing::error!(
                "[LendaSwap API] create_btc_to_evm_swap SDK call FAILED: {:?}",
                e
            );
            return Err(e);
        }
    };

    let result = BtcToEvmSwapResult {
        swap_id: response.common.id.to_string(),
        ln_invoice: response.ln_invoice,
        arkade_htlc_address: response.htlc_address_arkade,
        sats_to_send: response.sats_receive,
        target_amount_usd: response.common.asset_amount,
        fee_sats: response.common.fee_sats,
    };
    tracing::info!(
        "[LendaSwap API] returning BtcToEvmSwapResult for swap_id: {}",
        result.swap_id
    );
    Ok(result)
}

/// Response when creating an EVM to BTC swap.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EvmToBtcSwapResult {
    pub swap_id: String,
    /// EVM HTLC contract address to deposit tokens
    pub evm_htlc_address: String,
    /// Amount of tokens to deposit (in token's smallest unit)
    pub source_amount_usd: f64,
    /// BTC amount user will receive in satoshis
    pub sats_to_receive: i64,
    /// Fee in satoshis
    pub fee_sats: i64,
    /// Token address for approval (ERC20)
    pub source_token_address: String,
    /// Pre-built calldata for createSwap() contract call
    /// This MUST be called via WalletConnect to properly fund the HTLC
    pub create_swap_tx: Option<String>,
    /// Pre-built calldata for approve() on the ERC20 token
    pub approve_tx: Option<String>,
    /// Gelato forwarder address (for gasless transactions)
    pub gelato_forwarder_address: Option<String>,
    /// Gelato user nonce
    pub gelato_user_nonce: Option<String>,
    /// Gelato deadline
    pub gelato_user_deadline: Option<String>,
}

/// Create an EVM to BTC swap (buy BTC with stablecoins).
///
/// # Arguments
/// * `target_ark_address` - User's Arkade address to receive BTC
/// * `user_evm_address` - User's EVM address (source of funds)
/// * `source_amount_usd` - Amount of tokens to spend (in USD)
/// * `source_token` - Source token ID (e.g., "usdc_pol")
/// * `source_chain` - EVM chain: "polygon" or "ethereum"
/// * `referral_code` - Optional referral code
pub async fn lendaswap_create_evm_to_btc_swap(
    target_ark_address: String,
    user_evm_address: String,
    source_amount_usd: f64,
    source_token: String,
    source_chain: String,
    referral_code: Option<String>,
) -> Result<EvmToBtcSwapResult> {
    let token = lendaswap::parse_token_id(&source_token)?;
    let chain = lendaswap::parse_evm_chain(&source_chain)?;
    let amount = Decimal::from_str(&source_amount_usd.to_string())
        .map_err(|e| anyhow::anyhow!("Invalid amount: {}", e))?;

    let response = lendaswap::create_evm_to_btc_swap(
        target_ark_address,
        user_evm_address,
        amount,
        token,
        chain,
        referral_code,
    )
    .await?;

    Ok(EvmToBtcSwapResult {
        swap_id: response.common.id.to_string(),
        evm_htlc_address: response.htlc_address_evm,
        source_amount_usd: response.common.asset_amount,
        sats_to_receive: response.sats_receive,
        fee_sats: response.common.fee_sats,
        source_token_address: response.source_token_address,
        create_swap_tx: response.create_swap_tx,
        approve_tx: response.approve_tx,
        gelato_forwarder_address: response.gelato_forwarder_address,
        gelato_user_nonce: response.gelato_user_nonce,
        gelato_user_deadline: response.gelato_user_deadline,
    })
}

/// Create an EVM to Lightning swap.
///
/// # Arguments
/// * `bolt11_invoice` - Lightning BOLT11 invoice to pay
/// * `user_evm_address` - User's EVM address (source of funds)
/// * `source_token` - Source token ID (e.g., "usdc_pol")
/// * `source_chain` - EVM chain: "polygon" or "ethereum"
/// * `referral_code` - Optional referral code
pub async fn lendaswap_create_evm_to_lightning_swap(
    bolt11_invoice: String,
    user_evm_address: String,
    source_token: String,
    source_chain: String,
    referral_code: Option<String>,
) -> Result<EvmToBtcSwapResult> {
    let token = lendaswap::parse_token_id(&source_token)?;
    let chain = lendaswap::parse_evm_chain(&source_chain)?;

    let response = lendaswap::create_evm_to_lightning_swap(
        bolt11_invoice,
        user_evm_address,
        token,
        chain,
        referral_code,
    )
    .await?;

    Ok(EvmToBtcSwapResult {
        swap_id: response.common.id.to_string(),
        evm_htlc_address: response.htlc_address_evm,
        source_amount_usd: response.common.asset_amount,
        sats_to_receive: response.sats_receive,
        fee_sats: response.common.fee_sats,
        source_token_address: response.source_token_address,
        create_swap_tx: response.create_swap_tx,
        approve_tx: response.approve_tx,
        gelato_forwarder_address: response.gelato_forwarder_address,
        gelato_user_nonce: response.gelato_user_nonce,
        gelato_user_deadline: response.gelato_user_deadline,
    })
}

// ============================================================================
// Swap Management
// ============================================================================

/// Get swap details by ID.
pub async fn lendaswap_get_swap(swap_id: String) -> Result<SwapInfo> {
    tracing::info!("[LendaSwap API] get_swap called - swap_id: {}", swap_id);
    let data = match lendaswap::get_swap(&swap_id).await {
        Ok(d) => {
            tracing::info!("[LendaSwap API] get_swap SUCCESS for {}", swap_id);
            d
        }
        Err(e) => {
            tracing::error!("[LendaSwap API] get_swap FAILED for {}: {:?}", swap_id, e);
            return Err(e);
        }
    };
    let info = SwapInfo::from_extended_data(&data);
    tracing::info!(
        "[LendaSwap API] get_swap result - id: {}, status: {:?}, detailed_status: {}, can_claim_gelato: {}, can_claim_vhtlc: {}, can_refund: {}",
        info.id,
        info.status,
        info.detailed_status,
        info.can_claim_gelato,
        info.can_claim_vhtlc,
        info.can_refund
    );
    Ok(info)
}

/// List all swaps.
pub async fn lendaswap_list_swaps() -> Result<Vec<SwapInfo>> {
    tracing::info!("[LendaSwap API] list_swaps called");
    let swaps = match lendaswap::list_swaps().await {
        Ok(s) => {
            tracing::info!(
                "[LendaSwap API] list_swaps SUCCESS - found {} swaps from storage",
                s.len()
            );
            s
        }
        Err(e) => {
            tracing::error!("[LendaSwap API] list_swaps FAILED: {:?}", e);
            return Err(e);
        }
    };

    // Convert each swap with detailed logging
    let mut result = Vec::new();
    for (idx, swap_data) in swaps.iter().enumerate() {
        tracing::debug!(
            "[LendaSwap API] Converting swap {} of {}",
            idx + 1,
            swaps.len()
        );
        let info = SwapInfo::from_extended_data(swap_data);
        tracing::debug!(
            "[LendaSwap API] swap {} - id: {}, status: {:?}, detailed: {}, created_at: {}",
            idx + 1,
            info.id,
            info.status,
            info.detailed_status,
            info.created_at
        );
        result.push(info);
    }

    tracing::info!(
        "[LendaSwap API] list_swaps returning {} SwapInfo objects",
        result.len()
    );
    Ok(result)
}

/// Claim a swap via Gelato (gasless).
pub async fn lendaswap_claim_gelato(swap_id: String) -> Result<()> {
    tracing::info!("[LendaSwap API] claim_gelato called - swap_id: {}", swap_id);
    match lendaswap::claim_gelato(&swap_id, None).await {
        Ok(_) => {
            tracing::info!("[LendaSwap API] claim_gelato SUCCESS for {}", swap_id);
            Ok(())
        }
        Err(e) => {
            tracing::error!(
                "[LendaSwap API] claim_gelato FAILED for {}: {:?}",
                swap_id,
                e
            );
            Err(e)
        }
    }
}

/// Claim VHTLC for an EVM to BTC swap.
///
/// Returns the transaction ID.
pub async fn lendaswap_claim_vhtlc(swap_id: String) -> Result<String> {
    tracing::info!("[LendaSwap API] claim_vhtlc called - swap_id: {}", swap_id);
    match lendaswap::claim_vhtlc(&swap_id).await {
        Ok(txid) => {
            tracing::info!(
                "[LendaSwap API] claim_vhtlc SUCCESS for {} - txid: {}",
                swap_id,
                txid
            );
            Ok(txid)
        }
        Err(e) => {
            tracing::error!(
                "[LendaSwap API] claim_vhtlc FAILED for {}: {:?}",
                swap_id,
                e
            );
            Err(e)
        }
    }
}

/// Refund VHTLC for a failed BTC to EVM swap.
///
/// Returns the transaction ID.
pub async fn lendaswap_refund_vhtlc(swap_id: String, refund_address: String) -> Result<String> {
    lendaswap::refund_vhtlc(&swap_id, &refund_address).await
}

/// Refund on-chain HTLC for a failed BTC to Arkade swap.
///
/// This spends from the Taproot HTLC back to the user's Bitcoin address.
/// The refund is only possible after the locktime has expired.
///
/// Returns the transaction ID.
pub async fn lendaswap_refund_onchain_htlc(
    swap_id: String,
    refund_address: String,
) -> Result<String> {
    lendaswap::refund_onchain_htlc(&swap_id, &refund_address).await
}

/// Recover swaps from server (after mnemonic restore).
pub async fn lendaswap_recover_swaps() -> Result<Vec<SwapInfo>> {
    tracing::info!("[LendaSwap API] recover_swaps called");
    let swaps = match lendaswap::recover_swaps().await {
        Ok(s) => {
            tracing::info!(
                "[LendaSwap API] recover_swaps SDK SUCCESS - found {} swaps",
                s.len()
            );
            s
        }
        Err(e) => {
            tracing::error!("[LendaSwap API] recover_swaps SDK FAILED: {:?}", e);
            return Err(e);
        }
    };

    // Convert each swap with detailed logging to help debug serialization issues
    let mut result = Vec::new();
    for (idx, swap_data) in swaps.iter().enumerate() {
        tracing::debug!(
            "[LendaSwap API] Converting swap {} of {}",
            idx + 1,
            swaps.len()
        );
        let info = SwapInfo::from_extended_data(swap_data);
        tracing::debug!(
            "[LendaSwap API] Converted swap - id: {}, status: {:?}, direction: {}, created_at: {}",
            info.id,
            info.status,
            info.direction,
            info.created_at
        );
        result.push(info);
    }

    tracing::info!(
        "[LendaSwap API] recover_swaps returning {} SwapInfo objects",
        result.len()
    );
    Ok(result)
}

/// Delete a swap from local storage.
pub async fn lendaswap_delete_swap(swap_id: String) -> Result<()> {
    lendaswap::delete_swap(&swap_id).await
}

/// Clear all local swap storage and recover from server.
/// Use this when local storage is corrupted.
pub async fn lendaswap_clear_and_recover() -> Result<Vec<SwapInfo>> {
    lendaswap::clear_local_storage().await?;
    let swaps = lendaswap::recover_swaps().await?;
    Ok(swaps.iter().map(SwapInfo::from_extended_data).collect())
}

/// Get the preimage (secret) for a swap.
///
/// This is needed for claiming Ethereum swaps via WalletConnect,
/// where the user must call claimSwap(swapId, secret) on the HTLC contract.
///
/// # Returns
/// The preimage as a hex string (without 0x prefix).
pub async fn lendaswap_get_swap_preimage(swap_id: String) -> Result<String> {
    tracing::info!(
        "[LendaSwap API] get_swap_preimage called - swap_id: {}",
        swap_id
    );

    let data = lendaswap::get_swap(&swap_id).await?;
    let preimage_hex = hex::encode(data.swap_params.preimage);

    tracing::info!(
        "[LendaSwap API] get_swap_preimage SUCCESS - swap_id: {}, preimage_length: {}",
        swap_id,
        preimage_hex.len()
    );

    Ok(preimage_hex)
}

/// Get the HTLC claim data for a BTC→EVM swap.
///
/// Returns the data needed to call claimSwap on the Ethereum HTLC contract:
/// - htlc_address: The HTLC contract address on the EVM chain
/// - swap_id_bytes32: The swap ID formatted as bytes32 for the contract
/// - preimage_bytes32: The preimage/secret formatted as bytes32
/// - calldata: The complete calldata for the claimSwap transaction (ready to send)
///
/// The swap_id is converted to bytes32 by removing hyphens and padding with zeros.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HtlcClaimData {
    pub htlc_address: String,
    pub swap_id_bytes32: String,
    pub preimage_bytes32: String,
    /// Complete calldata for eth_sendTransaction: selector + swapId + secret
    pub calldata: String,
}

/// Get HTLC claim data for calling claimSwap on Ethereum.
///
/// This converts the swap ID and preimage to the bytes32 format expected
/// by the HTLC contract's claimSwap(bytes32 swapId, bytes32 secret) function.
pub async fn lendaswap_get_htlc_claim_data(swap_id: String) -> Result<HtlcClaimData> {
    tracing::info!(
        "[LendaSwap API] get_htlc_claim_data called - swap_id: {}",
        swap_id
    );

    let data = lendaswap::get_swap(&swap_id).await?;

    // Get the EVM HTLC address from the swap response
    let htlc_address = match &data.response {
        GetSwapResponse::BtcToEvm(r) => r.htlc_address_evm.clone(),
        _ => return Err(anyhow::anyhow!("Swap is not a BTC→EVM swap")),
    };

    // Convert UUID to bytes32: remove hyphens and pad with zeros
    // UUID is 32 hex chars (16 bytes), pad to 64 hex chars (32 bytes)
    let uuid_hex = swap_id.replace("-", "");
    let swap_id_hex = format!("{:0<64}", uuid_hex);
    let swap_id_bytes32 = format!("0x{}", swap_id_hex);

    // Preimage is already 32 bytes
    let preimage_hex = hex::encode(data.swap_params.preimage);
    let preimage_bytes32 = format!("0x{}", preimage_hex);

    // Build calldata: function selector (4 bytes) + swapId (32 bytes) + secret (32 bytes)
    // claimSwap(bytes32,bytes32) selector = 0x1818a9fa
    let calldata = format!("0x1818a9fa{}{}", swap_id_hex, preimage_hex);

    tracing::info!(
        "[LendaSwap API] get_htlc_claim_data SUCCESS - htlc: {}, calldata_len: {}",
        htlc_address,
        calldata.len()
    );

    Ok(HtlcClaimData {
        htlc_address,
        swap_id_bytes32,
        preimage_bytes32,
        calldata,
    })
}

// ============================================================================
// Helper exports for Flutter
// ============================================================================

/// Re-export SwapStatusSimple for Flutter.
pub use crate::lendaswap::SwapStatusSimple;

/// Re-export SwapInfo for Flutter.
pub use crate::lendaswap::SwapInfo as LendaswapSwapInfo;
