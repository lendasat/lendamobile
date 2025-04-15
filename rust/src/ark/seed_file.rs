use anyhow::anyhow;
use anyhow::Result;
use bitcoin::secp256k1::SecretKey;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::Path;

pub fn write_seed_file(sk: &SecretKey, data_dir: String) -> Result<()> {
    let data_path = Path::new(&data_dir);
    fs::create_dir_all(data_path).map_err(|e| anyhow!("Failed to create data directory: {}", e))?;
    let seed_path = data_path.join("seed");
    let mut file =
        File::create(&seed_path).map_err(|e| anyhow!("Failed to create seed file: {}", e))?;

    let sk_hex = hex::encode(sk.secret_bytes());

    file.write_all(sk_hex.as_bytes())
        .map_err(|e| anyhow!("Failed to write seed file: {}", e))?;

    tracing::debug!(seed_path = ?seed_path, "Stored secret key in file");

    Ok(())
}

pub fn read_seed_file(data_dir: &str) -> Result<Option<SecretKey>> {
    let data_path = Path::new(data_dir);
    let seed_path = data_path.join("seed");

    // Check if seed file exists
    if !seed_path.exists() {
        tracing::debug!(seed_path = ?seed_path, "Seed file does not exist");
        return Ok(None);
    }

    // Read the file contents
    let sk_hex =
        fs::read_to_string(&seed_path).map_err(|e| anyhow!("Failed to read seed file: {}", e))?;

    // Decode hex to bytes
    let sk_bytes = hex::decode(sk_hex.trim())
        .map_err(|e| anyhow!("Failed to decode hex in seed file: {}", e))?;

    // Create SecretKey from bytes
    let sk = SecretKey::from_slice(&sk_bytes)
        .map_err(|e| anyhow!("Failed to create secret key from seed file: {}", e))?;

    tracing::debug!(seed_path = ?seed_path, "Successfully read secret key from file");

    Ok(Some(sk))
}

pub fn reset_wallet(data_dir: &str) -> Result<()> {
    let data_path = Path::new(data_dir);
    let seed_path = data_path.join("seed");

    if !seed_path.exists() {
        tracing::warn!(seed_path = ?seed_path, "Seed file does not exist");
    } else {
        fs::remove_file(&seed_path)?;
        tracing::info!("Seed file deleted");
    }

    Ok(())
}
