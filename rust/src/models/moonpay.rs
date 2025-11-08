use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct MoonPayCurrencyLimits {
    #[serde(rename = "quoteCurrency")]
    pub quote_currency: CurrencyInfo,
    #[serde(rename = "baseCurrency")]
    pub base_currency: CurrencyInfo,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct CurrencyInfo {
    pub code: String,
    #[serde(rename = "minBuyAmount")]
    pub min_buy_amount: f64,
    #[serde(rename = "maxBuyAmount")]
    pub max_buy_amount: f64,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct MoonPayQuote {
    #[serde(rename = "baseCurrencyAmount")]
    pub base_currency_amount: f64,
    #[serde(rename = "quoteCurrencyAmount")]
    pub quote_currency_amount: f64,
    #[serde(rename = "baseCurrencyCode")]
    pub base_currency_code: String,
    pub exchange_rate: f64,
    pub timestamp: String,
}

impl MoonPayQuote {
    pub fn price_per_btc(&self) -> String {
        format!("${:.2}", self.exchange_rate)
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct MoonPayEncryptedData {
    pub ciphertext: String,
    pub iv: String,
}
