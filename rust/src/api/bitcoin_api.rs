use crate::models::historical_prices::{HistoricalPriceResponse, TimeRange};
use anyhow::{bail, Context as AnyhowContext, Result};

/// Fetch historical Bitcoin prices for a given time range.
pub async fn fetch_historical_prices(
    server_url: String,
    time_range: String,
) -> Result<HistoricalPriceResponse> {
    let range = TimeRange::from_string(&time_range)
        .ok_or_else(|| anyhow::anyhow!("Invalid time range: {}", time_range))?;

    let url = format!(
        "{}/api/historical-prices?range={}",
        server_url,
        range.to_query_param()
    );

    let client = reqwest::Client::new();
    let response = client
        .get(&url)
        .send()
        .await
        .context("Failed to fetch historical prices")?;

    if !response.status().is_success() {
        bail!(
            "Failed to fetch historical prices: status {}",
            response.status()
        );
    }

    let data = response
        .json::<HistoricalPriceResponse>()
        .await
        .context("Failed to parse historical prices response")?;

    Ok(data)
}
