# EVM → BTC Swap Problem Description

## Problem Summary

EVM to BTC swaps (e.g., USDC on Polygon → Bitcoin) get stuck at "Waiting for Deposit" even after the user has sent tokens to the HTLC address.

## Root Cause

The LendaSwap server detects deposits by listening for `SwapCreated` events emitted by the HTLC smart contract. The event is only emitted when the `createSwap()` function is called on the contract.

### How the Website Works (Correctly)

1. User enters their BTC receive address (manual input, no wallet needed)
2. User **connects their EVM wallet** (MetaMask via WalletConnect/browser extension)
3. User clicks "Fund Swap" button
4. Website calls `approve()` on the ERC20 token contract (user signs in MetaMask)
5. Website calls `createSwap()` on the HTLC contract using pre-generated calldata (`create_swap_tx`)
6. The `createSwap()` function:
   - Transfers tokens from user to HTLC contract
   - Locks tokens with proper hashlock, timelock, and swap parameters
   - **Emits `SwapCreated` event**
7. Server's EVM event watcher detects the event
8. Server marks swap as `ClientFunded` and proceeds to fund the BTC side

**Key Insight:** The website uses `wagmi` hooks to connect to the user's wallet and execute transactions. Without wallet connection, no transactions can be signed.

### How the Mobile App Works (Incorrectly)

1. App shows user the HTLC address and tells them to "send tokens"
2. User opens MetaMask/external wallet manually
3. User does a simple ERC20 token transfer to the HTLC address
4. **Problem:** A simple token transfer does NOT call `createSwap()`
5. No `SwapCreated` event is emitted
6. Server never detects the deposit
7. Swap stays stuck at "Waiting for Deposit" forever

### Why We Can't "Just Call createSwap()"

The user's USDC/tokens are in their **external wallet** (MetaMask). The app doesn't have access to that wallet's private key. To execute any transaction from that wallet, we need the user's signature.

Current app behavior (`lendaswap_service.dart:183`):
```dart
userEvmAddress: '0x0000000000000000000000000000000000000000', // Dummy!
```

The app sends a dummy address because it doesn't know or control the user's EVM wallet.

## Technical Details

### Missing API Field

The LendaSwap SDK returns `create_swap_tx` which contains the calldata needed to call `createSwap()`:

```rust
// In lendaswap-core SDK (client-sdk/core/src/api/types.rs)
pub struct EvmToBtcSwapResponse {
    // ... other fields ...
    pub create_swap_tx: Option<String>,  // <-- This is the key field!
    pub approve_tx: Option<String>,
    // ...
}
```

But the mobile app's API doesn't expose this field:

```rust
// In lendamobile (rust/src/api/lendaswap_api.rs)
pub struct EvmToBtcSwapResult {
    pub swap_id: String,
    pub evm_htlc_address: String,
    pub source_amount_usd: f64,
    pub sats_to_receive: i64,
    pub fee_sats: i64,
    pub source_token_address: String,
    pub gelato_forwarder_address: Option<String>,
    pub gelato_user_nonce: Option<String>,
    pub gelato_user_deadline: Option<String>,
    // MISSING: create_swap_tx: Option<String>,
}
```

### Event Detection Flow

```
User sends tokens directly → No event → Server doesn't see deposit → Stuck

User calls createSwap() → SwapCreated event emitted → Server detects → Swap proceeds
```

## Solution: WalletConnect Integration

### Why WalletConnect is the Only Real Solution

All other approaches have fundamental problems:
- **Manual calldata:** Users will still just send tokens incorrectly
- **Deep links to website:** Poor UX, context switching
- **Gelato signatures:** Still needs WalletConnect to get the user's signature!

WalletConnect is the industry standard for connecting mobile apps to external wallets. It's what the website uses (via wagmi), and it's what we need.

### Implementation Plan

#### Step 1: Add WalletConnect SDK

```yaml
# pubspec.yaml
dependencies:
  walletconnect_flutter_v2: ^2.x.x
  web3dart: ^2.x.x  # For transaction building
```

#### Step 2: Create Wallet Connection Service

