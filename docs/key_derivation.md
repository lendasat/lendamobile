# Unified Key Derivation Architecture

## Overview

This document describes the unified key derivation architecture that enables a single BIP39 mnemonic to be used across all Lendasat ecosystem services. This "one seed, all services" approach provides:

- **Single backup** - Users only need to secure 12/24 words
- **Cross-platform sync** - Same mnemonic works everywhere
- **Service interoperability** - All apps derive from same master seed
- **Standard compliance** - Uses BIP39/BIP32 industry standards

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
          ┌───────────────────┼───────────────────┬───────────────────┐
          │                   │                   │                   │
          ▼                   ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐
│   Ark Wallet    │ │   LendaSwap     │ │    Lendasat     │ │     Nostr       │
│                 │ │                 │ │                 │ │                 │
│ m/83696968'     │ │ m/83696968'     │ │ m/10101'        │ │ m/44            │
│   /11811'       │ │   /121923'      │ │   /0'           │ │   /0            │
│   /0            │ │   /{index}'     │ │   /{index}'     │ │   /0            │
│                 │ │                 │ │                 │ │   /0            │
│ Bitcoin funds   │ │ Swap keys       │ │ Collateral keys │ │   /0            │
│ (on/off-chain)  │ │ (HTLC secrets)  │ │ (loan contracts)│ │                 │
└─────────────────┘ └─────────────────┘ └─────────────────┘ │ Social identity │
                              │                             └─────────────────┘
                              │
                              ▼
                    ┌─────────────────┐
                    │ LendaSwap       │
                    │ User IDs        │
                    │                 │
                    │ m/9419'         │
                    │   /121923'      │
                    │   /0'           │
                    │   /{index}      │
                    │                 │
                    │ (for recovery)  │
                    └─────────────────┘
```

## Derivation Paths Reference

### Summary Table

| Service | Purpose | Derivation Path | Hardened | Notes |
|---------|---------|-----------------|----------|-------|
| **Ark SDK** | Wallet key | `m/83696968'/11811'/0` | Yes | BIP-85 prefix, single key |
| **LendaSwap** | Swap keys | `m/83696968'/121923'/{i}'` | Yes | One key per swap |
| **LendaSwap** | User IDs | `m/9419'/121923'/0'/{i}` | Mixed | For swap recovery |
| **Lendasat** | Contract keys | `m/10101'/0'/{i}'` | Yes | Collateral signing |
| **Nostr** | Identity | `m/44/0/0/0/0` | No | NIP-06 compatible |

### Path Component Meanings

#### BIP-85 Applications (prefix `83696968'`)

The number `83696968` is the BIP-85 application prefix, used for deriving application-specific keys:

- **`11811`** = Ark identifier
- **`121923`** = "LSW" (LendaSwap) encoded as: `L(12) S(19) W(23)`

#### Lendasat (`10101'`)

- **`10101`** = Lendasat-specific prefix for loan contracts
- Non-BIP-85, custom path for historical reasons

#### Nostr (`44/0/0/0/0`)

- Follows NIP-06 specification
- Non-hardened for compatibility with hardware wallets
- Path: `m/44'/1237'/{account}'/{change}/{index}` simplified to `m/44/0/0/0/0`

## Detailed Specifications

### 1. Ark SDK (Wallet)

**Purpose:** Hold and transact Bitcoin (on-chain and Ark off-chain)

**Path:** `m/83696968'/11811'/0`

```rust
// Ark SDK default derivation
const ARK_PATH: &str = "m/83696968'/11811'/0";

let seed = mnemonic.to_seed("");
let master = Xpriv::new_master(network, &seed)?;
let ark_key = master.derive_priv(&secp, &ARK_PATH.parse()?)?;
```

**Key usage:**
- Sign Ark transactions (VTXOs)
- Sign on-chain transactions (boarding, unilateral exits)
- Derive Ark addresses

### 2. LendaSwap (Swap Keys)

