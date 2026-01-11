import 'dart:async';

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
import 'package:ark_flutter/src/services/payment_monitoring_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/services/pending_transaction_service.dart';
import 'package:ark_flutter/src/services/recipient_storage_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/amount_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/theme.dart';
import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:provider/provider.dart';

/// SendScreen - BitNet-style send interface with Provider state management
/// Combines the visual design from the BitNet project with the Ark functionality
class SendScreen extends StatefulWidget {
  final String aspId;
  final double availableSats;
  final String? initialAddress;
  final bool fromClipboard;
  final double? bitcoinPrice; // Pass cached price to avoid network delay

  const SendScreen({
    super.key,
    required this.aspId,
    required this.availableSats,
    this.initialAddress,
    this.fromClipboard = false,
    this.bitcoinPrice,
  });

  @override
  SendScreenState createState() => SendScreenState();
}

class SendScreenState extends State<SendScreen> {
  // Controllers
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _btcController = TextEditingController();
  final TextEditingController _satController = TextEditingController();
  final TextEditingController _currController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _addressFocusNode = FocusNode();

  // State
  bool _isLoading = false;
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

  // Minimum sats for Lightning payments (Boltz minimum)
  static const int _minLightningSats = 333;

  // LNURL state
  LnurlPayParams? _lnurlParams;
  bool _isFetchingLnurl = false;

  // BIP21 multi-network support
  Map<String, String> _availableNetworks = {}; // network name -> address
  String? _selectedNetwork;

  // Amount locked state (when amount comes from Lightning invoice)
  bool _isAmountLocked = false;

  // Zero-amount Lightning invoice (not supported by SDK)
  bool _isZeroAmountLightningInvoice = false;

  // Amount input state (tracks whether showing fiat or bitcoin)
  String _amountInputState = 'sats'; // 'sats', 'bitcoin', or 'currency'

  // Debounce timer for address changes (prevents heavy processing on every keystroke)
  Timer? _addressChangeTimer;

