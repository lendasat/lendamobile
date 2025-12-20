use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExchangeRates {
    pub base: String,
    pub rates: HashMap<String, f64>,
    pub timestamp: i64,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum FiatCurrency {
    USD,
    EUR,
    GBP,
    JPY,
    CAD,
    AUD,
    CHF,
    CNY,
    INR,
    BRL,
    MXN,
    KRW,
}

impl FiatCurrency {
    pub fn code(&self) -> &'static str {
        match self {
            FiatCurrency::USD => "USD",
            FiatCurrency::EUR => "EUR",
            FiatCurrency::GBP => "GBP",
            FiatCurrency::JPY => "JPY",
            FiatCurrency::CAD => "CAD",
            FiatCurrency::AUD => "AUD",
            FiatCurrency::CHF => "CHF",
            FiatCurrency::CNY => "CNY",
            FiatCurrency::INR => "INR",
            FiatCurrency::BRL => "BRL",
            FiatCurrency::MXN => "MXN",
            FiatCurrency::KRW => "KRW",
        }
    }

    pub fn all() -> Vec<FiatCurrency> {
        vec![
            FiatCurrency::USD,
            FiatCurrency::EUR,
            FiatCurrency::GBP,
            FiatCurrency::JPY,
            FiatCurrency::CAD,
            FiatCurrency::AUD,
            FiatCurrency::CHF,
            FiatCurrency::CNY,
            FiatCurrency::INR,
            FiatCurrency::BRL,
            FiatCurrency::MXN,
            FiatCurrency::KRW,
        ]
    }
}

#[derive(Debug, Deserialize)]
struct ExchangeRateApiResponse {
    result: String,
    base_code: String,
    rates: HashMap<String, f64>,
    time_last_update_unix: i64,
}

pub async fn fetch_exchange_rates() -> anyhow::Result<ExchangeRates> {
    let url = "https://open.exchangerate-api.com/v6/latest/USD";

    let response = reqwest::get(url).await?;

    if !response.status().is_success() {
        anyhow::bail!("Failed to fetch exchange rates: {}", response.status());
    }

    let api_response: ExchangeRateApiResponse = response.json().await?;

    if api_response.result != "success" {
        anyhow::bail!("Exchange rate API returned non-success result");
    }

    Ok(ExchangeRates {
        base: api_response.base_code,
        rates: api_response.rates,
        timestamp: api_response.time_last_update_unix,
    })
}
