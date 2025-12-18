# Lendasat Native Integration - Implementation Plan

## Overview

This document describes the plan for integrating Lendasat (Bitcoin-collateralized lending) natively into the lendamobile Flutter app, replacing the iframe-based approach used on the web.

### What is Lendasat?
Lendasat is a Bitcoin-collateralized lending platform where users can:
1. **Borrow**: Lock BTC (via Bitcoin or Ark) as collateral and receive stablecoins (USDC/USDT on Polygon, Ethereum, etc.)
2. **Repay**: Pay back the loan + interest to unlock collateral
3. **Claim**: After repayment, sign a PSBT to withdraw collateral back to wallet

### Why Native vs iframe?
The iframe implementation uses PostMessage to communicate between the iframe (Lendasat UI) and the parent wallet. Since lendamobile **IS** the wallet, we have direct access to:
- Wallet keys (public key, signing)
- Ark addresses
- PSBT signing capabilities
- Message signing (for authentication)

This eliminates the need for the wallet-bridge abstraction layer.

---

## Architecture Comparison

### iframe Architecture (Web)
```
┌─────────────────────────────────────────┐
│     Parent Wallet (sample-wallet)        │
│  ┌───────────────────────────────────┐   │
│  │   Lendasat iframe (apps/iframe)    │   │
│  │                                    │   │
│  │   Uses LendasatClient              │   │
│  │   ↓ PostMessage                    │   │
│  └───────────────────────────────────┘   │
│                                          │
│   WalletProvider handles requests:       │
│   - getPublicKey()                       │
│   - signPsbt()                           │
│   - signMessage()                        │
└─────────────────────────────────────────┘
```

### Native Architecture (lendamobile)
```
┌─────────────────────────────────────────┐
│           lendamobile App                │
│                                          │
│  ┌──────────────┐   ┌────────────────┐   │
│  │  Flutter UI  │───│ Dart Services  │   │
│  │  (Screens)   │   │ LendasatService│   │
│  └──────────────┘   └───────┬────────┘   │
│                             │            │
│                    ┌────────▼────────┐   │
│                    │   Rust Layer    │   │
│                    │ lendasat_api.rs │   │
│                    │                 │   │
│                    │ - HTTP Client   │   │
│                    │ - Auth (JWT)    │   │
│                    │ - ECDSA Sign    │   │
│                    └────────┬────────┘   │
│                             │            │
│  ┌──────────────────────────▼──────────┐ │
│  │         Existing Ark Client         │ │
│  │   - KeyProvider (signing)           │ │
│  │   - Addresses                       │ │
│  │   - PSBT operations                 │ │
│  └─────────────────────────────────────┘ │
└─────────────────────────────────────────┘
```

---

## Prerequisites & Dependencies

### Existing Components (Already Available)
- ✅ Ark Client with KeyProvider (signing capabilities)
- ✅ Ark addresses (offchain/boarding)
- ✅ HTTP client (reqwest)
- ✅ Bitcoin/secp256k1 libraries
- ✅ Wallet mnemonic/key derivation
- ✅ Flutter-Rust bridge

### New Components to Implement
1. **Rust**: `lendasat_api.rs` - API client with auth
2. **Rust**: `lendasat.rs` - Models/types
3. **Dart**: `lendasat_service.dart` - Flutter service layer
4. **Dart**: `lendasat_models.dart` - Dart model classes
5. **Flutter**: UI screens for lending flow

---

## Implementation Steps

### Phase 1: Rust API Client (Foundation)

#### Step 1.1: Create Lendasat Models (`rust/src/lendasat/mod.rs`)
```rust
// Types matching the OpenAPI schema
pub enum LoanAsset { UsdcPol, UsdtPol, UsdcEth, ... }
pub enum CollateralAsset { BitcoinBtc, ArkadeBtc }
pub enum ContractStatus { Requested, Approved, CollateralConfirmed, ... }

pub struct LoanOffer { ... }
pub struct Contract { ... }
pub struct Installment { ... }
```

