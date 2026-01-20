import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';

/// Button for connecting/disconnecting EVM wallets via Reown AppKit
/// Creates its own ReownAppKitModal instance for reliable modal display
class WalletConnectButton extends StatefulWidget {
  final EvmChain chain;
  final VoidCallback? onConnected;
  final VoidCallback? onDisconnected;

  const WalletConnectButton({
    super.key,
    this.chain = EvmChain.polygon,
    this.onConnected,
    this.onDisconnected,
  });

  @override
  State<WalletConnectButton> createState() => _WalletConnectButtonState();
}

class _WalletConnectButtonState extends State<WalletConnectButton>
    with WidgetsBindingObserver {
  // Use the singleton service for state tracking
  final WalletConnectService _walletService = WalletConnectService();

  // But create our own modal instance for this widget
  ReownAppKitModal? _localAppKit;
  bool _isInitializing = false;
  bool _wasConnected = false;

  // Deep link handling
  AppLinks? _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _walletService.addListener(_onWalletStateChanged);
    _initializeLocalAppKit();
    _setupDeepLinkListener();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _walletService.removeListener(_onWalletStateChanged);
    _localAppKit?.removeListener(_onLocalAppKitChanged);
    _localAppKit?.dispose();
    super.dispose();
  }

  /// Set up deep link listener to handle wallet redirects
  void _setupDeepLinkListener() {
    if (kIsWeb) return;

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
    logger.i('WalletConnectButton received deep link: $uri');

    if (_localAppKit == null) {
      logger.w('AppKit not initialized, cannot handle deep link');
      return;
    }

    try {
      final handled = await _localAppKit!.dispatchEnvelope(uri.toString());
      logger.i('Deep link handled: $handled');

      if (handled) {
        // Force state update
        if (mounted) setState(() {});
      }
    } catch (e) {
      logger.e('Error handling deep link: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logger.i('App resumed - checking wallet connection state');
      // Check local AppKit state
      final isConnected = _localAppKit?.isConnected ?? false;
      logger.i(
          'Local AppKit connected: $isConnected, wasConnected: $_wasConnected');

      if (isConnected && !_wasConnected) {
        _wasConnected = true;
        widget.onConnected?.call();
        if (mounted) setState(() {});
      }
    }
  }

  void _onWalletStateChanged() {
    if (!mounted) return;
    setState(() {});

    if (_walletService.isConnected && !_wasConnected) {
      _wasConnected = true;
      widget.onConnected?.call();
    } else if (!_walletService.isConnected && _wasConnected) {
      _wasConnected = false;
      widget.onDisconnected?.call();
    }
  }

  void _onLocalAppKitChanged() {
    if (!mounted) return;
    logger.i(
        'Local AppKit state changed - connected: ${_localAppKit?.isConnected}');
    setState(() {});

    // Sync local state to global service
    if (_localAppKit?.isConnected == true && !_wasConnected) {
      _wasConnected = true;
      widget.onConnected?.call();
    } else if (_localAppKit?.isConnected != true && _wasConnected) {
      _wasConnected = false;
      widget.onDisconnected?.call();
    }
  }

  Future<void> _initializeLocalAppKit() async {
    setState(() => _isInitializing = true);

    try {
      logger.i('Creating local ReownAppKitModal instance...');

      _localAppKit = ReownAppKitModal(
        context: context,
        projectId: WalletConnectService.projectId,
        metadata: const PairingMetadata(
          name: 'LendaMobile',
          description: 'Bitcoin-collateralized lending & swaps',
          url: 'https://lendasat.com',
          icons: ['https://lendasat.com/logo.png'],
          redirect: Redirect(
            native: 'lendamobile://wc',
            universal: 'https://lendasat.com/wc',
            linkMode: false,
          ),
        ),
      );

      await _localAppKit!.init();
      _localAppKit!.addListener(_onLocalAppKitChanged);

      _wasConnected = _localAppKit!.isConnected;
      logger.i('Local AppKit initialized, connected: $_wasConnected');
    } catch (e) {
      logger.e('Failed to initialize local AppKit: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _openModal() async {
    if (_localAppKit == null) {
      logger.w('AppKit not initialized, initializing now...');
      await _initializeLocalAppKit();
    }

    if (_localAppKit == null) {
      logger.e('Failed to initialize AppKit');
      return;
    }

    try {
      logger.i('Opening modal view...');
      await _localAppKit!.openModalView();
      logger.i('Modal view opened');
    } catch (e) {
      logger.e('Failed to open modal: $e');

      // If modal fails, try reinitializing
      logger.i('Reinitializing AppKit after error...');
      _localAppKit?.removeListener(_onLocalAppKitChanged);
      _localAppKit?.dispose();
      _localAppKit = null;

      await _initializeLocalAppKit();

      // Try again
      if (_localAppKit != null) {
        try {
          await _localAppKit!.openModalView();
        } catch (e2) {
          logger.e('Failed to open modal after reinit: $e2');
        }
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await _localAppKit?.disconnect();
      logger.i('Wallet disconnected');

      // Reinitialize after disconnect to ensure clean state
      _localAppKit?.removeListener(_onLocalAppKitChanged);
      _localAppKit?.dispose();
      _localAppKit = null;

      await _initializeLocalAppKit();
    } catch (e) {
      logger.e('Failed to disconnect: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = _localAppKit?.isConnected ?? false;

    if (_isInitializing) {
      return const LongButtonWidget(
        buttonType: ButtonType.secondary,
        title: 'Initializing...',
        customWidth: double.infinity,
        onTap: null,
      );
    }

    if (isConnected) {
      final address = _localAppKit?.session?.getAddress('eip155') ??
          _localAppKit?.session?.getAddress('solana');
      final shortAddress = address != null && address.length > 12
          ? '${address.substring(0, 6)}...${address.substring(address.length - 4)}'
          : address;

      return Container(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.green.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.green,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Connected',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    shortAddress ?? '',
                    style: TextStyle(
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                      fontSize: 12,
                      fontFamily: 'monospace',
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _disconnect,
              icon: Icon(
                Icons.logout,
                color: isDark ? AppTheme.white60 : AppTheme.black60,
              ),
            ),
          ],
        ),
      );
    }

    // Disconnected state - show connect button with onTap
    return LongButtonWidget(
      buttonType: ButtonType.solid,
      title: 'Connect ${widget.chain.name} Wallet',
      leadingIcon: const Icon(
        Icons.account_balance_wallet_outlined,
        color: Color(0xFF1A0A00),
      ),
      customWidth: double.infinity,
      onTap: _openModal,
    );
  }
}

/// Compact wallet status indicator
class WalletStatusIndicator extends StatelessWidget {
  const WalletStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final walletService = WalletConnectService();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: walletService,
      builder: (context, _) {
        if (!walletService.isConnected) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                walletService.shortAddress ?? '',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white : Colors.black,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
