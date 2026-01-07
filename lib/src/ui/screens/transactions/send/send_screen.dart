import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/rust/api/mempool_api.dart' as mempool_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/lnurl_service.dart';
import 'package:ark_flutter/src/utils/address_validator.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/services/pending_transaction_service.dart';
import 'package:ark_flutter/src/ui/screens/transactions/receive/qr_scanner_screen.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/utility/amount_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/theme.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';

/// SendScreen - BitNet-style send interface with Provider state management
/// Combines the visual design from the BitNet project with the Ark functionality
class SendScreen extends StatefulWidget {
  final String aspId;
  final double availableSats;
  final String? initialAddress;

  const SendScreen({
    super.key,
    required this.aspId,
    required this.availableSats,
    this.initialAddress,
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

  // Image picker and scanner for QR from gallery
  final ImagePicker _imagePicker = ImagePicker();
  MobileScannerController? _scannerController;

  // State
  bool _isLoading = false;
  bool _isAddressExpanded = false;
  bool _hasValidAddress = false;
  String? _addressError; // Error message for invalid address format
  String? _description;
  double? _bitcoinPrice;

  // On-chain fee state
  bool _isOnChainAddress = false;
  RecommendedFees? _recommendedFees;
  bool _isFetchingFees = false;

  // Estimated transaction size in vBytes (typical P2WPKH: 1 input, 2 outputs)
  static const int _estimatedTxVbytes = 140;

  // Boltz submarine swap fee percentage (0.25% for paying Lightning invoices)
  static const double _boltzFeePercent = 0.25;

  // LNURL state
  LnurlPayParams? _lnurlParams;
  bool _isFetchingLnurl = false;

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

    // Set initial address if provided (e.g., from QR scan)
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _addressController.text = widget.initialAddress!;
      // Expand address field and validate
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onAddressChanged();
      });
    }

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
    _scannerController?.dispose();
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
    final validationResult = AddressValidator.validate(text);
    final isValid = validationResult.isValid;

    // If it looks like a complete invoice/URI with an amount, parse it
    // Only parse if the amount field is empty/zero to avoid overwriting user input
    // Also check for URI patterns to avoid re-parsing already extracted addresses
    final isUri = text.toLowerCase().startsWith('bitcoin:') ||
        text.toLowerCase().startsWith('lightning:');
    final amountIsDefault =
        _satController.text.isEmpty || _satController.text == '0';
    if (isValid && isUri && amountIsDefault) {
      _tryParseAmountFromAddress(text);
    }

    // Check if this is an LNURL or Lightning Address and fetch params
    if (isValid && _isLnurlOrLightningAddress(text)) {
      _fetchLnurlParams(text);
    } else if (_lnurlParams != null) {
      // Clear LNURL params if address changed to something else
      setState(() {
        _lnurlParams = null;
      });
    }

    // Check if this is an on-chain Bitcoin address and fetch fees
    final isOnChain = isValid && _isOnChainBitcoinAddress(text);
    if (isOnChain && !_isOnChainAddress) {
      // Address changed to on-chain - fetch fees
      _fetchRecommendedFees();
    }

    setState(() {
      _hasValidAddress = isValid;
      _isOnChainAddress = isOnChain;
      _addressError = text.isNotEmpty ? validationResult.error : null;
      // Clear fees if not on-chain
      if (!isOnChain) {
        _recommendedFees = null;
      }
    });
  }

  /// Fetch LNURL payment parameters
  Future<void> _fetchLnurlParams(String address) async {
    // Avoid duplicate fetches
    if (_isFetchingLnurl) return;

    setState(() {
      _isFetchingLnurl = true;
    });

    try {
      logger.i("Fetching LNURL params for: $address");
      final params = await LnurlService.fetchPayParams(address);

      if (!mounted) return;

      if (params != null) {
        logger.i(
            "LNURL params: min=${params.minSats} sats, max=${params.maxSats} sats");

        setState(() {
          _lnurlParams = params;
          _isFetchingLnurl = false;
          // Set default amount to minimum if no amount entered
          if (_satController.text.isEmpty || _satController.text == '0') {
            _satController.text = params.minSats.toString();
            _btcController.text = (params.minSats / BitcoinConstants.satsPerBtc)
                .toStringAsFixed(8);
          }
          // Set description from LNURL metadata if available
          if (params.description != null && _description == null) {
            _description = params.description;
          }
        });
      } else {
        logger.w("Failed to fetch LNURL parameters");
        setState(() {
          _isFetchingLnurl = false;
        });
      }
    } catch (e) {
      logger.e("Error fetching LNURL params: $e");
      if (mounted) {
        setState(() {
          _isFetchingLnurl = false;
        });
      }
    }
  }

  /// Try to extract address and amount from pasted Lightning invoice or BIP21 URI
  /// Also updates the address controller with the preferred address (ark > lightning > bitcoin)
  void _tryParseAmountFromAddress(String text) {
    int? amount;
    String address = text;
    bool addressExtracted = false;

    // Handle Lightning URI (lightning:lnbc...)
    if (text.toLowerCase().startsWith('lightning:')) {
      address = text.substring(10);
      addressExtracted = true;
    }
    // Parse BIP21 URI for amount
    else if (text.toLowerCase().startsWith('bitcoin:')) {
      final uri = Uri.tryParse(text);
      if (uri != null) {
        // Priority order for address selection (lower fees first):
        // 1. Ark address (lowest fees)
        // 2. Lightning invoice
        // 3. Bitcoin address (highest fees)
        if (uri.queryParameters.containsKey('ark')) {
          address = uri.queryParameters['ark']!;
          addressExtracted = true;
          logger.i("Using ark address from BIP21 for lower fees");
        } else if (uri.queryParameters.containsKey('arkade')) {
          address = uri.queryParameters['arkade']!;
          addressExtracted = true;
          logger.i("Using arkade address from BIP21 for lower fees");
        } else if (uri.queryParameters.containsKey('lightning')) {
          address = uri.queryParameters['lightning']!;
          addressExtracted = true;
        } else {
          // Use bitcoin address from path
          address = uri.path;
          addressExtracted = true;
        }
        // Parse amount from query parameters
        if (uri.queryParameters.containsKey('amount')) {
          final btcAmount =
              double.tryParse(uri.queryParameters['amount'] ?? '');
          if (btcAmount != null) {
            amount = (btcAmount * BitcoinConstants.satsPerBtc).round();
          }
        }
      }
    }

    // Parse Lightning invoice amount if it's a BOLT11 invoice
    if (_isLightningInvoice(address) && amount == null) {
      try {
        final invoice = Bolt11PaymentRequest(address);
        final btcAmount = invoice.amount.toDouble();
        if (btcAmount > 0) {
          amount = (btcAmount * BitcoinConstants.satsPerBtc).round();
          logger.i("Extracted amount from pasted invoice: $amount sats");
        }
      } catch (e) {
        // Ignore parse errors for incomplete invoices
      }
    }

    // Update address controller if we extracted a better address
    if (addressExtracted && address != text) {
      _addressController.text = address;
    }

    // Update amount fields if we extracted an amount
    if (amount != null && amount > 0) {
      _satController.text = amount.toString();
      _btcController.text =
          (amount / BitcoinConstants.satsPerBtc).toStringAsFixed(8);
    }
  }

  /// Check if address is valid using AddressValidator
  bool _isValidAddress(String address) {
    return AddressValidator.isValid(address);
  }

  /// Check if the address is a Lightning invoice (BOLT11)
  bool _isLightningInvoice(String address) {
    final result = AddressValidator.validate(address);
    return result.isValid && result.type == PaymentAddressType.lightningInvoice;
  }

  /// Check if the address is an LNURL or Lightning Address
  bool _isLnurlOrLightningAddress(String address) {
    final result = AddressValidator.validate(address);
    return result.isValid &&
        (result.type == PaymentAddressType.lnurl ||
            result.type == PaymentAddressType.lightningAddress);
  }

  /// Check if the address is an on-chain Bitcoin address (not Ark, not Lightning)
  bool _isOnChainBitcoinAddress(String address) {
    return AddressValidator.isOnChainBitcoin(address);
  }

  /// Fetch recommended fees from mempool.space API
  Future<void> _fetchRecommendedFees() async {
    if (_isFetchingFees) return;

    setState(() {
      _isFetchingFees = true;
    });

    try {
      final fees = await mempool_api.getRecommendedFees();
      if (mounted) {
        setState(() {
          _recommendedFees = fees;
          _isFetchingFees = false;
        });
        logger.i(
            "Fetched recommended fees: halfHourFee=${fees.halfHourFee} sat/vB");
      }
    } catch (e) {
      logger.e("Error fetching recommended fees: $e");
      if (mounted) {
        setState(() {
          _isFetchingFees = false;
        });
      }
    }
  }

  /// Calculate estimated network fee in sats for on-chain transaction
  int get _estimatedNetworkFeeSats {
    if (!_isOnChainAddress || _recommendedFees == null) {
      return 0;
    }
    // Use halfHourFee (standard) fee rate
    final feeRate = _recommendedFees!.halfHourFee;
    return (feeRate * _estimatedTxVbytes).round();
  }

  /// Check if this is a Lightning payment (invoice or LNURL/Lightning Address)
  bool get _isLightningPayment {
    final address = _addressController.text.trim();
    return _isLightningInvoice(address) || _isLnurlOrLightningAddress(address);
  }

  /// Calculate Boltz submarine swap fee for Lightning payments
  int _calculateBoltzFee(double amountSats) {
    if (!_isLightningPayment) return 0;
    // Boltz charges 0.25% for submarine swaps (paying LN invoices)
    return (amountSats * _boltzFeePercent / 100).round();
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

  /// Paste address from clipboard
  Future<void> _pasteFromClipboard() async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
        final text = clipboardData.text!.trim();
        _parseScannedData(text);
      }
    } catch (e) {
      logger.e('Error pasting from clipboard: $e');
    }
  }

  /// Pick image from gallery and scan for QR code
  Future<void> _pickImageAndScan() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
      );

      if (image != null) {
        // Create scanner controller if needed
        _scannerController ??= MobileScannerController();

        final BarcodeCapture? result = await _scannerController!.analyzeImage(
          image.path,
        );

        if (result != null && result.barcodes.isNotEmpty) {
          final String? code = result.barcodes.first.rawValue;
          if (code != null && mounted) {
            _parseScannedData(code);
          }
        } else {
          if (mounted) {
            OverlayService().showError('No QR code found in image');
          }
        }
      }
    } catch (e) {
      logger.e('Error picking/scanning image: $e');
      if (mounted) {
        OverlayService().showError('Error scanning image: $e');
      }
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

        // Priority order for address selection (lower fees first):
        // 1. Ark address (lowest fees)
        // 2. Lightning invoice
        // 3. Bitcoin address (highest fees)
        if (uri.queryParameters.containsKey('ark')) {
          // Prefer ark address for lower fees
          address = uri.queryParameters['ark']!;
          logger.i("Using ark address from BIP21 for lower fees");
        } else if (uri.queryParameters.containsKey('arkade')) {
          // Legacy arkade parameter support
          address = uri.queryParameters['arkade']!;
          logger.i("Using arkade address from BIP21 for lower fees");
        } else if (uri.queryParameters.containsKey('lightning')) {
          // Fall back to lightning invoice
          address = uri.queryParameters['lightning']!;
        }
        // Otherwise use the bitcoin address from uri.path

        // Parse query parameters
        if (uri.queryParameters.containsKey('amount')) {
          final btcAmount =
              double.tryParse(uri.queryParameters['amount'] ?? '');
          if (btcAmount != null) {
            amount = (btcAmount * BitcoinConstants.satsPerBtc).round();
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

    // Parse Lightning invoice amount if it's a BOLT11 invoice
    if (_isLightningInvoice(address) && amount == null) {
      try {
        final invoice = Bolt11PaymentRequest(address);
        // Amount is in BTC, convert to sats
        final btcAmount = invoice.amount.toDouble();
        if (btcAmount > 0) {
          amount = (btcAmount * BitcoinConstants.satsPerBtc).round();
          logger.i("Extracted amount from Lightning invoice: $amount sats");
        }
        // Try to get description from invoice tags
        if (invoice.tags.length > 1) {
          description ??= invoice.tags[1].data.toString();
        }
      } catch (e) {
        logger.w("Failed to parse Lightning invoice: $e");
      }
    }

    setState(() {
      _addressController.text = address;
      _hasValidAddress = _isValidAddress(address);
      if (amount != null && amount > 0) {
        _satController.text = amount.toString();
        _btcController.text =
            (amount / BitcoinConstants.satsPerBtc).toStringAsFixed(8);
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

  Future<void> _handleSend() async {
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

    // Validate LNURL amount bounds if applicable
    if (_lnurlParams != null) {
      final amountSats = amount.round();
      if (amountSats < _lnurlParams!.minSats) {
        _showSnackBar("Minimum amount is ${_lnurlParams!.minSats} sats");
        return;
      }
      if (amountSats > _lnurlParams!.maxSats) {
        _showSnackBar("Maximum amount is ${_lnurlParams!.maxSats} sats");
        return;
      }
    }

    final address = _addressController.text;
    final amountSats = amount.round();
    final isLightning = _isLightningInvoice(address);

    // Suppress payment notifications during send to avoid showing "payment received"
    // when change from the outgoing transaction is detected
    PaymentOverlayService().startSuppression();

    // Stop suppression after a delay to allow change transaction to settle
    Future.delayed(const Duration(seconds: 10), () {
      PaymentOverlayService().stopSuppression();
    });

    // For Lightning payments, we still need to wait (they're fast)
    // For onchain/Ark sends, use background processing
    if (isLightning || _lnurlParams?.callback != null) {
      // Lightning payments - keep the old synchronous flow (they're fast)
      await _handleLightningPayment(address, amountSats);
    } else {
      // Onchain/Ark sends - use background processing for better UX
      await _handleBackgroundSend(address, amountSats);
    }
  }

  /// Handle Lightning payments synchronously (they're fast)
  Future<void> _handleLightningPayment(String address, int amountSats) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isLoading = true;
    });

    try {
      String? invoiceToPaymentRequest;

      // If we have an LNURL callback, fetch the invoice first
      if (_lnurlParams?.callback != null) {
        logger.i("Fetching invoice from LNURL callback...");
        final invoiceResult = await LnurlService.requestInvoice(
          _lnurlParams!.callback,
          amountSats,
        );

        if (invoiceResult == null) {
          throw Exception("Failed to get invoice from LNURL service");
        }

        invoiceToPaymentRequest = invoiceResult.pr;
        logger.i(
            "Got invoice from LNURL: ${invoiceToPaymentRequest.substring(0, 30)}...");
      }

      if (invoiceToPaymentRequest != null) {
        // Pay the LNURL-generated invoice via submarine swap
        logger.i("Paying LNURL invoice via submarine swap...");
        final result = await payLnInvoice(invoice: invoiceToPaymentRequest);
        logger.i("LNURL payment successful! TXID: ${result.txid}");
      } else {
        // Pay Lightning invoice via submarine swap
        logger.i("Paying Lightning invoice: ${address.substring(0, 20)}...");
        final result = await payLnInvoice(invoice: address);
        logger.i("Lightning payment successful! TXID: ${result.txid}");
      }

      // Return to wallet and show success
      if (mounted) {
        _unfocusAll();
        Navigator.of(context).popUntil((route) => route.isFirst);
        OverlayService().showSuccess('Lightning payment sent!');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        OverlayService().showError('${l10n.transactionFailed} ${e.toString()}');
      }
    }
  }

  /// Handle onchain/Ark sends in the background for better UX
  Future<void> _handleBackgroundSend(String address, int amountSats) async {
    logger.i("Starting background send to $address for $amountSats sats");

    // Add pending transaction and start background send
    await PendingTransactionService().addPendingTransaction(
      address: address,
      amountSats: amountSats,
      sendFunction: () async {
        logger.i("Background: Executing send to $address for $amountSats sats");
        final txid = await send(
          address: address,
          amountSats: BigInt.from(amountSats),
        );
        logger.i("Background: Send completed with txid: $txid");
        return txid;
      },
    );

    // Return to wallet immediately - the send continues in background
    if (mounted) {
      _unfocusAll();
      Navigator.of(context).popUntil((route) => route.isFirst);
      // Show a subtle notification that send is in progress
      OverlayService().showSuccess('Sending transaction...');
    }
  }

  void _showSnackBar(String message) {
    OverlayService().showError(message);
  }

  void _copyAddress() {
    if (_addressController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _addressController.text));
      _showCopiedSnackBar();
    }
  }

  void _showCopiedSnackBar() {
    OverlayService()
        .showSuccess(AppLocalizations.of(context)!.walletAddressCopied);
  }

  /// Truncates an address for display (shows first 10 and last 10 chars)
  String _truncateAddress(String address) {
    if (address.length <= 24) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 10)}';
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
      _addressError = null;
      _description = null;
      _isAddressExpanded = true;
      _expandController.forward();
    });
  }

  /// Unfocus all text fields to dismiss keyboard
  void _unfocusAll() {
    _amountFocusNode.unfocus();
    _addressFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      resizeToAvoidBottomInset: false,
      appBar: BitNetAppBar(
        context: context,
        text: l10n.sendBitcoin,
        hasBackButton: true,
        onTap: () {
          _unfocusAll();
          Navigator.pop(context);
        },
        buttonType: ButtonType.transparent,
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            _unfocusAll();
          }
        },
        child: _buildSendContent(context),
      ),
    );
  }

  Widget _buildSendContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Add top padding to account for app bar when extendBodyBehindAppBar is true
    const topPadding = kToolbarHeight;

    return Padding(
      padding: const EdgeInsets.only(top: topPadding + AppTheme.elementSpacing),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                          // Available balance display
                          const SizedBox(height: AppTheme.cardPadding),
                          _buildAvailableBalance(context, l10n),
                          // Transaction details preview
                          const SizedBox(height: AppTheme.cardPadding),
                          _buildTransactionDetails(context, l10n),
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
        horizontal: AppTheme.cardPadding,
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
                        _addressError != null
                            ? _addressError!
                            : _hasValidAddress
                                ? (_isLightningPayment
                                    ? 'Lightning'
                                    : l10n.recipient)
                                : l10n.unknown,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: _addressError != null
                                  ? AppTheme.errorColor
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      // Address display with copy - masked for PostHog
                      if (_hasValidAddress)
                        PostHogMaskWidget(
                          child: GestureDetector(
                            onTap: _copyAddress,
                            child: Row(
                              children: [
                                Icon(
                                  CupertinoIcons.doc_on_doc,
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
                          ? CupertinoIcons.chevron_up
                          : CupertinoIcons.pencil,
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
                    child: PostHogMaskWidget(
                      child: TextField(
                        controller: _addressController,
                        focusNode: _addressFocusNode,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface),
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.cardPadding,
                            vertical: AppTheme.elementSpacing,
                          ),
                          hintText: l10n.bitcoinOrArkAddress,
                          hintStyle:
                              TextStyle(color: Theme.of(context).hintColor),
                          suffixIcon: _addressController.text.isNotEmpty
                              ? IconButton(
                                  icon: Icon(
                                    Icons.close_rounded,
                                    color: Theme.of(context).hintColor,
                                    size: 20,
                                  ),
                                  onPressed: () {
                                    _addressController.clear();
                                    // Listener will call _onAddressChanged()
                                  },
                                )
                              : null,
                        ),
                      ),
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
            bitcoinPrice: _bitcoinPrice ?? 0,
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
    // formatAmount already converts from USD, so don't multiply by fiatRate
    final fiatAvailable = _bitcoinPrice != null
        ? currencyService.formatAmount(
            (widget.availableSats / BitcoinConstants.satsPerBtc) *
                _bitcoinPrice!)
        : '\$0.00';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
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

  Widget _buildTransactionDetails(BuildContext context, AppLocalizations l10n) {
    final amountSats = double.tryParse(_satController.text) ?? 0;
    if (!_hasValidAddress || amountSats <= 0) {
      return const SizedBox.shrink();
    }

    // Calculate network fees based on address type
    int networkFees;
    if (_isOnChainAddress) {
      networkFees = _estimatedNetworkFeeSats;
    } else if (_isLightningPayment) {
      networkFees = _calculateBoltzFee(amountSats);
    } else {
      networkFees = 0; // Ark payments have no fees
    }
    final total = amountSats.toInt() + networkFees;

    // Fee display text
    String feeText;
    if (_isOnChainAddress) {
      if (_isFetchingFees) {
        feeText = '...';
      } else if (_recommendedFees != null) {
        feeText = '~$networkFees SATS';
      } else {
        feeText = '? SATS';
      }
    } else if (_isLightningPayment) {
      feeText = '~$networkFees SATS (${_boltzFeePercent}%)';
    } else {
      feeText = '0 SATS';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: AppTheme.cardRadiusSmall,
        padding: const EdgeInsets.all(AppTheme.elementSpacing),
        child: Column(
          children: [
            // Address row
            ArkListTile(
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing * 0.75,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              text: l10n.address,
              trailing: Text(
                _truncateAddress(_addressController.text),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            // Amount row
            ArkListTile(
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing * 0.75,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              text: l10n.amount,
              trailing: Text(
                '${amountSats.toInt()} SATS',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            // Network Fees row
            ArkListTile(
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing * 0.75,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              text: l10n.networkFees,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isOnChainAddress && _isFetchingFees)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  Text(
                    feeText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
            // Total row
            ArkListTile(
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing * 0.75,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              text: l10n.total,
              trailing: Text(
                _isFetchingFees ? '...' : '$total SATS',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
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
    final amountSats = double.tryParse(_satController.text) ?? 0;
    final hasInsufficientFunds = amountSats > widget.availableSats;
    final canSend = _hasValidAddress &&
        amountSats > 0 &&
        !hasInsufficientFunds &&
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
                  Theme.of(context)
                      .scaffoldBackgroundColor
                      .withValues(alpha: 0.0),
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          // Show quick action buttons when no valid address, otherwise show send button
          Container(
            width: double.infinity,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.only(
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              bottom: AppTheme.cardPadding,
            ),
            child: _hasValidAddress
                ? _buildSendButtonContent(
                    context, l10n, canSend, hasInsufficientFunds)
                : _buildQuickActionButtons(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSendButtonContent(
    BuildContext context,
    AppLocalizations l10n,
    bool canSend,
    bool hasInsufficientFunds,
  ) {
    return GestureDetector(
      onTap: canSend ? _handleSend : null,
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
          color: canSend
              ? null
              : Theme.of(context)
                  .colorScheme
                  .secondary
                  .withValues(alpha: hasInsufficientFunds ? 0.5 : 1.0),
          borderRadius: AppTheme.cardRadiusBig,
          boxShadow: canSend
              ? [
                  BoxShadow(
                    color: AppTheme.colorBitcoin.withValues(alpha: 0.4),
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
                  hasInsufficientFunds ? l10n.notEnoughFunds : l10n.sendNow,
                  style: TextStyle(
                    color: canSend ? Colors.black : Theme.of(context).hintColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? AppTheme.white90 : AppTheme.black90;
    const buttonSize = 56.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side buttons: Image, QR Scan, Paste
        Row(
          children: [
            // Image/Gallery button
            _buildQuickActionButton(
              icon: CupertinoIcons.photo_fill,
              onTap: _pickImageAndScan,
              iconColor: iconColor,
              size: buttonSize,
            ),
            const SizedBox(width: AppTheme.elementSpacing),
            // QR Scan button
            _buildQuickActionButton(
              icon: CupertinoIcons.qrcode_viewfinder,
              onTap: _handleQRScan,
              iconColor: iconColor,
              size: buttonSize,
            ),
            const SizedBox(width: AppTheme.elementSpacing),
            // Paste button
            _buildQuickActionButton(
              icon: CupertinoIcons.doc_on_clipboard_fill,
              onTap: _pasteFromClipboard,
              iconColor: iconColor,
              size: buttonSize,
            ),
          ],
        ),
        // Right side: Close button
        _buildQuickActionButton(
          icon: CupertinoIcons.xmark,
          onTap: () => Navigator.pop(context),
          iconColor: iconColor,
          size: buttonSize,
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color iconColor,
    required double size,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(size / 2),
        ),
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
