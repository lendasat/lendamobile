import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
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
import 'package:share_plus/share_plus.dart';

/// Receive type enum for address display
enum ReceiveType { combined, ark, onchain }

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
    with TickerProviderStateMixin {
  // Address data
  String _bip21Address = "";
  String _btcAddress = "";
  String _arkAddress = "";
  String _lightningInvoice = "";
  String? _boltzSwapId;
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
  bool _isLoading = true;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _currentAmount = widget.amount > 0 ? widget.amount : null;

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
    _animationController.dispose();
    _btcController.dispose();
    _satController.dispose();
    _currController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchAddresses() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final BigInt? amountSats =
          _currentAmount != null ? BigInt.from(_currentAmount!) : null;

      final addresses = await address(amount: amountSats);
      setState(() {
        _bip21Address = addresses.bip21;
        _arkAddress = addresses.offchain;
        _btcAddress = addresses.boarding;
        _lightningInvoice = addresses.lightning?.invoice ?? "";
        _boltzSwapId = addresses.lightning?.swapId;
        _isLoading = false;
      });

      _startPaymentMonitoring();
    } catch (e) {
      logger.e("Error fetching addresses: $e");
      setState(() {
        _error = e.toString();
        _isLoading = false;
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

      _showPaymentReceivedDialog(payment);
    } catch (e) {
      logger.e("Error waiting for payment: $e");
      if (!mounted) return;

      setState(() {
        _waitingForPayment = false;
      });

      if (!e.toString().contains('timeout') &&
          !e.toString().contains('Timeout')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!
                .paymentMonitoringError(e.toString())),
            backgroundColor: BitNetTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showPaymentReceivedDialog(PaymentReceived payment) {
    final theme = AppTheme.of(context, listen: false);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: theme.secondaryBlack,
          title: Row(
            children: [
              const Icon(Icons.check_circle,
                  color: BitNetTheme.successColor, size: 32),
              const SizedBox(width: 12),
              Text(AppLocalizations.of(context)!.paymentReceived,
                  style: TextStyle(color: theme.primaryWhite)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${AppLocalizations.of(context)!.amount}: ${payment.amountSats} sats',
                style: TextStyle(
                    color: theme.primaryWhite,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'TXID: ${payment.txid}',
                style: TextStyle(color: theme.mutedText, fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(AppLocalizations.of(context)!.ok,
                  style: const TextStyle(color: BitNetTheme.colorBitcoin)),
            ),
          ],
        );
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
    }
  }

  String _getReceiveTypeLabel() {
    switch (_receiveType) {
      case ReceiveType.combined:
        return 'BIP21';
      case ReceiveType.ark:
        return 'Ark';
      case ReceiveType.onchain:
        return 'Boarding';
    }
  }

  IconData _getReceiveTypeIcon() {
    switch (_receiveType) {
      case ReceiveType.combined:
        return FontAwesomeIcons.bitcoin;
      case ReceiveType.ark:
        return FontAwesomeIcons.water;
      case ReceiveType.onchain:
        return FontAwesomeIcons.link;
    }
  }

  void _copyAddress() {
    final address = _getCurrentQrData();
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.addressCopiedToClipboard),
        backgroundColor: BitNetTheme.successColor,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareAddress() {
    final address = _getCurrentQrData();
    Share.share(address);
  }

  void _refreshAddress() {
    _animationController.reset();
    _animationController.forward();
    _fetchAddresses();
  }

  void _showReceiveTypeSheet() {
    final theme = AppTheme.of(context, listen: false);

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.45,
      backgroundColor: theme.primaryBlack,
      child: ArkScaffold(
        context: context,
        appBar: ArkAppBar(
          context: context,
          hasBackButton: false,
          text: "Select Receive Type",
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: BitNetTheme.elementSpacing,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ArkListTile(
                text: "BIP21",
                selected: _receiveType == ReceiveType.combined,
                leading: RoundedButtonWidget(
                  buttonType: ButtonType.transparent,
                  iconData: FontAwesomeIcons.bitcoin,
                  size: BitNetTheme.cardPadding * 1.25,
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
                  size: BitNetTheme.cardPadding * 1.25,
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
                text: "Boarding",
                selected: _receiveType == ReceiveType.onchain,
                leading: RoundedButtonWidget(
                  buttonType: ButtonType.transparent,
                  iconData: FontAwesomeIcons.link,
                  size: BitNetTheme.cardPadding * 1.25,
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
            ],
          ),
        ),
      ),
    );
  }

  void _showAmountSheet() {
    final theme = AppTheme.of(context, listen: false);
    _satController.text = _currentAmount?.toString() ?? "0";

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.5,
      backgroundColor: theme.primaryBlack,
      child: ArkScaffold(
        context: context,
        appBar: ArkAppBar(
          context: context,
          hasBackButton: false,
          text: AppLocalizations.of(context)!.setAmount,
          actions: [
            IconButton(
              icon: Icon(Icons.close, color: theme.primaryWhite),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: BitNetTheme.cardPadding * 2,
                  horizontal: BitNetTheme.cardPadding,
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
              const SizedBox(height: BitNetTheme.cardPadding),
              LongButtonWidget(
                title: AppLocalizations.of(context)!.apply,
                buttonType: ButtonType.primary,
                customWidth: BitNetTheme.cardPadding * 10,
                customHeight: BitNetTheme.cardPadding * 2,
                onTap: () {
                  final amountText = _satController.text.trim();
                  if (amountText.isEmpty || amountText == "0") {
                    setState(() => _currentAmount = null);
                  } else {
                    final amount = int.tryParse(amountText);
                    if (amount != null && amount > 0) {
                      setState(() => _currentAmount = amount);
                    }
                  }
                  Navigator.pop(context);
                  _fetchAddresses();
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
                child: RoundedButtonWidget(
                  size: BitNetTheme.cardPadding * 1.5,
                  buttonType: ButtonType.transparent,
                  iconData: FontAwesomeIcons.arrowsRotate,
                  onTap: _refreshAddress,
                ),
              ),
            ],
          ),
          const SizedBox(width: BitNetTheme.elementSpacing / 2),
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
                    horizontal: BitNetTheme.cardPadding,
                  ),
                  child: _isLoading
                      ? const Center(
                          child: Padding(
                            padding:
                                EdgeInsets.all(BitNetTheme.cardPadding * 4),
                            child: CircularProgressIndicator(
                              color: BitNetTheme.colorBitcoin,
                            ),
                          ),
                        )
                      : _error != null
                          ? Center(
                              child: Column(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: BitNetTheme.errorColor, size: 48),
                                  const SizedBox(
                                      height: BitNetTheme.elementSpacing),
                                  Text(
                                    l10n.errorLoadingAddresses,
                                    style: const TextStyle(
                                        color: BitNetTheme.errorColor),
                                  ),
                                  const SizedBox(
                                      height: BitNetTheme.elementSpacing),
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
                                // Payment monitoring indicator at top
                                if (_waitingForPayment)
                                  _buildPaymentMonitoringIndicator(l10n),
                                const SizedBox(height: BitNetTheme.cardPadding),
                                // QR Code
                                _buildQrCode(isLight),
                                const SizedBox(height: BitNetTheme.cardPadding),
                                // Address tile
                                _buildAddressTile(),
                                // Amount tile
                                _buildAmountTile(l10n),
                                // Type tile
                                _buildTypeTile(),
                                const SizedBox(
                                    height: BitNetTheme.cardPadding * 2),
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

    return GestureDetector(
      onTap: _copyAddress,
      child: Center(
        child: Column(
          children: [
            CustomPaint(
              foregroundPainter:
                  isLight ? BorderPainterBlack() : BorderPainter(),
              child: Container(
                margin: const EdgeInsets.all(BitNetTheme.cardPadding),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BitNetTheme.cardRadiusBigger,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(BitNetTheme.cardPadding / 1.25),
                  child: qrData.isNotEmpty
                      ? PrettyQrView.data(
                          data: qrData,
                          decoration: const PrettyQrDecoration(
                            shape: PrettyQrSmoothSymbol(roundFactor: 1),
                          ),
                          errorCorrectLevel: QrErrorCorrectLevel.H,
                        )
                      : const SizedBox(
                          width: 200,
                          height: 200,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: BitNetTheme.colorBitcoin,
                            ),
                          ),
                        ),
                ),
              ),
            ),
            LongButtonWidget(
              customHeight: BitNetTheme.cardPadding * 2,
              customWidth: BitNetTheme.cardPadding * 5,
              title: AppLocalizations.of(context)!.share,
              leadingIcon: const Icon(Icons.share_rounded),
              onTap: _shareAddress,
              buttonType: ButtonType.transparent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressTile() {
    return ArkListTile(
      text: AppLocalizations.of(context)!.address,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.copy,
              color: AppTheme.of(context).mutedText,
              size: BitNetTheme.cardPadding * 0.75),
          const SizedBox(width: BitNetTheme.elementSpacing / 2),
          Text(
            _trimAddress(_getCurrentQrData()),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      onTap: _copyAddress,
    );
  }

  Widget _buildAmountTile(AppLocalizations l10n) {
    return ArkListTile(
      text: l10n.amount,
      trailing: GestureDetector(
        onTap: _showAmountSheet,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.edit,
              size: BitNetTheme.cardPadding * 0.75,
              color: AppTheme.of(context).mutedText,
            ),
            const SizedBox(width: BitNetTheme.elementSpacing / 2),
            Text(
              _currentAmount != null ? '$_currentAmount sats' : 'Any',
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
          horizontal: BitNetTheme.elementSpacing,
          vertical: BitNetTheme.elementSpacing / 2,
        ),
        child: GestureDetector(
          onTap: _showReceiveTypeSheet,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getReceiveTypeIcon(),
                size: BitNetTheme.cardPadding * 0.75,
                color: AppTheme.of(context).mutedText,
              ),
              const SizedBox(width: BitNetTheme.elementSpacing / 2),
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

  Widget _buildPaymentMonitoringIndicator(AppLocalizations l10n) {
    return Container(
      margin: const EdgeInsets.only(top: BitNetTheme.cardPadding),
      padding: const EdgeInsets.all(BitNetTheme.elementSpacing),
      decoration: BoxDecoration(
        color: BitNetTheme.colorBitcoin.withValues(alpha: 0.1),
        borderRadius: BitNetTheme.cardRadiusSmall,
        border: Border.all(
          color: BitNetTheme.colorBitcoin.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor:
                  AlwaysStoppedAnimation<Color>(BitNetTheme.colorBitcoin),
            ),
          ),
          const SizedBox(width: BitNetTheme.elementSpacing),
          Text(
            l10n.monitoringForIncomingPayment,
            style: TextStyle(
              color: BitNetTheme.colorBitcoin.withValues(alpha: 0.8),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
