# Native EVM Wallet Integration

## Current Approach: WalletConnect

For the initial release, we use **WalletConnect** to integrate with users' existing EVM wallets (MetaMask, Rainbow, Trust Wallet, etc.).

### Why WalletConnect First?

| Benefit | Description |
|---------|-------------|
| Faster to market | No need to build full EVM wallet infrastructure |
| User's existing wallets | Users keep their familiar wallet setup |
| Security delegation | Private key management handled by established wallets |
| Lower maintenance | No EVM node/RPC management needed |
| Focused scope | Stay focused on Bitcoin/Ark core functionality |

### WalletConnect Flow

```
User wants Bitcoin-backed loan
         │
         ▼
┌─────────────────────────┐
│  Connect EVM Wallet     │
│  via WalletConnect      │
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│  User approves in       │
│  MetaMask/Rainbow/etc.  │
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│  App reads stablecoin   │
│  balance & address      │
└─────────────────────────┘
         │
         ▼
┌─────────────────────────┐
│  Loan proceeds sent to  │
│  connected wallet       │
└─────────────────────────┘
```

---

## Future Consideration: Native EVM Wallet

If user research shows demand for an integrated solution (users without existing EVM wallets, or desire for single-app experience), we can add native EVM wallet support.

### Key Derivation (Unified Mnemonic)

The same mnemonic that powers Ark and Nostr can derive EVM keys:

```
Mnemonic (12 words)
    │
    ▼
Master Xpriv (from BIP39 seed)
    │
    ├─→ Ark Wallet
    │   └─→ m/83696968'/11811'/0/{index}   (Arkade Default)
    │
    ├─→ Nostr Identity
    │   └─→ m/44'/1237'/0'/0/0             (NIP-06)
    │
    ├─→ LendaSwap (planned)
    │   └─→ m/83696968'/121923'/{index}'
    │
    └─→ EVM Wallet (future)
        └─→ m/44'/60'/0'/0/{index}         (BIP44 Ethereum)
```

### Path Constants (Future Addition)

```rust
// rust/src/ark/mnemonic_file.rs (future)

/// EVM/Polygon derivation path (BIP44 standard for Ethereum)
/// Path: m/44'/60'/0'/0/{index}
/// Note: Same path works for Ethereum, Polygon, Arbitrum, etc.
pub const EVM_DERIVATION_PATH: &str = "m/44'/60'/0'/0";
```

### Technical Requirements

#### Rust Dependencies

```toml
# Cargo.toml additions
[dependencies]
alloy = { version = "0.1", features = ["full"] }  # Modern EVM library
# OR
ethers = { version = "2.0", features = ["rustls"] }  # Established alternative
```

#### Core Functionality Needed

| Feature | Library | Complexity |
|---------|---------|------------|
| Key derivation | `bip32` (already have) | Low |
| Address generation | `alloy-primitives` | Low |
| RPC connection | `alloy-provider` | Medium |
| ERC-20 balances | `alloy-contract` | Medium |
| Transaction signing | `alloy-signer` | Medium |
| Transaction sending | `alloy-provider` | Medium |

#### Supported Tokens (Polygon)

| Token | Contract Address | Decimals |
|-------|------------------|----------|
| USDC | `0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359` | 6 |
| USDT | `0xc2132D05D31c914a87C6611C10748AEb04B58e8F` | 6 |
| DAI | `0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063` | 18 |

### Implementation Outline

#### 1. EVM Key Provider

```rust
// rust/src/evm/key_provider.rs (future)

use alloy::signers::local::PrivateKeySigner;
use bitcoin::bip32::{DerivationPath, Xpriv};
use std::str::FromStr;

pub const EVM_DERIVATION_PATH: &str = "m/44'/60'/0'/0";

pub struct EvmKeyProvider {
    master_xpriv: Xpriv,
    base_path: DerivationPath,
}

impl EvmKeyProvider {
    pub fn new(master_xpriv: Xpriv) -> Self {
        let base_path = DerivationPath::from_str(EVM_DERIVATION_PATH)
            .expect("valid derivation path");
        Self { master_xpriv, base_path }
    }

    pub fn get_signer(&self, index: u32) -> PrivateKeySigner {
        // Derive child key at index
        let path = format!("{}/{}", EVM_DERIVATION_PATH, index);
        let derived = self.master_xpriv
            .derive_priv(&secp, &DerivationPath::from_str(&path).unwrap())
            .unwrap();

        // Convert to EVM signer
        PrivateKeySigner::from_bytes(&derived.private_key.secret_bytes())
            .expect("valid key")
    }

    pub fn get_address(&self, index: u32) -> Address {
        self.get_signer(index).address()
    }
}
```

