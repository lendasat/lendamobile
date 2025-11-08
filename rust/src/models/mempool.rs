use serde::{Deserialize, Serialize};

/// Block information from mempool.space
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Block {
    pub id: String,
    pub height: u64,
    pub version: u32,
    pub timestamp: u64,
    pub bits: u32,
    pub nonce: u32,
    pub difficulty: f64,
    pub merkle_root: String,
    pub tx_count: u32,
    pub size: u64,
    pub weight: u64,
    pub previousblockhash: Option<String>,
    pub mediantime: Option<u64>,
    pub stale: Option<bool>,
    pub extras: Option<BlockExtras>,
}

/// Extended block information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BlockExtras {
    pub median_fee: Option<f64>,
    pub total_fees: Option<u64>,
    pub avg_fee: Option<f64>,
    pub avg_fee_rate: Option<f64>,
    pub reward: Option<f64>,
    pub pool: Option<MiningPool>,
}

/// Mining pool information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MiningPool {
    pub id: Option<u32>,
    pub name: String,
    pub slug: Option<String>,
}

/// Transaction details from mempool.space
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BitcoinTransaction {
    pub txid: String,
    pub version: u32,
    pub locktime: u32,
    pub size: u32,
    pub weight: u32,
    pub fee: u64,
    pub sigops: Option<u32>,
    pub status: TxStatus,
    pub vin: Vec<TxInput>,
    pub vout: Vec<TxOutput>,
}

/// Transaction confirmation status
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TxStatus {
    pub confirmed: bool,
    pub block_height: Option<u64>,
    pub block_hash: Option<String>,
    pub block_time: Option<u64>,
}

/// Transaction input
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TxInput {
    pub txid: String,
    pub vout: u32,
    pub prevout: Option<TxOutput>,
    pub scriptsig: String,
    pub scriptsig_asm: String,
    pub witness: Option<Vec<String>>,
    pub is_coinbase: bool,
    pub sequence: u32,
}

/// Transaction output
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TxOutput {
    pub scriptpubkey: String,
    pub scriptpubkey_asm: String,
    pub scriptpubkey_type: String,
    pub scriptpubkey_address: Option<String>,
    pub value: u64,
}

/// Recommended fee rates for different confirmation targets
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RecommendedFees {
    #[serde(rename = "fastestFee")]
    pub fastest_fee: u32,
    #[serde(rename = "halfHourFee")]
    pub half_hour_fee: u32,
    #[serde(rename = "hourFee")]
    pub hour_fee: u32,
    #[serde(rename = "economyFee")]
    pub economy_fee: u32,
    #[serde(rename = "minimumFee")]
    pub minimum_fee: u32,
}

/// Difficulty adjustment information
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DifficultyAdjustment {
    #[serde(rename = "progressPercent")]
    pub progress_percent: f64,
    #[serde(rename = "difficultyChange")]
    pub difficulty_change: f64,
    #[serde(rename = "estimatedRetargetDate")]
    pub estimated_retarget_date: u64,
    #[serde(rename = "remainingBlocks")]
    pub remaining_blocks: u32,
    #[serde(rename = "remainingTime")]
    pub remaining_time: u64,
    #[serde(rename = "previousRetarget")]
    pub previous_retarget: Option<f64>,
    #[serde(rename = "previousTime")]
    pub previous_time: Option<u64>,
    #[serde(rename = "nextRetargetHeight")]
    pub next_retarget_height: u64,
    #[serde(rename = "timeAvg")]
    pub time_avg: u64,
    #[serde(rename = "adjustedTimeAvg")]
    pub adjusted_time_avg: Option<u64>,
    #[serde(rename = "timeOffset")]
    pub time_offset: i64,
    #[serde(rename = "expectedBlocks")]
    pub expected_blocks: f64,
}

/// Mining hashrate data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HashrateData {
    #[serde(rename = "currentHashrate")]
    pub current_hashrate: Option<f64>,
    #[serde(rename = "currentDifficulty")]
    pub current_difficulty: Option<f64>,
    pub hashrates: Vec<HashratePoint>,
    pub difficulty: Vec<DifficultyPoint>,
}

/// Single hashrate data point
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HashratePoint {
    pub timestamp: u64,
    #[serde(rename = "avgHashrate")]
    pub avg_hashrate: f64,
}

/// Single difficulty data point
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DifficultyPoint {
    pub timestamp: Option<u64>,
    pub difficulty: Option<f64>,
    pub height: Option<u64>,
}

/// Mempool block (unconfirmed/pending block)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MempoolBlock {
    #[serde(rename = "blockSize")]
    pub block_size: u64,
    #[serde(rename = "blockVSize")]
    pub block_vsize: f64,  // API returns float, not integer
    #[serde(rename = "nTx")]
    pub n_tx: u32,
    #[serde(rename = "totalFees")]
    pub total_fees: u64,
    #[serde(rename = "medianFee")]
    pub median_fee: f64,
    #[serde(rename = "feeRange")]
    pub fee_range: Vec<f64>,
}

/// WebSocket message envelope from mempool.space
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct MempoolWsMessage {
    #[serde(rename = "mempool-blocks")]
    pub mempool_blocks: Option<Vec<MempoolBlock>>,
    pub blocks: Option<Vec<Block>>,
    pub conversions: Option<Conversions>,
    pub fees: Option<RecommendedFees>,
    pub da: Option<DifficultyAdjustment>,
}

/// BTC price conversions
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Conversions {
    pub time: u64,
    #[serde(rename = "USD")]
    pub usd: f64,
    #[serde(rename = "EUR")]
    pub eur: Option<f64>,
}

/// Projected transaction in a mempool block
/// Format: [txid, value, vsize, feerate, flags]
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectedTransaction {
    pub txid: String,
    pub value: u64,      // in satoshis
    pub vsize: u32,      // virtual size in bytes
    pub fee_rate: f64,   // sat/vB
    pub flags: u32,
}

/// Message containing transactions for a tracked mempool block
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectedBlockTransactions {
    pub index: u32,
    pub transactions: Vec<ProjectedTransaction>,
}
