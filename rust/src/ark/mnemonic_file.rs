use anyhow::{anyhow, Result};
use bip39::Mnemonic;
use bitcoin::bip32::{DerivationPath, Xpriv};
use bitcoin::Network;
use rand::RngCore;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::Path;
use std::str::FromStr;

/// Arkade's default derivation path for HD wallet
/// This matches ark_core::DEFAULT_DERIVATION_PATH: m/83696968'/11811'/0/{index}
/// Note: This is NOT BIP84 - it's a custom path for Ark protocol
pub const ARK_BASE_DERIVATION_PATH: &str = "m/83696968'/11811'/0";

/// Derivation path for LendaSwap swap keys (from same mnemonic)
pub const LENDASWAP_DERIVATION_PATH: &str = "m/83696968'/121923'";

/// Derivation path for Lendasat contract keys (from same mnemonic)
pub const LENDASAT_DERIVATION_PATH: &str = "m/10101'/0'";

/// Derivation path for Nostr keys (NIP-06 compatible, from same mnemonic)
pub const NOSTR_DERIVATION_PATH: &str = "m/44'/1237'/0'/0/0";

/// Generate a new 12-word BIP39 mnemonic
pub fn generate_mnemonic() -> Result<Mnemonic> {
    // Generate 128 bits of entropy for 12-word mnemonic
    let mut entropy = [0u8; 16];
    rand::thread_rng().fill_bytes(&mut entropy);
    let mnemonic = Mnemonic::from_entropy(&entropy)
        .map_err(|e| anyhow!("Failed to generate mnemonic: {}", e))?;
    Ok(mnemonic)
}

/// Parse a mnemonic from a string (supports 12 or 24 words)
pub fn parse_mnemonic(words: &str) -> Result<Mnemonic> {
    let mnemonic = Mnemonic::from_str(words.trim())
        .map_err(|e| anyhow!("Failed to parse mnemonic: {}", e))?;
    Ok(mnemonic)
}

/// Derive the master extended private key (Xpriv) from a mnemonic
/// This is used for Arkade's Bip32KeyProvider which handles its own derivation paths
pub fn derive_master_xpriv(mnemonic: &Mnemonic, network: Network) -> Result<Xpriv> {
    let seed = mnemonic.to_seed("");
    let master = Xpriv::new_master(network, &seed)
        .map_err(|e| anyhow!("Failed to derive master key: {}", e))?;
    Ok(master)
}

/// Derive an extended private key (Xpriv) from a mnemonic at a specific path
/// Used for Nostr, LendaSwap, and other services that need their own derivation paths
pub fn derive_xpriv_at_path(mnemonic: &Mnemonic, path: &str, network: Network) -> Result<Xpriv> {
    let master = derive_master_xpriv(mnemonic, network)?;

    let derivation_path = DerivationPath::from_str(path)
        .map_err(|e| anyhow!("Invalid derivation path '{}': {}", path, e))?;

    let derived = master
        .derive_priv(&bitcoin::secp256k1::Secp256k1::new(), &derivation_path)
        .map_err(|e| anyhow!("Failed to derive key at path '{}': {}", path, e))?;

    Ok(derived)
}

/// Write the mnemonic to a file (encrypted storage recommended for production)
pub fn write_mnemonic_file(mnemonic: &Mnemonic, data_dir: &str) -> Result<()> {
    let data_path = Path::new(data_dir);
    fs::create_dir_all(data_path)
        .map_err(|e| anyhow!("Failed to create data directory: {}", e))?;

    let mnemonic_path = data_path.join("mnemonic");
    let mut file = File::create(&mnemonic_path)
        .map_err(|e| anyhow!("Failed to create mnemonic file: {}", e))?;

    // Store the mnemonic words
    file.write_all(mnemonic.to_string().as_bytes())
        .map_err(|e| anyhow!("Failed to write mnemonic file: {}", e))?;

    tracing::debug!(mnemonic_path = ?mnemonic_path, "Stored mnemonic in file");

    Ok(())
}

/// Read the mnemonic from a file
pub fn read_mnemonic_file(data_dir: &str) -> Result<Option<Mnemonic>> {
    let data_path = Path::new(data_dir);
    let mnemonic_path = data_path.join("mnemonic");

    if !mnemonic_path.exists() {
        tracing::debug!(mnemonic_path = ?mnemonic_path, "Mnemonic file does not exist");
        return Ok(None);
    }

    let mnemonic_str = fs::read_to_string(&mnemonic_path)
        .map_err(|e| anyhow!("Failed to read mnemonic file: {}", e))?;

    let mnemonic = parse_mnemonic(&mnemonic_str)?;

    tracing::debug!(mnemonic_path = ?mnemonic_path, "Successfully read mnemonic from file");

    Ok(Some(mnemonic))
}

/// Delete the mnemonic file
pub fn delete_mnemonic_file(data_dir: &str) -> Result<()> {
    let data_path = Path::new(data_dir);
    let mnemonic_path = data_path.join("mnemonic");

    if mnemonic_path.exists() {
        fs::remove_file(&mnemonic_path)
            .map_err(|e| anyhow!("Failed to delete mnemonic file: {}", e))?;
        tracing::info!("Mnemonic file deleted");
    } else {
        tracing::warn!(mnemonic_path = ?mnemonic_path, "Mnemonic file does not exist");
    }

    Ok(())
}

/// Check if a mnemonic file exists
pub fn mnemonic_exists(data_dir: &str) -> bool {
    let data_path = Path::new(data_dir);
    let mnemonic_path = data_path.join("mnemonic");
    mnemonic_path.exists()
}

/// Check if old seed file exists (for migration purposes)
pub fn legacy_seed_exists(data_dir: &str) -> bool {
    let data_path = Path::new(data_dir);
    let seed_path = data_path.join("seed");
    seed_path.exists()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_and_parse_mnemonic() {
        let mnemonic = generate_mnemonic().unwrap();
        let words = mnemonic.to_string();
        let parsed = parse_mnemonic(&words).unwrap();
        assert_eq!(mnemonic.to_string(), parsed.to_string());
    }

    #[test]
    fn test_derive_master_xpriv() {
        let mnemonic = parse_mnemonic(
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
        )
        .unwrap();
        let xpriv = derive_master_xpriv(&mnemonic, Network::Bitcoin).unwrap();
        assert!(xpriv.to_string().starts_with("xprv"));
    }

    #[test]
    fn test_derive_xpriv_at_path() {
        let mnemonic = parse_mnemonic(
            "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about",
        )
        .unwrap();
        let xpriv =
            derive_xpriv_at_path(&mnemonic, NOSTR_DERIVATION_PATH, Network::Bitcoin).unwrap();
        assert!(xpriv.to_string().starts_with("xprv"));
    }
}