**Purpose:** Generate cryptographic parameters for atomic swaps

**Path:** `m/83696968'/121923'/{index}'`

```rust
// From lendaswap-core/src/hd_wallet.rs
const SIGNING_PREFIX: u32 = 83696968;  // BIP-85
const LSW_IDENTIFIER: u32 = 121923;    // "LSW"

let path = format!("m/{}'/{}'/{}'", SIGNING_PREFIX, LSW_IDENTIFIER, index);
let derived = master.derive_priv(&secp, &path.parse()?)?;

// Derive swap parameters
let secret_key = derived.private_key;
let public_key = secret_key.public_key(&secp);
let preimage = tagged_hash("lendaswap/preimage", &secret_key.secret_bytes());
let preimage_hash = sha256(preimage);
```

**Key usage:**
- `secret_key` / `public_key` - Sign HTLC claims/refunds
- `preimage` - HTLC secret (revealed to claim)
- `preimage_hash` - HTLC lock (hash lock)

### 3. LendaSwap (User IDs)

**Purpose:** Enable swap recovery from server

**Path:** `m/9419'/121923'/0'/{index}` (note: last component non-hardened)

```rust
// From lendaswap-core/src/hd_wallet.rs
const ID_PREFIX: u32 = 9419;

// Derive Xpub for recovery (hardened base)
let xpub_path = format!("m/{}'/{}'/{}'", ID_PREFIX, LSW_IDENTIFIER, 0);
let xpub = master.derive_priv(&secp, &xpub_path.parse()?)?.to_xpub();

// Derive individual user_id (non-hardened from xpub)
let user_id_path = format!("m/{}/{}/{}", ID_PREFIX, LSW_IDENTIFIER, index);
let user_id_pubkey = xpub.derive_pub(&secp, &user_id_path.parse()?)?;
```

**Why mixed hardening?**
- Base path is hardened (protects master key)
- Final index is non-hardened (allows Xpub sharing)
- Server can derive user_ids from Xpub to find user's swaps

### 4. Lendasat (Contract Keys)

**Purpose:** Sign Bitcoin collateral contracts for loans

**Path:** `m/10101'/0'/{index}'`

```rust
// From lendasat/client-sdk/src/wallet.rs
let path = vec![
    ChildNumber::from_hardened_idx(10101)?,
    ChildNumber::from_hardened_idx(0)?,
    ChildNumber::from_hardened_idx(contract_index)?,
];
let contract_key = master.derive_priv(&secp, &path.into())?;
```

**Key usage:**
- Sign collateral deposit transactions
- Sign collateral release/liquidation transactions
- One key per loan contract

### 5. Nostr (Identity)

**Purpose:** Social identity for Nostr protocol

**Path:** `m/44/0/0/0/0` (non-hardened)

```rust
// From lendasat/client-sdk/src/wallet.rs
pub const NOSTR_DERIVATION_PATH: &str = "m/44/0/0/0/0";

let path = DerivationPath::from_str(NOSTR_DERIVATION_PATH)?;
let nostr_key = master.derive_priv(&secp, &path)?;
let npub = XOnlyPublicKey::from(nostr_key.public_key());
```

**Key usage:**
- Sign Nostr events (notes, reactions, etc.)
- Derive npub (public identifier)
- Encrypt/decrypt DMs (NIP-04)

## Security Considerations

### Path Isolation

All paths are carefully chosen to avoid collisions:

```
m/83696968'/11811'/...    - Ark (unique app ID: 11811)
m/83696968'/121923'/...   - LendaSwap swaps (unique app ID: 121923)
m/9419'/121923'/...       - LendaSwap recovery (different prefix: 9419)
m/10101'/...              - Lendasat (unique prefix: 10101)
m/44/...                  - Nostr (standard BIP-44 prefix)
```

### Hardened vs Non-Hardened

| Path Type | Security | Use Case |
|-----------|----------|----------|
| Hardened (`'`) | Child key cannot derive parent | Financial keys, secrets |
| Non-hardened | Xpub can derive child pubkeys | Recovery, Nostr compat |

