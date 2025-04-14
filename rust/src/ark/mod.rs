mod esplora;
mod storage;

use crate::ark::esplora::EsploraClient;
use crate::ark::storage::InMemoryDb;
use anyhow::{anyhow, Result};
use ark_rs::client::OfflineClient;
use bitcoin::key::{Keypair, Secp256k1};
use bitcoin::secp256k1::{All, SecretKey};
use bitcoin::Network;
use nostr::Keys;
use std::str::FromStr;
use std::sync::Arc;

// const ESPLORA_URL: &str = "https://mutinynet.com/api";
// const ARK_SERVER: &'static str = "https://mutinynet.arkade.sh";

const ESPLORA_URL: &str = "http://localhost:30000";
const ARK_SERVER: &str = "http://localhost:7070";

pub async fn setup_new_wallet() -> Result<String> {
    let secp = Secp256k1::new();

    // TODO: generate random one
    let sk =
        SecretKey::from_str("01010101010101010001020304050607ffff0000ffff00006363636363636363")
            .expect("to be a secret key");
    let kp = Keypair::from_secret_key(&secp, &sk);
    let string = setup_client(kp, secp).await?;
    Ok(string)
}

pub async fn restore_wallet(nsec: String) -> Result<String> {
    let secp = Secp256k1::new();
    let keys = Keys::parse(nsec.as_str())?;
    let kp = *keys.key_pair(&secp);
    let string = setup_client(kp, secp).await?;
    Ok(string)
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