#### Step 1.2: Create Lendasat API Client (`rust/src/api/lendasat_api.rs`)
```rust
// Core API client with JWT authentication
pub struct LendasatClient {
    http_client: reqwest::Client,
    base_url: String,
    jwt_token: Option<String>,
}

impl LendasatClient {
    // Auth endpoints
    pub async fn get_challenge(pubkey: &str) -> Result<String>;
    pub async fn verify_signature(pubkey: &str, challenge: &str, signature: &str) -> Result<AuthResponse>;

    // Offers
    pub async fn get_offers(filters: OfferFilters) -> Result<Vec<LoanOffer>>;

    // Contracts
    pub async fn create_contract(request: ContractRequest) -> Result<Contract>;
    pub async fn get_contracts() -> Result<Vec<Contract>>;
    pub async fn get_contract(id: &str) -> Result<Contract>;
    pub async fn cancel_contract(id: &str) -> Result<()>;

    // Repayment
    pub async fn mark_installment_paid(contract_id: &str, installment_id: &str, txid: &str) -> Result<()>;

    // Claim collateral
    pub async fn get_claim_psbt(contract_id: &str, fee_rate: u32) -> Result<ClaimPsbtResponse>;
    pub async fn broadcast_claim_tx(contract_id: &str, signed_tx: &str) -> Result<String>;

    // Ark-specific
    pub async fn get_claim_ark_psbt(contract_id: &str) -> Result<ArkClaimPsbtResponse>;
    pub async fn broadcast_claim_ark_tx(...) -> Result<String>;
}
```

#### Step 1.3: Implement Message Signing for Auth
The authentication requires ECDSA signature on a challenge message:
```rust
// In ark/client.rs or new signing module
pub async fn sign_message(message: &str) -> Result<String> {
    // 1. Get keypair from wallet
    // 2. SHA256 hash the message
    // 3. Sign with ECDSA (secp256k1)
    // 4. Return DER-encoded signature as hex
}

pub fn get_compressed_public_key() -> Result<String> {
    // Return 33-byte compressed pubkey as hex (66 chars)
}
```

### Phase 2: Flutter Bridge & Service Layer

#### Step 2.1: Create Dart Models (`lib/src/models/lendasat/`)
```dart
// lendasat_models.dart
enum LoanAsset { usdcPol, usdtPol, usdcEth, ... }
enum CollateralAsset { bitcoinBtc, arkadeBtc }
enum ContractStatus { requested, approved, ... }

class LoanOffer { ... }
class Contract { ... }
class Installment { ... }
```

#### Step 2.2: Create Lendasat Service (`lib/src/services/lendasat_service.dart`)
```dart
class LendasatService extends ChangeNotifier {
  bool _isAuthenticated = false;
  String? _jwtToken;
  List<LoanOffer> _offers = [];
  List<Contract> _contracts = [];

  // Authentication
  Future<void> authenticate() async {
    // 1. Get public key from wallet
    // 2. Request challenge from API
    // 3. Sign challenge with wallet
    // 4. Verify signature, receive JWT
    // 5. Store token for subsequent requests
  }

  // Offers
  Future<List<LoanOffer>> getOffers({...filters}) async;

  // Contracts
  Future<Contract> createContract({...params}) async;
  Future<List<Contract>> getContracts() async;
  Future<void> cancelContract(String id) async;

  // Repayment
  Future<void> markRepaid(String contractId, String installmentId, String txid) async;

  // Claim
  Future<String> claimCollateral(String contractId, int feeRate) async;
}
```

### Phase 3: Flutter UI Screens

#### Step 3.1: Offers Screen (`lib/src/ui/screens/lending/offers_screen.dart`)
- Display available loan offers
- Filter by: loan amount, duration, asset type, collateral type
- "Take Offer" button → navigate to contract creation

#### Step 3.2: Create Contract Screen (`lib/src/ui/screens/lending/create_contract_screen.dart`)
- Select loan amount (within offer range)
- Select duration (within offer range)
- Show calculated: collateral required, interest, total repayment
- Confirm → create contract

#### Step 3.3: Contracts List Screen (`lib/src/ui/screens/lending/contracts_screen.dart`)
- List all user's contracts
- Show status, amounts, expiry
- Navigate to contract details

#### Step 3.4: Contract Details Screen (`lib/src/ui/screens/lending/contract_details_screen.dart`)
- Full contract information
- Actions based on status:
  - `Approved`: Show deposit address, wait for collateral
  - `PrincipalGiven`: Show repayment info, "Mark as Repaid" button
  - `RepaymentConfirmed`: "Claim Collateral" button
  - `CollateralRecoverable`: "Recover Collateral" button

