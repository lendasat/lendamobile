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
use ark_client::{OfflineClient, SqliteSwapStorage};
use bitcoin::key::{Keypair, Secp256k1};
use bitcoin::secp256k1::{All, SecretKey};
use bitcoin::Network;
use nostr::Keys;
use parking_lot::RwLock;
use rand::RngCore;
use std::path::Path;
use std::sync::Arc;
use std::time::Duration;

pub async fn setup_new_wallet(
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();
    let secp = Secp256k1::new();
    let mut random_bytes = [0u8; 32];
    rand::thread_rng().fill_bytes(&mut random_bytes);

    // Create a secret key from the random bytes
    let sk = SecretKey::from_slice(&random_bytes)
        .map_err(|e| anyhow::anyhow!("Failed to create secret key: {}", e))?;

    write_seed_file(&sk, data_dir.clone())
        .map_err(|e| anyhow!("Failed to write seed file: {}", e))?;

    let kp = Keypair::from_secret_key(&secp, &sk);
    let pubkey = setup_client(
        kp,
        secp,
        network,
        esplora.clone(),
        server.clone(),
        boltz_url.clone(),
        data_dir
    )
    .await
    .map_err(|e| {
        anyhow!(
            "Failed to setup client - Network: {:?}, Esplora: {}, Server: {}, Boltz: {} - Error: {}",
            network,
            esplora,
            server,
            boltz_url,
            e
        )
    })?;
    Ok(pubkey)
}

pub async fn restore_wallet(
    nsec: String,
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();
    let secp = Secp256k1::new();
    let keys =
        Keys::parse(nsec.as_str()).map_err(|e| anyhow!("Failed to parse nsec key: {}", e))?;
    let kp = *keys.key_pair(&secp);
    write_seed_file(&kp.secret_key(), data_dir.clone())
        .map_err(|e| anyhow!("Failed to write seed file: {}", e))?;

    let pubkey = setup_client(kp, secp, network, esplora.clone(), server.clone(), boltz_url,data_dir ).await
        .map_err(|e| anyhow!("Failed to setup client after restore - Network: {:?}, Esplora: {}, Server: {} - Error: {}", network, esplora, server, e))?;
    Ok(pubkey)
}

pub(crate) async fn load_existing_wallet(
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();
    let maybe_sk = read_seed_file(data_dir.as_str())
        .map_err(|e| anyhow!("Failed to read seed file from '{}': {}", data_dir, e))?;

    match maybe_sk {
        None => {
            bail!("No seed file found in directory: {}", data_dir)
        }
        Some(key) => {
            let secp = Secp256k1::new();
            let kp = Keypair::from_secret_key(&secp, &key);
            let server_pk = setup_client(kp, secp, network, esplora.clone(), server.clone(), boltz_url, data_dir ).await
                .map_err(|e| anyhow!("Failed to setup client from existing wallet - Network: {:?}, Esplora: {}, Server: {} - Error: {}", network, esplora, server, e))?;
            Ok(server_pk)
        }
    }
}

pub async fn setup_client(
    kp: Keypair,
    secp: Secp256k1<All>,
    network: Network,
    esplora_url: String,
    server: String,
    boltz_url: String,
    data_dir: String,
) -> Result<String> {
    let db = InMemoryDb::default();

    let wallet = ark_bdk_wallet::Wallet::new(kp, secp, network, esplora_url.as_str(), db)
        .map_err(|e| anyhow!("Failed to create wallet: {}", e))?;

    let wallet = Arc::new(wallet);
    let esplora = EsploraClient::new(esplora_url.as_str()).map_err(|e| {
        anyhow!(
            "Failed to create Esplora client for URL '{}': {}",
            esplora_url,
            e
        )
    })?;
    tracing::info!("Checking esplora connection");

    esplora
        .check_connection()
        .await
        .map_err(|e| anyhow!("Failed to connect to Esplora at '{}': {}", esplora_url, e))?;

    tracing::info!("Connecting to Ark");

    let data_path = Path::new(data_dir.as_str());
    let swap_storage = data_path.join("boltz_swap_storage.sqlite");

    let sqlite_storage = SqliteSwapStorage::new(swap_storage)
        .await
        .map_err(|e| anyhow!(e))?;

    let client = OfflineClient::new(
        "sample-client".to_string(),
        kp,
        Arc::new(esplora),
        wallet,
        server.clone(),
        Arc::new(sqlite_storage),
        boltz_url,
        Duration::from_secs(30),
    )
    .connect()
    .await
    .map_err(|err| anyhow!("Failed to connect to Ark server at '{}': {}", server, err))?;

    let info = client.server_info.clone();

    ARK_CLIENT.set(RwLock::new(Arc::new(client)));

    tracing::info!(server_pk = ?info.signer_pk, "Connected to server");

    Ok(info.signer_pk.to_string())
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
