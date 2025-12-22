use crate::models::moonpay::{MoonPayCurrencyLimits, MoonPayEncryptedData, MoonPayQuote};
use anyhow::{Context, Result};

/// Get currency limits for MoonPay transactions
pub async fn moonpay_get_currency_limits(
    server_url: String,
    base_currency_code: String,
    payment_method: String,
) -> Result<MoonPayCurrencyLimits> {
    let url = format!(
        "{}/api/moonpay/limits?baseCurrencyCode={}&paymentMethod={}",
        server_url, base_currency_code, payment_method
    );

    let http_client = reqwest::Client::new();
    let response = http_client
        .get(&url)
        .send()
        .await
        .context("Failed to fetch MoonPay currency limits")?;

    if !response.status().is_success() {
        anyhow::bail!("Failed to get currency limits: {}", response.status());
    }

    let limits = response
        .json()
        .await
        .context("Failed to parse MoonPay currency limits response")?;

    Ok(limits)
}

/// Get a quote from MoonPay
pub async fn moonpay_get_quote(server_url: String) -> Result<MoonPayQuote> {
    let url = format!("{}/api/moonpay/quote", server_url);

    let http_client = reqwest::Client::new();
    let response = http_client
        .get(&url)
        .send()
        .await
        .context("Failed to fetch MoonPay quote")?;

    if !response.status().is_success() {
        anyhow::bail!("Failed to get quote: {}", response.status());
    }

    let quote = response
        .json()
        .await
        .context("Failed to parse MoonPay quote response")?;

    Ok(quote)
}

/// Encrypt data for MoonPay
pub async fn moonpay_encrypt_data(
    server_url: String,
    data: String,
) -> Result<MoonPayEncryptedData> {
    let url = format!("{}/api/moonpay/encrypt", server_url);

    let http_client = reqwest::Client::new();
    let response = http_client
        .post(&url)
        .header("Content-Type", "application/json")
        .body(format!(r#"{{"data":{}}}"#, data))
        .send()
        .await
        .context("Failed to encrypt data")?;

    if !response.status().is_success() {
        anyhow::bail!("Failed to encrypt data: {}", response.status());
    }

    let encrypted = response
        .json()
        .await
        .context("Failed to parse encrypt response")?;

    Ok(encrypted)
}
