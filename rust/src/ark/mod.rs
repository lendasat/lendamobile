mod esplora;
mod storage;

use crate::ark::esplora::EsploraClient;
use crate::ark::storage::InMemoryDb;
use anyhow::{anyhow, bail, Result};
use ark_rs::client::OfflineClient;
use bitcoin::key::{Keypair, Secp256k1};
use bitcoin::secp256k1::{All, SecretKey};
use bitcoin::Network;
use nostr::Keys;
use rand::RngCore;
use std::fs;
use std::fs::File;
use std::io::Write;
use std::path::Path;
use std::sync::Arc;

// const ESPLORA_URL: &str = "https://mutinynet.com/api";
// const ARK_SERVER: &'static str = "https://mutinynet.arkade.sh";

const ESPLORA_URL: &str = "http://localhost:30000";
const ARK_SERVER: &str = "http://localhost:7070";

pub fn write_seed_file(sk: &SecretKey, data_dir: String) -> Result<()> {
    let data_path = Path::new(&data_dir);
    fs::create_dir_all(data_path)
        .map_err(|e| anyhow::anyhow!("Failed to create data directory: {}", e))?;
    let seed_path = data_path.join("seed");
    let mut file = File::create(&seed_path)
        .map_err(|e| anyhow::anyhow!("Failed to create seed file: {}", e))?;

    let sk_hex = hex::encode(sk.secret_bytes());

    file.write_all(sk_hex.as_bytes())
        .map_err(|e| anyhow::anyhow!("Failed to write seed file: {}", e))?;

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
    let sk_hex = fs::read_to_string(&seed_path)
        .map_err(|e| anyhow::anyhow!("Failed to read seed file: {}", e))?;

    // Decode hex to bytes
    let sk_bytes = hex::decode(sk_hex.trim())
        .map_err(|e| anyhow::anyhow!("Failed to decode hex in seed file: {}", e))?;

    // Create SecretKey from bytes
    let sk = SecretKey::from_slice(&sk_bytes)
        .map_err(|e| anyhow::anyhow!("Failed to create secret key from seed file: {}", e))?;

    tracing::debug!(seed_path = ?seed_path, "Successfully read secret key from file");

    Ok(Some(sk))
}

pub async fn setup_new_wallet(data_dir: String) -> Result<String> {
    let secp = Secp256k1::new();
    let mut random_bytes = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut random_bytes);

    // Create a secret key from the random bytes
    let sk = SecretKey::from_slice(&random_bytes)
        .map_err(|e| anyhow::anyhow!("Failed to create secret key: {}", e))?;

    write_seed_file(&sk, data_dir)?;

    let kp = Keypair::from_secret_key(&secp, &sk);
    let pubkey = setup_client(kp, secp).await?;
    Ok(pubkey)
}

pub async fn restore_wallet(nsec: String, data_dir: String) -> Result<String> {
    let secp = Secp256k1::new();
    let keys = Keys::parse(nsec.as_str())?;
    let kp = *keys.key_pair(&secp);
    write_seed_file(&kp.secret_key(), data_dir)?;

    let pubkey = setup_client(kp, secp).await?;
    Ok(pubkey)
}

pub(crate) async fn load_existing_wallet(data_dir: String) -> Result<String> {
    let maybe_sk = read_seed_file(data_dir.as_str())?;

    match maybe_sk {
        None => {
            bail!("No seed file found")
        }
        Some(key) => {
            let secp = Secp256k1::new();
            let kp = Keypair::from_secret_key(&secp, &key);
            let server_pk = setup_client(kp, secp).await?;
            Ok(server_pk)
        }
    }
}

pub async fn setup_client(kp: Keypair, secp: Secp256k1<All>) -> Result<String> {
    let db = InMemoryDb::default();

    let wallet = ark_bdk_wallet::Wallet::new(kp, secp, Network::Signet, ESPLORA_URL, db)?;

    let wallet = Arc::new(wallet);
    let esplora = EsploraClient::new(ESPLORA_URL)?;
    tracing::info!("Checking esplora connection");

    esplora.check_connection().await?;

    tracing::info!("Connecting to Ark");
    let client = OfflineClient::new(
        "alice".to_string(),
        kp,
        Arc::new(esplora),
        wallet.clone(),
        ARK_SERVER.to_string(),
    )
    .connect()
    .await
    .map_err(|err| anyhow!(err))?;

    let info = client.server_info;

    tracing::info!(server_pk = ?info.pk, "Connected to server");

    Ok(info.pk.to_string())
}

pub(crate) async fn wallet_exists(data_dir: String) -> Result<bool> {
    let maybe_sk = read_seed_file(data_dir.as_str())?;
    Ok(maybe_sk.is_some())
}
