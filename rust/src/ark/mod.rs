mod address_helper;
pub mod client;
pub mod esplora;
pub mod mnemonic_file;
mod seed_file;
pub mod storage;

use crate::ark::esplora::EsploraClient;
use crate::ark::mnemonic_file::{
    delete_mnemonic_file, derive_master_xpriv, derive_xpriv_at_path, generate_mnemonic,
    legacy_seed_exists, mnemonic_exists, parse_mnemonic, read_mnemonic_file, write_mnemonic_file,
    ARK_BASE_DERIVATION_PATH, NOSTR_DERIVATION_PATH,
};
use crate::ark::seed_file::{read_seed_file, reset_wallet};
use crate::ark::storage::InMemoryDb;
use crate::state::{UnifiedKeyProvider, ARK_CLIENT};
use anyhow::{anyhow, bail, Result};
use ark_client::{Bip32KeyProvider, OfflineClient, SqliteSwapStorage, StaticKeyProvider};
use bitcoin::bip32::{DerivationPath, Xpriv};
use bitcoin::key::{Keypair, Secp256k1};
use bitcoin::secp256k1::All;
use bitcoin::Network;
use parking_lot::RwLock;
use std::path::Path;
use std::str::FromStr;
use std::sync::Arc;
use std::time::Duration;

