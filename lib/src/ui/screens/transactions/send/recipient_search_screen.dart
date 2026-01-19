import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/recipient_storage_service.dart';
import 'package:ark_flutter/src/ui/screens/transactions/receive/qr_scanner_screen.dart';
import 'package:ark_flutter/src/ui/screens/transactions/send/send_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/utils/address_validator.dart';
import 'package:ark_flutter/src/utils/number_formatter.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

/// RecipientSearchScreen - First screen in the send flow
/// Allows user to search, paste, or scan a recipient address
/// Once a valid address is detected, navigates to SendScreen
class RecipientSearchScreen extends StatefulWidget {
  final String aspId;
  final double availableSats;
  final double? bitcoinPrice; // Pass from WalletScreen to avoid redundant fetch

  const RecipientSearchScreen({
    super.key,
    required this.aspId,
    required this.availableSats,
    this.bitcoinPrice,
  });

  @override
  RecipientSearchScreenState createState() => RecipientSearchScreenState();
}

class RecipientSearchScreenState extends State<RecipientSearchScreen> {
  final FocusNode _searchFocusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  MobileScannerController? _scannerController;
  bool _clipboardChecked = false;

  // Clipboard address (if valid)
  String? _clipboardAddress;
  PaymentAddressType? _clipboardAddressType;

  // Debounce timer for search (prevents validation on every keystroke)
  Timer? _searchTimer;

  // Recent recipients from storage (only reusable ones)
  List<StoredRecipient> _recentRecipients = [];
  bool _isLoading = true;
  double? _bitcoinPrice;

  @override
  void initState() {
    super.initState();
    _loadRecentRecipients();
    // Use passed bitcoin price if available, otherwise fetch
    if (widget.bitcoinPrice != null) {
      _bitcoinPrice = widget.bitcoinPrice;
    } else {
      _fetchBitcoinPrice();
    }
    // Auto-check clipboard for valid address
    _checkClipboard();
  }