#### 2. Polygon Client

```rust
// rust/src/evm/polygon_client.rs (future)

use alloy::providers::{Provider, ProviderBuilder};
use alloy::primitives::{Address, U256};

pub struct PolygonClient {
    provider: impl Provider,
    key_provider: EvmKeyProvider,
}

impl PolygonClient {
    pub async fn new(rpc_url: &str, master_xpriv: Xpriv) -> Result<Self> {
        let provider = ProviderBuilder::new()
            .on_http(rpc_url.parse()?);

        Ok(Self {
            provider,
            key_provider: EvmKeyProvider::new(master_xpriv),
        })
    }

    pub async fn get_usdc_balance(&self, index: u32) -> Result<U256> {
        let address = self.key_provider.get_address(index);
        // Query ERC-20 balance
        // ...
    }

    pub async fn send_usdc(&self, to: Address, amount: U256) -> Result<TxHash> {
        // Sign and send ERC-20 transfer
        // ...
    }
}
```

#### 3. Flutter Bridge

```rust
// rust/src/api/evm_api.rs (future)

#[flutter_rust_bridge::frb]
pub async fn evm_get_address(index: u32) -> Result<String> {
    let state = get_evm_client()?;
    Ok(state.key_provider.get_address(index).to_string())
}

#[flutter_rust_bridge::frb]
pub async fn evm_get_usdc_balance() -> Result<String> {
    let state = get_evm_client()?;
    let balance = state.get_usdc_balance(0).await?;
    Ok(balance.to_string())
}

#[flutter_rust_bridge::frb]
pub async fn evm_send_usdc(to: String, amount: String) -> Result<String> {
    let state = get_evm_client()?;
    let to = to.parse()?;
    let amount = amount.parse()?;
    let tx_hash = state.send_usdc(to, amount).await?;
    Ok(tx_hash.to_string())
}
```

### Migration Path

```
Phase 1 (Current)
├── WalletConnect integration
├── Read balances from connected wallet
└── Display stablecoin info in app

Phase 2 (If needed)
├── Add native EVM key derivation
├── Generate addresses from same mnemonic
├── "Create integrated wallet" option for new users
└── Keep WalletConnect for existing users

Phase 3 (Full integration)
├── Full send/receive for stablecoins
├── Token swap integration (optional)
└── Unified transaction history
```

### Decision Criteria for Native Wallet

Consider building native EVM wallet if:

- [ ] >30% of users don't have an existing EVM wallet
- [ ] User feedback explicitly requests integrated solution
- [ ] WalletConnect UX proves to be a significant friction point
- [ ] Competitor analysis shows integrated wallets winning

### Security Considerations

| Aspect | WalletConnect | Native Wallet |
|--------|---------------|---------------|
| Key storage | User's wallet | Our secure storage |
| Attack surface | Minimal | Increased |
| Audit scope | Bitcoin/Ark only | + EVM signing |
| User trust | Delegated | Full responsibility |

### RPC Providers (Polygon)

For production native wallet:

| Provider | Free Tier | Notes |
|----------|-----------|-------|
| Alchemy | 300M compute/month | Recommended |
| Infura | 100k requests/day | Established |
| QuickNode | 10M requests/month | Fast |
| Public RPC | Unlimited | Less reliable |

```
Polygon Mainnet RPC:
- https://polygon-rpc.com (public)
- https://polygon-mainnet.g.alchemy.com/v2/{API_KEY}
- https://polygon-mainnet.infura.io/v3/{API_KEY}
```

---

## Summary

**Now:** WalletConnect - fast, secure, focused
**Later:** Native EVM wallet if user demand justifies the investment

The unified mnemonic architecture makes future migration straightforward - no breaking changes for users, just an additional derivation path.