### Mnemonic Security

1. **Generation** - Use cryptographically secure RNG
2. **Storage** - Encrypt at rest, use secure enclave if available
3. **Display** - Show only during backup, require auth to view
4. **Transmission** - Never send over network

## Implementation Guide

### Generating a New Wallet

```rust
use bip39::{Mnemonic, Language};

// Generate 12-word mnemonic
let mnemonic = Mnemonic::generate_in(Language::English, 12)?;
let phrase = mnemonic.to_string();

// Derive master seed (empty passphrase for compatibility)
let seed = mnemonic.to_seed("");
let master = Xpriv::new_master(Network::Bitcoin, &seed)?;

// Now derive keys for each service...
```

### Restoring from Mnemonic

```rust
use bip39::Mnemonic;

// Parse and validate mnemonic
let mnemonic = Mnemonic::parse(user_input)?;

// Derive same master seed
let seed = mnemonic.to_seed("");
let master = Xpriv::new_master(network, &seed)?;

// All derived keys will match original wallet
```

### Cross-Platform Sync

When user imports mnemonic on a new device/platform:

1. **Ark** - Sync with Ark server to recover VTXOs
2. **LendaSwap** - Call `recover_swaps()` with user ID Xpub
3. **Lendasat** - Server has contract history linked to pubkeys
4. **Nostr** - Follows/relays synced via Nostr protocol

## Testing Vectors

### Test Mnemonic

```
abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about
```

### Expected Derivations (Bitcoin Mainnet)

| Service | Path | Public Key (compressed hex) |
|---------|------|----------------------------|
| Ark | `m/83696968'/11811'/0` | (derive and verify) |
| LendaSwap[0] | `m/83696968'/121923'/0'` | (derive and verify) |
| Lendasat[0] | `m/10101'/0'/0'` | (derive and verify) |
| Nostr | `m/44/0/0/0/0` | (derive and verify) |

### Verification Code

```rust
#[test]
fn test_derivation_paths_no_collision() {
    let paths = vec![
        "m/83696968'/11811'/0",
        "m/83696968'/121923'/0'",
        "m/9419'/121923'/0'/0",
        "m/10101'/0'/0'",
        "m/44/0/0/0/0",
    ];

    // Ensure all paths are unique
    let unique: HashSet<_> = paths.iter().collect();
    assert_eq!(unique.len(), paths.len());
}

#[test]
fn test_same_mnemonic_same_keys() {
    let phrase = "abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about";

    // Derive twice
    let keys1 = derive_all_keys(phrase);
    let keys2 = derive_all_keys(phrase);

    // Must be identical
    assert_eq!(keys1, keys2);
}
```

## Migration from Legacy Systems

### From Raw Seed (Mobile App)

If user has existing raw seed (not mnemonic):

1. Cannot derive mnemonic from raw seed (one-way function)
2. Must create new mnemonic-based wallet
3. Transfer funds from old to new wallet
4. Securely delete old seed

### From Different Passphrase

If user used a passphrase with their mnemonic:

```rust
// Old system (with passphrase)
let seed_old = mnemonic.to_seed("user_passphrase");

// New system (no passphrase)
let seed_new = mnemonic.to_seed("");

// These produce DIFFERENT master keys!
// User must migrate funds if switching
```

## Future Considerations

### Additional Services

New services should:

1. Choose unique path prefix (avoid collisions)
2. Document in this file
3. Use hardened derivation for financial keys
4. Consider BIP-85 prefix (`83696968'`) for consistency

### Hardware Wallet Support

For hardware wallet compatibility:

- Non-hardened paths can be derived from Xpub
- Hardened paths require device signing
- Consider Taproot (BIP-86) paths for future

### Multi-Signature

For multi-sig setups:

- Each party uses their own mnemonic
- Derive keys at same path
- Combine pubkeys for multi-sig script
