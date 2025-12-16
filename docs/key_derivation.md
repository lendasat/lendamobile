# Unified Key Derivation Architecture

## Overview

This document describes the unified key derivation architecture that enables a single BIP39 mnemonic to be used across all Lendasat ecosystem services. This "one seed, all services" approach provides:

- **Single backup** - Users only need to secure 12/24 words
- **Cross-platform sync** - Same mnemonic works everywhere
- **Service interoperability** - All apps derive from same master seed
- **Standard compliance** - Uses BIP39/BIP32 industry standards

## Current Implementation

### Ark Mobile Wallet

The mobile wallet uses the **Arkade SDK** with custom derivation for HD wallet support:

```
Mnemonic (12 words)
    │
    ▼
Master Xpriv (from BIP39 seed)
    │
    ├─→ Arkade Bip32KeyProvider
    │   └─→ m/83696968'/11811'/0/{index}  (Arkade Default)
    │
    ├─→ Nostr Identity
    │   └─→ m/44/0/0/0/0          (LendaSat SDK)
    │
    ├─→ LendaSwap (future)
    │   └─→ m/83696968'/121923'/{index}'
    │
    └─→ Lendasat (future)
        └─→ m/10101'/0'/{index}'
```

### Key Files

| File | Purpose |
|------|---------|
| `rust/src/ark/mnemonic_file.rs` | Mnemonic generation, storage, and key derivation |
| `rust/src/ark/mod.rs` | Wallet setup with Bip32KeyProvider |
| `rust/src/state.rs` | UnifiedKeyProvider for HD and legacy support |

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────┐
│                     BIP39 Mnemonic (12/24 words)                    │
│          "abandon abandon abandon ... about"                        │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     BIP32 Master Seed                               │
│                     (512-bit from PBKDF2)                           │
│                     Passphrase: "" (empty)                          │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────────┐
│                     Master Xpriv                                    │
│              (passed to Arkade Bip32KeyProvider)                    │
└─────────────────────────────┬───────────────────────────────────────┘
                              │
          ┌───────────────────┼───────────────────┬───────────────────┐
          │                   │                   │                   │
          ▼                   ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Ark Wallet    │ │   LendaSwap     │ │    Lendasat     │ │     Nostr       │
│   (Arkade SDK)  │ │   (Future)      │ │   (Future)      │ │                 │
│                 │ │                 │ │                 │ │                 │
│ m/83696968'     │ │ m/83696968'     │ │ m/10101'        │ │ m/44/0          │
│   /11811'/0     │ │   /121923'      │ │   /0'           │ │   /0/0          │
│   /{index}      │ │   /{index}'     │ │   /{index}'     │ │   /0            │
│ Arkade Default  │ │                 │ │                 │ │                 │
│ (not BIP84)     │ │ Swap keys       │ │ Collateral keys │ │ LendaSat SDK    │
│                 │ │ (HTLC secrets)  │ │ (loan contracts)│ │ Social identity │
└─────────────────┘ └─────────────────┘ └─────────────────┘ └─────────────────┘
```

## Derivation Paths Reference

### Summary Table

| Service | Purpose | Derivation Path | Standard | Status |
|---------|---------|-----------------|----------|--------|
| **Ark SDK** | HD Wallet | `m/83696968'/11811'/0/{i}` | Arkade Default | **Implemented** |
| **Nostr** | Identity | `m/44/0/0/0/0` | LendaSat SDK | **Implemented** |
| **LendaSwap** | Swap keys | `m/83696968'/121923'/{i}'` | BIP-85 | Planned |
| **Lendasat** | Contract keys | `m/10101'/0'/{i}'` | Custom | Planned |

### Path Constants (Rust)

```rust
// rust/src/ark/mnemonic_file.rs

/// Arkade's default derivation path for HD wallet
/// This matches ark_core::DEFAULT_DERIVATION_PATH: m/83696968'/11811'/0/{index}
pub const ARK_BASE_DERIVATION_PATH: &str = "m/83696968'/11811'/0";

/// Derivation path for LendaSwap swap keys (from same mnemonic)
pub const LENDASWAP_DERIVATION_PATH: &str = "m/83696968'/121923'";

/// Derivation path for Lendasat contract keys (from same mnemonic)
pub const LENDASAT_DERIVATION_PATH: &str = "m/10101'/0'";

/// Derivation path for Nostr keys (matches LendaSat SDK)
pub const NOSTR_DERIVATION_PATH: &str = "m/44/0/0/0/0";
```

## Implementation Details

