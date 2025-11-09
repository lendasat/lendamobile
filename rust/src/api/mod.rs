use crate::frb_generated::StreamSink;
use crate::logger;
use crate::models::exchange_rates::{ExchangeRates, FiatCurrency};

pub mod ark_api;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn init_logging(sink: StreamSink<logger::LogEntry>) {
    logger::create_log_stream(sink)
}

pub async fn fetch_exchange_rates() -> anyhow::Result<ExchangeRates> {
    crate::models::exchange_rates::fetch_exchange_rates().await
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_supported_currencies() -> Vec<FiatCurrency> {
    FiatCurrency::all()
}

#[flutter_rust_bridge::frb(sync)]
pub fn currency_code(currency: FiatCurrency) -> String {
    currency.code().to_string()
}