#### Step 3.5: Deposit Collateral Screen (`lib/src/ui/screens/lending/deposit_screen.dart`)
- Show collateral address (Ark or Bitcoin)
- QR code for easy scanning
- Amount required
- Wait for confirmation

#### Step 3.6: Claim Collateral Screen (`lib/src/ui/screens/lending/claim_screen.dart`)
- Fetch PSBT from API
- Sign with wallet
- Broadcast transaction
- Show success/txid

---

## Authentication Flow (Critical)

The iframe uses secp256k1 pubkey challenge-response:

```
1. App: Get compressed pubkey (33 bytes hex)
   → e.g., "0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798"

2. App → API: POST /api/auth/pubkey-challenge { pubkey }
   ← API: { challenge: "random-string-from-server" }

3. App: Sign SHA256(challenge) with ECDSA
   → DER-encoded signature as hex

4. App → API: POST /api/auth/pubkey-verify { pubkey, challenge, signature }
   ← API: { token: "jwt-token", user: {...} }

5. App: Use JWT in Authorization header for all subsequent requests
   → Authorization: Bearer <jwt-token>
```

### Key Implementation Details

**Signing must match the iframe implementation:**
```typescript
// iframe: signMessage signs SHA256(message) with ECDSA
const signature = await client.signMessage(challenge);
```

In Rust:
```rust
use bitcoin::secp256k1::{Message, Secp256k1};
use sha2::{Sha256, Digest};

pub fn sign_message(message: &str, keypair: &Keypair) -> Result<String> {
    let secp = Secp256k1::new();

    // Hash the message
    let mut hasher = Sha256::new();
    hasher.update(message.as_bytes());
    let hash = hasher.finalize();

    // Create message from hash
    let msg = Message::from_digest_slice(&hash)?;

    // Sign
    let sig = secp.sign_ecdsa(&msg, &keypair.secret_key());

    // Return DER-encoded hex
    Ok(hex::encode(sig.serialize_der()))
}
```

---

## Contract Lifecycle

```
┌─────────────┐     ┌──────────┐     ┌───────────────────┐
│  Requested  │────▶│ Approved │────▶│ CollateralSeen    │
└─────────────┘     └──────────┘     └─────────┬─────────┘
                                               │
                    ┌──────────────────────────▼─────────────────────────┐
                    │              CollateralConfirmed                    │
                    └──────────────────────────┬─────────────────────────┘
                                               │
                    ┌──────────────────────────▼─────────────────────────┐
                    │                PrincipalGiven                       │
                    │        (Lender sends stablecoins to borrower)       │
                    └──────────────────────────┬─────────────────────────┘
                                               │
                    ┌──────────────────────────▼─────────────────────────┐
                    │              RepaymentProvided                       │
                    │        (Borrower marks repayment as sent)            │
                    └──────────────────────────┬─────────────────────────┘
                                               │
                    ┌──────────────────────────▼─────────────────────────┐
                    │              RepaymentConfirmed                      │
                    │        (Lender confirms receipt)                     │
                    └──────────────────────────┬─────────────────────────┘
                                               │
                    ┌──────────────────────────▼─────────────────────────┐
                    │                    Closed                           │
                    │        (Borrower claimed collateral back)           │
                    └────────────────────────────────────────────────────┘
```

---

## API Endpoints to Implement

### Authentication
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/pubkey-challenge` | Request auth challenge |
| POST | `/api/auth/pubkey-verify` | Verify signature, get JWT |
| POST | `/api/auth/pubkey-register` | Register new user |

### Offers
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/offers` | List available offers (with filters) |

### Contracts
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/contracts` | List user's contracts |
| POST | `/api/contracts` | Create new contract (take offer) |
| GET | `/api/contracts/{id}` | Get contract details |
| DELETE | `/api/contracts/{id}` | Cancel contract (if Requested) |
| PUT | `/api/contracts/{id}/installment-paid` | Mark repayment sent |

### Claim Collateral
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/contracts/{id}/claim` | Get PSBT for claiming |
| POST | `/api/contracts/{id}/broadcast-claim` | Broadcast signed TX |
| GET | `/api/contracts/{id}/claim-ark` | Get Ark PSBTs for claiming |
| POST | `/api/contracts/{id}/broadcast-claim-ark` | Broadcast Ark claim |

