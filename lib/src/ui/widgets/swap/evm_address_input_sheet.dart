import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/screens/transactions/receive/qr_scanner_screen.dart';
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
  String? _errorText;
  bool _isValid = false;

  @override
  void dispose() {
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

    // Different text based on whether this is source or destination address
    final titleText = widget.isSourceAddress
        ? 'Send ${widget.tokenSymbol}'
        : 'Receive ${widget.tokenSymbol}';
    final infoText = widget.isSourceAddress
        ? 'Enter your ${widget.network} wallet address that you will send ${widget.tokenSymbol} from'
        : 'Enter your ${widget.network} wallet address to receive ${widget.tokenSymbol}';

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            titleText,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Info text
          Text(
            infoText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                ),
          ),
          const SizedBox(height: AppTheme.cardPadding),
          // Address input
          GlassContainer(
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
                          color:
                              isDarkMode ? AppTheme.white60 : AppTheme.black60,
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
                  // Paste button
                  IconButton(
                    onPressed: _pasteFromClipboard,
                    icon: Icon(
                      Icons.paste_rounded,
                      color: isDarkMode ? AppTheme.white60 : AppTheme.black60,
                      size: 20,
                    ),
                    tooltip: 'Paste',
                  ),
                  // QR scan button
                  IconButton(
                    onPressed: _openQrScanner,
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
          ),
          const SizedBox(height: AppTheme.elementSpacing),
          // Warning text
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 16,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Make sure this is a ${widget.network} address. Sending to wrong network may result in loss of funds.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.orange,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardPadding),
          // Confirm button
          LongButtonWidget(
            title: 'Continue',
            customWidth: double.infinity,
            state: _isValid ? ButtonState.idle : ButtonState.disabled,
            onTap: _isValid
                ? () {
                    final address = _addressController.text;
                    Navigator.pop(context);
                    widget.onAddressConfirmed(address);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
