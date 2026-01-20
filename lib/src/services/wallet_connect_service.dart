import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:reown_appkit/reown_appkit.dart';
import 'package:app_links/app_links.dart';
import 'package:ark_flutter/src/logger/logger.dart';

/// Supported EVM chains for WalletConnect
enum EvmChain {
  polygon(chainId: 'eip155:137', name: 'Polygon', namespace: 'eip155'),
  ethereum(chainId: 'eip155:1', name: 'Ethereum', namespace: 'eip155');

  final String chainId;
  final String name;
  final String namespace;

  const EvmChain({
    required this.chainId,
    required this.name,
    required this.namespace,
  });

  /// Get the ReownAppKitModalNetworkInfo for this chain
  ReownAppKitModalNetworkInfo? get networkInfo {
    final networks = ReownAppKitModalNetworks.getAllSupportedNetworks(
      namespace: namespace,
    );
    return networks.cast<ReownAppKitModalNetworkInfo?>().firstWhere(
          (n) => n?.chainId == chainId,
          orElse: () => null,
        );
  }
}

/// Service for managing WalletConnect connections to EVM wallets
/// Uses Reown AppKit for the modal UI (same as lendaswap web frontend)
class WalletConnectService extends ChangeNotifier {
  static final WalletConnectService _instance =
      WalletConnectService._internal();
  factory WalletConnectService() => _instance;
  WalletConnectService._internal();

  // WalletConnect Project ID - same as lendaswap web frontend
  static const String projectId = 'a15c535db177c184c98bdbdc5ff12590';

  ReownAppKitModal? _appKitModal;
  bool _isInitialized = false;
  bool _needsReinitAfterDisconnect = false; // Track if modal needs reinit
  BuildContext? _context;
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  /// Whether AppKit is initialized
  bool get isInitialized => _isInitialized;

  /// Whether a wallet is connected
  bool get isConnected => _appKitModal?.isConnected ?? false;

  /// Connected wallet address (prefers EVM, then Solana)
  String? get connectedAddress {
    final eip155 = _appKitModal?.session?.getAddress('eip155');
    if (eip155 != null) return eip155;
    return _appKitModal?.session?.getAddress('solana');
  }

  /// Whether the current address is an EVM address
  bool get isEvmAddress => _appKitModal?.session?.getAddress('eip155') != null;

  /// Whether the current address is a Solana address
  bool get isSolanaAddress =>
      _appKitModal?.session?.getAddress('solana') != null;

  /// Connected chain ID (null if not connected)
  String? get connectedChainId => _appKitModal?.selectedChain?.chainId;

  /// Get the connected EvmChain enum
  EvmChain? get connectedChain {
    final chainId = connectedChainId;
    if (chainId == null) return null;
    return EvmChain.values.cast<EvmChain?>().firstWhere(
          (c) => c?.chainId == chainId,
          orElse: () => null,
        );
  }

  /// Shortened address for display (e.g., "0x1234...5678")
  String? get shortAddress {
    final addr = connectedAddress;
    if (addr == null) return null;
    if (addr.length < 12) return addr;
    return '${addr.substring(0, 6)}...${addr.substring(addr.length - 4)}';
  }

  /// The AppKit modal instance (for direct access to widgets)
  ReownAppKitModal? get appKitModal => _appKitModal;

  /// Initialize the AppKit modal
  /// Must be called with a BuildContext before using the service
  Future<void> initialize(BuildContext context, {bool force = false}) async {
    if (_isInitialized && _context != null && !force) return;

    _context = context;

    try {
      logger.i('Initializing Reown AppKit...');

      // Re-enable Solana networks if they were previously removed elsewhere
      // This allows multi-chain wallets like Phantom to show up and connect
      // We will handle the address validation ourselves.
      // ReownAppKitModalNetworks.removeSupportedNetworks('solana');
      logger.i('Solana networks enabled for multi-chain wallet support');

      _appKitModal = ReownAppKitModal(
        context: context,
        projectId: projectId,
        metadata: const PairingMetadata(
          name: 'LendaMobile',
          description: 'Bitcoin-collateralized lending & swaps',
          url: 'https://lendasat.com',
          icons: ['https://lendasat.com/logo.png'],
          redirect: Redirect(
            native: 'lendamobile://wc',
            universal: 'https://lendasat.com/wc',
            // linkMode: false for simple deep links (no domain verification needed)
            linkMode: false,
          ),
        ),
      );

      await _appKitModal!.init();

      // Listen for connection changes
      _appKitModal!.addListener(_onModalStateChanged);

      // Set up deep link handling for wallet redirects
      if (!kIsWeb) {
        _setupDeepLinkListener();
      }

      _isInitialized = true;
      _wasConnectedBeforeStateChange = isConnected;
      logger.i('Reown AppKit initialized successfully');
      notifyListeners();
    } catch (e) {
      logger.e('Failed to initialize Reown AppKit: $e');
      rethrow;
    }
  }

  bool _wasConnectedBeforeStateChange = false;

