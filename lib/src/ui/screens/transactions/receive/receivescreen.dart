import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/bitcoin_price_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitcoin_chart/bitcoin_chart_card.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/amount_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/qr_border_painter.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:posthog_flutter/posthog_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Receive type enum for address display
enum ReceiveType { combined, ark, onchain, lightning }

class ReceiveScreen extends StatefulWidget {
  final String aspId;
  final int amount;

  const ReceiveScreen({
    super.key,
    required this.aspId,
    required this.amount,
  });

  @override
  State<ReceiveScreen> createState() => _ReceiveScreenState();
}

class _ReceiveScreenState extends State<ReceiveScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  // Address data
  String _bip21Address = "";
  String _btcAddress = "";
  String _arkAddress = "";
  String? _boltzSwapId;
  String? _lightningInvoice;
  String? _error;

  // Current receive type
  ReceiveType _receiveType = ReceiveType.combined;

  // Amount state
  int? _currentAmount;

  // Bitcoin price for conversion
  double? _bitcoinPrice;

  // Amount controllers
  final TextEditingController _btcController = TextEditingController();
  final TextEditingController _satController = TextEditingController();
  final TextEditingController _currController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  // Payment monitoring
  bool _waitingForPayment = false;

  // Copy feedback
  bool _showCopied = false;

  // Lightning invoice timer
  Timer? _invoiceTimer;
  Duration _invoiceDuration = const Duration(minutes: 5);
  String _timerMin = "05";
  String _timerSec = "00";

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Keyboard visibility tracking for unfocusing amount field
  bool _wasKeyboardVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _currentAmount = widget.amount >= 0 ? widget.amount : 0;

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _satController.text = _currentAmount?.toString() ?? "0";
    _btcController.text = "0.0";
    _currController.text = "0.0";

    _fetchAddresses();
    _fetchBitcoinPrice();
    _animationController.forward();
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
      logger.e("Failed to fetch Bitcoin price: $e");
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _invoiceTimer?.cancel();
    _animationController.dispose();
    _btcController.dispose();
    _satController.dispose();
    _currController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // App came back to foreground - restart payment monitoring after a small delay
      // to allow old connections to properly terminate
      logger.i("App resumed, will restart payment monitoring");
      _restartPaymentMonitoring();
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    // Detect keyboard dismiss and unfocus the amount field
    // This handles the case when AmountWidget is inside arkBottomSheet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;
      if (_wasKeyboardVisible && !keyboardVisible) {
        // Keyboard was just dismissed - unfocus amount field
        _amountFocusNode.unfocus();
      }
      _wasKeyboardVisible = keyboardVisible;
    });
  }

  Future<void> _restartPaymentMonitoring() async {
    // Only restart if we have addresses to monitor
    if (_arkAddress.isNotEmpty || _boltzSwapId != null) {
      // Small delay to let old connections terminate
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      setState(() {
        _waitingForPayment = false;
      });
      _startPaymentMonitoring();
    }
  }

  void _startInvoiceTimer() {
    _invoiceTimer?.cancel();
    _invoiceDuration = const Duration(minutes: 5);
    _updateTimerDisplay();

    _invoiceTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_invoiceDuration.inSeconds > 0) {
        setState(() {
          _invoiceDuration = _invoiceDuration - const Duration(seconds: 1);
          _updateTimerDisplay();
        });
      } else {
        timer.cancel();
        // Auto-refresh when timer expires
        if (_receiveType == ReceiveType.lightning && mounted) {
          _refreshLightningInvoice();
        }
      }
    });
  }

  void _updateTimerDisplay() {
    _timerMin = (_invoiceDuration.inMinutes % 60).toString().padLeft(2, '0');
    _timerSec = (_invoiceDuration.inSeconds % 60).toString().padLeft(2, '0');
  }

  void _refreshLightningInvoice() {
    _animationController.reset();
    _animationController.forward();
    _fetchLightningInvoice();
  }

  Future<void> _fetchAddresses({bool includeLightning = false}) async {
    setState(() {
      _error = null;
    });

    try {
      // Pass amount only when fetching Lightning invoice
      // (Rust API generates Lightning when amount is provided)
      final BigInt? amountSats = includeLightning && (_currentAmount ?? 0) > 0
          ? BigInt.from(_currentAmount!)
          : null;

      final addresses = await address(amount: amountSats);

      // Construct BIP21 with amount if set (for non-Lightning types)
      String bip21 = addresses.bip21;
      if (!includeLightning && (_currentAmount ?? 0) > 0) {
        // Add amount to BIP21 if not already present
        final amountBtc = _currentAmount! / 100000000.0;
        if (!bip21.contains('?')) {
          bip21 = '$bip21?amount=$amountBtc';
        } else if (!bip21.contains('amount=')) {
          bip21 = '$bip21&amount=$amountBtc';
        }
      }

      setState(() {
        _bip21Address = bip21;
        _arkAddress = addresses.offchain;
        _btcAddress = addresses.boarding;
        _boltzSwapId = addresses.lightning?.swapId;
        _lightningInvoice = addresses.lightning?.invoice;
      });

      // Start timer if we have a Lightning invoice
      if (_lightningInvoice != null && _lightningInvoice!.isNotEmpty) {
        _startInvoiceTimer();
      }

      _startPaymentMonitoring();
    } catch (e) {
      logger.e("Error fetching addresses: $e");
      setState(() {
        _error = e.toString();
      });
    }
  }

  // Default amount for Lightning invoices (Boltz minimum is 333 sats)
  static const int _defaultLightningAmount = 10000;

  // Boltz fee constants for reverse swaps (receiving Lightning)
  static const double _boltzServiceFeePercent = 0.25;
  static const int _boltzClaimFeeSats = 250;

  /// Calculate the gross invoice amount needed to receive a specific net amount
  /// Formula: Gross = (Net + ClaimFee) / (1 - ServiceFeePercent/100)
  int _calculateGrossAmount(int netAmount) {
    return ((netAmount + _boltzClaimFeeSats) /
            (1 - _boltzServiceFeePercent / 100))
        .ceil();
  }

  Future<void> _fetchLightningInvoice() async {
    try {
      // Boltz requires minimum 333 sats, use default if no amount set
      final int requestedAmount =
          (_currentAmount ?? 0) > 0 ? _currentAmount! : _defaultLightningAmount;

      // Calculate gross amount so receiver gets exactly what they requested
      // Sender covers the Boltz fees
      final int grossAmount = _calculateGrossAmount(requestedAmount);
      final BigInt amountSats = BigInt.from(grossAmount);
      final addresses = await address(amount: amountSats);

      setState(() {
        _boltzSwapId = addresses.lightning?.swapId;
        _lightningInvoice = addresses.lightning?.invoice;
      });

      if (_lightningInvoice != null && _lightningInvoice!.isNotEmpty) {
        _startInvoiceTimer();
      } else {
        OverlayService().showError("Lightning service temporarily unavailable");
        // Fall back to combined view
        setState(() {
          _receiveType = ReceiveType.combined;
        });
      }
    } catch (e) {
      logger.e("Error fetching Lightning invoice: $e");
      OverlayService()
          .showError("Lightning error: ${e.toString().split('\n').first}");
      // Fall back to combined view
      setState(() {
        _receiveType = ReceiveType.combined;
      });
    }
  }

  Future<void> _startPaymentMonitoring() async {
    if (_waitingForPayment) return;

    setState(() {
      _waitingForPayment = true;
    });

    try {
      logger.i("Started waiting for payment...");

      final payment = await waitForPayment(
        arkAddress: _arkAddress.isNotEmpty ? _arkAddress : null,
        boardingAddress: _btcAddress.isNotEmpty ? _btcAddress : null,
        boltzSwapId: _boltzSwapId,
        timeoutSeconds: BigInt.from(300),
      );

      if (!mounted) return;

      setState(() {
        _waitingForPayment = false;
      });

      logger.i(
          "Payment received! TXID: ${payment.txid}, Amount: ${payment.amountSats} sats");

      _showPaymentReceivedOverlay(payment);
    } catch (e) {
      logger.e("Error waiting for payment: $e");
      if (!mounted) return;

      setState(() {
        _waitingForPayment = false;
      });

      final errorStr = e.toString().toLowerCase();

      // Don't show snackbar for expected errors:
      // - Timeouts (expected when waiting)
      // - Connection errors (expected when app goes to background)
      final isExpectedError = errorStr.contains('timeout') ||
          errorStr.contains('transport error') ||
          errorStr.contains('connectionaborted') ||
          errorStr.contains('connection aborted') ||
          errorStr.contains('stream ended') ||
          errorStr.contains('h2 protocol error') ||
          errorStr.contains('canceled') ||
          errorStr.contains('cancelled');

      if (!isExpectedError) {
        OverlayService().showError(
          AppLocalizations.of(context)!.paymentMonitoringError(e.toString()),
        );
      }
    }
  }

  void _showPaymentReceivedOverlay(PaymentReceived payment) {
    // Track receive transaction
    final transactionType = _receiveType == ReceiveType.lightning
        ? 'lightning'
        : _receiveType == ReceiveType.ark
            ? 'ark'
            : 'onchain';
    AnalyticsService().trackReceiveTransaction(
      amountSats: payment.amountSats.toInt(),
      transactionType: transactionType,
      txId: payment.txid,
    );

    PaymentOverlayService().showPaymentReceivedOverlay(
      context: context,
      payment: payment,
      onDismiss: () {
        if (mounted) {
          _unfocusAll();
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      },
    );
  }

  String _getCurrentQrData() {
    switch (_receiveType) {
      case ReceiveType.combined:
        return _bip21Address;
      case ReceiveType.ark:
        // Return Arkade address with amount if set
        if ((_currentAmount ?? 0) > 0) {
          final amountBtc = _currentAmount! / 100000000.0;
          return '$_arkAddress?amount=$amountBtc';
        }
        return _arkAddress;
      case ReceiveType.onchain:
        // Return BIP21 URI with amount if set
        if ((_currentAmount ?? 0) > 0) {
          final amountBtc = _currentAmount! / 100000000.0;
          return 'bitcoin:$_btcAddress?amount=$amountBtc';
        }
        return _btcAddress;
      case ReceiveType.lightning:
        // Prefix with lightning: for proper QR code scanning
        final invoice = _lightningInvoice ?? "";
        return invoice.isNotEmpty ? "lightning:$invoice" : "";
    }
  }

  /// Get the appropriate QR code center image for current receive type
  AssetImage _getQrCenterImage() {
    switch (_receiveType) {
      case ReceiveType.combined:
        return const AssetImage('assets/images/bip21.png');
      case ReceiveType.ark:
        return const AssetImage('assets/images/bitcoin.png');
      case ReceiveType.onchain:
        return const AssetImage('assets/images/bitcoin.png');
      case ReceiveType.lightning:
        return const AssetImage('assets/images/lightning.png');
    }
  }

  /// Get the raw address/invoice for copying
  /// Includes amount query param when set
  String _getRawAddress() {
    switch (_receiveType) {
      case ReceiveType.combined:
        return _bip21Address;
      case ReceiveType.ark:
        // Return Arkade address with amount if set
        if ((_currentAmount ?? 0) > 0) {
          final amountBtc = _currentAmount! / 100000000.0;
          return '$_arkAddress?amount=$amountBtc';
        }
        return _arkAddress;
      case ReceiveType.onchain:
        // Return BIP21 URI with amount if set
        if ((_currentAmount ?? 0) > 0) {
          final amountBtc = _currentAmount! / 100000000.0;
          return 'bitcoin:$_btcAddress?amount=$amountBtc';
        }
        return _btcAddress;
      case ReceiveType.lightning:
        return _lightningInvoice ?? "";
    }
  }

  bool _isLightningAvailable() {
    return _lightningInvoice != null && _lightningInvoice!.isNotEmpty;
  }

  void _copyAddress() {
    final address = _getRawAddress();
    Clipboard.setData(ClipboardData(text: address));
    HapticFeedback.lightImpact();

    setState(() {
      _showCopied = true;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showCopied = false;
        });
      }
    });
  }

  void _shareAddress() {
    final address = _getRawAddress();
    Share.share(address);
  }

  void _showAmountSheet() {
    // Only pre-fill if there's an actual amount set (not 0)
    // Empty string shows hint text "0"
    if (_currentAmount != null && _currentAmount! > 0) {
      _satController.text = _currentAmount.toString();
    } else {
      _satController.clear();
    }

    // Auto-focus the text field after the sheet is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _amountFocusNode.requestFocus();
    });

    final isLightning = _receiveType == ReceiveType.lightning;

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.85,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final amountText = _satController.text.trim();
          final amount = int.tryParse(amountText) ?? 0;
          final isBelowMinimum =
              isLightning && amount < _defaultLightningAmount;

          return ArkScaffold(
            context: context,
            appBar: BitNetAppBar(
              context: context,
              hasBackButton: false,
              text: AppLocalizations.of(context)!.setAmount,
              actions: [
                IconButton(
                  icon: Icon(Icons.close,
                      color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () {
                    _unfocusAll();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
            body: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.cardPadding * 2,
                      horizontal: AppTheme.cardPadding,
                    ),
                    child: AmountWidget(
                      enabled: () => true,
                      btcController: _btcController,
                      satController: _satController,
                      currController: _currController,
                      focusNode: _amountFocusNode,
                      bitcoinUnit: CurrencyType.sats,
                      swapped: false,
                      autoConvert: true,
                      bitcoinPrice: _bitcoinPrice,
                      onAmountChange: (_, __) {
                        // Rebuild the sheet to update button state
                        setSheetState(() {});
                      },
                    ),
                  ),
                  // Show Boltz fee breakdown for Lightning
                  if (isLightning && amount >= _defaultLightningAmount) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.cardPadding,
                      ),
                      child: Builder(
                        builder: (context) {
                          // Calculate gross amount (what sender pays)
                          final int grossAmount = _calculateGrossAmount(amount);
                          final int serviceFee =
                              (grossAmount * _boltzServiceFeePercent / 100)
                                  .round();
                          final isDark =
                              Theme.of(context).brightness == Brightness.dark;

                          return Container(
                            padding: const EdgeInsets.all(AppTheme.cardPadding),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.03),
                              borderRadius: AppTheme.cardRadiusSmall,
                            ),
                            child: Column(
                              children: [
                                _buildFeeRow(
                                  context,
                                  'You receive',
                                  '$amount sats',
                                  isDark,
                                  isTotal: true,
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 8),
                                  child: Divider(height: 1),
                                ),
                                _buildFeeRow(
                                  context,
                                  'Service fee (0.25%)',
                                  '+$serviceFee sats',
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildFeeRow(
                                  context,
                                  'Claim fee',
                                  '+$_boltzClaimFeeSats sats',
                                  isDark,
                                ),
                                const SizedBox(height: 8),
                                _buildFeeRow(
                                  context,
                                  'Sender pays',
                                  '~$grossAmount sats',
                                  isDark,
                                  isTotal: true,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppTheme.cardPadding),
                  ] else
                    const SizedBox(height: AppTheme.cardPadding),
                  LongButtonWidget(
                    title: isBelowMinimum
                        ? 'Amount too low'
                        : AppLocalizations.of(context)!.apply,
                    buttonType: isBelowMinimum
                        ? ButtonType.transparent
                        : ButtonType.primary,
                    customWidth: AppTheme.cardPadding * 10,
                    customHeight: AppTheme.cardPadding * 2,
                    onTap: isBelowMinimum
                        ? null
                        : () {
                            final amountText = _satController.text.trim();
                            final amount = int.tryParse(amountText) ?? 0;
                            setState(() =>
                                _currentAmount = amount >= 0 ? amount : 0);
                            _unfocusAll();
                            Navigator.pop(context);
                            // Re-fetch Lightning invoice if on Lightning, otherwise fetch addresses
                            if (_receiveType == ReceiveType.lightning) {
                              _fetchLightningInvoice();
                            } else {
                              _fetchAddresses();
                            }
                          },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      // Ensure keyboard is dismissed when bottom sheet closes by any means
      // (swipe down, tap outside, or button press)
      _unfocusAll();
    });
  }

  String _trimAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 10)}';
  }

  /// Unfocus all text fields to dismiss keyboard
  void _unfocusAll() {
    _amountFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: BitNetAppBar(
        context: context,
        text: l10n.receiveLower,
        onTap: () {
          _unfocusAll();
          Navigator.pop(context);
        },
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizeTransition(
                sizeFactor: _animation,
                axis: Axis.horizontal,
                axisAlignment: -1.0,
                child: _receiveType == ReceiveType.lightning &&
                        _isLightningAvailable()
                    ? LongButtonWidget(
                        customShadow: isLight ? [] : null,
                        buttonType: ButtonType.transparent,
                        customHeight: AppTheme.cardPadding * 1.5,
                        customWidth: AppTheme.cardPadding * 4,
                        leadingIcon: Icon(
                          FontAwesomeIcons.arrowsRotate,
                          color: isLight ? AppTheme.black60 : AppTheme.white80,
                          size: AppTheme.elementSpacing * 1.5,
                        ),
                        title: "$_timerMin:$_timerSec",
                        onTap: _refreshLightningInvoice,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.elementSpacing / 2),
        ],
      ),
      body: PopScope(
        canPop: true,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) {
            _unfocusAll();
          }
        },
        child: SingleChildScrollView(
          child: SizedBox(
            width: double.infinity,
            child: Column(
              children: [
                const SizedBox(height: kToolbarHeight),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.cardPadding,
                  ),
                  child: _error != null
                      ? Center(
                          child: Column(
                            children: [
                              const Icon(Icons.error_outline,
                                  color: AppTheme.errorColor, size: 48),
                              const SizedBox(height: AppTheme.elementSpacing),
                              Text(
                                l10n.errorLoadingAddresses,
                                style:
                                    const TextStyle(color: AppTheme.errorColor),
                              ),
                              const SizedBox(height: AppTheme.elementSpacing),
                              LongButtonWidget(
                                title: l10n.retry,
                                buttonType: ButtonType.primary,
                                onTap: _fetchAddresses,
                              ),
                            ],
                          ),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppTheme.cardPadding),
                            // QR Code
                            _buildQrCode(isLight),
                            const SizedBox(height: AppTheme.elementSpacing),
                            // Type selector tabs
                            _buildTypeSelector(),
                            const SizedBox(height: AppTheme.cardPadding),
                            // Address tile
                            _buildAddressTile(),
                            // Amount tile
                            _buildAmountTile(l10n),
                            const SizedBox(height: AppTheme.cardPadding * 2),
                            // Share button
                            _buildShareButton(),
                            const SizedBox(height: AppTheme.cardPadding * 2),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShareButton() {
    final qrData = _getCurrentQrData();
    final isLoading = qrData.isEmpty;

    return Center(
      child: LongButtonWidget(
        customHeight: AppTheme.cardPadding * 2,
        customWidth: AppTheme.cardPadding * 5,
        title: AppLocalizations.of(context)!.share,
        leadingIcon: const Icon(Icons.share_rounded),
        onTap: isLoading ? null : _shareAddress,
        buttonType: ButtonType.transparent,
      ),
    );
  }

  Widget _buildQrCode(bool isLight) {
    final qrData = _getCurrentQrData();
    final isLoading = qrData.isEmpty;

    return GestureDetector(
      onTap: isLoading ? null : _copyAddress,
      child: Center(
        child: Column(
          children: [
            // QR code masked for PostHog session replay (contains sensitive address)
            PostHogMaskWidget(
              child: CustomPaint(
                foregroundPainter:
                    isLight ? BorderPainterBlack() : BorderPainter(),
                child: Container(
                  margin: const EdgeInsets.all(AppTheme.cardPadding),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: AppTheme.cardRadiusBigger,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.cardPadding / 1.25),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        PrettyQrView.data(
                          data: isLoading ? "loading..." : qrData,
                          decoration: PrettyQrDecoration(
                            shape: const PrettyQrSmoothSymbol(roundFactor: 1),
                            image: isLoading
                                ? null
                                : PrettyQrDecorationImage(
                                    image: _getQrCenterImage(),
                                  ),
                          ),
                          errorCorrectLevel: QrErrorCorrectLevel.H,
                        ),
                        if (isLoading)
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: AppTheme.colorBitcoin,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile() {
    final label = _receiveType == ReceiveType.lightning
        ? AppLocalizations.of(context)!.lightningInvoice
        : AppLocalizations.of(context)!.address;

    return ArkListTile(
      text: label,
      trailing: _showCopied
          ? Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(
                  Icons.check,
                  color: AppTheme.successColor,
                  size: AppTheme.cardPadding * 0.75,
                ),
                const SizedBox(width: AppTheme.elementSpacing / 2),
                Text(
                  AppLocalizations.of(context)!.copied,
                  style: TextStyle(
                    color: AppTheme.successColor,
                    fontSize: Theme.of(context).textTheme.bodySmall?.fontSize,
                  ),
                ),
              ],
            )
          : PostHogMaskWidget(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.copy,
                    color: Theme.of(context).hintColor,
                    size: AppTheme.cardPadding * 0.75,
                  ),
                  const SizedBox(width: AppTheme.elementSpacing / 2),
                  Text(
                    _trimAddress(_getRawAddress()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
      onTap: _copyAddress,
    );
  }

  Widget _buildAmountTile(AppLocalizations l10n) {
    final displayAmount = _currentAmount ?? 0;
    return ArkListTile(
      text: l10n.amount,
      trailing: GestureDetector(
        onTap: _showAmountSheet,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit,
              size: AppTheme.cardPadding * 0.75,
              color: Theme.of(context).hintColor,
            ),
            const SizedBox(width: AppTheme.elementSpacing / 2),
            Text(
              displayAmount > 0 ? '$displayAmount sats' : 'Any',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      onTap: _showAmountSheet,
    );
  }

  Widget _buildTypeSelector() {
    final selectedIndex = ReceiveType.values.indexOf(_receiveType);
    final isLight = Theme.of(context).brightness == Brightness.light;
    const double containerPadding = 4;
    const double indicatorMargin = 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.elementSpacing),
      child: Container(
        height: 48,
        padding: const EdgeInsets.all(containerPadding),
        decoration: BoxDecoration(
          color: isLight
              ? Colors.black.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tabWidth = constraints.maxWidth / 4;
            final indicatorHeight = constraints.maxHeight;
            return Stack(
              children: [
                // Animated sliding pill indicator
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutExpo,
                  left: selectedIndex * tabWidth + indicatorMargin,
                  top: 0,
                  height: indicatorHeight,
                  width: tabWidth - (indicatorMargin * 2),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isLight
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black
                              .withValues(alpha: isLight ? 0.08 : 0.15),
                          blurRadius: 6,
                          spreadRadius: 0,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                // Tab items
                Row(
                  children: ReceiveType.values.map((type) {
                    final isSelected = _receiveType == type;
                    final icon = switch (type) {
                      ReceiveType.combined => FontAwesomeIcons.qrcode,
                      ReceiveType.ark => FontAwesomeIcons.spaceAwesome,
                      ReceiveType.onchain => FontAwesomeIcons.link,
                      ReceiveType.lightning => FontAwesomeIcons.bolt,
                    };
                    final label = switch (type) {
                      ReceiveType.combined => 'Unified',
                      ReceiveType.ark => 'Arkade',
                      ReceiveType.onchain => 'Onchain',
                      ReceiveType.lightning => 'Lightning',
                    };

                    return Expanded(
                      child: GestureDetector(
                        onTap: () => _onTypeSelected(type),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: double.infinity,
                          margin: const EdgeInsets.symmetric(
                              horizontal: indicatorMargin),
                          alignment: Alignment.center,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  icon,
                                  size: 12,
                                  color: isSelected
                                      ? (isLight
                                          ? Colors.black87
                                          : Colors.white)
                                      : (isLight
                                          ? Colors.black38
                                          : Colors.white38),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? (isLight
                                            ? Colors.black87
                                            : Colors.white)
                                        : (isLight
                                            ? Colors.black38
                                            : Colors.white38),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _onTypeSelected(ReceiveType type) {
    if (type == _receiveType) return;

    final wasLightning = _receiveType == ReceiveType.lightning;
    final hadDefaultLightningAmount = _currentAmount == _defaultLightningAmount;

    setState(() {
      _receiveType = type;

      if (type == ReceiveType.lightning) {
        // Lightning requires minimum amount (Boltz minimum is 333 sats, we use 10k default)
        // Auto-adjust to 10k if amount is not set or below minimum
        if ((_currentAmount ?? 0) < _defaultLightningAmount) {
          _currentAmount = _defaultLightningAmount;
        }
      } else if (wasLightning && hadDefaultLightningAmount) {
        // Reset amount when leaving Lightning if it was the auto-set default
        _currentAmount = 0;
      }
    });

    // Fetch Lightning invoice if switching to Lightning
    if (type == ReceiveType.lightning) {
      _fetchLightningInvoice();
    }
  }

  Widget _buildFeeRow(
    BuildContext context,
    String label,
    String value,
    bool isDark, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isDark ? AppTheme.white60 : AppTheme.black60,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isTotal
                    ? (isDark ? Colors.white : Colors.black)
                    : (isDark ? AppTheme.white60 : AppTheme.black60),
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
