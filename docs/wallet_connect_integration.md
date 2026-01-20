# WalletConnect Integration

This document describes how WalletConnect (via Reown AppKit) is integrated into LendaMobile for connecting EVM wallets like MetaMask, Trust Wallet, etc.

## Overview

The integration uses the `reown_appkit` Flutter package (formerly WalletConnect) to enable users to connect their EVM wallets for:

- EVM → BTC swaps (depositing USDC/USDT from Polygon/Ethereum)
- BTC → EVM swaps (claiming tokens on Ethereum)
- Future loan collateral management

## Architecture

### Key Components

```
┌─────────────────────────────────────────────────────────────────┐
│                        WalletConnectButton                       │
│  (StatefulWidget - creates and manages ReownAppKitModal)         │
│                                                                  │
│  - Creates modal in didChangeDependencies() for valid context    │
│  - Syncs modal to global WalletConnectService                    │
│  - Handles connect/disconnect UI                                 │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ setAppKitModal()
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                      WalletConnectService                        │
│  (Singleton ChangeNotifier)                                      │
│                                                                  │
│  - Holds reference to ReownAppKitModal                          │
│  - Provides isConnected, connectedAddress, etc.                 │
│  - Used by other screens to check connection state              │
│  - Handles deep links for wallet redirects                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              │ Listeners
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              Other Screens (evm_swap_funding_screen, etc.)       │
│                                                                  │
│  - Check _walletService.isConnected                             │
│  - Use WalletConnectButton widget for connect UI                │
│  - Call _walletService.sendTransaction() for transactions       │
└─────────────────────────────────────────────────────────────────┘
```

### Why This Architecture?

The `reown_appkit` library's `ReownAppKitModal` requires a valid `BuildContext` with an active `Navigator` to display its modal bottom sheet. Previous approaches failed because:

1. **Singleton with stored context**: The context stored during initial initialization became stale after widget rebuilds or navigation, causing `openModalView()` to silently fail.

2. **Service-only initialization**: Creating the modal in a service without widget tree presence meant no valid Navigator context.

**Solution**: Create the `ReownAppKitModal` inside the `WalletConnectButton` widget's `didChangeDependencies()` lifecycle method, where the context is guaranteed to be fully initialized with a valid Navigator. Then sync this instance to the global service so other screens can access connection state.

## Implementation Details

### WalletConnectButton Widget

Location: `lib/src/ui/widgets/swap/wallet_connect_button.dart`

```dart
class _WalletConnectButtonState extends State<WalletConnectButton> {
  ReownAppKitModal? _appKit;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize here where context is guaranteed to be valid
    if (!_didInit) {
      _didInit = true;
      _initializeAppKit();
    }
  }

  Future<void> _initializeAppKit() async {
    _appKit = ReownAppKitModal(
      context: context,  // Valid context with Navigator
      projectId: WalletConnectService.projectId,
      metadata: const PairingMetadata(...),
    );

    await _appKit!.init();

    // Sync to global service
    WalletConnectService().setAppKitModal(_appKit);
  }

  Future<void> _openModal() async {
    await _appKit!.openModalView(ReownAppKitModalMainWalletsPage());
  }
}
```

### WalletConnectService

Location: `lib/src/services/wallet_connect_service.dart`

```dart
class WalletConnectService extends ChangeNotifier {
  static final WalletConnectService _instance = WalletConnectService._internal();
  factory WalletConnectService() => _instance;

  ReownAppKitModal? _appKitModal;

  // Called by WalletConnectButton after initialization
  void setAppKitModal(ReownAppKitModal? modal) {
    _appKitModal = modal;
    modal?.addListener(_onModalStateChanged);
    notifyListeners();
  }

  bool get isConnected => _appKitModal?.isConnected ?? false;
  String? get connectedAddress => _appKitModal?.session?.getAddress('eip155');
}
```

### Using in Screens

**Preferred: Use WalletConnectButton widget**

```dart
class _EvmSwapFundingScreenState extends State<EvmSwapFundingScreen> {
  final WalletConnectService _walletService = WalletConnectService();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Use the button widget for connect UI
        WalletConnectButton(
          chain: EvmChain.polygon,
          onConnected: () => setState(() {}),
        ),

        // Check connection state from service
        if (_walletService.isConnected)
          Text('Connected: ${_walletService.shortAddress}'),
      ],
    );
  }
}
```

**Alternative: Direct service call with custom UI**

If you need custom connect button styling (e.g., in a bottom sheet), you can call `openModal()` directly. **IMPORTANT**: Always pass the current `context` to ensure the modal uses a valid Navigator:

```dart
Future<void> _connectWallet() async {
  // If disconnecting first, add a small delay for cleanup
  if (_walletService.isConnected) {
    await _walletService.disconnect();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  // ALWAYS pass context - this ensures the modal reinitializes
  // with the current Navigator context
  await _walletService.openModal(context: context);
}
```

