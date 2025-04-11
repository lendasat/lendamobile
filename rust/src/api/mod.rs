use crate::frb_generated::StreamSink;
use crate::logger;

pub mod simple;

pub fn test(i: i32) {
    // using the 'log' crate macros
    tracing::info!("test called with: {i}")
}

pub fn init_logging(sink: StreamSink<logger::LogEntry>) {
    logger::create_log_stream(sink)
}
