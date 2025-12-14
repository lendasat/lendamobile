import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/qr_scanner_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Bottom sheet for entering addresses for EVM → BTC swaps.
/// Requires both the user's EVM address (source) and Ark/BTC address (target).
class EvmToBtcAddressSheet extends StatefulWidget {
  final String sourceTokenSymbol;
  final String sourceNetwork;
  final Function(String evmAddress, String btcAddress) onAddressesConfirmed;

  const EvmToBtcAddressSheet({
    super.key,
    required this.sourceTokenSymbol,
    required this.sourceNetwork,
    required this.onAddressesConfirmed,
  });

  @override
  State<EvmToBtcAddressSheet> createState() => _EvmToBtcAddressSheetState();
}

class _EvmToBtcAddressSheetState extends State<EvmToBtcAddressSheet> {
  final TextEditingController _evmController = TextEditingController();
  final TextEditingController _btcController = TextEditingController();
  String? _evmError;
  String? _btcError;
  bool _isEvmValid = false;
  bool _isBtcValid = false;

  @override
  void dispose() {
    _evmController.dispose();
    _btcController.dispose();
    super.dispose();
  }

  bool _validateEvmAddress(String address) {
    final regex = RegExp(r'^0x[a-fA-F0-9]{40}$');
    return regex.hasMatch(address);
  }

  bool _validateBtcAddress(String address) {
    // Basic validation for Ark/Bitcoin addresses
    // Ark addresses start with 'ark1' or 'tark1' (bech32m)
    // Regular Bitcoin addresses: bc1, tb1, 1, 3, m, n, 2
    if (address.isEmpty) return false;

    // Ark bech32m addresses
    if (address.startsWith('ark1') || address.startsWith('tark1')) {
      return address.length >= 20;
    }

    // Bitcoin bech32 addresses
    if (address.startsWith('bc1') || address.startsWith('tb1')) {
      return address.length >= 26;
    }

    // Legacy Bitcoin addresses
    if (address.startsWith('1') || address.startsWith('3') ||
        address.startsWith('m') || address.startsWith('n') ||
        address.startsWith('2')) {
      return address.length >= 26 && address.length <= 35;
    }

    return false;
  }

  void _onEvmChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _evmError = null;
        _isEvmValid = false;
      } else if (!_validateEvmAddress(value)) {
        _evmError = 'Invalid ${widget.sourceNetwork} address';
        _isEvmValid = false;
      } else {
        _evmError = null;
        _isEvmValid = true;
      }
    });
  }

  void _onBtcChanged(String value) {
    setState(() {
      if (value.isEmpty) {
        _btcError = null;
        _isBtcValid = false;
      } else if (!_validateBtcAddress(value)) {
        _btcError = 'Invalid Bitcoin/Ark address';
        _isBtcValid = false;
      } else {
        _btcError = null;
        _isBtcValid = true;
      }
    });
  }

  Future<void> _pasteToController(TextEditingController controller, Function(String) onChange) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      controller.text = data!.text!.trim();
      onChange(controller.text);
    }
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

  /// Clean BTC/Ark address from QR code data
  String _cleanBtcAddress(String data) {
    String cleanAddress = data.trim();

    // Remove bitcoin: prefix if present
    if (cleanAddress.toLowerCase().startsWith('bitcoin:')) {
      cleanAddress = cleanAddress.substring(8);
    }

    // Remove any query parameters
    if (cleanAddress.contains('?')) {
      cleanAddress = cleanAddress.split('?').first;
    }

    return cleanAddress.trim();
  }

  Future<void> _openEvmQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      final cleanAddress = _cleanEvmAddress(result);
      _evmController.text = cleanAddress;
      _onEvmChanged(_evmController.text);
    }
  }

  Future<void> _openBtcQrScanner() async {
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && mounted) {
      final cleanAddress = _cleanBtcAddress(result);
      _btcController.text = cleanAddress;
      _onBtcChanged(_btcController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isValid = _isEvmValid && _isBtcValid;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: ArkAppBar(
        context: context,
        text: 'Enter Addresses',
        hasBackButton: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppTheme.cardPadding * 2),

            // EVM Address Section
            Text(
              'Your ${widget.sourceNetwork} Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The address you will send ${widget.sourceTokenSymbol} from',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            _buildAddressInput(
              controller: _evmController,
              hint: '0x...',
              error: _evmError,
              onChanged: _onEvmChanged,
              onPaste: () => _pasteToController(_evmController, _onEvmChanged),
              onScanQr: _openEvmQrScanner,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: AppTheme.cardPadding * 1.5),

            // BTC Address Section
            Text(
              'Your Bitcoin Address',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'The address where you want to receive BTC',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            _buildAddressInput(
              controller: _btcController,
              hint: 'ark1... or bc1...',
              error: _btcError,
              onChanged: _onBtcChanged,
              onPaste: () => _pasteToController(_btcController, _onBtcChanged),
              onScanQr: _openBtcQrScanner,
              isDarkMode: isDarkMode,
            ),

            const SizedBox(height: AppTheme.cardPadding),

            // Info text
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'You will need to send ${widget.sourceTokenSymbol} from the address above to complete the swap. The BTC will be sent to your Bitcoin address.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                        ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.cardPadding * 2),

            // Continue button
            LongButtonWidget(
              title: 'Continue',
              customWidth: double.infinity,
              state: isValid ? ButtonState.idle : ButtonState.disabled,
              onTap: isValid
                  ? () {
                      widget.onAddressesConfirmed(
                        _evmController.text,
                        _btcController.text,
                      );
                      Navigator.pop(context);
                    }
                  : null,
            ),
            const SizedBox(height: AppTheme.cardPadding),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInput({
    required TextEditingController controller,
    required String hint,
    required String? error,
    required Function(String) onChanged,
    required VoidCallback onPaste,
    required VoidCallback onScanQr,
    required bool isDarkMode,
  }) {
    return GlassContainer(
      borderRadius: BorderRadius.circular(AppTheme.borderRadiusMid),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.cardPadding,
          vertical: AppTheme.elementSpacing * 0.5,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                style: TextStyle(
                  color: isDarkMode ? Colors.white : Colors.black,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                    color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                  ),
                  border: InputBorder.none,
                  errorText: error,
                  errorStyle: const TextStyle(
                    color: AppTheme.errorColor,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            IconButton(
              onPressed: onPaste,
              icon: Icon(
                Icons.paste_rounded,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                size: 20,
              ),
              tooltip: 'Paste',
            ),
            IconButton(
              onPressed: onScanQr,
              icon: Icon(
                Icons.qr_code_scanner_rounded,
                color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                size: 20,
              ),
              tooltip: 'Scan QR',
            ),
          ],
        ),
      ),
    );
  }
}
