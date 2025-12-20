//! Lendasat integration module.
//!
//! This module provides the integration with the Lendasat lending platform
//! for Bitcoin-collateralized loans with stablecoin payouts.
//!
//! ## Architecture
//!
//! Unlike the iframe implementation which uses PostMessage for wallet communication,
//! the native integration directly accesses the Ark wallet for:
//! - Public key retrieval
//! - Message signing (for authentication)
//! - PSBT signing (for collateral claim/recovery)
//!
//! ## Authentication
//!
//! Lendasat uses secp256k1 pubkey challenge-response authentication:
//! 1. Get compressed public key from wallet
//! 2. Request challenge from API
//! 3. Sign challenge with ECDSA (SHA256 hash)
//! 4. Verify signature and receive JWT token

pub mod auth;
pub mod models;
pub mod storage;

pub use models::*;