### 1. Ark SDK (Bip32KeyProvider)

The Arkade SDK uses `Bip32KeyProvider` which handles HD key derivation internally.

**Path:** `m/83696968'/11811'/0/{index}` (Arkade Default - NOT BIP84)

```rust
// rust/src/ark/mod.rs

pub async fn setup_client_hd(
    master_xpriv: Xpriv,  // Master key from mnemonic
    // ...
) -> Result<String> {
    // Arkade handles key derivation at m/83696968'/11811'/0/{i}
    let base_path = DerivationPath::from_str(ARK_BASE_DERIVATION_PATH)?;
    let bip32_provider = Bip32KeyProvider::new(master_xpriv, base_path);
    let key_provider = UnifiedKeyProvider::Hd(bip32_provider);

    let client = OfflineClient::new(
        "lenda-mobile".to_string(),
        Arc::new(key_provider),
        // ...
    );
}
```

**Key features of Bip32KeyProvider:**
- `get_next_keypair()` - Automatically derives next key at path `/{index}`
- `get_keypair_for_pk()` - Retrieves keypair by public key from cache
- `supports_discovery()` - Enables BIP44-style gap limit discovery

### 2. Nostr Identity (LendaSat SDK)

**Path:** `m/44/0/0/0/0` (LendaSat SDK - NOT NIP-06)

```rust
// rust/src/ark/mod.rs

pub(crate) async fn nsec(data_dir: String, network: Network) -> Result<nostr::SecretKey> {
    if let Some(mnemonic) = read_mnemonic_file(&data_dir)? {
        let xpriv = derive_xpriv_at_path(&mnemonic, NOSTR_DERIVATION_PATH, network)?;
        let sk = nostr::SecretKey::from_slice(xpriv.private_key.secret_bytes().as_ref())?;
        return Ok(sk);
    }
    // Fall back to legacy...
}
```

**Note:** Nostr keys are network-independent. The derived key is the same regardless of Bitcoin network. This path matches the LendaSat web SDK for cross-platform consistency (NOT the NIP-06 standard path of `m/44'/1237'/0'/0/0`).

### 3. Mnemonic Generation & Storage

```rust
// rust/src/ark/mnemonic_file.rs

/// Generate a new 12-word BIP39 mnemonic
pub fn generate_mnemonic() -> Result<Mnemonic> {
    let mut entropy = [0u8; 16];  // 128 bits = 12 words
    rand::thread_rng().fill_bytes(&mut entropy);
    Mnemonic::from_entropy(&entropy)
}

/// Derive the master extended private key from mnemonic
pub fn derive_master_xpriv(mnemonic: &Mnemonic, network: Network) -> Result<Xpriv> {
    let seed = mnemonic.to_seed("");  // Empty passphrase
    Xpriv::new_master(network, &seed)
}

/// Derive xpriv at a specific path (for Nostr, LendaSwap, etc.)
pub fn derive_xpriv_at_path(mnemonic: &Mnemonic, path: &str, network: Network) -> Result<Xpriv> {
    let master = derive_master_xpriv(mnemonic, network)?;
    let derivation_path = DerivationPath::from_str(path)?;
    master.derive_priv(&Secp256k1::new(), &derivation_path)
}
```

### 4. UnifiedKeyProvider

Supports both HD wallets (new) and legacy wallets (migration):

```rust
// rust/src/state.rs

pub enum UnifiedKeyProvider {
    Hd(Bip32KeyProvider),      // New: mnemonic-based HD wallet
    Legacy(StaticKeyProvider), // Old: raw seed file
}

impl KeyProvider for UnifiedKeyProvider {
    fn get_next_keypair(&self, keypair_index: KeypairIndex) -> Result<Keypair, Error> {
        match self {
            UnifiedKeyProvider::Hd(kp) => kp.get_next_keypair(keypair_index),
            UnifiedKeyProvider::Legacy(kp) => kp.get_next_keypair(keypair_index),
        }
    }
    // ... other trait methods
}
```

## Wallet Types

### HD Wallet (New)

- Created with `setup_new_wallet()` or `restore_wallet(mnemonicWords: ...)`
- Stored in `mnemonic` file (12/24 words)
- Uses `Bip32KeyProvider` with BIP84 derivation
- Supports key discovery and multiple addresses

### Legacy Wallet (Migration)

- Created with old `setup_new_wallet()` (pre-mnemonic)
- Stored in `seed` file (raw hex bytes)
- Uses `StaticKeyProvider` (single key)
- **Migration recommended:** Transfer funds to new HD wallet