The service will automatically reinitialize the modal when the context changes, which handles cases where the modal was previously created by a `WalletConnectButton` in a different screen.

## Configuration

### Project ID

The WalletConnect Project ID is stored in `WalletConnectService`:

```dart
static const String projectId = 'a15c535db177c184c98bdbdc5ff12590';
```

This is the same project ID used by the LendaSwap web frontend for consistency.

### Deep Links (Android)

Deep links are configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<!-- Deep link for WalletConnect redirect -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="lendamobile"/>
</intent-filter>

<!-- WalletConnect specific deep link with path -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="lendamobile" android:host="wc"/>
</intent-filter>

<!-- Standard WalletConnect wc:// scheme -->
<intent-filter>
    <action android:name="android.intent.action.VIEW"/>
    <category android:name="android.intent.category.DEFAULT"/>
    <category android:name="android.intent.category.BROWSABLE"/>
    <data android:scheme="wc"/>
</intent-filter>
```

### Metadata Configuration

```dart
metadata: const PairingMetadata(
  name: 'LendaMobile',
  description: 'Bitcoin-collateralized lending & swaps',
  url: 'https://lendasat.com',
  icons: ['https://lendasat.com/logo.png'],
  redirect: Redirect(
    native: 'lendamobile://wc',
    universal: 'https://lendasat.com/wc',
    linkMode: false,  // Simple deep links, no domain verification needed
  ),
),
```

## Supported Chains

Defined in `EvmChain` enum:

```dart
enum EvmChain {
  polygon(chainId: 'eip155:137', name: 'Polygon', namespace: 'eip155'),
  ethereum(chainId: 'eip155:1', name: 'Ethereum', namespace: 'eip155');
}
```

## Transaction Methods

### Send Transaction

```dart
Future<String> sendTransaction({
  required String to,
  required String data,
  String? value,
}) async {
  final result = await _appKitModal!.request(
    topic: session.topic ?? '',
    chainId: selectedChain.chainId,
    request: SessionRequestParams(
      method: 'eth_sendTransaction',
      params: [{
        'from': connectedAddress,
        'to': to,
        'data': data,
        if (value != null) 'value': value,
      }],
    ),
  );
  return result as String;  // Transaction hash
}
```

### ERC20 Token Approval

```dart
Future<String> approveToken({
  required String tokenAddress,
  required String spenderAddress,
  BigInt? amount,  // null = max uint256
}) async {
  final calldata = buildApproveCalldata(spenderAddress, amount);
  return sendTransaction(to: tokenAddress, data: calldata);
}
```

### Sign Typed Data (EIP-712)

```dart
Future<String> signTypedData({required String typedData}) async {
  final result = await _appKitModal!.request(
    topic: session.topic ?? '',
    chainId: selectedChain.chainId,
    request: SessionRequestParams(
      method: 'eth_signTypedData_v4',
      params: [connectedAddress, typedData],
    ),
  );
  return result as String;  // Signature
}
```

## Troubleshooting

### Modal Not Showing

If `openModalView()` returns successfully but the modal doesn't appear:

1. **Check context validity**: Ensure the modal is created in `didChangeDependencies()` or after the widget is fully mounted
2. **Check Navigator**: The context must have a valid Navigator ancestor
3. **Pass explicit page**: Use `openModalView(ReownAppKitModalMainWalletsPage())` instead of `openModalView()`

### Connection State Not Updating

1. **Check service sync**: Ensure `WalletConnectService().setAppKitModal(_appKit)` is called after modal init
2. **Check listeners**: The service should add a listener to the modal for state changes
3. **Check UI rebuild**: Screens need to call `setState()` or use `ListenableBuilder` to react to service changes

### Deep Link Redirect Issues

1. **Verify AndroidManifest.xml**: Ensure all intent-filters are correctly configured
2. **Check linkMode**: Set `linkMode: false` for simple deep links without domain verification
3. **Test with adb**: `adb shell am start -W -a android.intent.action.VIEW -d "lendamobile://wc"`

## Files Reference

| File                                                   | Purpose                                                        |
| ------------------------------------------------------ | -------------------------------------------------------------- |
| `lib/src/services/wallet_connect_service.dart`         | Global singleton service for connection state and transactions |
| `lib/src/ui/widgets/swap/wallet_connect_button.dart`   | Button widget that creates and manages ReownAppKitModal        |
| `lib/src/ui/screens/swap/evm_swap_funding_screen.dart` | EVM → BTC swap funding flow                                    |
| `lib/src/ui/screens/swap/swap_processing_screen.dart`  | Swap status and claiming flow                                  |
| `android/app/src/main/AndroidManifest.xml`             | Deep link configuration                                        |

## Version History

- **Initial Implementation**: Used singleton service with stored context - caused modal display issues after disconnect
- **Local Instance Approach**: Each widget created its own modal - caused connection state sync issues
- **Current Approach**: Widget creates modal and syncs to global service - reliable modal display with shared state