```dart
// lib/src/services/wallet_connect_service.dart
class WalletConnectService {
  Web3App? _web3App;
  String? _connectedAddress;

  Future<void> connect() async {
    // Initialize WalletConnect
    _web3App = await Web3App.createInstance(
      projectId: 'YOUR_WALLETCONNECT_PROJECT_ID',
      metadata: PairingMetadata(
        name: 'LendaMobile',
        description: 'Bitcoin-collateralized lending',
        url: 'https://lendasat.com',
        icons: ['https://lendasat.com/logo.png'],
      ),
    );

    // Connect to wallet (opens MetaMask/etc)
    final session = await _web3App!.connect(
      requiredNamespaces: {
        'eip155': RequiredNamespace(
          chains: ['eip155:137'], // Polygon
          methods: ['eth_sendTransaction', 'personal_sign'],
          events: ['accountsChanged'],
        ),
      },
    );

    _connectedAddress = session.namespaces['eip155']?.accounts.first;
  }

  Future<String> sendTransaction({
    required String to,
    required String data,
    required BigInt value,
  }) async {
    // Request transaction signing via WalletConnect
    final txHash = await _web3App!.request(
      topic: _session!.topic,
      chainId: 'eip155:137',
      request: SessionRequestParams(
        method: 'eth_sendTransaction',
        params: [{
          'from': _connectedAddress,
          'to': to,
          'data': data,
          'value': '0x${value.toRadixString(16)}',
        }],
      ),
    );
    return txHash;
  }
}
```

#### Step 3: Update Swap Flow

```dart
// In swap_screen.dart or new evm_funding_screen.dart
Future<void> _fundEvmSwap(EvmToBtcSwapResult swap) async {
  final walletService = WalletConnectService();

  // 1. Connect wallet if not connected
  if (!walletService.isConnected) {
    await walletService.connect();
  }

  // 2. Approve ERC20 (if needed)
  await walletService.sendTransaction(
    to: swap.sourceTokenAddress,
    data: _buildApproveCalldata(swap.evmHtlcAddress, amount),
    value: BigInt.zero,
  );

  // 3. Call createSwap on HTLC
  await walletService.sendTransaction(
    to: swap.evmHtlcAddress,
    data: swap.createSwapTx, // Need to add this field!
    value: BigInt.zero,
  );

  // 4. Done! Server will detect the event
}
```

#### Step 4: Add `create_swap_tx` to API

```rust
// rust/src/api/lendaswap_api.rs
pub struct EvmToBtcSwapResult {
    // ... existing fields ...

    /// Pre-built calldata for createSwap() contract call
    pub create_swap_tx: Option<String>,  // ADD THIS
}
```

### Gasless Option with Gelato

Once WalletConnect is integrated, we can add gasless support:

1. Instead of `eth_sendTransaction`, use `eth_signTypedData_v4`
2. User signs EIP-712 message (no gas)
3. App submits signature to Gelato Relay
4. Gelato executes transaction and pays gas

The contracts already support this via `ERC2771Forwarder`.

### Flutter Packages to Use

| Package | Purpose |
|---------|---------|
| `walletconnect_flutter_v2` | WalletConnect protocol |
| `web3dart` | Ethereum transaction building |
| `eth_sig_util` | EIP-712 signing (for Gelato) |

### UI Flow

```
┌─────────────────────────────────────┐
│         EVM → BTC Swap              │
├─────────────────────────────────────┤
│  Amount: 50 USDC                    │
│  You receive: ~0.0005 BTC           │
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐    │
│  │  🦊 Connect MetaMask        │    │  ← WalletConnect
│  └─────────────────────────────┘    │
│                                     │
│  Connected: 0x1234...5678           │
│                                     │
│  ┌─────────────────────────────┐    │
│  │  ✓ Approve & Fund Swap      │    │  ← Sends 2 TXs
│  └─────────────────────────────┘    │
└─────────────────────────────────────┘
```

## Summary

**The Problem:** App can't call `createSwap()` because user's tokens are in external wallet (MetaMask).

**The Solution:** Integrate WalletConnect to connect to user's wallet and request transaction signatures.

**Bonus:** Once WalletConnect works, gasless via Gelato is easy to add.

## Related Files

- `rust/src/api/lendaswap_api.rs` - API types (needs `create_swap_tx`)
- `lib/src/services/lendaswap_service.dart` - Dart service layer
- `lib/src/ui/screens/swap_processing_screen.dart` - Swap UI
- `lib/src/ui/widgets/swap/evm_address_input_sheet.dart` - EVM address input

## References

- LendaSwap SDK: `~/.cargo/git/checkouts/lendaswap-*/*/client-sdk/core/src/api/types.rs`
- Website deposit step: `frontend/apps/lendaswap/src/app/wizard/steps/PolygonDepositStep.tsx`
- Server event handler: `swap/src/evm/evm_to_bitcoin_fund_events.rs`
