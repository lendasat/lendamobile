use crate::frb_generated::StreamSink;
use crate::logger;
use crate::models;
use anyhow::Result;

pub mod ark_api;
pub mod moonpay_api;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn init_logging(sink: StreamSink<logger::LogEntry>) {
    logger::create_log_stream(sink)
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
