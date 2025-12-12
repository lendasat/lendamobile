# Wallet Mnemonic Migration Guide

## Overview

This document outlines the migration from raw seed-based wallet storage to BIP39 mnemonic-based wallet storage. This change enables:

1. **Unified key derivation** - One mnemonic for both Ark wallet and LendaSwap
2. **Standard backup** - Users backup 12/24 words instead of raw hex/nsec
3. **Cross-platform sync** - Same mnemonic on web + mobile = same everything
4. **HD wallet support** - Multiple derived keys from single seed

## Current Implementation

### How it works now

```
rust/src/ark/
├── mod.rs          # Wallet setup functions
├── seed_file.rs    # Raw seed storage (32 bytes hex)
└── client.rs       # Ark client operations
```

**Current flow:**
```rust
// setup_new_wallet() in mod.rs
let mut random_bytes = [0u8; 32];
rand::thread_rng().fill_bytes(&mut random_bytes);
let sk = SecretKey::from_slice(&random_bytes)?;
write_seed_file(&sk, data_dir)?;  // Stores raw hex bytes
```

**Current backup/restore:**
- Export: `nsec` (Nostr bech32 encoding of raw secret key)
- Import: Parse `nsec` → SecretKey → store

### Problems with current approach

1. Non-standard backup format (nsec vs BIP39 mnemonic)
2. Cannot derive multiple keys (e.g., for LendaSwap)
3. Not compatible with other HD wallets
4. No path for web/mobile sync

## New Implementation

### Architecture

```
BIP39 Mnemonic (12 or 24 words)
         │
         ↓
    BIP32 Master Seed
         │
         ├─→ m/83696968'/11811'/0      → Ark wallet key
         │                               (default Ark SDK path)
         │
         └─→ m/83696968'/121923'/{i}'  → LendaSwap swap keys
                                         (LendaSwap SDK path)
```

Both Ark SDK and LendaSwap SDK use the same BIP-85 prefix (`83696968`), with different application identifiers:
- Ark: `11811`
- LendaSwap: `121923` (encodes "LSW")

### File changes

#### 1. Add dependencies to `Cargo.toml`

```toml
[dependencies]
# Add BIP39 support
bip39 = "2.0"
```

#### 2. Create new mnemonic storage (`rust/src/ark/mnemonic_file.rs`)

```rust
use anyhow::{anyhow, Result};
use std::fs::{self, File};
use std::io::Write;
use std::path::Path;

const MNEMONIC_FILENAME: &str = "mnemonic";

/// Write mnemonic to file (encrypted in production)
pub fn write_mnemonic_file(mnemonic: &str, data_dir: &str) -> Result<()> {
    let data_path = Path::new(data_dir);
    let mnemonic_path = data_path.join(MNEMONIC_FILENAME);

    // TODO: Encrypt mnemonic before storing
    let mut file = File::create(&mnemonic_path)
        .map_err(|e| anyhow!("Failed to create mnemonic file: {}", e))?;

    file.write_all(mnemonic.as_bytes())
        .map_err(|e| anyhow!("Failed to write mnemonic file: {}", e))?;

    tracing::debug!(path = ?mnemonic_path, "Stored mnemonic in file");
    Ok(())
}

/// Read mnemonic from file
pub fn read_mnemonic_file(data_dir: &str) -> Result<Option<String>> {
    let data_path = Path::new(data_dir);
    let mnemonic_path = data_path.join(MNEMONIC_FILENAME);

    if !mnemonic_path.exists() {
        tracing::debug!(path = ?mnemonic_path, "Mnemonic file does not exist");
        return Ok(None);
    }

    // TODO: Decrypt mnemonic after reading
    let mnemonic = fs::read_to_string(&mnemonic_path)
        .map_err(|e| anyhow!("Failed to read mnemonic file: {}", e))?;

    // Validate mnemonic
    bip39::Mnemonic::parse(&mnemonic)
        .map_err(|e| anyhow!("Invalid mnemonic in file: {}", e))?;

    tracing::debug!(path = ?mnemonic_path, "Successfully read mnemonic from file");
    Ok(Some(mnemonic.trim().to_string()))
}

/// Check if mnemonic file exists
pub fn mnemonic_exists(data_dir: &str) -> bool {
    let data_path = Path::new(data_dir);
    data_path.join(MNEMONIC_FILENAME).exists()
}

/// Delete mnemonic file
pub fn delete_mnemonic_file(data_dir: &str) -> Result<()> {
    let data_path = Path::new(data_dir);
    let mnemonic_path = data_path.join(MNEMONIC_FILENAME);

    if mnemonic_path.exists() {
        fs::remove_file(&mnemonic_path)?;
    }
    Ok(())
}
```

