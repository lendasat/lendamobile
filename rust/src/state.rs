use crate::ark::esplora::EsploraClient;
use crate::ark::storage::InMemoryDb;
use crate::frb_generated::StreamSink;
use crate::logger::LogEntry;
use ark_bdk_wallet::Wallet;
use ark_client::{Client, SqliteSwapStorage, StaticKeyProvider};
use parking_lot::RwLock;
use state::InitCell;
use std::sync::Arc;

pub static LOG_STREAM_SINK: InitCell<RwLock<Arc<StreamSink<LogEntry>>>> = InitCell::new();
#[allow(clippy::type_complexity)]
pub static ARK_CLIENT: InitCell<
    RwLock<Arc<Client<EsploraClient, Wallet<InMemoryDb>, SqliteSwapStorage, StaticKeyProvider>>>,
> = InitCell::new();
