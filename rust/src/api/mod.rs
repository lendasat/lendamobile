use crate::frb_generated::StreamSink;
use crate::logger;
use crate::models;
use anyhow::Result;

pub mod ark_api;
pub mod bitcoin_api;
pub mod mempool_api;
pub mod mempool_block_tracker;
pub mod mempool_ws;
pub mod moonpay_api;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn init_logging(sink: StreamSink<logger::LogEntry>) {
    logger::create_log_stream(sink)
}

// Mempool API functions

/// Get the latest 15 Bitcoin blocks
pub async fn get_blocks() -> Result<Vec<models::mempool::Block>> {
    mempool_api::get_blocks().await
}

/// Get blocks starting from a specific height
pub async fn get_blocks_at_height(height: u64) -> Result<Vec<models::mempool::Block>> {
    mempool_api::get_blocks_at_height(height).await
}

/// Get detailed block information by hash
pub async fn get_block_by_hash(hash: String) -> Result<models::mempool::Block> {
    mempool_api::get_block_by_hash(&hash).await
}

/// Get paginated block transactions
/// start_index should be multiples of 25 (0, 25, 50, etc.)
pub async fn get_block_transactions(
    hash: String,
    start_index: u32,
) -> Result<Vec<models::mempool::BitcoinTransaction>> {
    mempool_api::get_block_transactions(&hash, start_index).await
}

/// Get recommended fee rates for different confirmation targets
pub async fn get_recommended_fees() -> Result<models::mempool::RecommendedFees> {
    mempool_api::get_recommended_fees().await
}

/// Get mining hashrate data for a specific time period
/// period: "1M", "3M", "6M", "1Y", "3Y"
pub async fn get_hashrate_data(period: String) -> Result<models::mempool::HashrateData> {
    mempool_api::get_hashrate_data(&period).await
}

/// Get detailed transaction information by transaction ID
pub async fn get_transaction(txid: String) -> Result<models::mempool::BitcoinTransaction> {
    mempool_api::get_transaction(&txid).await
}

/// Subscribe to real-time mempool updates via WebSocket
pub async fn subscribe_mempool_updates(
    sink: StreamSink<models::mempool::MempoolWsMessage>,
) -> Result<()> {
    mempool_ws::subscribe_mempool_updates(sink).await
}

/// Track a specific mempool block to receive its projected transactions.
pub async fn track_mempool_block(
    block_index: u32,
    sink: StreamSink<models::mempool::ProjectedBlockTransactions>,
) -> Result<()> {
    mempool_block_tracker::track_mempool_block(block_index, sink).await
}

pub async fn moonpay_get_currency_limits(
    server_url: String,
    base_currency_code: String,
    payment_method: String,
) -> Result<models::moonpay::MoonPayCurrencyLimits> {
    moonpay_api::moonpay_get_currency_limits(server_url, base_currency_code, payment_method).await
}

pub async fn moonpay_get_quote(server_url: String) -> Result<models::moonpay::MoonPayQuote> {
    moonpay_api::moonpay_get_quote(server_url).await
}

pub async fn moonpay_encrypt_data(
    server_url: String,
    data: String,
) -> Result<models::moonpay::MoonPayEncryptedData> {
    moonpay_api::moonpay_encrypt_data(server_url, data).await
}
