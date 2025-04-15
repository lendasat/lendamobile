mod address_helper;
pub mod client;
pub mod esplora;
mod seed_file;
pub mod storage;

use crate::ark::esplora::EsploraClient;
use crate::ark::seed_file::{read_seed_file, reset_wallet, write_seed_file};
use crate::ark::storage::InMemoryDb;
use crate::state::ARK_CLIENT;
use anyhow::{anyhow, bail, Result};
use ark_rs::client::OfflineClient;
use bitcoin::key::{Keypair, Secp256k1};
use bitcoin::secp256k1::{All, SecretKey};
use bitcoin::Network;
use nostr::Keys;
use parking_lot::RwLock;
use rand::RngCore;
use std::sync::Arc;

// const ESPLORA_URL: &str = "https://mutinynet.com/api";
// const ARK_SERVER: &'static str = "https://mutinynet.arkade.sh";

const ESPLORA_URL: &str = "http://localhost:30000";
const ARK_SERVER: &str = "http://localhost:7070";

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

    let info = client.server_info.clone();

    ARK_CLIENT.set(RwLock::new(Arc::new(client)));

    tracing::info!(server_pk = ?info.pk, "Connected to server");

    Ok(info.pk.to_string())
}

pub(crate) async fn wallet_exists(data_dir: String) -> Result<bool> {
    let maybe_sk = read_seed_file(data_dir.as_str())?;
    Ok(maybe_sk.is_some())
}

pub(crate) async fn nsec(data_dir: String) -> Result<nostr::SecretKey> {
    let sk = read_seed_file(data_dir.as_str())?.ok_or(anyhow!("Seed file does not exist"))?;
    let sk = nostr::SecretKey::from_slice(sk.as_ref())?;
    Ok(sk)
}

pub fn delete_wallet(data_dir: String) -> Result<()> {
    reset_wallet(data_dir.as_str())
}
