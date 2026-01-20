import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/ui/screens/transactions/receive/qr_scanner_screen.dart';
import 'package:ark_flutter/src/services/wallet_connect_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet for entering EVM (Ethereum/Polygon) wallet address.
/// Used for both receiving stablecoins (BTC -> EVM) and sending stablecoins (EVM -> BTC).
class EvmAddressInputSheet extends StatefulWidget {
  final String tokenSymbol;
  final String network;
  final Function(String address) onAddressConfirmed;

  /// If true, this is the source address (where user sends from).
  /// If false (default), this is the destination address (where user receives).
  final bool isSourceAddress;

  const EvmAddressInputSheet({
    super.key,
    required this.tokenSymbol,
    required this.network,
    required this.onAddressConfirmed,
    this.isSourceAddress = false,
  });

  @override
  State<EvmAddressInputSheet> createState() => _EvmAddressInputSheetState();
}

class _EvmAddressInputSheetState extends State<EvmAddressInputSheet> {
  final TextEditingController _addressController = TextEditingController();
  final WalletConnectService _walletConnectService = WalletConnectService();
  String? _errorText;
  bool _isValid = false;
  bool _addressFromWallet = false;
  bool _isConnectingWallet = false;

  @override
  void initState() {
    super.initState();
    // Prefill address from connected wallet if available
    _prefillFromConnectedWallet();
    // Listen to wallet connection changes
    _walletConnectService.addListener(_onWalletConnectionChanged);
  }

  void _onWalletConnectionChanged() {
    if (mounted) {
      _prefillFromConnectedWallet();
    }
  }

  /// Get the required EVM chain based on the network parameter
  EvmChain get _requiredChain {
    final networkLower = widget.network.toLowerCase();
    if (networkLower.contains('ethereum') || networkLower.contains('eth')) {
      return EvmChain.ethereum;
    }
    // Default to Polygon for all other cases
    return EvmChain.polygon;
  }

  Future<void> _prefillFromConnectedWallet() async {
    if (_walletConnectService.isConnected &&
        _walletConnectService.isEvmAddress) {
      // First ensure we're on the correct chain
      try {
        await _walletConnectService.ensureCorrectChain(_requiredChain);
      } catch (e) {
        logger.e('Failed to switch chain: $e');
      }

      // Then get the address for this chain
      final address = _walletConnectService.connectedAddress;
      if (address != null && address.startsWith('0x') && mounted) {
        setState(() {
          _addressController.text = address;
          _addressFromWallet = true;
          _isValid = _validateEvmAddress(address);
          _errorText = null;
        });
      }
    }
  }

  Future<void> _connectWallet({bool isChanging = false}) async {
    if (_isConnectingWallet) return;

    setState(() => _isConnectingWallet = true);

    try {
      // If changing wallet, disconnect first
      if (isChanging && _walletConnectService.isConnected) {
        await _walletConnectService.disconnect();
        if (mounted) {
          setState(() {
            _addressController.clear();
            _addressFromWallet = false;
            _isValid = false;
          });
        }
        // Small delay after disconnect to allow cleanup
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Always pass fresh context to ensure modal can be shown properly
      // The service will reinitialize if needed
      await _walletConnectService.openModal(context: context);

      // After connecting, switch to the required chain and get address
      if (_walletConnectService.isConnected) {
        await _walletConnectService.ensureCorrectChain(_requiredChain);
        // Manually trigger prefill after chain switch
        await _prefillFromConnectedWallet();
      }
    } catch (e) {
      logger.e('Error connecting wallet: $e');
      OverlayService().showError('Failed to connect wallet');
    } finally {
      if (mounted) {
        setState(() => _isConnectingWallet = false);
      }
    }
  }

  @override
  void dispose() {
    _walletConnectService.removeListener(_onWalletConnectionChanged);
    _addressController.dispose();
    super.dispose();
  }

  bool _validateEvmAddress(String address) {
    // Basic EVM address validation (0x followed by 40 hex chars)
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }

  void _onAddressChanged(String value) {
    setState(() {
      // If user manually edits, clear the "from wallet" indicator
      if (_addressFromWallet &&
          value != _walletConnectService.connectedAddress) {
        _addressFromWallet = false;
      }

      if (value.isEmpty) {
        _errorText = null;
        _isValid = false;
      } else if (!_validateEvmAddress(value)) {
        _errorText = 'Invalid ${widget.network} address';
        _isValid = false;
      } else {
        _errorText = null;
        _isValid = true;
      }
    });
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      final cleanAddress = _cleanEvmAddress(data!.text!);
      _addressController.text = cleanAddress;
      _onAddressChanged(_addressController.text);
    }
  }

  void _clearAddress() {
    _addressController.clear();
    _onAddressChanged('');
  }

  /// Clean EVM address from QR code data
  String _cleanEvmAddress(String data) {
    String cleanAddress = data.trim();

    // Remove ethereum: prefix if present
    if (cleanAddress.toLowerCase().startsWith('ethereum:')) {
      cleanAddress = cleanAddress.substring(9);
    }

    // Remove any query parameters or chain ID
    if (cleanAddress.contains('@')) {
      cleanAddress = cleanAddress.split('@').first;
    }
    if (cleanAddress.contains('?')) {
      cleanAddress = cleanAddress.split('?').first;
    }

    return cleanAddress.trim();
  }

