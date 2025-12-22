//! LendaSwap API for Flutter.
//!
//! This module exposes the LendaSwap functionality to Flutter via flutter_rust_bridge.
//! All functions use simple types that can be easily marshalled across the FFI boundary.

use crate::lendaswap::{self, SwapInfo};
use anyhow::Result;
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
pub async fn lendaswap_init(
    data_dir: String,
    network: String,
    api_url: String,
    arkade_url: String,
) -> Result<()> {
    let network = lendaswap::parse_network(&network)?;
    lendaswap::init_client(data_dir, network, api_url, arkade_url).await
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
    let token = lendaswap::parse_token_id(&target_token)?;
    let chain = lendaswap::parse_evm_chain(&target_chain)?;
    let amount = Decimal::from_str(&target_amount_usd.to_string())
        .map_err(|e| anyhow::anyhow!("Invalid amount: {}", e))?;

    let response =
        lendaswap::create_btc_to_evm_swap(target_evm_address, amount, token, chain, referral_code)
            .await?;

    Ok(BtcToEvmSwapResult {
        swap_id: response.common.id.to_string(),
        ln_invoice: response.ln_invoice,
        arkade_htlc_address: response.htlc_address_arkade,
        sats_to_send: response.sats_receive,
        target_amount_usd: response.common.asset_amount,
        fee_sats: response.common.fee_sats,
    })
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
    let data = lendaswap::get_swap(&swap_id).await?;
    Ok(SwapInfo::from_extended_data(&data))
}

/// List all swaps.
pub async fn lendaswap_list_swaps() -> Result<Vec<SwapInfo>> {
    let swaps = lendaswap::list_swaps().await?;
    Ok(swaps.iter().map(SwapInfo::from_extended_data).collect())
}

/// Claim a swap via Gelato (gasless).
pub async fn lendaswap_claim_gelato(swap_id: String) -> Result<()> {
    lendaswap::claim_gelato(&swap_id, None).await
}

/// Claim VHTLC for an EVM to BTC swap.
///
/// Returns the transaction ID.
pub async fn lendaswap_claim_vhtlc(swap_id: String) -> Result<String> {
    lendaswap::claim_vhtlc(&swap_id).await
}

/// Refund VHTLC for a failed BTC to EVM swap.
///
/// Returns the transaction ID.
pub async fn lendaswap_refund_vhtlc(swap_id: String, refund_address: String) -> Result<String> {
    lendaswap::refund_vhtlc(&swap_id, &refund_address).await
}

/// Recover swaps from server (after mnemonic restore).
pub async fn lendaswap_recover_swaps() -> Result<Vec<SwapInfo>> {
    let swaps = lendaswap::recover_swaps().await?;
    Ok(swaps.iter().map(SwapInfo::from_extended_data).collect())
}

/// Delete a swap from local storage.
pub async fn lendaswap_delete_swap(swap_id: String) -> Result<()> {
    lendaswap::delete_swap(&swap_id).await
}

// ============================================================================
// Helper exports for Flutter
// ============================================================================

/// Re-export SwapStatusSimple for Flutter.
pub use crate::lendaswap::SwapStatusSimple;

/// Re-export SwapInfo for Flutter.
pub use crate::lendaswap::SwapInfo as LendaswapSwapInfo;
