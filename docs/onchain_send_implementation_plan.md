# Onchain Send Implementation Plan

## Status: IMPLEMENTED ✅

The fix has been implemented as described below. See commit history for changes.

## Problem

When sending onchain (from Ark VTXOs to a Bitcoin address), the app fails with:

```
INVALID_PSBT_INPUT (5): vtxo expires after 2026-01-20... (minExpiryGap: 695h53m36s)
```

The ASP (Ark Service Provider) requires VTXOs to have at least ~30 days (696 hours) remaining before expiry. The current implementation uses `collaborative_redeem()` which automatically selects ALL VTXOs, including ones close to expiry.

## How Arkade Wallet Solves This

Location: `~/lendasat/wallet/src/lib/asp.ts` (lines 87-130)

```typescript
export const collaborativeExitWithFees = async (
  wallet: IWallet,
  inputAmount: number,
  outputAmount: number,
  address: string, // Bitcoin onchain address
): Promise<string> => {
  // 1. Get all VTXOs
  const vtxos = await wallet.getVtxos();

  // 2. Sort by batch expiry ASCENDING (use VTXOs expiring soonest first)
  const vtxosSorted = vtxos.sort((a, b) =>
    (a.virtualStatus.batchExpiry ?? 0) - (b.virtualStatus.batchExpiry ?? 0)
  );

  // 3. Select VTXOs to cover the amount
  const selectedVtxos = [];
  let selectedAmount = 0;
  for (const vtxo of vtxosSorted) {
    if (selectedAmount >= inputAmount) break;
    selectedVtxos.push(vtxo);
    selectedAmount += vtxo.value;
  }

  // 4. Build outputs (onchain address + change to offchain)
  const outputs = [{ address, amount: BigInt(outputAmount) }];
  const changeAmount = selectedAmount - inputAmount;
  if (changeAmount > 0) {
    const { offchainAddr } = await getReceivingAddresses(wallet);
    outputs.push({ address: offchainAddr, amount: BigInt(changeAmount) });
  }

  // 5. Call settle with specific inputs and outputs
  return await wallet.settle({ inputs: selectedVtxos, outputs });
};
```

**Key Insight**: Arkade uses `wallet.settle({ inputs, outputs })` which allows:

- Specifying exactly which VTXOs to use as inputs
- Specifying outputs including onchain Bitcoin addresses

## Current Lendamobile Implementation

Location: `/mnt/c/Users/tobia/StudioProjects/lendamobile/rust/src/ark/client.rs` (lines 202-218)

```rust
} else if is_btc_address(address.as_str()) {
    let address = Address::from_str(address.as_str())?;
    let rng = &mut StdRng::from_entropy();
    let txid = client
        .collaborative_redeem(rng, address.assume_checked(), amount)
        .await
        .map_err(|e| anyhow!("Failed sending onchain {e:#}"))?;
    Ok(txid)
}
```

**Problem**: `collaborative_redeem()` in ark-client automatically selects VTXOs using `fetch_commitment_transaction_inputs()` which includes ALL VTXOs, even those close to expiry.

## ark-rs SDK Analysis

Location: `~/.cargo/git/checkouts/ark-rs-df93e4a881b127c7/09b0732/ark-client/src/`

### Available Methods

1. **`list_vtxos()`** (lib.rs:749) - Returns `VtxoList` with categorized VTXOs
2. **`settle_vtxos()`** (batch.rs:116) - Settles specific VTXOs but only to offchain address
3. **`collaborative_redeem()`** (batch.rs:193) - Sends to onchain but auto-selects VTXOs

### VirtualTxOutPoint Structure (ark-core/src/server.rs:302)

```rust
pub struct VirtualTxOutPoint {
    pub outpoint: OutPoint,
    pub created_at: i64,
    pub expires_at: i64, // <-- Unix timestamp for expiry
    pub amount: Amount,
    pub script: ScriptBuf,
    pub is_preconfirmed: bool,
    pub is_swept: bool,
    pub is_unrolled: bool,
    pub is_spent: bool,
    // ...
}
```

### BatchOutputType (batch.rs)

```rust
pub(crate) enum BatchOutputType {
    Board {
        to_address: ArkAddress,
        to_amount: Amount,
    },
    OffBoard {
        // <-- This is what we need for onchain sends
        to_address: Address, // Bitcoin address
        to_amount: Amount,
        change_address: ArkAddress, // Ark address for change
        change_amount: Amount,
    },
}
```

### The Missing Piece

The ark-rs SDK has `join_next_batch()` (internal) which takes specific inputs and `BatchOutputType`, but it's not exposed publicly. The `collaborative_redeem()` uses it internally with auto-selected VTXOs.

## Implementation Options

### Option 1: Modify ark-rs SDK (Recommended)

Add a new public method to ark-client that combines VTXO selection with onchain output:

```rust
/// Send to onchain address with custom VTXO selection
pub async fn collaborative_redeem_with_vtxos<R>(
    &self,
    rng: &mut R,
    vtxo_outpoints: &[OutPoint],  // Specific VTXOs to use
    to_address: Address,
    to_amount: Amount,
) -> Result<Txid, Error>
```

**Location**: `~/.cargo/git/checkouts/ark-rs-df93e4a881b127c7/*/ark-client/src/batch.rs`

Or fork ark-rs to: `~/lendasat/rust-sdk` or similar

### Option 2: Implement in Lendamobile Rust Layer