  /// Check clipboard for a valid Bitcoin/Lightning address
  /// If valid, stores it to show as a selectable option
  Future<void> _checkClipboard() async {
    if (_clipboardChecked) return;
    _clipboardChecked = true;

    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        final text = clipboardData.text!.trim();
        final result = AddressValidator.validate(text);
        if (result.isValid && mounted) {
          // Valid address in clipboard - store it to show as option
          setState(() {
            _clipboardAddress = text;
            _clipboardAddressType = result.type;
          });
        }
      }
    } catch (e) {
      logger.e('Error checking clipboard: $e');
    }
  }

  @override
  void dispose() {
    _searchTimer?.cancel();
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

  Future<void> _fetchBitcoinPrice() async {
    try {
      final priceData = await fetchBitcoinPriceData(TimeRange.day);
      if (priceData.isNotEmpty && mounted) {
        setState(() {
          _bitcoinPrice = priceData.last.price;
        });
      }
    } catch (e) {
      logger.e('Error fetching bitcoin price: $e');
    }
  }

  /// Debounced search handler - delays validation until user stops typing
  void _onSearchChanged(String text) {
    _searchTimer?.cancel();
    _searchTimer = Timer(const Duration(milliseconds: 300), () {
      if (text.trim().isEmpty) return;

      // Check if valid address
      final result = AddressValidator.validate(text.trim());
      if (result.isValid) {
        // Valid address - navigate to send screen
        _navigateToSendScreen(text.trim());
      }
    });
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
          bitcoinPrice: _bitcoinPrice,
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
    // Handle Arkade address with query params (ark1...?amount=0.0001)
    else if ((data.startsWith('ark1') || data.startsWith('tark1')) &&
        data.contains('?')) {
      // Extract just the address part for validation
      address = data.split('?').first;
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
    // Get currency service ONCE here instead of in each list item
    final currencyService = context.watch<CurrencyPreferenceService>();
    final showBtcAsMain = currencyService.showCoinBalance;

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
                const SizedBox(
                    height: kToolbarHeight + AppTheme.cardPadding * 2),
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

                // From Clipboard section
                if (_clipboardAddress != null) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.cardPadding,
                    ),
                    child: Text(
                      l10n.fromClipboard,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.cardPadding,
                    ),
                    child: _buildClipboardItem(),
                  ),
                  const SizedBox(height: AppTheme.cardPadding * 1.5),
                ],

                // Recent recipients section
                if (_isLoading) ...[
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.cardPadding),
                    child: dotProgress(context),
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
                        children:
                            List.generate(_recentRecipients.length, (index) {
                          final recipient = _recentRecipients[index];
                          return _buildRecentRecipientItem(
                            recipient: recipient,
                            isLast: index == _recentRecipients.length - 1,
                            currencyService: currencyService,
                            showBtcAsMain: showBtcAsMain,
                          );
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

  Widget _buildClipboardItem() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppTheme.white60 : AppTheme.black60;

    // Get address type label and icon widget
    String typeLabel;
    Widget typeIconWidget;
    const double iconSize = 12.0;

    // Check if BIP21 contains ark/arkade parameter
    bool bip21HasArk = false;
    if (_clipboardAddressType == PaymentAddressType.bip21 &&
        _clipboardAddress != null) {
      final lower = _clipboardAddress!.toLowerCase();
      bip21HasArk = lower.contains('ark=') || lower.contains('arkade=');
    }

    switch (_clipboardAddressType) {
      case PaymentAddressType.lightningInvoice:
      case PaymentAddressType.lnurl:
      case PaymentAddressType.lightningAddress:
        typeLabel = 'Lightning';
        typeIconWidget = FaIcon(
          FontAwesomeIcons.bolt,
          size: iconSize,
          color: iconColor,
        );
        break;
      case PaymentAddressType.ark:
      case PaymentAddressType.arkTestnet:
        typeLabel = 'Arkade';
        typeIconWidget = SvgPicture.asset(
          'assets/images/tokens/arkade.svg',
          width: iconSize,
          height: iconSize,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        );
        break;
      case PaymentAddressType.bip21WithLightning:
        typeLabel = 'Lightning & Bitcoin';
        typeIconWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              FontAwesomeIcons.bolt,
              size: iconSize,
              color: iconColor,
            ),
            const SizedBox(width: 4),
            FaIcon(
              FontAwesomeIcons.link,
              size: iconSize,
              color: iconColor,
            ),
          ],
        );
        break;
      case PaymentAddressType.bip21:
        if (bip21HasArk) {
          typeLabel = 'Arkade & Bitcoin';
          typeIconWidget = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SvgPicture.asset(
                'assets/images/tokens/arkade.svg',
                width: iconSize,
                height: iconSize,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
              const SizedBox(width: 4),
              FaIcon(
                FontAwesomeIcons.link,
                size: iconSize,
                color: iconColor,
              ),
            ],
          );
        } else {
          typeLabel = 'Bitcoin';
          typeIconWidget = FaIcon(
            FontAwesomeIcons.link,
            size: iconSize,
            color: iconColor,
          );
        }
        break;
      default:
        typeLabel = 'Bitcoin';
        typeIconWidget = FaIcon(
          FontAwesomeIcons.link,
          size: iconSize,
          color: iconColor,
        );
    }

    const radius = BorderRadius.all(Radius.circular(24));

    return GlassContainer(
      opacity: 0.05,
      borderRadius: radius,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: () =>
              _navigateToSendScreen(_clipboardAddress!, fromClipboard: true),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.elementSpacing * 1.25,
              vertical: AppTheme.elementSpacing * 0.85,
            ),
            child: Row(
              children: [
                // Clipboard icon in circle
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.doc_on_clipboard_fill,
                    size: 16,
                    color: isDark ? AppTheme.white70 : AppTheme.black70,
                  ),
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                // Address and type stacked
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _truncateAddress(_clipboardAddress!),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color:
                                  isDark ? AppTheme.white90 : AppTheme.black90,
                              fontWeight: FontWeight.w500,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          typeIconWidget,
                          const SizedBox(width: 4),
                          Text(
                            typeLabel,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: iconColor,
                                      fontSize: 11,
                                    ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Arrow
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: iconColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentRecipientItem({
    required StoredRecipient recipient,
    required bool isLast,
    required CurrencyPreferenceService currencyService,
    required bool showBtcAsMain,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate fiat amount
    final amountBtc = recipient.amountSats / BitcoinConstants.satsPerBtc;
    final btcPrice = _bitcoinPrice ?? 0;
    final fiatAmount = amountBtc * btcPrice;

    // Wrap in RepaintBoundary to prevent unnecessary repaints during scroll
    return RepaintBoundary(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToSendScreen(recipient.address),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppTheme.elementSpacing,
            ),
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppTheme.elementSpacing * 0.75,
                right: AppTheme.elementSpacing * 1,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // LEFT SIDE
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar instead of arrow icon
                      const Avatar(
                        size: AppTheme.cardPadding * 2,
                        fallbackIcon: Icons.person,
                      ),
                      const SizedBox(width: AppTheme.elementSpacing * 0.75),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: AppTheme.cardPadding * 6.5,
                            child: Text(
                              _truncateAddress(recipient.address),
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall!
                                  .copyWith(
                                    color: isDark
                                        ? AppTheme.white90
                                        : AppTheme.black90,
                                  ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.elementSpacing / 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _formatTimeAgo(recipient.timestamp, l10n),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.elementSpacing / 2,
                                ),
                                child: Text(
                                  '·',
                                  style: Theme.of(context).textTheme.labelSmall,
                                ),
                              ),
                              Text(
                                _getTypeLabel(recipient.type),
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.labelSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                  // RIGHT SIDE - Amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Text(
                            showBtcAsMain
                                ? NumberFormatter.formatSats(
                                    recipient.amountSats)
                                : currencyService.formatAmount(fiatAmount),
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (showBtcAsMain)
                            Icon(
                              AppTheme.satoshiIcon,
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getTypeLabel(RecipientType type) {
    switch (type) {
      case RecipientType.ark:
        return 'Arkade';
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
    final l10n = AppLocalizations.of(context)!;

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
              child: LongButtonWidget(
                title: l10n.scanQrCode,
                buttonType: ButtonType.transparent,
                leadingIcon: Icon(
                  CupertinoIcons.qrcode_viewfinder,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? AppTheme.white90
                      : AppTheme.black90,
                  size: 20,
                ),
                onTap: _handleQRScan,
                customWidth: double.infinity,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