### Recovery (Expired Contracts)
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/contracts/{id}/recover` | Get recovery PSBT |
| POST | `/api/contracts/{id}/broadcast-recover` | Broadcast recovery TX |

---

## File Structure

```
rust/
└── src/
    ├── api/
    │   ├── mod.rs                    # Add lendasat_api
    │   └── lendasat_api.rs           # NEW: API client
    ├── lendasat/
    │   ├── mod.rs                    # NEW: Module root
    │   ├── models.rs                 # NEW: Types/structs
    │   ├── auth.rs                   # NEW: Auth/signing
    │   └── storage.rs                # NEW: Local storage for JWT

lib/
└── src/
    ├── models/
    │   └── lendasat/
    │       └── lendasat_models.dart  # NEW: Dart models
    ├── services/
    │   └── lendasat_service.dart     # NEW: Service layer
    └── ui/
        └── screens/
            └── lending/
                ├── offers_screen.dart          # NEW
                ├── create_contract_screen.dart # NEW
                ├── contracts_screen.dart       # NEW
                ├── contract_details_screen.dart# NEW
                ├── deposit_screen.dart         # NEW
                └── claim_screen.dart           # NEW
```

---

## Testing Checklist

### Authentication
- [ ] Can get public key from wallet
- [ ] Can sign challenge message correctly (matches expected format)
- [ ] Can authenticate and receive JWT
- [ ] JWT is stored and used for subsequent requests
- [ ] Token refresh works

### Offers
- [ ] Can fetch available offers
- [ ] Filters work correctly
- [ ] Offer details display properly

### Contracts
- [ ] Can create a contract from an offer
- [ ] Contract list displays correctly
- [ ] Contract details show all information
- [ ] Can cancel a Requested contract

### Collateral Deposit
- [ ] Correct address displayed (Ark vs Bitcoin)
- [ ] Amount calculation is correct
- [ ] Can detect when collateral is confirmed

### Repayment
- [ ] Installment information displays correctly
- [ ] Can mark installment as paid
- [ ] Status updates after marking paid

### Claim
- [ ] Can fetch claim PSBT
- [ ] Can sign PSBT with wallet
- [ ] Can broadcast signed transaction
- [ ] Transaction ID is returned and displayed

---

## Security Considerations

1. **JWT Storage**: Store JWT token securely (not in plain SharedPreferences)
2. **Key Exposure**: Never log or expose private keys
3. **Signature Verification**: Ensure signatures are created correctly
4. **HTTPS**: All API calls must use HTTPS
5. **Error Handling**: Don't leak sensitive info in error messages

---

## Implementation Order

1. **Week 1**: Rust API client + Auth flow
   - [ ] Create lendasat models
   - [ ] Implement HTTP client
   - [ ] Implement auth (challenge-response)
   - [ ] Test authentication end-to-end

2. **Week 2**: Dart service layer + Basic UI
   - [ ] Create Dart models
   - [ ] Implement LendasatService
   - [ ] Create Offers screen
   - [ ] Create basic Contracts list

3. **Week 3**: Contract creation + Details
   - [ ] Create Contract screen
   - [ ] Contract Details screen
   - [ ] Deposit screen with address/QR

4. **Week 4**: Repayment + Claim flow
   - [ ] Repayment UI
   - [ ] Claim flow (PSBT signing)
   - [ ] Recovery flow
   - [ ] Testing & polish

---

## Environment Configuration

```dart
// lib/src/config/lendasat_config.dart
class LendasatConfig {
  static String get apiUrl {
    // TODO: Use environment-based configuration
    return kDebugMode
      ? 'https://apiborrowersignet.lendasat.com'  // Signet/Testnet
      : 'https://apiborrow.lendasat.com';          // Mainnet
  }
}
```

---

## Open Questions

1. **Registration**: Do users need to register before borrowing, or is pubkey auth sufficient?
   - Answer: Registration is required (email + name + invite code optional)

2. **Derivation Path**: Which key/derivation path should be used for Lendasat?
   - Recommend: Use the same key as Ark client for consistency

3. **Ark Settlement**: Some contracts require `requiresArkSettlement` - need to understand this flow better
   - This is for recoverable VTXOs that need on-chain settlement

4. **Notifications**: How to notify user of status changes?
   - Consider: Local polling or push notifications via Nostr (npub)