Add a wrapper function that:

1. Calls `client.list_vtxos()` to get VTXOs with expiry info
2. Sorts by `expires_at` ascending
3. Filters to only `confirmed()` VTXOs (not expired, not pre-confirmed)
4. Selects VTXOs to cover amount
5. Calls a modified version of collaborative_redeem

**Location**: `/mnt/c/Users/tobia/StudioProjects/lendamobile/rust/src/ark/client.rs`

```rust
/// Send to onchain address with proper VTXO selection (like Arkade wallet)
pub async fn send_onchain_with_vtxo_selection(address: Address, amount: Amount) -> Result<Txid> {
    let client = get_client()?;

    // 1. Get all VTXOs
    let (vtxo_list, _) = client.list_vtxos().await?;

    // 2. Get confirmed VTXOs and sort by expiry ascending
    let mut vtxos: Vec<_> = vtxo_list.confirmed().collect();
    vtxos.sort_by_key(|v| v.expires_at);

    // 3. Select VTXOs to cover amount
    let mut selected = Vec::new();
    let mut selected_amount = Amount::ZERO;
    for vtxo in vtxos {
        if selected_amount >= amount {
            break;
        }
        selected.push(vtxo.outpoint);
        selected_amount += vtxo.amount;
    }

    // 4. Call settle/collaborative_redeem with selected VTXOs
    // ... (requires access to internal join_next_batch or SDK modification)
}
```

### Option 3: Pre-settle Before Send

Simpler workaround - settle all VTXOs first to get fresh ones with longer expiry:

```rust
} else if is_btc_address(address.as_str()) {
    // Settle first to refresh VTXOs with longer expiry
    let _ = settle().await;

    // Then send onchain
    let txid = client.collaborative_redeem(...).await?;
}
```

**Downside**: Requires waiting for an Ark round, adds latency.

## Recommended Implementation Steps

### Step 1: Fork or Modify ark-rs

1. Clone ark-rs to `~/lendasat/rust-sdk`
2. Add `collaborative_redeem_with_vtxos()` method to `ark-client/src/batch.rs`
3. Update Cargo.toml to use local path or forked repo

### Step 2: Implement VTXO Selection in Lendamobile

In `/mnt/c/Users/tobia/StudioProjects/lendamobile/rust/src/ark/client.rs`:

```rust
use ark_core::server::VirtualTxOutPoint;

/// Select VTXOs for onchain send, sorted by expiry (soonest first)
async fn select_vtxos_for_amount(client: &ArkClient, amount: Amount) -> Result<Vec<OutPoint>> {
    let (vtxo_list, _) = client
        .list_vtxos()
        .await
        .map_err(|e| anyhow!("Failed to list VTXOs: {e}"))?;

    // Get confirmed VTXOs only (not expired, not pre-confirmed)
    let mut vtxos: Vec<&VirtualTxOutPoint> = vtxo_list.confirmed().collect();

    // Sort by expiry ascending - use VTXOs expiring soonest first
    // This matches Arkade wallet behavior
    vtxos.sort_by_key(|v| v.expires_at);

    // Select VTXOs to cover the amount
    let mut selected = Vec::new();
    let mut selected_amount = Amount::ZERO;

    for vtxo in vtxos {
        if selected_amount >= amount {
            break;
        }
        selected.push(vtxo.outpoint);
        selected_amount += vtxo.amount;
    }

    if selected_amount < amount {
        bail!("Insufficient confirmed VTXOs for amount");
    }

    Ok(selected)
}

pub async fn send_onchain(address: String, amount: Amount) -> Result<Txid> {
    let client = get_client()?;
    let address = Address::from_str(&address)?;

    // Select VTXOs sorted by expiry
    let vtxo_outpoints = select_vtxos_for_amount(&client, amount).await?;

    // Use the new method with specific VTXOs
    let rng = &mut StdRng::from_entropy();
    let txid = client
        .collaborative_redeem_with_vtxos(rng, &vtxo_outpoints, address, amount)
        .await?;

    Ok(txid)
}
```

### Step 3: Update Send Function

Replace the current BTC address handling in `send()`:

```rust
} else if is_btc_address(address.as_str()) {
    send_onchain(address, amount).await
}
```

## Files to Modify

1. **ark-rs SDK** (fork to ~/lendasat/rust-sdk):
   - `ark-client/src/batch.rs` - Add `collaborative_redeem_with_vtxos()`

2. **Lendamobile Rust**:
   - `rust/Cargo.toml` - Point to forked ark-rs
   - `rust/src/ark/client.rs` - Add VTXO selection and new send function

3. **Recompile**:
   ```bash
   cd /mnt/c/Users/tobia/StudioProjects/lendamobile/rust
   cargo ndk -t arm64-v8a -o ../android/app/src/main/jniLibs build --release
   ```

## Testing

1. Check VTXOs have varying expiry times: Some close to expiry, some fresh
2. Send onchain should succeed by using the fresh VTXOs
3. Verify the VTXOs used are sorted by expiry (soonest first from logs)

## References

- Arkade wallet: `~/lendasat/wallet/src/lib/asp.ts` (collaborativeExitWithFees)
- ark-rs SDK: `~/.cargo/git/checkouts/ark-rs-df93e4a881b127c7/09b0732/ark-client/src/batch.rs`
- VirtualTxOutPoint: `ark-core/src/server.rs:302`
- VtxoList: `ark-core/src/vtxo_list.rs`