  Future<void> _openQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      final cleanAddress = _cleanEvmAddress(result);
      _addressController.text = cleanAddress;
      _onAddressChanged(_addressController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final hasText = _addressController.text.isNotEmpty;
    final hasError = _errorText != null;

    // Different text based on whether this is source or destination address
    final titleText = widget.isSourceAddress
        ? 'Send ${widget.tokenSymbol}'
        : 'Receive ${widget.tokenSymbol}';

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: titleText,
        hasBackButton: false,
        actions: _addressFromWallet
            ? [
                Padding(
                  padding:
                      const EdgeInsets.only(right: AppTheme.elementSpacing),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Connected',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.successColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          const SizedBox(height: AppTheme.cardPadding * 3.5),

          Expanded(
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Connect/Change wallet button
                  if (!_walletConnectService.isConnected &&
                          _addressController.text.isEmpty ||
                      _addressFromWallet) ...[
                    GestureDetector(
                      onTap: _isConnectingWallet
                          ? null
                          : () =>
                              _connectWallet(isChanging: _addressFromWallet),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: _addressFromWallet
                              ? Colors.transparent
                              : (isDarkMode
                                  ? Colors.white.withValues(alpha: 0.08)
                                  : Colors.black.withValues(alpha: 0.05)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDarkMode
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_isConnectingWallet)
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: dotProgress(
                                  context,
                                  size: 8,
                                  color: isDarkMode
                                      ? AppTheme.white60
                                      : AppTheme.black60,
                                ),
                              )
                            else
                              Icon(
                                _addressFromWallet
                                    ? Icons.swap_horiz_rounded
                                    : Icons.account_balance_wallet_outlined,
                                size: 18,
                                color: isDarkMode
                                    ? AppTheme.white60
                                    : AppTheme.black60,
                              ),
                            const SizedBox(width: 8),
                            Text(
                              _isConnectingWallet
                                  ? 'Connecting...'
                                  : (_addressFromWallet
                                      ? 'Change Wallet'
                                      : 'Connect Wallet'),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? AppTheme.white60
                                        : AppTheme.black60,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (!_addressFromWallet) ...[
                      const SizedBox(height: AppTheme.elementSpacing),
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.2),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.elementSpacing),
                            child: Text(
                              'or enter manually',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: isDarkMode
                                        ? Colors.white.withValues(alpha: 0.4)
                                        : Colors.black.withValues(alpha: 0.4),
                                  ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: isDarkMode
                                  ? Colors.white.withValues(alpha: 0.2)
                                  : Colors.black.withValues(alpha: 0.2),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppTheme.elementSpacing),
                  ],

                  // Address input
                  GlassContainer(
                    borderRadius:
                        BorderRadius.circular(AppTheme.borderRadiusMid),
                    border: _addressFromWallet
                        ? Border.all(
                            color: AppTheme.successColor.withValues(alpha: 0.3),
                            width: 1,
                          )
                        : (hasError
                            ? Border.all(
                                color:
                                    AppTheme.errorColor.withValues(alpha: 0.5),
                                width: 1,
                              )
                            : null),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.cardPadding,
                        vertical: AppTheme.elementSpacing * 0.5,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _addressController,
                              onChanged: _onAddressChanged,
                              style: TextStyle(
                                color: isDarkMode ? Colors.white : Colors.black,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                              decoration: InputDecoration(
                                hintText: '0x...',
                                hintStyle: TextStyle(
                                  color: isDarkMode
                                      ? AppTheme.white60
                                      : AppTheme.black60,
                                ),
                                border: InputBorder.none,
                                errorText: _errorText,
                                errorStyle: const TextStyle(
                                  color: AppTheme.errorColor,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          // Show clear button if text exists, otherwise show paste and QR buttons
                          if (hasText) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: _clearAddress,
                              child: Icon(
                                Icons.cancel,
                                color: Theme.of(context).hintColor,
                                size: 22,
                              ),
                            ),
                          ] else ...[
                            // Paste button (Apple standard icon)
                            IconButton(
                              onPressed: _pasteFromClipboard,
                              icon: Icon(
                                CupertinoIcons.doc_on_clipboard,
                                color: isDarkMode
                                    ? AppTheme.white60
                                    : AppTheme.black60,
                                size: 20,
                              ),
                              tooltip: 'Paste',
                            ),
                            // QR scan button
                            IconButton(
                              onPressed: _openQrScanner,
                              icon: Icon(
                                Icons.qr_code_scanner_rounded,
                                color: isDarkMode
                                    ? AppTheme.white60
                                    : AppTheme.black60,
                                size: 20,
                              ),
                              tooltip: 'Scan QR',
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom button
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: LongButtonWidget(
                title: 'Continue',
                customWidth: double.infinity,
                buttonType:
                    _isValid ? ButtonType.solid : ButtonType.transparent,
                state: _isValid ? ButtonState.idle : ButtonState.disabled,
                onTap: _isValid
                    ? () {
                        final address = _addressController.text;
                        Navigator.pop(context);
                        widget.onAddressConfirmed(address);
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
