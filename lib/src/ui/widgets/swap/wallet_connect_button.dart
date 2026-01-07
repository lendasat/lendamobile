import 'package:flutter/material.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/logger/logger.dart';

/// Button for connecting/disconnecting EVM wallets via Reown AppKit
/// Shows the same wallet selection modal as the lendaswap website
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

class _WalletConnectButtonState extends State<WalletConnectButton> {
  final WalletConnectService _walletService = WalletConnectService();
  bool _isInitializing = false;
  bool _wasConnected = false;

  @override
  void initState() {
    super.initState();
    _walletService.addListener(_onWalletStateChanged);
    _initializeAppKit();
  }

  @override
  void dispose() {
    _walletService.removeListener(_onWalletStateChanged);
    super.dispose();
  }

  void _onWalletStateChanged() {
    if (!mounted) return;

    setState(() {});

    // Detect connection state changes
    if (_walletService.isConnected && !_wasConnected) {
      _wasConnected = true;
      widget.onConnected?.call();
    } else if (!_walletService.isConnected && _wasConnected) {
      _wasConnected = false;
      widget.onDisconnected?.call();
    }
  }

  Future<void> _initializeAppKit() async {
    if (_walletService.isInitialized) return;

    setState(() => _isInitializing = true);

    try {
      await _walletService.initialize(context);
      _wasConnected = _walletService.isConnected;
    } catch (e) {
      logger.e('Failed to initialize AppKit: $e');
    } finally {
      if (mounted) {
        setState(() => _isInitializing = false);
      }
    }
  }

  Future<void> _openModal() async {
    if (!_walletService.isInitialized) {
      await _initializeAppKit();
    }

    try {
      await _walletService.openModal();
    } catch (e) {
      logger.e('Failed to open modal: $e');
      if (mounted) {
        OverlayService()
            .showError('Failed to open wallet modal: ${e.toString()}');
      }
    }
  }

  Future<void> _disconnect() async {
    try {
      await _walletService.disconnect();
    } catch (e) {
      logger.e('Failed to disconnect: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isInitializing) {
      return LongButtonWidget(
        buttonType: ButtonType.secondary,
        title: 'Initializing...',
        customWidth: double.infinity,
        onTap: null,
      );
    }

    if (_walletService.isConnected) {
      // Connected state
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
                    _walletService.shortAddress ?? '',
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

    // Disconnected state
    return LongButtonWidget(
      buttonType: ButtonType.secondary,
      title: 'Connect ${widget.chain.name} Wallet',
      leadingIcon: Icon(
        Icons.account_balance_wallet_outlined,
        color: isDark ? Colors.white : Colors.black,
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
