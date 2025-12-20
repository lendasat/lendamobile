use serde::{Deserialize, Serialize};

/// Block information from mempool.space
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct Block {
    #[serde(default)]
    pub id: String,
    #[serde(default)]
    pub height: u64,
    #[serde(default)]
    pub version: u32,
    #[serde(default)]
    pub timestamp: u64,
    #[serde(default)]
    pub bits: u32,
    #[serde(default)]
    pub nonce: u32,
    #[serde(default)]
    pub difficulty: f64,
    #[serde(default)]
    pub merkle_root: String,
    #[serde(default)]
    pub tx_count: u32,
    #[serde(default)]
    pub size: u64,
    #[serde(default)]
    pub weight: u64,
    #[serde(default)]
    pub previousblockhash: Option<String>,
    #[serde(default)]
    pub mediantime: Option<u64>,
    #[serde(default)]
    pub stale: Option<bool>,
    #[serde(default)]
    pub extras: Option<BlockExtras>,
}

/// Extended block information
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct BlockExtras {
    #[serde(rename = "medianFee", default)]
    pub median_fee: Option<f64>,
    #[serde(rename = "totalFees", default)]
    pub total_fees: Option<u64>,
    #[serde(rename = "avgFee", default)]
    pub avg_fee: Option<f64>,
    #[serde(rename = "avgFeeRate", default)]
    pub avg_fee_rate: Option<f64>,
    #[serde(default)]
    pub reward: Option<u64>,
    #[serde(default)]
    pub pool: Option<MiningPool>,
    #[serde(rename = "matchRate", default)]
    pub match_rate: Option<f64>,
    #[serde(default)]
    pub similarity: Option<f64>,
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
    pub fastest_fee: f64,
    #[serde(rename = "halfHourFee")]
    pub half_hour_fee: f64,
    #[serde(rename = "hourFee")]
    pub hour_fee: f64,
    #[serde(rename = "economyFee")]
    pub economy_fee: f64,
    #[serde(rename = "minimumFee")]
    pub minimum_fee: f64,
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
    pub block_vsize: f64, // API returns float, not integer
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
    pub value: u64,    // in satoshis
    pub vsize: u32,    // virtual size in bytes
    pub fee_rate: f64, // sat/vB
    pub flags: u32,
}

/// Message containing transactions for a tracked mempool block

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ProjectedBlockTransactions {
    pub index: u32,
    pub transactions: Vec<ProjectedTransaction>,
}

/// Fear & Greed Index response from RapidAPI
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FearGreedIndex {
    #[serde(rename = "lastUpdated")]
    pub last_updated: Option<FearGreedLastUpdated>,
    pub fgi: Option<FearGreedData>,
}

/// Last updated timestamp for Fear & Greed data
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FearGreedLastUpdated {
    #[serde(rename = "epochUnixSeconds")]
    pub epoch_unix_seconds: Option<i64>,
    #[serde(rename = "humanDate")]
    pub human_date: Option<String>,
}

/// Fear & Greed data with current and historical values
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FearGreedData {
    pub now: Option<FearGreedValue>,
    #[serde(rename = "previousClose")]
    pub previous_close: Option<FearGreedValue>,
    #[serde(rename = "oneWeekAgo")]
    pub one_week_ago: Option<FearGreedValue>,
    #[serde(rename = "oneMonthAgo")]
    pub one_month_ago: Option<FearGreedValue>,
    #[serde(rename = "oneYearAgo")]
    pub one_year_ago: Option<FearGreedValue>,
}

/// Single Fear & Greed value with numeric value and text description
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FearGreedValue {
    pub value: Option<i32>,
    #[serde(rename = "valueText")]
    pub value_text: Option<String>,
}