  void _onModalStateChanged() {
    logger.i('=== AppKit State Changed ===');
    logger.i('isConnected: $isConnected');
    logger.i('connectedAddress: $connectedAddress');
    logger.i('connectedChainId: $connectedChainId');
    logger.i('session: ${_appKitModal?.session}');
    logger.i('session service: ${_appKitModal?.session?.sessionService}');
    logger.i('============================');

    // If we just connected (state changed from disconnected to connected),
    // try to close the modal since the library's internal closeModal may fail
    // due to stale context
    if (isConnected && !_wasConnectedBeforeStateChange && _context != null) {
      _tryCloseModalSafely();
    }

    // If we just disconnected, mark that modal needs reinit before next use
    if (!isConnected && _wasConnectedBeforeStateChange) {
      _needsReinitAfterDisconnect = true;
    }

    _wasConnectedBeforeStateChange = isConnected;

    notifyListeners();
  }

  /// Try to close the modal safely using the root navigator
  /// This handles the case where the library's internal closeModal fails
  void _tryCloseModalSafely() {
    // Use post-frame callback to ensure we're not in the middle of a build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_context == null) return;

      try {
        // Check if context is still mounted
        if (_context is Element && !(_context as Element).mounted) {
          logger.w('Context no longer mounted, cannot close modal');
          return;
        }

        // Try to pop using the root navigator to close the bottom sheet modal
        final navigator = Navigator.maybeOf(_context!, rootNavigator: true);
        if (navigator != null && navigator.canPop()) {
          logger.i('Manually closing wallet connect modal after connection');
          navigator.pop();
        }
      } catch (e) {
        // Silently ignore - the modal may already be closed or context is invalid
        logger.w('Could not manually close modal: $e');
      }
    });
  }

  /// Set up deep link listener to handle wallet redirects
  void _setupDeepLinkListener() {
    _appLinks = AppLinks();

    // Handle links that opened the app
    _appLinks!.getInitialLink().then((uri) {
      if (uri != null) {
        _handleDeepLink(uri);
      }
    });

    // Handle links while app is running
    _linkSubscription = _appLinks!.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  /// Handle incoming deep links from wallets
  Future<void> _handleDeepLink(Uri uri) async {
    logger.i('Received deep link: $uri');
    logger.i('Deep link scheme: ${uri.scheme}');
    logger.i('Deep link host: ${uri.host}');
    logger.i('Deep link path: ${uri.path}');
    logger.i('Deep link query: ${uri.query}');
    logger.i('Full URI string: ${uri.toString()}');

    if (_appKitModal == null) {
      logger.w('AppKit not initialized, cannot handle deep link');
      return;
    }

    try {
      // Pass the link to AppKit for processing (handles Phantom, etc.)
      final handled = await _appKitModal!.dispatchEnvelope(uri.toString());
      logger.i('dispatchEnvelope returned: $handled');

      if (handled) {
        logger.i('Deep link handled by AppKit');
        // Force state update
        notifyListeners();
      } else {
        logger.w('Deep link NOT handled by AppKit');

        // Try alternative formats if standard didn't work
        // Some wallets send the data in the query string
        if (uri.queryParameters.isNotEmpty) {
          for (final entry in uri.queryParameters.entries) {
            logger.i('Trying query param: ${entry.key}');
            final altHandled =
                await _appKitModal!.dispatchEnvelope(entry.value);
            if (altHandled) {
              logger.i('Handled via query param: ${entry.key}');
              notifyListeners();
              break;
            }
          }
        }
      }

      // Log current state after handling
      logger.i(
          'After deep link - isConnected: $isConnected, address: $connectedAddress');
    } catch (e) {
      logger.e('Error handling deep link: $e');
    }
  }

  /// Open the wallet connection modal
  /// This shows the same UI as lendaswap website (all wallets, social login, etc.)
  Future<void> openModal({int retryCount = 0}) async {
    if (_appKitModal == null) {
      throw Exception(
          'AppKit not initialized. Call initialize(context) first.');
    }

    // Proactively reinit if needed (after disconnect, the modal state is corrupted)
    if (_needsReinitAfterDisconnect && _context != null) {
      logger.i('Reinitializing modal after disconnect...');
      await _reinitializeModal();
    }

    logger.i('Opening wallet connect modal (attempt ${retryCount + 1})...');

    try {
      await _appKitModal!.openModalView();
      logger.i('Modal opened successfully');
    } catch (e) {
      final errorStr = e.toString();
      logger.e('Modal open error: $errorStr');

      // Handle "Bad state: No element" bug in reown_appkit after disconnect
      // The modal's internal widget stack is empty after disconnect
      final needsReinit = errorStr.contains('No element') ||
          errorStr.contains('Bad state') ||
          errorStr.contains('disposed');

      if (needsReinit && _context != null && retryCount < 2) {
        logger.w('Modal needs reinit, attempting recovery...');
        await _reinitializeModal();

        // Try opening again after reinit
        await openModal(retryCount: retryCount + 1);
      } else {
        rethrow;
      }
    }
  }

  /// Reinitialize the modal (used after disconnect or on error)
  Future<void> _reinitializeModal() async {
    _isInitialized = false;
    _needsReinitAfterDisconnect = false;
    _appKitModal?.removeListener(_onModalStateChanged);
    try {
      _appKitModal?.dispose();
    } catch (_) {}
    _appKitModal = null;

    // Small delay to let cleanup finish
    await Future.delayed(const Duration(milliseconds: 300));

    if (_context != null) {
      await initialize(_context!, force: true);
    }
  }

  /// Open modal with network selection first
  Future<void> openNetworkModal() async {
    if (_appKitModal == null) {
      throw Exception(
          'AppKit not initialized. Call initialize(context) first.');
    }

    try {
      await _appKitModal!.openModalView(
        ReownAppKitModalSelectNetworkPage(),
      );
    } catch (e) {
      logger.e('Failed to open network modal: $e');
      rethrow;
    }
  }

  /// Switch to a specific chain
  Future<void> switchChain(EvmChain chain) async {
    if (_appKitModal == null || !isConnected) {
      throw Exception('Wallet not connected');
    }

    final networkInfo = chain.networkInfo;
    if (networkInfo == null) {
      throw Exception('Network not supported: ${chain.name}');
    }

    try {
      await _appKitModal!.selectChain(networkInfo);
      logger.i('Switched to ${chain.name}');
    } catch (e) {
      logger.e('Failed to switch chain: $e');
      rethrow;
    }
  }

  /// Ensure we're on the correct chain for a swap, switch if needed
  Future<void> ensureCorrectChain(EvmChain requiredChain) async {
    if (!isConnected) return;

    final currentChainId = connectedChainId;
    if (currentChainId != requiredChain.chainId) {
      logger.i(
          'Current chain: $currentChainId, required: ${requiredChain.chainId}');
      await switchChain(requiredChain);
    }
  }

  /// Disconnect the current session
  Future<void> disconnect() async {
    if (_appKitModal == null) return;

    try {
      await _appKitModal!.disconnect();
      logger.i('Wallet disconnected');
    } catch (e) {
      logger.e('Error disconnecting: $e');
    }

    // Mark that we need to reinit the modal before next use
    // The reown_appkit library has a bug where the internal widget stack
    // becomes corrupted after disconnect
    _needsReinitAfterDisconnect = true;

    notifyListeners();
  }

  /// Send a transaction via the connected wallet
  /// Returns the transaction hash
  Future<String> sendTransaction({
    required String to,
    required String data,
    String? value,
  }) async {
    if (!isConnected || _appKitModal == null) {
      throw Exception('Wallet not connected');
    }

    final session = _appKitModal!.session;
    final selectedChain = _appKitModal!.selectedChain;

    if (session == null || selectedChain == null) {
      throw Exception('No active session');
    }

    try {
      logger.i('Sending transaction to $to on ${selectedChain.chainId}...');

      final result = await _appKitModal!.request(
        topic: session.topic ?? '',
        chainId: selectedChain.chainId,
        request: SessionRequestParams(
          method: 'eth_sendTransaction',
          params: [
            {
              'from': connectedAddress,
              'to': to,
              'data': data,
              if (value != null) 'value': value,
            },
          ],
        ),
      );

      final txHash = result as String;
      logger.i('Transaction sent: $txHash');
      return txHash;
    } catch (e) {
      logger.e('Failed to send transaction: $e');
      rethrow;
    }
  }

  /// Sign typed data (EIP-712)
  Future<String> signTypedData({
    required String typedData,
  }) async {
    if (!isConnected || _appKitModal == null) {
      throw Exception('Wallet not connected');
    }

    final session = _appKitModal!.session;
    final selectedChain = _appKitModal!.selectedChain;

    if (session == null || selectedChain == null) {
      throw Exception('No active session');
    }

    try {
      logger.i('Signing typed data on ${selectedChain.chainId}...');

      final result = await _appKitModal!.request(
        topic: session.topic ?? '',
        chainId: selectedChain.chainId,
        request: SessionRequestParams(
          method: 'eth_signTypedData_v4',
          params: [connectedAddress, typedData],
        ),
      );

      final signature = result as String;
      logger.i('Typed data signed');
      return signature;
    } catch (e) {
      logger.e('Failed to sign typed data: $e');
      rethrow;
    }
  }

  /// Build ERC20 approve calldata
  String buildApproveCalldata(String spender, BigInt amount) {
    // approve(address spender, uint256 amount)
    // Function selector: 0x095ea7b3
    final spenderPadded =
        spender.toLowerCase().replaceFirst('0x', '').padLeft(64, '0');
    final amountHex = amount.toRadixString(16).padLeft(64, '0');
    return '0x095ea7b3$spenderPadded$amountHex';
  }

  /// Approve ERC20 token spending
  Future<String> approveToken({
    required String tokenAddress,
    required String spenderAddress,
    BigInt? amount,
  }) async {
    // Use max uint256 if no amount specified
    final approveAmount = amount ??
        BigInt.parse(
          'ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff',
          radix: 16,
        );

    final calldata = buildApproveCalldata(spenderAddress, approveAmount);

    return sendTransaction(
      to: tokenAddress,
      data: calldata,
    );
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _appKitModal?.removeListener(_onModalStateChanged);
    _appKitModal?.dispose();
    super.dispose();
  }
}
