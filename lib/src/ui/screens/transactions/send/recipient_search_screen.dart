import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/recipient_storage_service.dart';
import 'package:ark_flutter/src/ui/screens/transactions/receive/qr_scanner_screen.dart';
import 'package:ark_flutter/src/ui/screens/transactions/send/send_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/utils/address_validator.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

/// RecipientSearchScreen - First screen in the send flow
/// Allows user to search, paste, or scan a recipient address
/// Once a valid address is detected, navigates to SendScreen
class RecipientSearchScreen extends StatefulWidget {
  final String aspId;
  final double availableSats;

  const RecipientSearchScreen({
    super.key,
    required this.aspId,
    required this.availableSats,
  });

  @override
  RecipientSearchScreenState createState() => RecipientSearchScreenState();
}

class RecipientSearchScreenState extends State<RecipientSearchScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  MobileScannerController? _scannerController;
  bool _clipboardChecked = false;

  // Recent recipients from storage (only reusable ones)
  List<StoredRecipient> _recentRecipients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecentRecipients();
    // Auto-check clipboard for valid address
    _checkClipboard();
  }

  /// Check clipboard for a valid Bitcoin/Lightning address and auto-paste
  Future<void> _checkClipboard() async {
    if (_clipboardChecked) return;
    _clipboardChecked = true;

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        final text = clipboardData.text!.trim();
        final result = AddressValidator.validate(text);
        if (result.isValid) {
          // Valid address in clipboard - navigate directly
          _navigateToSendScreen(text, fromClipboard: true);
        }
      }
    } catch (e) {
      logger.e('Error checking clipboard: $e');
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  Future<void> _loadRecentRecipients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get only reusable recipients (excludes Lightning invoices)
      final recipients = await RecipientStorageService.getReusableRecipients();

      if (mounted) {
        setState(() {
          _recentRecipients = recipients;
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error loading recipients: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String text) {
    if (text.trim().isEmpty) return;

    // Check if valid address
    final result = AddressValidator.validate(text.trim());
    if (result.isValid) {
      // Valid address - navigate to send screen
      _navigateToSendScreen(text.trim());
    }
  }

  void _navigateToSendScreen(String address, {bool fromClipboard = false}) {
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SendScreen(
          aspId: widget.aspId,
          availableSats: widget.availableSats,
          initialAddress: address,
          fromClipboard: fromClipboard,
        ),
      ),
    );
  }

  Future<void> _handleQRScan() async {
    _searchFocusNode.unfocus();
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && result is String && mounted) {
      _processScannedData(result);
    }
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        _processScannedData(clipboardData.text!.trim());
      }
    } catch (e) {
      logger.e('Error pasting from clipboard: $e');
    }
  }

  Future<void> _pickImageAndScan() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        _scannerController ??= MobileScannerController();
        final BarcodeCapture? result = await _scannerController!.analyzeImage(
          image.path,
        );

        if (result != null && result.barcodes.isNotEmpty) {
          final String? code = result.barcodes.first.rawValue;
          if (code != null && mounted) {
            _processScannedData(code);
          }
        }
      }
    } catch (e) {
      logger.e('Error picking/scanning image: $e');
    }
  }

  void _processScannedData(String data) {
    String address = data;

    // Handle Lightning URI
    if (data.toLowerCase().startsWith('lightning:')) {
      address = data.substring(10);
    }
    // Handle BIP21 URI - extract best address
    else if (data.toLowerCase().startsWith('bitcoin:')) {
      final uri = Uri.tryParse(data);
      if (uri != null) {
        // Priority: ark > arkade > lightning > bitcoin
        if (uri.queryParameters.containsKey('ark')) {
          address = uri.queryParameters['ark']!;
        } else if (uri.queryParameters.containsKey('arkade')) {
          address = uri.queryParameters['arkade']!;
        } else if (uri.queryParameters.containsKey('lightning')) {
          address = uri.queryParameters['lightning']!;
        } else {
          address = uri.path;
        }
      }
    }

    // Validate and navigate
    final result = AddressValidator.validate(address);
    if (result.isValid) {
      // Navigate with the full original data to preserve amount/description
      _navigateToSendScreen(data);
    }
    // Invalid addresses are ignored - user can try again
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: l10n.chooseRecipient,
        hasBackButton: true,
        onTap: () {
          _searchFocusNode.unfocus();
          Navigator.pop(context);
        },
        buttonType: ButtonType.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: kToolbarHeight + AppTheme.cardPadding * 2),
                // Search field
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.cardPadding,
                  ),
                  child: SearchFieldWidget(
                    hintText: l10n.searchRecipient,
                    isSearchEnabled: true,
                    handleSearch: _onSearchChanged,
                    onChanged: _onSearchChanged,
                    node: _searchFocusNode,
                    suffixIcon: IconButton(
                      icon: Icon(
                        CupertinoIcons.doc_on_clipboard,
                        color: Theme.of(context).hintColor,
                      ),
                      onPressed: _pasteFromClipboard,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.cardPadding * 1.5),

                // Recent recipients section
                if (_isLoading) ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.cardPadding),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ] else if (_recentRecipients.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.cardPadding,
                    ),
                    child: Text(
                      l10n.recent,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.cardPadding,
                    ),
                    child: GlassContainer(
                      opacity: 0.05,
                      borderRadius: AppTheme.cardRadiusSmall,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTheme.elementSpacing / 2,
                      ),
                      child: Column(
                        children: List.generate(_recentRecipients.length, (index) {
                          final recipient = _recentRecipients[index];
                          return _buildRecentRecipientItem(
                              recipient, index == _recentRecipients.length - 1);
                        }),
                      ),
                    ),
                  ),
                ],

                // Bottom padding for buttons
                const SizedBox(height: 120),
              ],
            ),
          ),
          // Bottom action buttons
          _buildBottomButtons(context),
        ],
      ),
    );
  }

  Widget _buildRecentRecipientItem(StoredRecipient recipient, bool isLast) {
    final l10n = AppLocalizations.of(context)!;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _navigateToSendScreen(recipient.address),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing,
          vertical: AppTheme.elementSpacing * 0.75,
        ),
        child: Row(
          children: [
            // Avatar
            _buildRecipientAvatar(),
            const SizedBox(width: AppTheme.elementSpacing),
            // Address and time ago
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _truncateAddress(recipient.address),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_getTypeLabel(recipient.type)} • ${_formatTimeAgo(recipient.timestamp, l10n)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
            // Amount
            Text(
              '${_formatAmount(recipient.amountSats)} sats',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipientAvatar() {
    return const Avatar(
      size: AppTheme.cardPadding * 1.75,
      fallbackIcon: Icons.person,
    );
  }

  String _getTypeLabel(RecipientType type) {
    switch (type) {
      case RecipientType.ark:
        return 'Ark';
      case RecipientType.lightning:
        return 'Lightning';
      case RecipientType.lightningInvoice:
        return 'Invoice';
      case RecipientType.onchain:
        return 'Onchain';
    }
  }

  String _truncateAddress(String address) {
    if (address.length <= 20) return address;
    // For Lightning addresses (user@domain), show as-is if reasonable
    if (address.contains('@') && address.length <= 30) {
      return address;
    }
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
  }

  String _formatAmount(int sats) {
    if (sats >= 1000000) {
      return '${(sats / 1000000).toStringAsFixed(2)}M';
    } else if (sats >= 1000) {
      return '${(sats / 1000).toStringAsFixed(1)}k';
    }
    return sats.toString();
  }

  String _formatTimeAgo(int timestamp, AppLocalizations l10n) {
    final now = DateTime.now();
    final txTime = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final difference = now.difference(txTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? l10n.yearAgo : l10n.yearsAgo}';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? l10n.monthAgo : l10n.monthsAgo}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} ${difference.inDays == 1 ? l10n.dayAgo : l10n.daysAgo}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} ${difference.inHours == 1 ? l10n.hourAgo : l10n.hoursAgo}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} ${difference.inMinutes == 1 ? l10n.minuteAgo : l10n.minutesAgo}';
    } else {
      return l10n.justNow;
    }
  }

  Widget _buildBottomButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppTheme.white90 : AppTheme.black90;
    const buttonSize = 48.0;

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Gradient fade
          Container(
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.0),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.only(
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              bottom: AppTheme.cardPadding,
            ),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                  vertical: AppTheme.elementSpacing,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: AppTheme.cardRadiusBig,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: CupertinoIcons.photo_fill,
                      onTap: _pickImageAndScan,
                      iconColor: iconColor,
                      size: buttonSize,
                    ),
                    const SizedBox(width: AppTheme.elementSpacing),
                    _buildActionButton(
                      icon: CupertinoIcons.qrcode_viewfinder,
                      onTap: _handleQRScan,
                      iconColor: iconColor,
                      size: buttonSize,
                    ),
                    const SizedBox(width: AppTheme.elementSpacing),
                    _buildActionButton(
                      icon: CupertinoIcons.doc_on_clipboard_fill,
                      onTap: _pasteFromClipboard,
                      iconColor: iconColor,
                      size: buttonSize,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
    required double size,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon,
            color: iconColor,
            size: 24,
          ),
        ),
      ),
    );
  }
}
