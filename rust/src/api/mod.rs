use crate::frb_generated::StreamSink;
use crate::logger;

pub mod ark_api;
pub mod bitcoin_api;

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

pub fn init_logging(sink: StreamSink<logger::LogEntry>) {
    logger::create_log_stream(sink)
}
