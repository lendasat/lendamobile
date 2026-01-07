# Arkade Loan Flow - Complete Technical Documentation

This document explains how Arkade (Ark) loans work in LendaSat, and compares the backend implementation with what lendamobile is currently doing.

---

## Table of Contents

1. [Overview](#overview)
2. [VTXO States](#vtxo-states)
3. [The Arkade Taproot Script](#the-arkade-taproot-script)
4. [Claim Flows](#claim-flows)
   - [Offchain Claim (Non-Recoverable VTXOs)](#offchain-claim-non-recoverable-vtxos)
   - [Settlement Claim (Recoverable VTXOs)](#settlement-claim-recoverable-vtxos)
5. [Forfeit Transactions](#forfeit-transactions)
6. [Output Distribution](#output-distribution)
7. [What lendamobile Is Currently Doing](#what-lendamobile-is-currently-doing)
8. [Compliance Analysis](#compliance-analysis)
9. [Key Participants](#key-participants)
10. [API Endpoints](#api-endpoints)

---

## Overview

LendaSat uses the Ark protocol for instant, offchain Bitcoin collateral. When a borrower takes a loan:

1. They send collateral to a special **Arkade address** (VTXO)
2. The VTXO is locked with a custom Taproot script with 6 spending paths
3. Different parties can spend it depending on loan outcome
4. On repayment, borrower claims their collateral back

There are **two distinct claim flows** depending on VTXO state:

| Flow | VTXO State | Endpoints | When Used |
|------|------------|-----------|-----------|
| **Offchain Claim** | Non-recoverable | `claim-ark` -> `broadcast-claim-ark` | Normal case |
| **Settlement** | Recoverable | `settle-ark` -> `finish-settle-ark` | VTXOs swept to recoverable state |

---

## VTXO States

The collateral VTXOs can be in these states:

```
PreConfirmed --> Confirmed --+--> Spent (offchain tx completed)
                             |
                             +--> Recoverable --> Settled (via batch)
```

| Status | Meaning | Offchain Claimable? |
|--------|---------|---------------------|
| `Confirmed` | VTXO is spendable | Yes |
| `PreConfirmed` | Pending confirmation | No (wait) |
| `Spent` | Already spent | N/A |
| `Recoverable` | Needs settlement flow | No (use settle-ark) |
| `Settled` | Completed via batch | N/A |

**Why do VTXOs become recoverable?**
- Ark periodically "sweeps" old VTXOs into new rounds
- If a VTXO is swept while collateral is locked, it becomes recoverable
- Recoverable VTXOs cannot be spent offchain - must go through settlement

---

## The Arkade Taproot Script

Each collateral VTXO uses a custom Taproot tree with **6 spending paths**:

### Offchain Paths (require Ark server signature)

| Script | Signers Required | Purpose |
|--------|------------------|---------|
| `borrower_hub_script` | Borrower + Hub + Server | Borrower claims after repayment |
| `lender_hub_script` | Lender + Hub + Server | Lender liquidates on default |
| `borrower_lender_script` | Borrower + Lender + Server | Cooperative spend |

### Onchain Paths (time-locked, no server needed)

| Script | Signers Required | Purpose |
|--------|------------------|---------|
| `unilateral_borrower_hub_script` | Borrower + Hub + CSV delay | Unilateral exit by borrower |
| `unilateral_lender_hub_script` | Lender + Hub + CSV delay | Unilateral exit by lender |
| `unilateral_borrower_lender_script` | Borrower + Lender + CSV delay | Cooperative unilateral |

The CSV (CheckSequenceVerify) delay ensures the server has time to respond before unilateral exits are possible.

---

## Claim Flows

### Offchain Claim (Non-Recoverable VTXOs)

This is the **normal, fast path** for claiming collateral after loan repayment.

#### Step 1: `GET /api/contracts/{id}/claim-ark`

**What happens on the backend:**
1. Validates contract belongs to borrower
2. Checks loan is fully repaid (`balance_outstanding == 0`)
3. Loads collateral VTXOs from database
4. **Fails if any VTXO is recoverable** (must use settlement instead)
5. Builds Ark PSBT (main spend transaction)
6. Builds checkpoint PSBTs (one per VTXO for Ark protocol)
7. Hub signs both with its key
8. Returns to client

**Response:**
```json
{
  "ark_psbt": "<hex-encoded main PSBT, hub-signed>",
  "checkpoint_psbts": ["<hex checkpoint PSBT 1>", "<hex checkpoint PSBT 2>", ...],
  "borrower_pk": "<33-byte compressed pubkey>",
  "derivation_path": "m/83696968'/11811'/0/0"
}
```

#### Step 2: Borrower Signs PSBTs Locally

The borrower signs using their **Ark identity key** (NOT Lendasat auth key):
- Main Ark PSBT
- All checkpoint PSBTs

#### Step 3: `POST /api/contracts/{id}/broadcast-claim-ark`

**What happens on the backend:**
1. Receives signed PSBTs from borrower
2. Connects to Arkade server
3. Submits offchain transaction: `submit_offchain_transaction_request(ark_psbt, checkpoint_psbts)`
4. Combines signatures (hub + borrower)
5. Finalizes transaction: `finalize_offchain_transaction(ark_txid, final_checkpoint_psbts)`
6. Marks contract as `ClosingByClaim`
7. Returns TXID

---

### Settlement Claim (Recoverable VTXOs)

This flow is required when VTXOs are in **recoverable state** (cannot be spent offchain).

#### Step 1: `GET /api/contracts/{id}/settle-ark`

**What happens on the backend:**
1. Validates contract (same as offchain)
2. Builds **Intent PSBT** (declares what outputs the user wants)
3. Builds **Forfeit PSBTs** (one per VTXO - exchanged for new confirmed VTXOs)
4. Generates a **cosigner keypair** for the delegate protocol
5. Stores pending settlement in memory
6. Returns to client

**Response:**
```json
{
  "intent_message": "<message for Ark server>",
  "intent_proof": "<BASE64 PSBT to sign>",
  "forfeit_psbts": ["<BASE64 forfeit PSBT 1>", "<BASE64 forfeit PSBT 2>", ...],
  "delegate_cosigner_pk": "<hub's cosigner pubkey>",
  "user_pk": "<borrower's Ark identity pubkey>",
  "derivation_path": "m/83696968'/11811'/0/0"
}
```

**IMPORTANT:** Settlement PSBTs are returned in **BASE64** format (not hex like offchain).

#### Step 2: Borrower Signs All PSBTs Locally

The borrower signs with their **Ark identity key**:
- Intent proof PSBT (after converting BASE64 -> HEX)
- All forfeit PSBTs (after converting BASE64 -> HEX)
- Then converts signed PSBTs back to BASE64 for the API

#### Step 3: `POST /api/contracts/{id}/finish-settle-ark`

**What happens on the backend (this is complex!):**

1. Receives signed PSBTs from borrower
2. Retrieves pending settlement from memory
3. Hub signs delegate PSBTs with its key
4. **Full Ark Batch Protocol:**
   ```
   a. register_intent() with Ark server
   b. Wait for BatchStarted event
   c. confirm_registration()
   d. generate_nonces() and submit to server
   e. Wait for aggregated_nonces
   f. sign_vtxo_tree()
   g. Wait for BatchFinalization
   h. submit_signed_forfeit_txs() with connector outputs
   i. Wait for BatchFinalized event
   ```
5. Returns commitment TXID

---

## Forfeit Transactions

Forfeit transactions are a critical safety mechanism in the Ark protocol.

**Purpose:** Allow the Ark server to claim old VTXOs if the user abandons the batch.

**Structure:**
```
Old VTXO ----+
             |
Forfeit TX --+--> Connector Output (links to commitment tx)
             |
             +--> Ark Server can claim if batch completes
                  without user finishing
```

**When they execute:**
- Only if user doesn't complete batch participation
- Ark server broadcasts them to take custody of abandoned VTXOs

**When they DON'T execute:**
- Normal flow: user completes batch -> gets new confirmed VTXOs
- Forfeit TXs are never broadcast

---

## Output Distribution

### Borrower Claim (loan fully repaid)

```
Total Collateral
    |
    +-- Borrower receives: collateral - origination_fee
    |
    +-- Hub receives: origination_fee
```

### Lender Liquidation (loan defaulted)

```
Total Collateral
    |
    +-- Lender receives: outstanding_balance
    |
    +-- Borrower receives: collateral - origination_fee - outstanding_balance
    |
    +-- Hub receives: origination_fee
```

---

## What lendamobile Is Currently Doing

### Contract Creation

**File:** `rust/src/api/lendasat_api.rs:579-664`

lendamobile correctly uses the **Ark identity pubkey** as `borrower_pk`:

```rust
// CRITICAL: Use Ark identity pubkey for borrower_pk, NOT the Lendasat derivation path key!
let ark_identity_pubkey = get_ark_identity_pubkey().await?;
let borrower_btc_address = get_ark_address().await?;

let request = CreateContractRequest {
    borrower_pk: ark_identity_pubkey.clone(),  // Ark identity key (m/83696968'/11811'/0/0)
    borrower_btc_address: borrower_btc_address.clone(),  // Ark offchain address
    // ...
};
```

### Claim Collateral Flow

**File:** `lib/src/services/lendasat_service.dart:480-642`

The `claimArkCollateral()` method correctly checks which flow to use:

```dart
Future<String> claimArkCollateral({required String contractId}) async {
  // Get the contract to check if settlement is required
  final contract = await getContract(contractId);
  final requiresSettlement = contract.requiresArkSettlement ?? false;

  if (requiresSettlement) {
    // Settlement flow for recoverable VTXOs
    return await _claimArkViaSettlement(contractId);
  } else {
    // Offchain claim flow for non-recoverable VTXOs
    return await _claimArkViaOffchain(contractId);
  }
}
```

### Offchain Claim Implementation

**File:** `lib/src/services/lendasat_service.dart:510-563`

```dart
Future<String> _claimArkViaOffchain(String contractId) async {
  // 1. Get claim PSBTs from API
  final arkResponse = await getClaimArkPsbt(contractId);

  // 2. Sign main PSBT with Ark identity (NOT Lendasat key!)
  final signedArkPsbt = await ark_api.signPsbtWithArkIdentity(
    psbtHex: arkResponse.arkPsbt,
  );

  // 3. Sign all checkpoint PSBTs with Ark identity
  final signedCheckpointPsbts = <String>[];
  for (final checkpointPsbt in arkResponse.checkpointPsbts) {
    final signedCheckpoint = await ark_api.signPsbtWithArkIdentity(
      psbtHex: checkpointPsbt,
    );
    signedCheckpointPsbts.add(signedCheckpoint);
  }

  // 4. Broadcast signed transactions
  final txid = await broadcastClaimArkTx(
    contractId: contractId,
    signedArkPsbt: signedArkPsbt,
    signedCheckpointPsbts: signedCheckpointPsbts,
  );

  return txid;
}
```

### Settlement Claim Implementation

**File:** `lib/src/services/lendasat_service.dart:575-641`

```dart
Future<String> _claimArkViaSettlement(String contractId) async {
  // 1. Get settle PSBTs (returned in BASE64 format)
  final settleResponse = await lendasat_api.lendasatGetSettleArkPsbt(
    contractId: contractId,
  );

  // 2. Convert intent proof BASE64 -> HEX for signing
  final intentProofHex = await lendasat_api.lendasatPsbtBase64ToHex(
    base64Psbt: settleResponse.intentProof,
  );

  // 3. Sign intent proof with Ark identity (NOT Lendasat key!)
  final signedIntentHex = await ark_api.signPsbtWithArkIdentity(
    psbtHex: intentProofHex,
  );

  // 4. Convert signed intent back to BASE64
  final signedIntentBase64 = await lendasat_api.lendasatPsbtHexToBase64(
    hexPsbt: signedIntentHex,
  );

  // 5. Sign all forfeit PSBTs (BASE64 -> HEX -> sign -> BASE64)
  final signedForfeitPsbtsBase64 = <String>[];
  for (final forfeitPsbtBase64 in settleResponse.forfeitPsbts) {
    final forfeitHex = await lendasat_api.lendasatPsbtBase64ToHex(
      base64Psbt: forfeitPsbtBase64,
    );
    final signedForfeitHex = await ark_api.signPsbtWithArkIdentity(
      psbtHex: forfeitHex,
    );
    final signedForfeitBase64 = await lendasat_api.lendasatPsbtHexToBase64(
      hexPsbt: signedForfeitHex,
    );
    signedForfeitPsbtsBase64.add(signedForfeitBase64);
  }

  // 6. Finish settlement (API handles full batch protocol)
  final commitmentTxid = await lendasat_api.lendasatFinishSettleArk(
    contractId: contractId,
    signedIntentPsbt: signedIntentBase64,
    signedForfeitPsbts: signedForfeitPsbtsBase64,
  );

  return commitmentTxid;
}
```

---

## Compliance Analysis

### Is lendamobile Following All Steps Correctly?

| Step | Required | lendamobile | Status |
|------|----------|-------------|--------|
| Use Ark identity key for `borrower_pk` | Yes | Yes | CORRECT |
| Use Ark offchain address for collateral | Yes | Yes | CORRECT |
| Check `requiresArkSettlement` before claiming | Yes | Yes | CORRECT |
| Sign with Ark identity (not Lendasat key) | Yes | Yes | CORRECT |
| Handle BASE64 <-> HEX conversion for settlement | Yes | Yes | CORRECT |
| Sign main Ark PSBT | Yes | Yes | CORRECT |
| Sign all checkpoint PSBTs | Yes | Yes | CORRECT |
| Sign intent proof PSBT (settlement) | Yes | Yes | CORRECT |
| Sign all forfeit PSBTs (settlement) | Yes | Yes | CORRECT |
| Call correct broadcast/finish endpoint | Yes | Yes | CORRECT |

### Summary

**lendamobile is correctly implementing the Arkade loan claim flow.** It:

1. **Uses dual-key architecture correctly:**
   - Lendasat key (`m/10101'/0'/0`) for authentication only
   - Ark identity key (`m/83696968'/11811'/0/0`) for collateral operations

2. **Handles both claim scenarios:**
   - Offchain claim for non-recoverable VTXOs
   - Settlement flow for recoverable VTXOs

3. **Signs with the correct key:**
   - Uses `ark_api.signPsbtWithArkIdentity()` for all collateral PSBTs
   - This matches the `borrower_pk` used in contract creation

4. **Handles format conversions correctly:**
   - Settlement PSBTs: BASE64 -> HEX for signing -> BASE64 for API
   - Offchain PSBTs: Already in HEX format

5. **Calls the correct endpoints:**
   - `claim-ark` + `broadcast-claim-ark` for offchain
   - `settle-ark` + `finish-settle-ark` for settlement

---

## Key Participants

| Participant | Role | Key Path | When Signs |
|-------------|------|----------|------------|
| **Borrower** | Collateral owner | `m/83696968'/11811'/0/0` | Claims after repayment |
| **Lender** | Loan provider | (lender's key) | Liquidates on default |
| **Hub** | LendaSat server | (server key) | All operations (escrow) |
| **Ark Server** | Arkade server | (server key) | Offchain transactions only |

---

## API Endpoints

### Offchain Claim

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/contracts/{id}/claim-ark` | GET | Get PSBTs for offchain claim |
| `/api/contracts/{id}/broadcast-claim-ark` | POST | Broadcast signed claim |

### Settlement Claim

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/contracts/{id}/settle-ark` | GET | Get PSBTs for settlement |
| `/api/contracts/{id}/finish-settle-ark` | POST | Complete settlement |

### Other

| Endpoint | Method | Purpose |
|----------|--------|---------|
| `/api/contracts/{id}/liquidate-ark` | POST | Lender liquidation |
| `/api/contracts/{id}/finish-liquidate-ark` | POST | Complete liquidation |

---

## Decision Tree for Claiming

```
Borrower wants to claim collateral
            |
            v
    Is loan fully repaid?
       /          \
      No           Yes
      |             |
   CANNOT          |
   CLAIM           v
              contract.requiresArkSettlement?
               /              \
            false              true
              |                  |
              v                  v
         OFFCHAIN            SETTLEMENT
           CLAIM               FLOW
              |                  |
              v                  v
         claim-ark          settle-ark
              |                  |
              v                  v
       broadcast-          finish-
        claim-ark         settle-ark
              |                  |
              v                  v
           TXID           commitment_txid
```

---

## Files Reference

### Backend (~/lendasat/lendasat)

| File | Purpose |
|------|---------|
| `hub/src/routes/borrower/contracts.rs` | Borrower claim/settle endpoints |
| `hub/src/routes/lender/contracts.rs` | Lender liquidation endpoints |
| `hub/src/wallet.rs` | PSBT creation logic |
| `hub/src/wallet/arkade.rs` | Ark batch protocol implementation |
| `hub/src/model/arkade_script.rs` | Taproot script definitions |
| `hub/src/db/collateral_vtxos.rs` | VTXO database model |

### lendamobile

| File | Purpose |
|------|---------|
| `rust/src/api/lendasat_api.rs` | Rust API client for LendaSat |
| `lib/src/services/lendasat_service.dart` | Dart service layer |
| `lib/src/ui/screens/contract_detail_screen.dart` | UI for contract actions |

---

---

## Appendix: Will `signPsbtWithArkIdentity` Actually Work?

### Deep Analysis of the Signing Chain

#### 1. How the LendaSat Hub Builds Claim PSBTs

When a borrower requests claim PSBTs (`GET /claim-ark`), the hub:

```rust
// hub/src/wallet.rs:364-367
let (script, control_block) = match is_signed_with_borrower {
    true => arkade_contract.offchain_spend_script_with_borrower_spend_info()?,
    false => arkade_contract.offchain_spend_script_with_lender_spend_info()?,
};
```

For borrower claims, it uses `borrower_hub_script` (one of the 6 Taproot paths).

The PSBTs are built with:
- `tap_scripts`: Contains **only** the `borrower_hub_script` and its control block
- `witness_utxo`: The VTXO being spent
- `witness_script`: The spend script

#### 2. Hub Pre-Signs the PSBTs

```rust
// hub/src/wallet.rs:390-408
let sign_fn = |_: &mut psbt::Input, msg: Message| {
    let sig = Secp256k1::new().sign_schnorr_no_aux_rand(&msg, &hub_kp);
    let pk = hub_kp.x_only_public_key().0;
    Ok((sig, pk))
};

// Sign all inputs in Ark PSBT
for i in 0..checkpoint_txs.len() {
    sign_ark_transaction(sign_fn, &mut ark_tx, i)?;
}

// Sign all checkpoint PSBTs
for checkpoint_psbt in checkpoint_txs.iter_mut() {
    sign_checkpoint_transaction(sign_fn, checkpoint_psbt)?;
}
```

**Result**: When lendamobile receives the PSBTs, they already contain the hub's signature.

#### 3. How `sign_ark_transaction` Works (ark-core)

```rust
// ark-core/src/send.rs:447-496
pub fn sign_ark_transaction<S>(sign_fn: S, psbt: &mut Psbt, input_index: usize) -> Result<(), Error>
where
    S: FnOnce(&mut psbt::Input, Message) -> Result<Vec<(schnorr::Signature, XOnlyPublicKey)>, Error>,
{
    // Get the first (and only) script from tap_scripts
    let (_, (vtxo_spend_script, leaf_version)) =
        psbt_input.tap_scripts.first_key_value().expect("one entry");

    // Compute the Taproot script-path sighash
    let leaf_hash = TapLeafHash::from_script(vtxo_spend_script, *leaf_version);
    let tap_sighash = SighashCache::new(&psbt.unsigned_tx)
        .taproot_script_spend_signature_hash(input_index, &prevouts, leaf_hash, TapSighashType::Default)?;

    let msg = secp256k1::Message::from_digest(tap_sighash.to_raw_hash().to_byte_array());

    // Call the signing function
    let sigs = sign_fn(psbt_input, msg)?;

    // Insert signatures into tap_script_sigs
    for (sig, pk) in sigs {
        psbt_input.tap_script_sigs.insert((pk, leaf_hash), sig);
    }
}
```

**Critical insight**: The function expects exactly one script in `tap_scripts` (which the hub provides).

#### 4. How lendamobile Signs

```rust
// rust/src/api/ark_api.rs:338-429
pub async fn sign_psbt_with_ark_identity(psbt_hex: String) -> Result<String> {
    // Get keypair from Ark SDK
    let ark_keypair = client_arc.get_keypair_for_pk(&identity_pk)?;

    // Sign each input using sign_ark_transaction
    for input_idx in 0..num_inputs {
        let sign_fn = |_input: &mut psbt::Input, msg: Message| {
            let sig = secp.sign_schnorr_no_aux_rand(&msg, &kp);
            let pk = kp.x_only_public_key().0;
            Ok(vec![(sig, pk)])
        };

        sign_ark_transaction(sign_fn, &mut psbt, input_idx)?;
    }
}
```

#### 5. Why This Should Work

| Component | Expectation | lendamobile | Status |
|-----------|-------------|-------------|--------|
| PSBT has `tap_scripts` | One entry with spend script | ✅ Hub provides this | Correct |
| PSBT has `witness_utxo` | Set by hub | ✅ Hub provides this | Correct |
| Correct signing key | Ark identity key | ✅ Uses `get_keypair_for_pk(&identity_pk)` | Correct |
| Signing function | Returns (signature, pubkey) | ✅ Returns `vec![(sig, pk)]` | Correct |
| Signature placement | `tap_script_sigs[(pk, leaf_hash)]` | ✅ Handled by `sign_ark_transaction` | Correct |

#### 6. The Script Requires 3 Signatures

The `borrower_hub_script` requires: **Borrower + Hub + Server**

| Signer | When Added | Key Used |
|--------|------------|----------|
| Hub | Before returning to client | Hub's keypair |
| Borrower | Client-side (`sign_psbt_with_ark_identity`) | Ark identity key |
| Server | During `broadcast-claim-ark` | Ark server key |

**Flow:**
```
GET /claim-ark
    └── Hub creates PSBTs with borrower_hub_script
    └── Hub signs with hub_kp
    └── Returns partially-signed PSBTs

Client signs with Ark identity key
    └── sign_psbt_with_ark_identity()

POST /broadcast-claim-ark
    └── Hub submits to Ark server
    └── Ark server adds its signature
    └── Transaction finalized and broadcast
```

#### 7. Key Matching Verification

For this to work, the borrower's signing key must match what's in the script.

**Contract creation (rust/src/api/lendasat_api.rs:587-622):**
```rust
let ark_identity_pubkey = get_ark_identity_pubkey().await?;

let request = CreateContractRequest {
    borrower_pk: ark_identity_pubkey.clone(),  // This is embedded in the script
    // ...
};
```

**Signing (rust/src/api/ark_api.rs:379-386):**
```rust
let (_ark_address, vtxo) = client_arc.get_offchain_address()?;
let identity_pk = vtxo.owner_pk();
let ark_keypair = client_arc.get_keypair_for_pk(&identity_pk)?;
```

**Both derive from the same source**: The Ark identity key path (`m/83696968'/11811'/0/0`).

### Conclusion: YES, It Should Work

The implementation is correct because:

1. ✅ **PSBT structure is correct** - Hub provides properly formatted PSBTs with one script in `tap_scripts`
2. ✅ **Hub pre-signs** - PSBTs arrive with hub's signature already added
3. ✅ **Same signing function** - lendamobile uses the exact same `sign_ark_transaction` function as the hub
4. ✅ **Key derivation matches** - Both contract creation and signing use the Ark identity key
5. ✅ **Signature format correct** - Schnorr signatures with `TapSighashType::Default`

### Comparison with iframe Reference

| Aspect | iframe (sample-wallet) | lendamobile |
|--------|------------------------|-------------|
| Signing method | `psbtObj.signAllInputs(keyPair)` | `sign_ark_transaction(sign_fn, psbt, i)` |
| Key source | User-provided raw private key | Ark SDK's key provider |
| Script handling | bitcoinjs-lib handles automatically | ark-core handles correctly |
| PSBT format | Hex | Hex |

Both approaches correctly handle Taproot script-path signing because the PSBTs are pre-formatted by the LendaSat hub with the correct script information.

---

*Last updated: December 2024*
