//! Lendasat authentication module.
//!
//! Implements the secp256k1 pubkey challenge-response authentication
//! used by the Lendasat API.
//!
//! Uses a dedicated derivation path for Lendasat keys: m/10101'/0'/0

use crate::ark::mnemonic_file::{LENDASAT_DERIVATION_PATH, read_mnemonic_file};
use anyhow::{Result, anyhow};
use bitcoin::Network;
use bitcoin::PrivateKey;
use bitcoin::bip32::{DerivationPath, Xpriv};
use bitcoin::hashes::{Hash, sha256};
use bitcoin::key::{Keypair, Secp256k1};
use bitcoin::psbt::Psbt;
use bitcoin::secp256k1::Message;
use bitcoin::secp256k1::ecdsa::Signature;
use std::collections::HashMap;
use std::str::FromStr;
use std::sync::OnceLock;
use tokio::sync::RwLock;

/// Cache the Lendasat keypair for the session
static LENDASAT_KEYPAIR: OnceLock<RwLock<Option<Keypair>>> = OnceLock::new();

fn get_keypair_lock() -> &'static RwLock<Option<Keypair>> {
    LENDASAT_KEYPAIR.get_or_init(|| RwLock::new(None))
}

/// Clear the cached Lendasat keypair.
/// This MUST be called when the wallet is reset to ensure a new keypair
/// is derived from the new mnemonic.
pub async fn reset_keypair_cache() {
    let lock = get_keypair_lock();
    let mut guard = lock.write().await;
    *guard = None;
    tracing::info!("Lendasat keypair cache cleared");
}

/// Get or derive the Lendasat keypair from the wallet mnemonic.
async fn get_or_derive_keypair(data_dir: &str, network: Network) -> Result<Keypair> {
    let lock = get_keypair_lock();

    // Check if we already have the keypair cached
    {
        let guard = lock.read().await;
        if let Some(kp) = guard.as_ref() {
            return Ok(*kp);
        }
    }

    // Derive the keypair from mnemonic
    let mnemonic = read_mnemonic_file(data_dir)?
        .ok_or_else(|| anyhow!("No mnemonic file found - wallet not initialized"))?;

    let secp = Secp256k1::new();

    // Derive master key
    let seed = mnemonic.to_seed("");
    let master = Xpriv::new_master(network, &seed)
        .map_err(|e| anyhow!("Failed to derive master key: {}", e))?;

    // Derive at Lendasat path: m/10101'/0'/0
    let path = format!("{}/0", LENDASAT_DERIVATION_PATH);
    let derivation_path =
        DerivationPath::from_str(&path).map_err(|e| anyhow!("Invalid derivation path: {}", e))?;

    let derived = master
        .derive_priv(&secp, &derivation_path)
        .map_err(|e| anyhow!("Failed to derive key: {}", e))?;

    let keypair = Keypair::from_secret_key(&secp, &derived.private_key);

    // Cache the keypair
    {
        let mut guard = lock.write().await;
        *guard = Some(keypair);
    }

    tracing::debug!("Lendasat keypair derived at path: {}", path);

    Ok(keypair)
}

/// Get the compressed public key from the wallet.
/// Returns a 33-byte compressed public key as hex string (66 characters).
///
/// # Arguments
/// * `data_dir` - Path to the app's data directory containing the mnemonic
/// * `network` - Bitcoin network (for key derivation)
pub async fn get_public_key(data_dir: &str, network: Network) -> Result<String> {
    let keypair = get_or_derive_keypair(data_dir, network).await?;
    let pubkey_bytes = keypair.public_key().serialize();
    Ok(hex::encode(pubkey_bytes))
}

/// Get the derivation path used for Lendasat keys.
pub fn get_derivation_path() -> String {
    format!("{}/0", LENDASAT_DERIVATION_PATH)
}

/// Sign a message using the Lendasat private key.
///
/// The message is hashed with SHA256 before signing with ECDSA.
/// Returns a DER-encoded signature as hex string.
///
/// This matches the iframe wallet-bridge signMessage behavior:
/// 1. SHA256 hash the message bytes
/// 2. Sign the hash with ECDSA (secp256k1)
/// 3. Return DER-encoded signature as hex
///
/// # Arguments
/// * `message` - The message string to sign (typically a challenge from the server)
/// * `data_dir` - Path to the app's data directory
/// * `network` - Bitcoin network
pub async fn sign_message(message: &str, data_dir: &str, network: Network) -> Result<String> {
    let keypair = get_or_derive_keypair(data_dir, network).await?;
    let secp = Secp256k1::new();

    // Hash the message with SHA256
    let message_hash = sha256::Hash::hash(message.as_bytes());

    // Create a secp256k1 message from the hash
    let secp_message = Message::from_digest_slice(message_hash.as_ref())
        .map_err(|e| anyhow!("Failed to create message from hash: {}", e))?;

    // Sign the message
    let signature: Signature = secp.sign_ecdsa(&secp_message, &keypair.secret_key());

    // Return DER-encoded signature as hex
    Ok(hex::encode(signature.serialize_der()))
}

/// Clear the cached keypair (e.g., on logout or wallet reset).
pub async fn clear_cached_keypair() {
    let lock = get_keypair_lock();
    let mut guard = lock.write().await;
    *guard = None;
}

