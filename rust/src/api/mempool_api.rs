use crate::models::mempool::{BitcoinTransaction, Block, FearGreedIndex, HashrateData, RecommendedFees};
use anyhow::{Context, Result, bail};

/// Get the latest 15 Bitcoin blocks
pub async fn get_blocks() -> Result<Vec<Block>> {
    tracing::info!("Fetching latest blocks from mempool.space");

    let url = "https://mempool.space/api/blocks";

    let client = reqwest::Client::new();
    let response = client
        .get(url)
        .send()
        .await
        .context("Failed to fetch blocks from mempool.space")?;

    if !response.status().is_success() {
        bail!("Failed to fetch blocks: status {}", response.status());
    }

    let blocks = response
        .json::<Vec<Block>>()
        .await
        .context("Failed to parse blocks response")?;

    Ok(blocks)
}

/// Get blocks starting from a specific height
pub async fn get_blocks_at_height(height: u64) -> Result<Vec<Block>> {
    tracing::info!("Fetching blocks at height {} from mempool.space", height);

    let url = format!("https://mempool.space/api/blocks/{}", height);

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .context("Failed to fetch blocks at height from mempool.space")?;

    if !response.status().is_success() {
        bail!(
            "Failed to fetch blocks at height: status {}",
            response.status()
        );
    }

    let blocks = response
        .json::<Vec<Block>>()
        .await
        .context("Failed to parse blocks response")?;

    Ok(blocks)
}

/// Get detailed block information by hash
/// Uses the v1 API endpoint which includes extras (pool, reward, fees, etc.)
pub async fn get_block_by_hash(hash: &str) -> Result<Block> {
    tracing::info!("Fetching block by hash {} from mempool.space v1 API", hash);

    // Use v1 API to get full block details including extras
    let url = format!("https://mempool.space/api/v1/block/{}", hash);

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .context("Failed to fetch block by hash from mempool.space")?;

    if !response.status().is_success() {
        bail!(
            "Failed to fetch block by hash: status {}",
            response.status()
        );
    }

    let block = response
        .json::<Block>()
        .await
        .context("Failed to parse block response")?;

    Ok(block)
}

/// Get paginated block transactions
/// start_index should be multiples of 25 (0, 25, 50, etc.)
pub async fn get_block_transactions(
    hash: &str,
    start_index: u32,
) -> Result<Vec<BitcoinTransaction>> {
    tracing::info!(
        "Fetching transactions from mempool.space for block {} starting at {}",
        hash,
        start_index
    );

    let url = format!(
        "https://mempool.space/api/block/{}/txs/{}",
        hash, start_index
    );

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .context("Failed to fetch block transactions from mempool.space")?;

    if !response.status().is_success() {
        bail!(
            "Failed to fetch block transactions: status {}",
            response.status()
        );
    }

    let transactions = response
        .json::<Vec<BitcoinTransaction>>()
        .await
        .context("Failed to parse transactions response")?;

    Ok(transactions)
}

/// Get recommended fee rates for different confirmation targets
pub async fn get_recommended_fees() -> Result<RecommendedFees> {
    tracing::info!("Fetching recommended fees from mempool.space");

    let url = "https://mempool.space/api/v1/fees/recommended";

    let client = reqwest::Client::new();
    let response = client
        .get(url)
        .send()
        .await
        .context("Failed to fetch recommended fees from mempool.space")?;

    if !response.status().is_success() {
        bail!(
            "Failed to fetch recommended fees: status {}",
            response.status()
        );
    }

    let fees = response
        .json::<RecommendedFees>()
        .await
        .context("Failed to parse fees response")?;

    Ok(fees)
}

/// Get mining hashrate data for a specific time period
/// period: "1D", "1W", "1M", "1Y", "3Y"
pub async fn get_hashrate_data(period: &str) -> Result<HashrateData> {
    tracing::info!(
        "Fetching hashrate data for period {} from mempool.space",
        period
    );

    let url = format!("https://mempool.space/api/v1/mining/hashrate/{}", period);

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .context("Failed to fetch hashrate data from mempool.space")?;

    if !response.status().is_success() {
        bail!(
            "Failed to fetch hashrate data: status {}",
            response.status()
        );
    }

    let hashrate = response
        .json::<HashrateData>()
        .await
        .context("Failed to parse hashrate response")?;

    Ok(hashrate)
}

/// Get detailed transaction information by txid
pub async fn get_transaction(txid: &str) -> Result<BitcoinTransaction> {
    tracing::info!("Fetching transaction {} from mempool.space", txid);

    let url = format!("https://mempool.space/api/tx/{}", txid);

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .context("Failed to fetch transaction from mempool.space")?;

    if !response.status().is_success() {
        bail!("Failed to fetch transaction: status {}", response.status());
    }

    let transaction = response
        .json::<BitcoinTransaction>()
        .await
        .context("Failed to parse transaction response")?;

    Ok(transaction)
}

/// Get Fear & Greed Index from RapidAPI
/// Returns the current fear and greed index along with historical comparisons
pub async fn get_fear_greed_index() -> Result<FearGreedIndex> {
    tracing::info!("Fetching Fear & Greed Index from RapidAPI");

    let url = "https://fear-and-greed-index.p.rapidapi.com/v1/fgi";

    let client = reqwest::Client::new();
    let response = client
        .get(url)
        .header("X-RapidAPI-Key", "REDACTED_API_KEY")
        .header("X-RapidAPI-Host", "fear-and-greed-index.p.rapidapi.com")
        .send()
        .await
        .context("Failed to fetch Fear & Greed Index from RapidAPI")?;

    if !response.status().is_success() {
        bail!(
            "Failed to fetch Fear & Greed Index: status {}",
            response.status()
        );
    }

    let fgi = response
        .json::<FearGreedIndex>()
        .await
        .context("Failed to parse Fear & Greed Index response")?;

    Ok(fgi)
}
