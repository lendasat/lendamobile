mod address_helper;
pub mod client;
pub mod esplora;
pub mod mnemonic_file;
pub mod storage;

use crate::ark::esplora::EsploraClient;
use crate::ark::mnemonic_file::{
    delete_mnemonic_file, derive_master_xpriv, derive_xpriv_at_path, generate_mnemonic,
    mnemonic_exists, parse_mnemonic, read_mnemonic_file, write_mnemonic_file,
    ARK_BASE_DERIVATION_PATH, NOSTR_DERIVATION_PATH,
};
use crate::ark::storage::InMemoryDb;
use crate::state::{UnifiedKeyProvider, ARK_CLIENT};
use anyhow::{anyhow, Result};
use ark_client::{Bip32KeyProvider, OfflineClient, SqliteSwapStorage};
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
pub(crate) async fn load_existing_wallet(
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();
    let secp = Secp256k1::new();

    // Load from mnemonic file
    let mnemonic = read_mnemonic_file(&data_dir)
        .map_err(|e| anyhow!("Failed to read mnemonic file from '{}': {}", data_dir, e))?
        .ok_or_else(|| anyhow!("No wallet found in directory: {}", data_dir))?;

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

    Ok(server_pk)
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

    // Check if ARK_CLIENT is already initialized (e.g., after wallet reset without app restart)
    // If so, overwrite the RwLock content instead of calling set() which only works once
    if let Some(existing_lock) = ARK_CLIENT.try_get() {
        let mut guard = existing_lock.write();
        *guard = Arc::new(client);
        tracing::info!("Replaced existing ARK_CLIENT with new wallet");
    } else {
        ARK_CLIENT.set(RwLock::new(Arc::new(client)));
        tracing::info!("Initialized new ARK_CLIENT");
    }

    tracing::info!(server_pk = ?info.signer_pk, "Connected to server with HD wallet");

    Ok(info.signer_pk.to_string())
}

/// Check if a wallet exists (mnemonic file)
pub(crate) async fn wallet_exists(data_dir: String) -> Result<bool> {
    Ok(mnemonic_exists(&data_dir))
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
    let mnemonic = read_mnemonic_file(&data_dir)?
        .ok_or_else(|| anyhow!("No wallet found"))?;
    let xpriv = derive_xpriv_at_path(&mnemonic, NOSTR_DERIVATION_PATH, network)?;
    let sk = nostr::SecretKey::from_slice(xpriv.private_key.secret_bytes().as_ref())?;
    Ok(sk)
}

/// Get the Nostr public key (npub) derived from the mnemonic
/// Uses the NIP-06 Nostr derivation path: m/44'/1237'/0'/0/0
///
/// This is the CANONICAL USER IDENTIFIER used across all services:
/// - PostHog analytics
/// - User identification
/// - Cross-service correlation
///
/// All other keys (Arkade, Lendasat, LendaSwap) are service-specific
/// and derived at different paths for security isolation.
pub(crate) async fn npub(data_dir: String, network: Network) -> Result<nostr::PublicKey> {
    let sk = nsec(data_dir, network).await?;
    let keys = nostr::Keys::new(sk);
    Ok(keys.public_key())
}

/// Delete the wallet mnemonic file and associated user data
///
/// This includes:
/// - The mnemonic file
/// - LendaSwap swap storage (lendaswap_swaps/ and lendaswap_key_index)
/// - LendaSat auth tokens (lendasat_auth.json)
///
/// Note: Swaps can be recovered from the server using `recover_swaps()` after
/// restoring the wallet with the same mnemonic, as they are associated with
/// the user's xpub on the server.
///
/// TODO: In the future, consider storing swap history in the cloud associated
/// with the user account instead of locally. This would provide:
/// - Cross-device sync
/// - Automatic backup
/// - Better user experience after wallet restore
pub fn delete_wallet(data_dir: String) -> Result<()> {
    use std::fs;

    // Delete mnemonic file
    if mnemonic_exists(&data_dir) {
        delete_mnemonic_file(&data_dir)?;
    }

    // Delete LendaSwap swap storage directory
    let swaps_dir = Path::new(&data_dir).join("lendaswap_swaps");
    if swaps_dir.exists() {
        fs::remove_dir_all(&swaps_dir).map_err(|e| {
            anyhow!("Failed to delete lendaswap_swaps directory: {}", e)
        })?;
        tracing::info!("Deleted lendaswap_swaps directory");
    }

    // Delete LendaSwap key index file
    let key_index_file = Path::new(&data_dir).join("lendaswap_key_index");
    if key_index_file.exists() {
        fs::remove_file(&key_index_file).map_err(|e| {
            anyhow!("Failed to delete lendaswap_key_index file: {}", e)
        })?;
        tracing::info!("Deleted lendaswap_key_index file");
    }

    // Delete LendaSat auth tokens
    let lendasat_auth_file = Path::new(&data_dir).join("lendasat_auth.json");
    if lendasat_auth_file.exists() {
        fs::remove_file(&lendasat_auth_file).map_err(|e| {
            anyhow!("Failed to delete lendasat_auth.json file: {}", e)
        })?;
        tracing::info!("Deleted lendasat_auth.json file");
    }

    Ok(())
}