/// Sign a PSBT using the Lendasat private key.
///
/// This function mirrors the iframe wallet-bridge `signPsbt` behavior:
/// 1. Parse the PSBT from hex
/// 2. Verify the borrower_pk matches our public key (warning if not)
/// 3. Sign all inputs with our keypair
/// 4. Return the signed PSBT as hex
///
/// # Arguments
/// * `psbt_hex` - The PSBT encoded as hex string
/// * `collateral_descriptor` - The collateral descriptor (for context/logging)
/// * `borrower_pk` - The borrower public key (for verification)
/// * `data_dir` - Path to the app's data directory
/// * `network` - Bitcoin network
///
/// # Returns
/// The signed PSBT as hex string
pub async fn sign_psbt(
    psbt_hex: &str,
    _collateral_descriptor: &str,
    borrower_pk: &str,
    data_dir: &str,
    network: Network,
) -> Result<String> {
    // Get our keypair
    let keypair = get_or_derive_keypair(data_dir, network).await?;
    let secp = Secp256k1::new();

    // Get our public key as hex for comparison
    let our_pk_bytes = keypair.public_key().serialize();
    let our_pk_hex = hex::encode(our_pk_bytes);

    // Verify borrower_pk matches our key (warn if not, but don't fail)
    // This mirrors the iframe behavior which logs a warning
    if borrower_pk != our_pk_hex {
        tracing::warn!(
            "Warning: Borrower PK {} doesn't match wallet PK {}",
            &borrower_pk[..std::cmp::min(16, borrower_pk.len())],
            &our_pk_hex[..16]
        );
    }

    // Parse PSBT from hex
    let psbt_bytes = hex::decode(psbt_hex).map_err(|e| anyhow!("Invalid PSBT hex: {}", e))?;
    let mut psbt =
        Psbt::deserialize(&psbt_bytes).map_err(|e| anyhow!("Failed to parse PSBT: {}", e))?;

    tracing::debug!("Signing PSBT with {} inputs", psbt.inputs.len());

    // Create a key map for signing
    // The PSBT sign method requires a type that implements GetKey
    // We use a HashMap<PublicKey, PrivateKey>
    let private_key = PrivateKey::new(keypair.secret_key(), network);
    let public_key = bitcoin::PublicKey::new(keypair.public_key());

    let mut key_map: HashMap<bitcoin::PublicKey, PrivateKey> = HashMap::new();
    key_map.insert(public_key, private_key);

    // Sign all inputs that match our key
    match psbt.sign(&key_map, &secp) {
        Ok(signed_inputs) => {
            tracing::debug!("Signed {} inputs", signed_inputs.len());
        }
        Err((signed_inputs, errors)) => {
            // Partial success - some inputs may not need our key
            tracing::debug!(
                "Signed {} inputs, {} could not be signed (may not need our key)",
                signed_inputs.len(),
                errors.len()
            );
            for (idx, err) in &errors {
                tracing::debug!("Input {} signing note: {:?}", idx, err);
            }
        }
    }

    // Serialize the signed PSBT back to hex
    let signed_psbt_bytes = psbt.serialize();
    let signed_psbt_hex = hex::encode(signed_psbt_bytes);

    tracing::info!("PSBT signed successfully");

    Ok(signed_psbt_hex)
}

/// Verify a signature locally (for testing).
/// Returns true if the signature is valid.
#[allow(dead_code)]
pub fn verify_signature(pubkey_hex: &str, message: &str, signature_hex: &str) -> Result<bool> {
    // Decode public key
    let pubkey_bytes = hex::decode(pubkey_hex).map_err(|e| anyhow!("Invalid pubkey hex: {}", e))?;
    let pubkey = bitcoin::secp256k1::PublicKey::from_slice(&pubkey_bytes)
        .map_err(|e| anyhow!("Invalid public key: {}", e))?;

    // Hash the message
    let message_hash = sha256::Hash::hash(message.as_bytes());
    let secp_message = Message::from_digest_slice(message_hash.as_ref())
        .map_err(|e| anyhow!("Failed to create message: {}", e))?;

    // Decode signature
    let sig_bytes =
        hex::decode(signature_hex).map_err(|e| anyhow!("Invalid signature hex: {}", e))?;
    let signature =
        Signature::from_der(&sig_bytes).map_err(|e| anyhow!("Invalid DER signature: {}", e))?;

    // Verify
    let secp = Secp256k1::new();
    match secp.verify_ecdsa(&secp_message, &signature, &pubkey) {
        Ok(()) => Ok(true),
        Err(_) => Ok(false),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use bitcoin::secp256k1::rand::rngs::OsRng;

    #[test]
    fn test_sign_and_verify() {
        let secp = Secp256k1::new();
        let keypair = Keypair::new(&secp, &mut OsRng);

        let message = "test-challenge-12345";

        // Hash the message
        let message_hash = sha256::Hash::hash(message.as_bytes());
        let secp_message = Message::from_digest_slice(message_hash.as_ref()).unwrap();

        // Sign
        let signature = secp.sign_ecdsa(&secp_message, &keypair.secret_key());
        let sig_hex = hex::encode(signature.serialize_der());

        // Get pubkey
        let pubkey_hex = hex::encode(keypair.public_key().serialize());

        // Verify
        let result = verify_signature(&pubkey_hex, message, &sig_hex).unwrap();
        assert!(result);
    }

    #[test]
    fn test_invalid_signature() {
        let secp = Secp256k1::new();
        let keypair1 = Keypair::new(&secp, &mut OsRng);
        let keypair2 = Keypair::new(&secp, &mut OsRng);

        let message = "test-challenge-12345";

        // Hash and sign with keypair1
        let message_hash = sha256::Hash::hash(message.as_bytes());
        let secp_message = Message::from_digest_slice(message_hash.as_ref()).unwrap();
        let signature = secp.sign_ecdsa(&secp_message, &keypair1.secret_key());
        let sig_hex = hex::encode(signature.serialize_der());

        // Try to verify with keypair2's public key (should fail)
        let pubkey2_hex = hex::encode(keypair2.public_key().serialize());
        let result = verify_signature(&pubkey2_hex, message, &sig_hex).unwrap();
        assert!(!result);
    }
}