#### 3. Update wallet setup functions (`rust/src/ark/mod.rs`)

```rust
mod mnemonic_file;

use mnemonic_file::{write_mnemonic_file, read_mnemonic_file, mnemonic_exists};
use bip39::{Mnemonic, Language};

/// Create a new wallet with mnemonic
pub async fn setup_new_wallet(
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();

    // Generate new mnemonic (12 words)
    let mnemonic = Mnemonic::generate_in(Language::English, 12)
        .map_err(|e| anyhow!("Failed to generate mnemonic: {}", e))?;

    let mnemonic_str = mnemonic.to_string();

    // Store mnemonic
    write_mnemonic_file(&mnemonic_str, &data_dir)?;

    // Setup client with mnemonic (Ark SDK handles derivation)
    let pubkey = setup_client_with_mnemonic(
        &mnemonic_str,
        network,
        esplora,
        server,
        boltz_url,
        data_dir,
    ).await?;

    Ok(pubkey)
}

/// Restore wallet from mnemonic
pub async fn restore_wallet_from_mnemonic(
    mnemonic: String,
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();

    // Validate mnemonic
    Mnemonic::parse(&mnemonic)
        .map_err(|e| anyhow!("Invalid mnemonic: {}", e))?;

    // Store mnemonic
    write_mnemonic_file(&mnemonic, &data_dir)?;

    // Setup client
    let pubkey = setup_client_with_mnemonic(
        &mnemonic,
        network,
        esplora,
        server,
        boltz_url,
        data_dir,
    ).await?;

    Ok(pubkey)
}

/// Load existing wallet (supports both mnemonic and legacy seed)
pub async fn load_existing_wallet(
    data_dir: String,
    network: Network,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    crate::init_crypto_provider();

    // Try mnemonic first (new format)
    if let Some(mnemonic) = read_mnemonic_file(&data_dir)? {
        return setup_client_with_mnemonic(
            &mnemonic,
            network,
            esplora,
            server,
            boltz_url,
            data_dir,
        ).await;
    }

    // Fall back to legacy seed file
    if let Some(sk) = read_seed_file(&data_dir)? {
        tracing::warn!("Using legacy seed file - consider migrating to mnemonic");
        let secp = Secp256k1::new();
        let kp = Keypair::from_secret_key(&secp, &sk);
        return setup_client(kp, secp, network, esplora, server, boltz_url, data_dir).await;
    }

    bail!("No wallet found in directory: {}", data_dir)
}

/// Setup client using mnemonic (Ark SDK handles HD derivation)
async fn setup_client_with_mnemonic(
    mnemonic: &str,
    network: Network,
    esplora_url: String,
    server: String,
    boltz_url: String,
    data_dir: String,
) -> Result<String> {
    // The new Ark SDK accepts mnemonic directly
    // It derives the key at m/83696968'/11811'/0 by default

    // TODO: Update when Ark SDK mnemonic API is available
    // For now, we manually derive the key
    let seed = bip39::Mnemonic::parse(mnemonic)?.to_seed("");
    let master = bitcoin::bip32::Xpriv::new_master(network, &seed)?;
    let secp = Secp256k1::new();

    // Ark default path: m/83696968'/11811'/0
    let path: bitcoin::bip32::DerivationPath = "m/83696968'/11811'/0".parse()?;
    let derived = master.derive_priv(&secp, &path)?;
    let kp = Keypair::from_secret_key(&secp, &derived.private_key);

    setup_client(kp, secp, network, esplora_url, server, boltz_url, data_dir).await
}

/// Export mnemonic for backup
pub fn export_mnemonic(data_dir: String) -> Result<String> {
    read_mnemonic_file(&data_dir)?
        .ok_or_else(|| anyhow!("No mnemonic found - wallet may use legacy format"))
}

/// Check wallet type
pub fn wallet_type(data_dir: String) -> Result<WalletType> {
    if mnemonic_exists(&data_dir) {
        Ok(WalletType::Mnemonic)
    } else if read_seed_file(&data_dir)?.is_some() {
        Ok(WalletType::LegacySeed)
    } else {
        Ok(WalletType::None)
    }
}

pub enum WalletType {
    Mnemonic,
    LegacySeed,
    None,
}
```