/// Setup a new wallet with a freshly generated mnemonic
/// Returns the mnemonic words (user should back these up!)
pub async fn setup_new_wallet(
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();
    let secp = Secp256k1::new();

    // Generate a new 12-word mnemonic
    let mnemonic =
        generate_mnemonic().map_err(|e| anyhow!("Failed to generate mnemonic: {}", e))?;

    // Save the mnemonic to file
    write_mnemonic_file(&mnemonic, &data_dir)
        .map_err(|e| anyhow!("Failed to write mnemonic file: {}", e))?;

    // Derive the master xpriv from the mnemonic
    // Arkade's Bip32KeyProvider will handle its own derivation paths internally
    let master_xpriv = derive_master_xpriv(&mnemonic, network)
        .map_err(|e| anyhow!("Failed to derive master key: {}", e))?;

    let _server_pk = setup_client_hd(
        master_xpriv,
        secp,
        network,
        esplora.clone(),
        server.clone(),
        boltz_url.clone(),
        data_dir,
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

    // Return the mnemonic words so the user can back them up
    Ok(mnemonic.to_string())
}

/// Restore a wallet from a mnemonic phrase (12 or 24 words)
pub async fn restore_wallet(
    mnemonic_words: String,
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();
    let secp = Secp256k1::new();

    // Parse the mnemonic
    let mnemonic =
        parse_mnemonic(&mnemonic_words).map_err(|e| anyhow!("Failed to parse mnemonic: {}", e))?;

    // Save the mnemonic to file
    write_mnemonic_file(&mnemonic, &data_dir)
        .map_err(|e| anyhow!("Failed to write mnemonic file: {}", e))?;

    // Derive the master xpriv from the mnemonic
    // Arkade's Bip32KeyProvider will handle its own derivation paths internally
    let master_xpriv = derive_master_xpriv(&mnemonic, network)
        .map_err(|e| anyhow!("Failed to derive master key: {}", e))?;

    let server_pk = setup_client_hd(
        master_xpriv,
        secp,
        network,
        esplora.clone(),
        server.clone(),
        boltz_url,
        data_dir,
    )
    .await
    .map_err(|e| {
        anyhow!(
            "Failed to setup client after restore - Network: {:?}, Esplora: {}, Server: {} - Error: {}",
            network,
            esplora,
            server,
            e
        )
    })?;
    Ok(server_pk)
}

/// Load an existing wallet from stored mnemonic
/// Also supports legacy seed file migration
pub(crate) async fn load_existing_wallet(
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();
    let secp = Secp256k1::new();

    // First, try to load from mnemonic file (new format)
    if let Some(mnemonic) = read_mnemonic_file(&data_dir)
        .map_err(|e| anyhow!("Failed to read mnemonic file from '{}': {}", data_dir, e))?
    {
        tracing::info!("Loading wallet from mnemonic file");
        // Derive the master xpriv - Arkade handles its own derivation paths
        let master_xpriv = derive_master_xpriv(&mnemonic, network)
            .map_err(|e| anyhow!("Failed to derive master key: {}", e))?;

        let server_pk = setup_client_hd(
            master_xpriv,
            secp,
            network,
            esplora.clone(),
            server.clone(),
            boltz_url,
            data_dir,
        )
        .await
        .map_err(|e| {
            anyhow!(
                "Failed to setup client from existing wallet - Network: {:?}, Esplora: {}, Server: {} - Error: {}",
                network,
                esplora,
                server,
                e
            )
        })?;
        return Ok(server_pk);
    }

    // Fall back to legacy seed file (for migration)
    if let Some(key) = read_seed_file(&data_dir)
        .map_err(|e| anyhow!("Failed to read seed file from '{}': {}", data_dir, e))?
    {
        tracing::warn!("Loading wallet from legacy seed file - migration recommended");
        let kp = Keypair::from_secret_key(&secp, &key);
        let server_pk = setup_client_legacy(
            kp,
            secp,
            network,
            esplora.clone(),
            server.clone(),
            boltz_url,
            data_dir,
        )
        .await
        .map_err(|e| {
            anyhow!(
                "Failed to setup client from existing wallet - Network: {:?}, Esplora: {}, Server: {} - Error: {}",
                network,
                esplora,
                server,
                e
            )
        })?;
        return Ok(server_pk);
    }

    bail!("No wallet found in directory: {}", data_dir)
}

/// Setup client using HD wallet with Bip32KeyProvider
/// The master xpriv is passed in - Arkade's Bip32KeyProvider handles derivation internally
pub async fn setup_client_hd(
    master_xpriv: Xpriv,
    secp: Secp256k1<All>,
    network: Network,
    esplora_url: String,
    server: String,
    boltz_url: String,
    data_dir: String,
) -> Result<String> {
    let db = InMemoryDb::default();

    // Create keypair from master xpriv for the BDK wallet
    let kp = Keypair::from_secret_key(&secp, &master_xpriv.private_key);

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

    // Create HD key provider using Bip32KeyProvider with Arkade's default derivation path
    // Arkade uses m/83696968'/11811'/0/{i} by default (ark_core::DEFAULT_DERIVATION_PATH)
    let base_path = DerivationPath::from_str(ARK_BASE_DERIVATION_PATH)
        .map_err(|e| anyhow!("Invalid base derivation path: {}", e))?;
    let bip32_provider = Bip32KeyProvider::new(master_xpriv, base_path);
    let key_provider = UnifiedKeyProvider::Hd(bip32_provider);

    let client = OfflineClient::new(
        "lenda-mobile".to_string(),
        Arc::new(key_provider),
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

    tracing::info!(server_pk = ?info.signer_pk, "Connected to server with HD wallet");

    Ok(info.signer_pk.to_string())
}

/// Legacy setup client using StaticKeyProvider (for backward compatibility)
pub async fn setup_client_legacy(
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

    tracing::info!("Connecting to Ark (legacy mode)");

    let data_path = Path::new(data_dir.as_str());
    let swap_storage = data_path.join("boltz_swap_storage.sqlite");

    let sqlite_storage = SqliteSwapStorage::new(swap_storage)
        .await
        .map_err(|e| anyhow!(e))?;

    // Create a static key provider from the keypair (legacy)
    let static_provider = StaticKeyProvider::new(kp);
    let key_provider = UnifiedKeyProvider::Legacy(static_provider);

    let client = OfflineClient::new(
        "lenda-mobile".to_string(),
        Arc::new(key_provider),
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

    tracing::info!(server_pk = ?info.signer_pk, "Connected to server (legacy mode)");

    Ok(info.signer_pk.to_string())
}

/// Check if a wallet exists (mnemonic or legacy seed file)
pub(crate) async fn wallet_exists(data_dir: String) -> Result<bool> {
    // Check for mnemonic file first (new format)
    if mnemonic_exists(&data_dir) {
        return Ok(true);
    }
    // Check for legacy seed file
    if legacy_seed_exists(&data_dir) {
        return Ok(true);
    }
    Ok(false)
}

/// Get the stored mnemonic words (for backup display)
pub(crate) fn get_mnemonic(data_dir: String) -> Result<String> {
    let mnemonic = read_mnemonic_file(&data_dir)?
        .ok_or(anyhow!("Mnemonic file does not exist"))?;
    Ok(mnemonic.to_string())
}

/// Get the Nostr secret key derived from the mnemonic
/// Uses the NIP-06 Nostr derivation path: m/44'/1237'/0'/0/0
pub(crate) async fn nsec(data_dir: String, network: Network) -> Result<nostr::SecretKey> {
    // Try to load from mnemonic first
    if let Some(mnemonic) = read_mnemonic_file(&data_dir)? {
        let xpriv = derive_xpriv_at_path(&mnemonic, NOSTR_DERIVATION_PATH, network)?;
        let sk = nostr::SecretKey::from_slice(xpriv.private_key.secret_bytes().as_ref())?;
        return Ok(sk);
    }

    // Fall back to legacy seed file
    let sk = read_seed_file(&data_dir)?.ok_or(anyhow!("No wallet found"))?;
    let sk = nostr::SecretKey::from_slice(sk.as_ref())?;
    Ok(sk)
}

/// Delete the wallet (both mnemonic and legacy seed files)
pub fn delete_wallet(data_dir: String) -> Result<()> {
    // Delete mnemonic file if exists
    if mnemonic_exists(&data_dir) {
        delete_mnemonic_file(&data_dir)?;
    }
    // Delete legacy seed file if exists
    if legacy_seed_exists(&data_dir) {
        reset_wallet(&data_dir)?;
    }
    Ok(())
}

/// Check if the wallet is using the new mnemonic format
pub fn is_hd_wallet(data_dir: &str) -> bool {
    mnemonic_exists(data_dir)
}

/// Check if the wallet is using the legacy seed file format
pub fn is_legacy_wallet(data_dir: &str) -> bool {
    !mnemonic_exists(data_dir) && legacy_seed_exists(data_dir)
}
