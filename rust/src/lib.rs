pub mod api;
pub mod ark;
pub mod lendaswap;
pub mod logger;
pub mod models;
mod state;

#[allow(clippy::all)]
mod frb_generated;

use std::sync::Once;

static INIT: Once = Once::new();

pub fn init_crypto_provider() {
    INIT.call_once(|| {
        let _ = rustls::crypto::ring::default_provider().install_default();
    });
}
