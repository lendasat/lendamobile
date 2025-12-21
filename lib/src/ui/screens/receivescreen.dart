import 'dart:async';

import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/payment_overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/rounded_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/amount_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
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

  // Amount controllers
  final TextEditingController _btcController = TextEditingController();
  final TextEditingController _satController = TextEditingController();
  final TextEditingController _currController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  // Payment monitoring
  bool _waitingForPayment = false;

  // Lightning invoice timer
  Timer? _invoiceTimer;
  Duration _invoiceDuration = const Duration(minutes: 5);
  String _timerMin = "05";
  String _timerSec = "00";

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

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
    _animationController.forward();
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
      // Only pass amount when fetching Lightning invoice
      // Passing null skips Lightning/Boltz entirely
      final BigInt? amountSats = includeLightning && (_currentAmount ?? 0) > 0
          ? BigInt.from(_currentAmount!)
          : null;

      final addresses = await address(amount: amountSats);
      setState(() {
        _bip21Address = addresses.bip21;
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

  Future<void> _fetchLightningInvoice() async {
    try {
      // Boltz requires minimum 333 sats, use default if no amount set
      final int amount = (_currentAmount ?? 0) > 0 ? _currentAmount! : _defaultLightningAmount;
      final BigInt amountSats = BigInt.from(amount);
      final addresses = await address(amount: amountSats);

      setState(() {
        _boltzSwapId = addresses.lightning?.swapId;
        _lightningInvoice = addresses.lightning?.invoice;
      });

      if (_lightningInvoice != null && _lightningInvoice!.isNotEmpty) {
        _startInvoiceTimer();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lightning service temporarily unavailable"),
            backgroundColor: AppTheme.errorColor,
          ),
        );
        // Fall back to combined view
        setState(() {
          _receiveType = ReceiveType.combined;
        });
      }
    } catch (e) {
      logger.e("Error fetching Lightning invoice: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Lightning error: ${e.toString().split('\n').first}"),
          backgroundColor: AppTheme.errorColor,
        ),
      );
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .paymentMonitoringError(e.toString())),
            backgroundColor: AppTheme.errorColor,
          ),
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
        return _arkAddress;
      case ReceiveType.onchain:
        return _btcAddress;
      case ReceiveType.lightning:
        // Prefix with lightning: for proper QR code scanning
        final invoice = _lightningInvoice ?? "";
        return invoice.isNotEmpty ? "lightning:$invoice" : "";
    }
  }

  String _getReceiveTypeLabel() {
    switch (_receiveType) {
      case ReceiveType.combined:
        return 'Unified';
      case ReceiveType.ark:
        return 'Ark';
      case ReceiveType.onchain:
        return 'Onchain';
      case ReceiveType.lightning:
        return 'Lightning';
    }
  }

  IconData _getReceiveTypeIcon() {
    switch (_receiveType) {
      case ReceiveType.combined:
        return FontAwesomeIcons.qrcode;
      case ReceiveType.ark:
        return FontAwesomeIcons.water;
      case ReceiveType.onchain:
        return FontAwesomeIcons.link;
      case ReceiveType.lightning:
        return FontAwesomeIcons.bolt;
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

  /// Get the raw address/invoice for copying (without URI prefix)
  String _getRawAddress() {
    switch (_receiveType) {
      case ReceiveType.combined:
        return _bip21Address;
      case ReceiveType.ark:
        return _arkAddress;
      case ReceiveType.onchain:
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.addressCopiedToClipboard),
        backgroundColor: AppTheme.successColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareAddress() {
    final address = _getRawAddress();
    Share.share(address);
  }

  void _refreshAddress() {
    _animationController.reset();
    _animationController.forward();
    _fetchAddresses();
  }

  void _showReceiveTypeSheet() {
    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.55,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ArkScaffold(
        context: context,
        appBar: ArkAppBar(
          context: context,
          hasBackButton: false,
          text: "Select Receive Type",
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.elementSpacing,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArkListTile(
                text: "Unified QR Code",
                selected: _receiveType == ReceiveType.combined,
                leading: RoundedButtonWidget(
                  buttonType: ButtonType.transparent,
                  iconData: FontAwesomeIcons.qrcode,
                  size: AppTheme.cardPadding * 1.25,
                  onTap: () {
                    setState(() => _receiveType = ReceiveType.combined);
                    Navigator.of(context).pop();
                  },
                ),
                onTap: () {
                  setState(() => _receiveType = ReceiveType.combined);
                  Navigator.of(context).pop();
                },
              ),
              ArkListTile(
                text: "Ark",
                selected: _receiveType == ReceiveType.ark,
                leading: RoundedButtonWidget(
                  buttonType: ButtonType.transparent,
                  iconData: FontAwesomeIcons.water,
                  size: AppTheme.cardPadding * 1.25,
                  onTap: () {
                    setState(() => _receiveType = ReceiveType.ark);
                    Navigator.of(context).pop();
                  },
                ),
                onTap: () {
                  setState(() => _receiveType = ReceiveType.ark);
                  Navigator.of(context).pop();
                },
              ),
              ArkListTile(
                text: "Onchain",
                selected: _receiveType == ReceiveType.onchain,
                leading: RoundedButtonWidget(
                  buttonType: ButtonType.transparent,
                  iconData: FontAwesomeIcons.link,
                  size: AppTheme.cardPadding * 1.25,
                  onTap: () {
                    setState(() => _receiveType = ReceiveType.onchain);
                    Navigator.of(context).pop();
                  },
                ),
                onTap: () {
                  setState(() => _receiveType = ReceiveType.onchain);
                  Navigator.of(context).pop();
                },
              ),
              ArkListTile(
                text: "Lightning",
                subtitle: Text(
                  "Default: 10,000 sats",
                  style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontSize: 12,
                  ),
                ),
                selected: _receiveType == ReceiveType.lightning,
                leading: RoundedButtonWidget(
                  buttonType: ButtonType.transparent,
                  iconData: FontAwesomeIcons.bolt,
                  size: AppTheme.cardPadding * 1.25,
                  onTap: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _receiveType = ReceiveType.lightning;
                      // Set default amount for Lightning if not already set
                      if ((_currentAmount ?? 0) <= 0) {
                        _currentAmount = _defaultLightningAmount;
                      }
                    });
                    _fetchLightningInvoice();
                  },
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  setState(() {
                    _receiveType = ReceiveType.lightning;
                    // Set default amount for Lightning if not already set
                    if ((_currentAmount ?? 0) <= 0) {
                      _currentAmount = _defaultLightningAmount;
                    }
                  });
                  _fetchLightningInvoice();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAmountSheet() {
    _satController.text = _currentAmount?.toString() ?? "0";

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.75,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ArkScaffold(
        context: context,
        appBar: ArkAppBar(
          context: context,
          hasBackButton: false,
          text: AppLocalizations.of(context)!.setAmount,
          actions: [
            IconButton(
              icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
              onPressed: () => Navigator.pop(context),
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
                  bitcoinPrice: 60000.0,
                ),
              ),
              const SizedBox(height: AppTheme.cardPadding),
              LongButtonWidget(
                title: AppLocalizations.of(context)!.apply,
                buttonType: ButtonType.primary,
                customWidth: AppTheme.cardPadding * 10,
                customHeight: AppTheme.cardPadding * 2,
                onTap: () {
                  final amountText = _satController.text.trim();
                  final amount = int.tryParse(amountText) ?? 0;
                  setState(() => _currentAmount = amount >= 0 ? amount : 0);
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
      ),
    );
  }

  String _trimAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 10)}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLight = Theme.of(context).brightness == Brightness.light;

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: ArkAppBar(
        context: context,
        text: l10n.receiveLower,
        onTap: () => Navigator.pop(context),
        actions: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizeTransition(
                sizeFactor: _animation,
                axis: Axis.horizontal,
                axisAlignment: -1.0,
                child: _receiveType == ReceiveType.lightning && _isLightningAvailable()
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
                    : RoundedButtonWidget(
                        size: AppTheme.cardPadding * 1.5,
                        buttonType: ButtonType.transparent,
                        iconData: FontAwesomeIcons.arrowsRotate,
                        onTap: _refreshAddress,
                      ),
              ),
            ],
          ),
          const SizedBox(width: AppTheme.elementSpacing / 2),
        ],
      ),
      body: PopScope(
        canPop: true,
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
                              const SizedBox(
                                  height: AppTheme.elementSpacing),
                              Text(
                                l10n.errorLoadingAddresses,
                                style: const TextStyle(
                                    color: AppTheme.errorColor),
                              ),
                              const SizedBox(
                                  height: AppTheme.elementSpacing),
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
                            const SizedBox(height: AppTheme.cardPadding),
                            // Address tile
                            _buildAddressTile(),
                            // Amount tile
                            _buildAmountTile(l10n),
                            // Type tile
                            _buildTypeTile(),
                            const SizedBox(
                                height: AppTheme.cardPadding * 2),
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
            LongButtonWidget(
              customHeight: AppTheme.cardPadding * 2,
              customWidth: AppTheme.cardPadding * 5,
              title: AppLocalizations.of(context)!.share,
              leadingIcon: const Icon(Icons.share_rounded),
              onTap: isLoading ? null : _shareAddress,
              buttonType: ButtonType.transparent,
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
      trailing: PostHogMaskWidget(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.copy,
                color: Theme.of(context).hintColor,
                size: AppTheme.cardPadding * 0.75),
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

  Widget _buildTypeTile() {
    return ArkListTile(
      text: "Type",
      trailing: GlassContainer(
        opacity: 0.05,
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.elementSpacing,
          vertical: AppTheme.elementSpacing / 2,
        ),
        child: GestureDetector(
          onTap: _showReceiveTypeSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getReceiveTypeIcon(),
                size: AppTheme.cardPadding * 0.75,
                color: Theme.of(context).hintColor,
              ),
              const SizedBox(width: AppTheme.elementSpacing / 2),
              Text(
                _getReceiveTypeLabel(),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
      onTap: _showReceiveTypeSheet,
    );
  }

}