  @override
  void initState() {
    super.initState();
    logger.i("SendScreen initialized with ASP ID: ${widget.aspId}");

    // Initialize controllers as empty - hint text will show "0"
    _satController.text = '';
    _btcController.text = '';
    _currController.text = '';

    // Use passed bitcoin price immediately if available (avoids network delay)
    if (widget.bitcoinPrice != null && widget.bitcoinPrice! > 0) {
      _bitcoinPrice = widget.bitcoinPrice;
    }

    // Listen to address changes
    _addressController.addListener(_onAddressChanged);

    // Set initial address if provided (e.g., from QR scan or recipient search)
    if (widget.initialAddress != null && widget.initialAddress!.isNotEmpty) {
      _addressController.text = widget.initialAddress!;
      // Process address synchronously - don't wait for post-frame callback
      // This parses the invoice and sets sats/btc/fiat values immediately
      _processAddressChange();
      // Request focus after first frame (if amount not locked)
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_isAmountLocked && mounted) {
          _amountFocusNode.requestFocus();
        }
      });
    }

    // Fetch fresh bitcoin price in background (updates if different from cached)
    _fetchBitcoinPrice();
  }

  @override
  void dispose() {
    _addressChangeTimer?.cancel();
    _addressController.removeListener(_onAddressChanged);
    _addressController.dispose();
    _btcController.dispose();
    _satController.dispose();
    _currController.dispose();
    _amountFocusNode.dispose();
    _addressFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchBitcoinPrice() async {
    try {
      final priceData = await fetchBitcoinPriceData(TimeRange.day);
      if (priceData.isNotEmpty && mounted) {
        setState(() {
          _bitcoinPrice = priceData.last.price;
        });
        // Update fiat controller after widget rebuilds (so enabled state is synced)
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _updateFiatFromSats();
        });
      }
    } catch (e) {
      logger.e('Error fetching bitcoin price: $e');
    }
  }

  /// Update the fiat controller based on current sats value
  void _updateFiatFromSats() {
    if (_bitcoinPrice == null) return;
    final sats = int.tryParse(_satController.text) ?? 0;
    if (sats > 0) {
      final btcAmount = sats / BitcoinConstants.satsPerBtc;
      final currencyService = context.read<CurrencyPreferenceService>();
      final exchangeRates = currencyService.exchangeRates;
      final fiatRate = exchangeRates?.rates[currencyService.code] ?? 1.0;
      final fiatAmount = btcAmount * _bitcoinPrice! * fiatRate;
      _currController.text = fiatAmount.toStringAsFixed(2);
    }
  }

  /// Debounced address change handler - delays processing until user stops typing
  void _onAddressChanged() {
    _addressChangeTimer?.cancel();
    _addressChangeTimer =
        Timer(const Duration(milliseconds: 300), _processAddressChange);
  }

  /// Process address changes (validation, LNURL fetching, fee fetching)
  /// Called after debounce delay to avoid processing on every keystroke
  void _processAddressChange() {
    final text = _addressController.text.trim();
    final validationResult = AddressValidator.validate(text);
    final isValid = validationResult.isValid;

    // If it looks like a complete invoice/URI with an amount, parse it
    // Only parse if the amount field is empty/zero to avoid overwriting user input
    // Check for URI patterns, Lightning invoices, or Arkade addresses with query params
    final isUri = text.toLowerCase().startsWith('bitcoin:') ||
        text.toLowerCase().startsWith('lightning:');
    final isArkadeWithAmount =
        (text.startsWith('ark1') || text.startsWith('tark1')) &&
            text.contains('?amount=');
    final isLightningInvoice = _isLightningInvoice(text);
    final amountIsDefault =
        _satController.text.isEmpty || _satController.text == '0';
    if (isValid &&
        (isUri || isLightningInvoice || isArkadeWithAmount) &&
        amountIsDefault) {
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
      // Reset zero-amount invoice flag if address is not a Lightning invoice
      // (it will be set by _tryParseAmountFromAddress if needed)
      if (!isLightningInvoice && !isUri) {
        _isZeroAmountLightningInvoice = false;
        _isAmountLocked = false;
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
          // Don't auto-fill amount - let user enter it manually (like Ark addresses)
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
  /// Also extracts all available networks for BIP21 URIs and selects the best one
  void _tryParseAmountFromAddress(String text) {
    int? amount;
    String address = text;
    bool addressExtracted = false;
    Map<String, String> networks = {};
    String? selectedNetwork;

    // Handle Lightning URI (lightning:lnbc...)
    if (text.toLowerCase().startsWith('lightning:')) {
      address = text.substring(10);
      addressExtracted = true;
      networks['Lightning'] = address;
      selectedNetwork = 'Lightning';
    }
    // Handle Arkade address with amount query param (ark1...?amount=0.0001)
    else if ((text.startsWith('ark1') || text.startsWith('tark1')) &&
        text.contains('?')) {
      final parts = text.split('?');
      address = parts[0];
      addressExtracted = true;
      networks['Arkade'] = address;
      selectedNetwork = 'Arkade';

      // Parse amount from query string
      if (parts.length > 1) {
        final queryString = parts[1];
        final params = Uri.splitQueryString(queryString);
        if (params.containsKey('amount')) {
          final btcAmount = double.tryParse(params['amount'] ?? '');
          if (btcAmount != null) {
            amount = (btcAmount * BitcoinConstants.satsPerBtc).round();
            logger.i("Extracted amount from Arkade address: $amount sats");
          }
        }
      }
    }
    // Parse BIP21 URI for amount and all available networks
    else if (text.toLowerCase().startsWith('bitcoin:')) {
      final uri = Uri.tryParse(text);
      if (uri != null) {
        // Extract all available addresses
        if (uri.path.isNotEmpty) {
          networks['Onchain'] = uri.path;
        }
        if (uri.queryParameters.containsKey('lightning')) {
          networks['Lightning'] = uri.queryParameters['lightning']!;
        }
        if (uri.queryParameters.containsKey('ark')) {
          networks['Arkade'] = uri.queryParameters['ark']!;
        } else if (uri.queryParameters.containsKey('arkade')) {
          networks['Arkade'] = uri.queryParameters['arkade']!;
        }

        // Priority order for address selection (lower fees first):
        // 1. Ark address (lowest fees)
        // 2. Lightning invoice
        // 3. Bitcoin address (highest fees)
        if (networks.containsKey('Arkade')) {
          address = networks['Arkade']!;
          selectedNetwork = 'Arkade';
          logger.i("Using Ark address from BIP21 for lower fees");
        } else if (networks.containsKey('Lightning')) {
          address = networks['Lightning']!;
          selectedNetwork = 'Lightning';
          logger.i("Using Lightning address from BIP21");
        } else if (networks.containsKey('Onchain')) {
          address = networks['Onchain']!;
          selectedNetwork = 'Onchain';
        }
        addressExtracted = true;

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
    bool amountFromInvoice = false;
    bool isZeroAmountInvoice = false;
    if (_isLightningInvoice(address) && amount == null) {
      try {
        final invoice = Bolt11PaymentRequest(address);
        final btcAmount = invoice.amount.toDouble();
        if (btcAmount > 0) {
          amount = (btcAmount * BitcoinConstants.satsPerBtc).round();
          amountFromInvoice = true;
          logger.i(
              "Extracted amount from Lightning invoice: $amount sats (locked)");
        } else {
          // Zero-amount invoice - NOT SUPPORTED by SDK
          // The Ark SDK's Boltz submarine swap implementation only reads amount from the invoice
          isZeroAmountInvoice = true;
          logger.w(
              "Zero-amount Lightning invoice detected - NOT SUPPORTED by SDK");
        }
      } catch (e) {
        // Ignore parse errors for incomplete invoices
      }
    }

    // Store available networks for switching
    setState(() {
      _availableNetworks = networks;
      _selectedNetwork = selectedNetwork;
      // Lock amount if it came from a Lightning invoice with amount (can't be changed)
      _isAmountLocked = amountFromInvoice;
      // Track zero-amount invoices (not supported by SDK)
      _isZeroAmountLightningInvoice = isZeroAmountInvoice;
    });

    // Update address controller if we extracted a better address
    if (addressExtracted && address != text) {
      _addressController.text = address;
    }

    // Update amount fields if we extracted an amount
    if (amount != null && amount > 0) {
      final btcAmount = amount / BitcoinConstants.satsPerBtc;
      _satController.text = amount.toString();
      _btcController.text = btcAmount.toStringAsFixed(8);
      // Also set fiat controller so it works when user is in fiat mode
      _updateFiatFromSats();
    }
  }

  /// Switch to a different network from available BIP21 options
  void _switchNetwork(String network) {
    if (_availableNetworks.containsKey(network)) {
      final newAddress = _availableNetworks[network]!;
      setState(() {
        _selectedNetwork = network;
        _addressController.text = newAddress;
      });
      // Re-validate and update state
      _onAddressChanged();
      logger
          .i("Switched to $network network: ${newAddress.substring(0, 20)}...");
    }
  }

  /// Get the current network name based on address type
  String _getCurrentNetworkName() {
    if (_selectedNetwork != null) {
      return _selectedNetwork!;
    }
    final address = _addressController.text.trim();
    if (_isLightningInvoice(address) || _isLnurlOrLightningAddress(address)) {
      return 'Lightning';
    } else if (_isOnChainBitcoinAddress(address)) {
      return 'Onchain';
    } else if (_hasValidAddress) {
      return 'Arkade';
    }
    return 'Unknown';
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
    // Use ceil() to be conservative and match _getEstimatedFees()
    final feeRate = _recommendedFees!.halfHourFee;
    return (feeRate * _estimatedTxVbytes).ceil();
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

    // Calculate fees to include in balance check
    int fees = 0;
    if (_isOnChainAddress) {
      fees = _estimatedNetworkFeeSats;
    } else if (_isLightningPayment) {
      fees = _calculateBoltzFee(amount);
    }

    if (amount + fees > widget.availableSats) {
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

      String? txid;
      if (invoiceToPaymentRequest != null) {
        // Pay the LNURL-generated invoice via submarine swap
        logger.i("Paying LNURL invoice via submarine swap...");
        final result = await payLnInvoice(invoice: invoiceToPaymentRequest);
        txid = result.txid;
        logger.i("LNURL payment successful! TXID: $txid");
      } else {
        // Pay Lightning invoice via submarine swap
        logger.i("Paying Lightning invoice: ${address.substring(0, 20)}...");
        final result = await payLnInvoice(invoice: address);
        txid = result.txid;
        logger.i("Lightning payment successful! TXID: $txid");
      }

      // Save recipient for future use
      // For LNURL, save the original address (reusable)
      // For direct invoice, save as non-reusable
      final recipientAddress = _lnurlParams?.callback != null
          ? _addressController.text // Original LNURL/Lightning Address
          : address;
      final recipientType = _lnurlParams?.callback != null
          ? RecipientType.lightning
          : RecipientType.lightningInvoice;
      await RecipientStorageService.saveRecipient(
        address: recipientAddress,
        type: recipientType,
        amountSats: amountSats,
        txid: txid,
      );

      // Return to wallet and show success bottom sheet
      if (mounted) {
        _unfocusAll();
        Navigator.of(context).popUntil((route) => route.isFirst);

        // Trigger wallet refresh to show the new transaction
        PaymentMonitoringService().triggerWalletRefresh();

        // Show proper success bottom sheet with bani
        PendingTransactionService().showSuccessBottomSheet(
          address: address,
          amountSats: amountSats,
          txid: txid,
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        // Show proper error bottom sheet
        PendingTransactionService().showErrorBottomSheet(
          address: address,
          amountSats: amountSats,
          errorMessage: e.toString(),
        );
      }
    }
  }

  /// Handle onchain/Ark sends in the background for better UX
  Future<void> _handleBackgroundSend(String address, int amountSats) async {
    logger.i("Starting background send to $address for $amountSats sats");

    // Determine recipient type
    final recipientType = RecipientStorageService.determineType(address);

    // Save recipient before starting (so we have it even if tx fails for retry)
    await RecipientStorageService.saveRecipient(
      address: address,
      type: recipientType,
      amountSats: amountSats,
    );

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

        // Update recipient with txid on success
        await RecipientStorageService.updateRecipientTxid(address, txid);

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

  /// Truncates an address for display (shows first 10 and last 8 chars)
  String _truncateAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
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
      resizeToAvoidBottomInset: true,
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
                          const SizedBox(height: AppTheme.cardPadding * 1.25),
                          // Bitcoin amount widget
                          Center(
                            child: _buildBitcoinWidget(context),
                          ),
                          const SizedBox(height: AppTheme.cardPadding * 1.25),
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
                          // Available balance display (hide when amount is locked from invoice)
                          if (!_isAmountLocked)
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
        horizontal: AppTheme.cardPadding,
      ),
      child: Row(
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
                Row(
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
                    // Show "from clipboard" indicator
                    if (widget.fromClipboard && _hasValidAddress) ...[
                      const SizedBox(width: AppTheme.elementSpacing / 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .hintColor
                              .withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          l10n.fromClipboard,
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: Theme.of(context).hintColor,
                                  ),
                        ),
                      ),
                    ],
                  ],
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
                          Text(
                            _truncateAddress(_addressController.text),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context).hintColor,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Text(
                    l10n.recipientAddress,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
              ],
            ),
          ),
          // Edit button - go back to recipient search screen
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _unfocusAll();
              Navigator.pop(context);
            },
            child: Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              child: Icon(
                CupertinoIcons.pencil,
                color: Theme.of(context).hintColor,
                size: AppTheme.cardPadding,
              ),
            ),
          ),
        ],
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
            enabled: () => !_isAmountLocked,
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
            onInputStateChange: (inputState) {
              setState(() {
                _amountInputState = inputState;
              });
            },
          ),
          // Show locked indicator when amount is from invoice
          if (_isAmountLocked)
            Padding(
              padding: const EdgeInsets.only(
                  top: AppTheme.elementSpacing / 2, left: AppTheme.cardPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    CupertinoIcons.lock_fill,
                    size: 12,
                    color: Theme.of(context).hintColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Amount set by invoice',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Calculate estimated fees for the current network type
  /// Used by Max button to calculate maximum sendable amount
  int _getEstimatedFees() {
    final currentNetwork = _getCurrentNetworkName();
    switch (currentNetwork) {
      case 'Arkade':
        // Ark has no fees
        return 0;
      case 'Lightning':
        // Lightning via Boltz: 0.25% swap fee
        // To find max amount: amount + fee = balance, where fee = amount * 0.0025
        // So: amount * 1.0025 = balance => amount = balance / 1.0025
        // Use floor() for maxAmount to be conservative, then verify with actual fee calc
        final maxAmount =
            (widget.availableSats / (1 + _boltzFeePercent / 100)).floor();
        // Calculate what the actual fee would be (using same rounding as _calculateBoltzFee)
        final actualFee = (maxAmount * _boltzFeePercent / 100).round();
        // If total exceeds balance due to rounding edge case, add 1 to fee
        if (maxAmount + actualFee > widget.availableSats) {
          return actualFee + 1;
        }
        return actualFee;
      case 'Onchain':
        // On-chain: use the same getter as fee display for consistency
        // Use ceil() to be conservative and avoid 1 sat shortfall
        if (_recommendedFees == null) {
          // If fees haven't loaded yet, use conservative estimate
          return (_estimatedTxVbytes * 10.0).ceil();
        }
        // Use ceil() instead of round() to ensure we never underestimate
        return (_estimatedTxVbytes * _recommendedFees!.halfHourFee).ceil();
      default:
        return 0;
    }
  }

  void _setMaxAmount() {
    final estimatedFees = _getEstimatedFees();
    final maxSats = (widget.availableSats - estimatedFees).floor();
    final safeMax = maxSats > 0 ? maxSats : 0;

    // Calculate all values from sats (source of truth)
    final btcAmount = safeMax / BitcoinConstants.satsPerBtc;

    // Calculate fiat from sats for display
    double fiatAmount = 0;
    if (_bitcoinPrice != null) {
      final currencyService = context.read<CurrencyPreferenceService>();
      final exchangeRates = currencyService.exchangeRates;
      final fiatRate = exchangeRates?.rates[currencyService.code] ?? 1.0;
      fiatAmount = btcAmount * _bitcoinPrice! * fiatRate;
    }

    setState(() {
      // Set all controllers - sats is the authoritative source
      _satController.text = safeMax.toString();
      _btcController.text = btcAmount.toStringAsFixed(8);
      _currController.text = fiatAmount.toStringAsFixed(2);
    });
  }

  Widget _buildAvailableBalance(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final currencyService = context.watch<CurrencyPreferenceService>();

    // Format available balance based on current input state
    String availableDisplay;
    if (_amountInputState == 'currency') {
      // Show in fiat
      availableDisplay = _bitcoinPrice != null
          ? currencyService.formatAmount(
              (widget.availableSats / BitcoinConstants.satsPerBtc) *
                  _bitcoinPrice!)
          : '\$0.00';
    } else if (_amountInputState == 'bitcoin') {
      // Show in BTC
      final btcAvailable = widget.availableSats / BitcoinConstants.satsPerBtc;
      availableDisplay = '${btcAvailable.toStringAsFixed(8)} BTC';
    } else {
      // Show in sats (default)
      availableDisplay = '${widget.availableSats.toStringAsFixed(0)} sats';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${l10n.available}: ',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                ),
          ),
          Text(
            availableDisplay,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          // Hide Max button when amount is locked from invoice
          if (!_isAmountLocked) ...[
            const SizedBox(width: AppTheme.elementSpacing),
            GestureDetector(
              onTap: _setMaxAmount,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                // Extra padding around the button for larger hit area
                padding: const EdgeInsets.all(AppTheme.elementSpacing / 2),
                child: GlassContainer(
                  opacity: 0.1,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.elementSpacing * 1.25,
                    vertical: AppTheme.elementSpacing / 2,
                  ),
                  child: Text(
                    'Max',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionDetails(BuildContext context, AppLocalizations l10n) {
    final amountSats = double.tryParse(_satController.text) ?? 0;
    final hasAmount = amountSats > 0;

    // Calculate network fees based on address type (only if we have an amount)
    int networkFees = 0;
    if (hasAmount) {
      if (_isOnChainAddress) {
        networkFees = _estimatedNetworkFeeSats;
      } else if (_isLightningPayment) {
        networkFees = _calculateBoltzFee(amountSats);
      } else {
        networkFees = 0; // Ark payments have no fees
      }
    }
    final total = amountSats.toInt() + networkFees;

    // Fee display text (only show if we have an amount)
    String? feeText;
    if (hasAmount) {
      if (_isOnChainAddress) {
        if (_isFetchingFees) {
          feeText = '...';
        } else if (_recommendedFees != null) {
          feeText = '~$networkFees sats';
        } else {
          feeText = '? sats';
        }
      } else if (_isLightningPayment) {
        feeText = '~$networkFees sats';
      } else {
        feeText = '0 sats';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
      child: GlassContainer(
        opacity: 0.05,
        borderRadius: AppTheme.cardRadiusSmall,
        padding: const EdgeInsets.all(AppTheme.elementSpacing),
        child: Column(
          children: [
            // Address row - always show
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
            // Amount row - show empty if no amount
            ArkListTile(
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing * 0.75,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              text: l10n.amount,
              trailing: Text(
                hasAmount ? '${amountSats.toInt()} sats' : '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            // Network row - always show
            _buildNetworkRow(context, l10n),
            // Network Fees row - show empty if no amount
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
                  if (hasAmount && _isOnChainAddress && _isFetchingFees)
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
                    feeText ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                ],
              ),
            ),
            // Total row - show empty if no amount
            ArkListTile(
              margin: EdgeInsets.zero,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing * 0.75,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              text: l10n.total,
              trailing: Text(
                hasAmount ? (_isFetchingFees ? '...' : '$total sats') : '',
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

  Widget _buildNetworkRow(BuildContext context, AppLocalizations l10n) {
    final currentNetwork = _getCurrentNetworkName();
    final hasMultipleNetworks = _availableNetworks.length > 1;

    return ArkListTile(
      margin: EdgeInsets.zero,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppTheme.elementSpacing * 0.75,
        vertical: AppTheme.elementSpacing * 0.5,
      ),
      text: l10n.network,
      trailing: hasMultipleNetworks
          ? GlassContainer(
              opacity: 0.05,
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing,
                vertical: AppTheme.elementSpacing / 2,
              ),
              child: GestureDetector(
                onTap: () => _showNetworkPicker(context),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getNetworkIcon(currentNetwork),
                      size: AppTheme.cardPadding * 0.75,
                      color: Theme.of(context).hintColor,
                    ),
                    const SizedBox(width: AppTheme.elementSpacing / 2),
                    Text(
                      currentNetwork,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getNetworkIcon(currentNetwork),
                  size: AppTheme.cardPadding * 0.75,
                  color: Theme.of(context).hintColor,
                ),
                const SizedBox(width: AppTheme.elementSpacing / 2),
                Text(
                  currentNetwork,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
      onTap: hasMultipleNetworks ? () => _showNetworkPicker(context) : null,
    );
  }

  void _showNetworkPicker(BuildContext context) {
    final networks = _availableNetworks.keys.toList();
    // Sort: Ark first, then Lightning, then Bitcoin
    networks.sort((a, b) {
      const order = {'Arkade': 0, 'Lightning': 1, 'Onchain': 2};
      return (order[a] ?? 3).compareTo(order[b] ?? 3);
    });

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.45,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ArkScaffold(
        context: context,
        appBar: BitNetAppBar(
          context: context,
          hasBackButton: false,
          text: AppLocalizations.of(context)!.selectNetwork,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.elementSpacing,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: networks.map((network) {
              final isSelected = _selectedNetwork == network;
              final feeHint = _getNetworkFeeHint(network);

              return ArkListTile(
                text: network,
                subtitle: Text(
                  feeHint,
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
                selected: isSelected,
                leading: RoundedButtonWidget(
                  buttonType: ButtonType.transparent,
                  iconData: _getNetworkIcon(network),
                  size: AppTheme.cardPadding * 1.25,
                  onTap: () {
                    Navigator.of(context).pop();
                    _switchNetwork(network);
                  },
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _switchNetwork(network);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  IconData _getNetworkIcon(String network) {
    switch (network) {
      case 'Lightning':
        return FontAwesomeIcons.bolt;
      case 'Onchain':
        return FontAwesomeIcons.link;
      case 'Arkade':
        return FontAwesomeIcons.spaceAwesome;
      default:
        return FontAwesomeIcons.question;
    }
  }

  String _getNetworkFeeHint(String network) {
    switch (network) {
      case 'Arkade':
        return 'Instant, no fees';
      case 'Lightning':
        return '~0.25% swap fee';
      case 'Onchain':
        return 'On-chain fees apply';
      default:
        return '';
    }
  }

  void _showConfirmationSheet() {
    final l10n = AppLocalizations.of(context)!;
    final amountSats = double.tryParse(_satController.text) ?? 0;

    // Calculate network fees based on address type
    int networkFees = 0;
    if (amountSats > 0) {
      if (_isOnChainAddress) {
        networkFees = _estimatedNetworkFeeSats;
      } else if (_isLightningPayment) {
        networkFees = _calculateBoltzFee(amountSats);
      } else {
        networkFees = 0; // Ark payments have no fees
      }
    }
    final total = amountSats.toInt() + networkFees;

    // Fee display text
    String feeText;
    if (_isOnChainAddress) {
      if (_isFetchingFees) {
        feeText = '...';
      } else if (_recommendedFees != null) {
        feeText = '~$networkFees sats';
      } else {
        feeText = '? sats';
      }
    } else if (_isLightningPayment) {
      feeText = '~$networkFees sats';
    } else {
      feeText = '0 sats';
    }

    final currentNetwork = _getCurrentNetworkName();
    final hasMultipleNetworks = _availableNetworks.length > 1;

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.55,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ArkScaffoldUnsafe(
        context: context,
        appBar: BitNetAppBar(
          context: context,
          hasBackButton: false,
          text: 'Confirm',
          transparent: false,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
          child: Column(
            children: [
              const SizedBox(height: AppTheme.cardPadding),
              // Transaction details
              GlassContainer(
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
                        '${amountSats.toInt()} sats',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ),
                    // Network row (with picker for BIP21)
                    ArkListTile(
                      margin: EdgeInsets.zero,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.elementSpacing * 0.75,
                        vertical: AppTheme.elementSpacing * 0.5,
                      ),
                      text: l10n.network,
                      trailing: hasMultipleNetworks
                          ? GestureDetector(
                              onTap: () {
                                Navigator.pop(context);
                                _showNetworkPicker(context);
                              },
                              child: GlassContainer(
                                opacity: 0.05,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppTheme.elementSpacing,
                                  vertical: AppTheme.elementSpacing / 2,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getNetworkIcon(currentNetwork),
                                      size: AppTheme.cardPadding * 0.75,
                                      color: Theme.of(context).hintColor,
                                    ),
                                    const SizedBox(
                                        width: AppTheme.elementSpacing / 2),
                                    Text(
                                      currentNetwork,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                    const SizedBox(
                                        width: AppTheme.elementSpacing / 2),
                                    Icon(
                                      Icons.keyboard_arrow_down,
                                      size: 16,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getNetworkIcon(currentNetwork),
                                  size: AppTheme.cardPadding * 0.75,
                                  color: Theme.of(context).hintColor,
                                ),
                                const SizedBox(
                                    width: AppTheme.elementSpacing / 2),
                                Text(
                                  currentNetwork,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface,
                                      ),
                                ),
                              ],
                            ),
                      onTap: hasMultipleNetworks
                          ? () {
                              Navigator.pop(context);
                              _showNetworkPicker(context);
                            }
                          : null,
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
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
                        _isFetchingFees ? '...' : '$total sats',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: LongButtonWidget(
                      buttonType: ButtonType.transparent,
                      title: l10n.cancel,
                      onTap: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: AppTheme.elementSpacing),
                  Expanded(
                    child: LongButtonWidget(
                      buttonType: ButtonType.solid,
                      title: 'Confirm',
                      onTap: () {
                        Navigator.pop(context);
                        _handleSend();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTheme.cardPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSendButton(
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final amountSats = double.tryParse(_satController.text) ?? 0;

    // Calculate network fees to include in balance check
    int networkFees = 0;
    if (amountSats > 0) {
      if (_isOnChainAddress) {
        networkFees = _estimatedNetworkFeeSats;
      } else if (_isLightningPayment) {
        networkFees = _calculateBoltzFee(amountSats);
      }
    }
    final totalWithFees = amountSats + networkFees;

    // Check if total (amount + fees) exceeds available balance
    final hasInsufficientFunds = totalWithFees > widget.availableSats;
    final isBelowLightningMinimum =
        _isLightningPayment && amountSats > 0 && amountSats < _minLightningSats;
    final canSend = _hasValidAddress &&
        amountSats > 0 &&
        !hasInsufficientFunds &&
        !isBelowLightningMinimum &&
        !_isZeroAmountLightningInvoice &&
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
          // Send button
          Container(
            width: double.infinity,
            color: Theme.of(context).scaffoldBackgroundColor,
            padding: const EdgeInsets.only(
              left: AppTheme.cardPadding,
              right: AppTheme.cardPadding,
              bottom: AppTheme.cardPadding,
            ),
            child: _buildSendButtonContent(
                context,
                l10n,
                canSend,
                hasInsufficientFunds,
                isBelowLightningMinimum,
                _isZeroAmountLightningInvoice),
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
    bool isBelowLightningMinimum,
    bool isZeroAmountInvoice,
  ) {
    // Determine button text based on state
    String buttonText;
    if (hasInsufficientFunds) {
      buttonText = l10n.notEnoughFunds;
    } else if (isBelowLightningMinimum) {
      buttonText = 'Minimum $_minLightningSats sats required';
    } else if (isZeroAmountInvoice) {
      buttonText = 'Zero-amount invoices not supported';
    } else {
      buttonText = l10n.sendNow;
    }

    final isDisabledState =
        hasInsufficientFunds || isBelowLightningMinimum || isZeroAmountInvoice;

    return GestureDetector(
      onTap: canSend ? _showConfirmationSheet : null,
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
                  .withValues(alpha: isDisabledState ? 0.5 : 1.0),
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
                      canSend
                          ? const Color(
                              0xFF1A0A00) // Dark brown/orange like button text
                          : Theme.of(context).hintColor,
                    ),
                  ),
                )
              : Text(
                  buttonText,
                  style: TextStyle(
                    color: canSend
                        ? const Color(0xFF1A0A00) // Dark brown/orange
                        : Theme.of(context).hintColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
