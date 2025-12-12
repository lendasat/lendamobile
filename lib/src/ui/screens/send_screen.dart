import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/ui/screens/qr_scanner_screen.dart';
import 'package:ark_flutter/src/ui/screens/sign_transaction_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/amount_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// SendScreen - BitNet-style send interface with Provider state management
/// Combines the visual design from the BitNet project with the Ark functionality
class SendScreen extends StatefulWidget {
  final String aspId;
  final double availableSats;

  const SendScreen({
    super.key,
    required this.aspId,
    required this.availableSats,
  });

  @override
  SendScreenState createState() => SendScreenState();
}

class SendScreenState extends State<SendScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _btcController = TextEditingController();
  final TextEditingController _satController = TextEditingController();
  final TextEditingController _currController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();

  // State
  final bool _isLoading = false;
  bool _isAddressExpanded = false;
  bool _hasValidAddress = false;
  String? _description;
  double? _bitcoinPrice;

  // Animation controller for address field expansion
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    logger.i("SendScreen initialized with ASP ID: ${widget.aspId}");

    // Initialize animation controller
    _expandController = AnimationController(
      duration: AppTheme.animationDuration,
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: AppTheme.animationCurve,
    );

    // Initialize controllers with default values
    _satController.text = '0';
    _btcController.text = '0.0';
    _currController.text = '0.0';

    // Listen to address changes
    _addressController.addListener(_onAddressChanged);

    // Fetch bitcoin price
    _fetchBitcoinPrice();
  }

  @override
  void dispose() {
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _btcController.dispose();
    _satController.dispose();
    _currController.dispose();
    _amountFocusNode.dispose();
    _addressFocusNode.dispose();
    _expandController.dispose();
    super.dispose();
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

  void _onAddressChanged() {
    final text = _addressController.text.trim();
    setState(() {
      _hasValidAddress = text.isNotEmpty && _isValidAddress(text);
    });
  }

  bool _isValidAddress(String address) {
    // Basic validation for Bitcoin/Ark/Lightning addresses
    if (address.isEmpty) return false;

    final lower = address.toLowerCase().trim();

    // Lightning invoices (BOLT11) - lnbc (mainnet), lntb (testnet), lnbcrt (regtest)
    if (lower.startsWith('lnbc') ||
        lower.startsWith('lntb') ||
        lower.startsWith('lnbcrt')) {
      return address.length >= 50; // BOLT11 invoices are typically very long
    }

    // Bitcoin mainnet
    if (address.startsWith('1') ||
        address.startsWith('3') ||
        address.startsWith('bc1')) {
      return address.length >= 26 && address.length <= 62;
    }

    // Bitcoin testnet
    if (address.startsWith('m') ||
        address.startsWith('n') ||
        address.startsWith('2') ||
        address.startsWith('tb1')) {
      return address.length >= 26 && address.length <= 62;
    }

    // Ark addresses - add specific validation
    // For now, accept any reasonable length string
    return address.length >= 10;
  }

  /// Check if the address is a Lightning invoice
  bool _isLightningInvoice(String address) {
    final lower = address.toLowerCase().trim();
    return lower.startsWith('lnbc') ||
        lower.startsWith('lntb') ||
        lower.startsWith('lnbcrt');
  }

  void _toggleAddressExpanded() {
    setState(() {
      _isAddressExpanded = !_isAddressExpanded;
      if (_isAddressExpanded) {
        _expandController.forward();
        // Focus the address field when expanded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _addressFocusNode.requestFocus();
        });
      } else {
        _expandController.reverse();
        _addressFocusNode.unfocus();
      }
    });
  }

  Future<void> _handleQRScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && result is String && mounted) {
      _parseScannedData(result);
    }
  }

  void _parseScannedData(String data) {
    String address = data;
    int? amount;
    String? description;

    // Handle Lightning URI (lightning:lnbc...)
    if (data.toLowerCase().startsWith('lightning:')) {
      address = data.substring(10); // Remove "lightning:" prefix
    }
    // Parse BIP21 URI if applicable
    else if (data.toLowerCase().startsWith('bitcoin:')) {
      final uri = Uri.tryParse(data);
      if (uri != null) {
        address = uri.path;

        // Check for Lightning invoice in query params
        if (uri.queryParameters.containsKey('lightning')) {
          address = uri.queryParameters['lightning']!;
        }

        // Parse query parameters
        if (uri.queryParameters.containsKey('amount')) {
          final btcAmount =
              double.tryParse(uri.queryParameters['amount'] ?? '');
          if (btcAmount != null) {
            amount = (btcAmount * 100000000).round();
          }
        }
        if (uri.queryParameters.containsKey('message')) {
          description = uri.queryParameters['message'];
        }
        if (uri.queryParameters.containsKey('label')) {
          description ??= uri.queryParameters['label'];
        }
      }
    }

    setState(() {
      _addressController.text = address;
      _hasValidAddress = _isValidAddress(address);
      if (amount != null && amount > 0) {
        _satController.text = amount.toString();
        _btcController.text = (amount / 100000000).toString();
      }
      if (description != null) {
        _description = description;
      }
      // Collapse the address field after scanning
      if (_isAddressExpanded) {
        _isAddressExpanded = false;
        _expandController.reverse();
      }
    });
  }

  void _handleContinue() {
    final l10n = AppLocalizations.of(context)!;

    if (_addressController.text.isEmpty || _satController.text.isEmpty) {
      _showSnackBar(l10n.pleaseEnterBothAddressAndAmount);
      return;
    }

    double? amount = double.tryParse(_satController.text);
    if (amount == null || amount <= 0) {
      _showSnackBar(l10n.pleaseEnterAValidAmount);
      return;
    }

    if (amount > widget.availableSats) {
      _showSnackBar(l10n.insufficientFunds);
      return;
    }

    // Navigate to sign transaction screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SignTransactionScreen(
          aspId: widget.aspId,
          address: _addressController.text,
          amount: amount,
        ),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
      ),
    );
  }

  void _copyAddress() {
    if (_addressController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _addressController.text));
      _showCopiedSnackBar();
    }
  }

  void _showCopiedSnackBar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.walletAddressCopied),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  /// Resets all form values to their defaults
  /// Can be called when user wants to clear and start over
  void resetValues() {
    setState(() {
      _addressController.clear();
      _satController.text = '0';
      _btcController.text = '0.0';
      _currController.text = '0.0';
      _hasValidAddress = false;
      _description = null;
      _isAddressExpanded = true;
      _expandController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: ArkAppBar(
        context: context,
        text: l10n.sendBitcoin,
        hasBackButton: true,
        onTap: () => Navigator.pop(context),
        buttonType: ButtonType.transparent,
        actions: [
          // Network type indicator
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.elementSpacing),
            child: RoundedButtonWidget(
              size: AppTheme.cardPadding * 1.5,
              buttonType: ButtonType.transparent,
              iconData: Icons.currency_bitcoin,
              onTap: () {},
            ),
          ),
        ],
      ),
      body: PopScope(
        canPop: true,
        child: _buildSendContent(context),
      ),
    );
  }

  Widget _buildSendContent(BuildContext context) {
    
    final l10n = AppLocalizations.of(context)!;
    // Add top padding to account for app bar when extendBodyBehindAppBar is true
    const topPadding = kToolbarHeight;

    return Padding(
      padding:
          const EdgeInsets.only(top: topPadding + AppTheme.elementSpacing),
      child: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              children: [
                // User tile with expandable address input
                _buildUserTile(context, l10n),

                // Main content area
                SizedBox(
                  height: MediaQuery.of(context).size.height -
                      AppTheme.cardPadding * 7.5,
                  width: MediaQuery.of(context).size.width,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: AppTheme.cardPadding * 4),
                          // Bitcoin amount widget
                          Center(
                            child: _buildBitcoinWidget(context),
                          ),
                          const SizedBox(height: AppTheme.cardPadding * 3.5),
                          // Description if available
                          if (_description != null &&
                              _description!.isNotEmpty) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.cardPadding,
                              ),
                              child: Text(
                                ',,${_description!}"',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          // Available balance display
                          const SizedBox(height: AppTheme.cardPadding),
                          _buildAvailableBalance(context, l10n),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 100), // space for bottom button
              ],
            ),
          ),
          // Send button
          _buildSendButton(context, l10n),
        ],
      ),
    );
  }

  Widget _buildUserTile(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.elementSpacing,
      ),
      child: GlassContainer(
        padding: const EdgeInsets.all(AppTheme.elementSpacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main tile row
            Row(
              children: [
                // Avatar
                const Avatar(
                  isNft: false,
                  size: AppTheme.cardPadding * 2,
                ),
                const SizedBox(width: AppTheme.elementSpacing),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hasValidAddress
                            ? (_isLightningInvoice(_addressController.text)
                                ? 'Lightning'
                                : l10n.recipient)
                            : l10n.unknown,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      // Address display with copy
                      if (_hasValidAddress)
                        GestureDetector(
                          onTap: _copyAddress,
                          child: Row(
                            children: [
                              Icon(
                                Icons.copy_rounded,
                                color: Theme.of(context).hintColor,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _addressController.text,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color: Theme.of(context).hintColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Text(
                          l10n.recipientAddress,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                    ],
                  ),
                ),
                // Edit button
                GestureDetector(
                  onTap: _toggleAddressExpanded,
                  child: Container(
                    padding: const EdgeInsets.all(AppTheme.elementSpacing),
                    child: Icon(
                      _isAddressExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.edit_rounded,
                      color: Theme.of(context).hintColor,
                      size: AppTheme.cardPadding,
                    ),
                  ),
                ),
              ],
            ),
            // Expandable address input
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.elementSpacing),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: AppTheme.cardRadiusSmall,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressController,
                            focusNode: _addressFocusNode,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: AppTheme.cardPadding,
                                vertical: AppTheme.elementSpacing,
                              ),
                              hintText: l10n.bitcoinOrArkAddress,
                              hintStyle: TextStyle(color: Theme.of(context).hintColor),
                            ),
                          ),
                        ),
                        // QR Code button
                        IconButton(
                          icon: Icon(
                            Icons.qr_code_scanner_rounded,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: _handleQRScan,
                        ),
                        const SizedBox(width: AppTheme.elementSpacing / 2),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBitcoinWidget(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AmountWidget(
            enabled: () => true,
            btcController: _btcController,
            satController: _satController,
            currController: _currController,
            focusNode: _amountFocusNode,
            bitcoinUnit: CurrencyType.sats,
            swapped: false,
            autoConvert: true,
            bitcoinPrice: _bitcoinPrice ?? 65000.0,
            lowerBound: 0,
            upperBound: widget.availableSats.toInt(),
            boundType: CurrencyType.sats,
            onAmountChange: (currencyType, text) {
              // Update state when amount changes
              setState(() {});
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableBalance(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final currencyService = context.watch<CurrencyPreferenceService>();
    final satsAvailable = widget.availableSats.toStringAsFixed(0);
    final fiatAvailable = _bitcoinPrice != null
        ? currencyService
            .formatAmount((widget.availableSats / 100000000) * _bitcoinPrice!)
        : '\$0.00';

    return Padding(
      padding:
          const EdgeInsets.symmetric(horizontal: AppTheme.elementSpacing),
      child: ArkListTile(
        text: l10n.available,
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$satsAvailable SATS',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              fiatAvailable,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final canSend = _hasValidAddress &&
        (double.tryParse(_satController.text) ?? 0) > 0 &&
        !_isLoading;

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
                  Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.0),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          // Button container
          Container(
            width: double.infinity,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.only(
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              bottom: AppTheme.cardPadding,
            ),
            child: GestureDetector(
              onTap: canSend ? _handleContinue : null,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: canSend
                      ? const LinearGradient(
                          colors: [
                            AppTheme.colorBitcoin,
                            AppTheme.colorPrimaryGradient,
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        )
                      : null,
                  color: canSend ? null : Theme.of(context).colorScheme.secondary,
                  borderRadius: AppTheme.cardRadiusBig,
                  boxShadow: canSend
                      ? [
                          BoxShadow(
                            color:
                                AppTheme.colorBitcoin.withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: _isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              canSend ? Colors.black : Theme.of(context).hintColor,
                            ),
                          ),
                        )
                      : Text(
                          l10n.sendNow,
                          style: TextStyle(
                            color: canSend ? Colors.black : Theme.of(context).hintColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