#### 4. Add Flutter API functions (`rust/src/api/ark_api.rs`)

```rust
// Add these new API functions

/// Create new wallet (returns mnemonic for user to backup)
pub async fn create_wallet_with_mnemonic(
    data_dir: String,
    network: String,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<WalletCreationResult> {
    let network = parse_network(&network)?;
    let pubkey = crate::ark::setup_new_wallet(data_dir.clone(), network, esplora, server, boltz_url).await?;
    let mnemonic = crate::ark::export_mnemonic(data_dir)?;

    Ok(WalletCreationResult { pubkey, mnemonic })
}

pub struct WalletCreationResult {
    pub pubkey: String,
    pub mnemonic: String,
}

/// Restore wallet from mnemonic
pub async fn restore_wallet_from_mnemonic(
    mnemonic: String,
    data_dir: String,
    network: String,
    esplora: String,
    server: String,
    boltz_url: String,
) -> Result<String> {
    let network = parse_network(&network)?;
    crate::ark::restore_wallet_from_mnemonic(mnemonic, data_dir, network, esplora, server, boltz_url).await
}

/// Export mnemonic for backup display
pub fn export_mnemonic(data_dir: String) -> Result<String> {
    crate::ark::export_mnemonic(data_dir)
}

/// Get wallet type (mnemonic, legacy, or none)
pub fn get_wallet_type(data_dir: String) -> Result<String> {
    match crate::ark::wallet_type(data_dir)? {
        WalletType::Mnemonic => Ok("mnemonic".to_string()),
        WalletType::LegacySeed => Ok("legacy".to_string()),
        WalletType::None => Ok("none".to_string()),
    }
}
```

## Migration Strategy

### For new users
- Automatically use mnemonic-based wallet
- Show mnemonic backup screen after creation

### For existing users (legacy seed)
Two options:

**Option A: Automatic migration (if possible)**
- Not recommended - would require deriving mnemonic from seed (not standard)

**Option B: Manual migration (recommended)**
1. Detect legacy wallet on app open
2. Show migration prompt: "Upgrade to recovery phrase backup"
3. User creates new mnemonic wallet
4. User transfers funds from old to new
5. User deletes old wallet

### Flutter UI changes

```dart
// On app startup
final walletType = await api.getWalletType(dataDir);

if (walletType == "legacy") {
  // Show migration prompt
  showMigrationDialog();
} else if (walletType == "none") {
  // Show onboarding (create or restore)
  showOnboarding();
} else {
  // Normal app flow
  loadWallet();
}
```

## Security Considerations

1. **Mnemonic encryption at rest**
   - Encrypt mnemonic file with device-specific key
   - Use Flutter Secure Storage or platform keychain

2. **Mnemonic display**
   - Only show once during creation
   - Require authentication to view backup
   - Warn users not to screenshot

3. **Memory handling**
   - Zero mnemonic from memory after use
   - Use secure string handling

## Testing Checklist

- [ ] New wallet creation generates valid 12-word mnemonic
- [ ] Mnemonic restore produces same keys
- [ ] Legacy seed wallets still load correctly
- [ ] Ark SDK derives correct key at m/83696968'/11811'/0
- [ ] LendaSwap SDK can use same mnemonic
- [ ] Cross-platform: same mnemonic works on web and mobile
- [ ] Mnemonic backup/export works
- [ ] Migration flow works for legacy users
