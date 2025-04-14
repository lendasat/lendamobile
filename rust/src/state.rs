use crate::frb_generated::StreamSink;
use crate::logger::LogEntry;
use parking_lot::RwLock;
use state::InitCell;
use std::sync::Arc;

pub static LOG_STREAM_SINK: InitCell<RwLock<Arc<StreamSink<LogEntry>>>> = InitCell::new();
