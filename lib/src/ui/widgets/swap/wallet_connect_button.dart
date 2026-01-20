import 'package:flutter/material.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:reown_appkit/reown_appkit.dart';

/// Button for connecting/disconnecting EVM wallets via Reown AppKit
/// Creates ReownAppKitModal in didChangeDependencies to ensure valid context
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
  ReownAppKitModal? _appKit;
  bool _isInitializing = false;
  bool _wasConnected = false;
  bool _didInit = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize here where context is guaranteed to be valid
    if (!_didInit) {
      _didInit = true;
      _initializeAppKit();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _appKit?.removeListener(_onAppKitChanged);
    // Don't dispose - the service manages the lifecycle
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      logger.i('App resumed - checking wallet connection');
      if (_appKit?.isConnected == true && !_wasConnected) {
        _wasConnected = true;
        widget.onConnected?.call();
        if (mounted) setState(() {});
      }
    }
  }

  void _onAppKitChanged() {
    if (!mounted) return;
    logger.i('AppKit changed - connected: ${_appKit?.isConnected}');
    setState(() {});

    final isConnected = _appKit?.isConnected ?? false;
    if (isConnected && !_wasConnected) {
      _wasConnected = true;
      widget.onConnected?.call();
    } else if (!isConnected && _wasConnected) {
      _wasConnected = false;
      widget.onDisconnected?.call();
    }
    // Service is automatically notified via its listener on the modal
  }

  Future<void> _initializeAppKit() async {
    if (_appKit != null) return;

    setState(() => _isInitializing = true);

    try {
      logger.i('Creating ReownAppKitModal with widget context...');

      _appKit = ReownAppKitModal(
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

      await _appKit!.init();
      _appKit!.addListener(_onAppKitChanged);
      _wasConnected = _appKit!.isConnected;

      // Sync to global service so other screens can access connection state
      // Pass context to enable auto-close functionality when wallet connects
      WalletConnectService().setAppKitModal(_appKit, context: context);

      logger.i('AppKit initialized in widget, connected: $_wasConnected');
    } catch (e) {
      logger.e('Failed to initialize AppKit: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _openModal() async {
    if (_appKit == null) {
      logger.w('AppKit not ready, initializing...');
      await _initializeAppKit();
    }

    if (_appKit == null) {
      logger.e('AppKit still null after init');
      return;
    }

    try {
      logger.i('Opening modal with MainWalletsPage...');
      await _appKit!.openModalView(ReownAppKitModalMainWalletsPage());
      logger.i('Modal should be visible now');
    } catch (e) {
      logger.e('Error opening modal: $e');
    }
  }

  Future<void> _disconnect() async {
    try {
      await _appKit?.disconnect();
      logger.i('Disconnected');
    } catch (e) {
      logger.e('Disconnect error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = _appKit?.isConnected ?? false;

    if (_isInitializing) {
      return const LongButtonWidget(
        buttonType: ButtonType.secondary,
        title: 'Initializing...',
        customWidth: double.infinity,
        onTap: null,
      );
    }

    if (isConnected) {
      final address = _appKit?.session?.getAddress('eip155') ??
          _appKit?.session?.getAddress('solana');
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

    // Not connected - show connect button
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