Check wallet type:
```rust
pub fn is_hd_wallet(data_dir: &str) -> bool {
    mnemonic_exists(data_dir)
}

pub fn is_legacy_wallet(data_dir: &str) -> bool {
    !mnemonic_exists(data_dir) && legacy_seed_exists(data_dir)
}
```

## Security Considerations

### Path Isolation

All paths are carefully chosen to avoid collisions:

```
m/83696968'/11811'/0/...  - Ark (Arkade default)
m/44/0/0/0/0              - Nostr (LendaSat SDK)
m/83696968'/121923'/...   - LendaSwap (BIP-85 prefix)
m/10101'/...              - Lendasat (custom prefix)
```

### Hardened vs Non-Hardened

| Path Type | Security | Use Case |
|-----------|----------|----------|
| Hardened (`'`) | Child key cannot derive parent | Financial keys, secrets |
| Non-hardened | Xpub can derive child pubkeys | Address discovery |

### Mnemonic Security

1. **Generation** - Use cryptographically secure RNG (128 bits entropy)
2. **Storage** - Written to app's private directory
3. **Display** - Shown only after security warning, with numbered words
4. **Backup** - User must manually copy and secure

## Flutter API

### Dart Bindings (Generated)

```dart
// lib/src/rust/api/ark_api.dart

/// Create new wallet, returns mnemonic for backup
Future<String> setupNewWallet({
    required String dataDir,
    required String network,
    required String esplora,
    required String server,
    required String boltzUrl,
});

/// Restore wallet from mnemonic
Future<String> restoreWallet({
    required String mnemonicWords,  // 12 or 24 words
    required String dataDir,
    required String network,
    required String esplora,
    required String server,
    required String boltzUrl,
});

/// Get mnemonic for backup display
Future<String> getMnemonic({required String dataDir});

/// Check wallet type
Future<bool> isHdWallet({required String dataDir});
Future<bool> isLegacyWallet({required String dataDir});

/// Get Nostr identity (nsec)
Future<String> nsec({required String dataDir});
```

## Testing Vectors

### Test Mnemonic

```
abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
```

### Expected Derivations (Bitcoin Mainnet)

| Service | Path | Notes |
|---------|------|-------|
| Ark (index 0) | `m/83696968'/11811'/0/0` | First Ark address |
| Ark (index 1) | `m/83696968'/11811'/0/1` | Second Ark address |
| Nostr | `m/44/0/0/0/0` | LendaSat SDK identity |

### Verification Code

```rust
#[test]
fn test_same_mnemonic_same_keys() {
    let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    let mnemonic = parse_mnemonic(phrase).unwrap();

    let master1 = derive_master_xpriv(&mnemonic, Network::Bitcoin).unwrap();
    let master2 = derive_master_xpriv(&mnemonic, Network::Bitcoin).unwrap();

    assert_eq!(master1.to_string(), master2.to_string());
}

#[test]
fn test_nostr_derivation() {
    let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";
    let mnemonic = parse_mnemonic(phrase).unwrap();

    let xpriv = derive_xpriv_at_path(&mnemonic, NOSTR_DERIVATION_PATH, Network::Bitcoin).unwrap();
    // Verify against known test vector...
}
```

## Migration from Legacy

### From Raw Seed (Pre-Mnemonic Wallet)

Users with legacy wallets cannot derive a mnemonic from the raw seed. They must:

1. Create a new HD wallet (generates fresh mnemonic)
2. Back up the new mnemonic securely
3. Transfer funds from legacy to new wallet
4. Delete legacy wallet

The app detects legacy wallets and shows a migration warning in settings.

### Cross-Platform Sync

When user imports mnemonic on a new device:

1. **Ark** - Bip32KeyProvider discovers used keys automatically
2. **Nostr** - Same npub derived from LendaSat SDK path
3. **LendaSwap** (future) - Recover swaps via server lookup
4. **Lendasat** (future) - Server has contract history

## Future Considerations

### Additional Services

New services should:

1. Choose unique path prefix (avoid collisions with existing)
2. Document in this file
3. Use hardened derivation for financial keys
4. Consider BIP-85 prefix (`83696968'`) for consistency

### Hardware Wallet Support

For hardware wallet compatibility:

- Arkade path (`m/83696968'/11811'/0`) is custom and may require specific hardware support
- LendaSat SDK Nostr path (m/44/0/0/0/0) may require custom app on hardware wallet
- Consider Taproot (BIP-86) paths for future Bitcoin on-chain addresses
