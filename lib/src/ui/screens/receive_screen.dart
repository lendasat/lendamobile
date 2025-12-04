import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/models/app_theme_model.dart';
import 'package:ark_flutter/src/providers/theme_provider.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/ui/widgets/utility/amount_widget.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:flutter/services.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/app_theme.dart';
import 'package:ark_flutter/src/ui/widgets/utility/qr_border_painter.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';

enum AddressType { bip21, btc, ark }

class ReceiveScreen extends StatefulWidget {
  final String aspId;
  final int amount; // Amount in sats, 0 means any amount

  const ReceiveScreen({
    super.key,
    required this.aspId,
    required this.amount,
  });

  @override
  ReceiveScreenState createState() => ReceiveScreenState();
}

class ReceiveScreenState extends State<ReceiveScreen> {
  String? _error;

  String _bip21Address = "";
  String _btcAddress = "";
  String _arkAddress = "";
  String _lightningInvoice = "";
  String? _boltzSwapId;

  // Current amount in sats (null means no amount set)
  int? _currentAmount;

  // Current address type for display
  AddressType _currentAddressType = AddressType.bip21;

  // Amount widget controllers
  final TextEditingController _btcController = TextEditingController();
  final TextEditingController _satController = TextEditingController();
  final TextEditingController _currController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  // Payment monitoring state
  bool _waitingForPayment = false;
  PaymentReceived? _paymentReceived;

  @override
  void initState() {
    super.initState();
    // Initialize amount from widget (0 means no amount)
    _currentAmount = widget.amount > 0 ? widget.amount : null;
    _fetchAddresses();
  }

  Future<void> _fetchAddresses() async {
    try {
      // Use current amount (null means any amount)
      final BigInt? amountSats =
          _currentAmount != null ? BigInt.from(_currentAmount!) : null;

      final addresses = await address(amount: amountSats);
      setState(() {
        _bip21Address = addresses.bip21;
        _arkAddress = addresses.offchain;
        _btcAddress = addresses.boarding;
        _lightningInvoice = addresses.lightning?.invoice ?? "";
        _boltzSwapId = addresses.lightning?.swapId;
      });

      // Start monitoring for payments
      _startPaymentMonitoring();
    } catch (e) {
      logger.e("Error fetching addresses: $e");
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _startPaymentMonitoring() async {
    if (_waitingForPayment) {
      logger.i("Already waiting for payment, skipping duplicate call");
      return;
    }

    setState(() {
      _waitingForPayment = true;
    });

    try {
      logger.i("Started waiting for payment...");
      logger.i("Ark address: $_arkAddress");
      logger.i("Boarding address: $_btcAddress");
      logger.i("Boltz swap ID: $_boltzSwapId");

      // Wait for payment with 5 minute timeout
      final payment = await waitForPayment(
        arkAddress: _arkAddress.isNotEmpty ? _arkAddress : null,
        boardingAddress: _btcAddress.isNotEmpty ? _btcAddress : null,
        boltzSwapId: _boltzSwapId,
        timeoutSeconds: BigInt.from(300), // 5 minutes
      );

      if (!mounted) return;

      setState(() {
        _paymentReceived = payment;
        _waitingForPayment = false;
      });

      logger.i(
          "Payment received! TXID: ${payment.txid}, Amount: ${payment.amountSats} sats");

      // Show success dialog
      _showPaymentReceivedDialog(payment);
    } catch (e) {
      logger.e("Error waiting for payment: $e");
      if (!mounted) return;

      setState(() {
        _waitingForPayment = false;
      });

      // Don't show error if it's just a timeout - that's expected
      if (!e.toString().contains('timeout') &&
          !e.toString().contains('Timeout')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(AppLocalizations.of(context)!
                  .paymentMonitoringError(e.toString()))),
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
              const Icon(Icons.check_circle, color: Colors.amber, size: 32),
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
                // Close dialog
                Navigator.of(context).pop();

                // Navigate back to dashboard (pop until we reach it)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(AppLocalizations.of(context)!.ok,
                  style: const TextStyle(color: Colors.amber)),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _btcController.dispose();
    _satController.dispose();
    _currController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _copyCurrentAddress() {
    final theme = AppTheme.of(context);
    String address = _getCurrentAddressData();
    Clipboard.setData(ClipboardData(text: address));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.addressCopiedToClipboard),
        backgroundColor: theme.secondaryBlack,
      ),
    );
    logger.i("Copied address: $address");
  }

  void _cycleAddressType() {
    setState(() {
      switch (_currentAddressType) {
        case AddressType.bip21:
          _currentAddressType = AddressType.btc;
          break;
        case AddressType.btc:
          _currentAddressType = AddressType.ark;
          break;
        case AddressType.ark:
          _currentAddressType = AddressType.bip21;
          break;
      }
    });
  }

  String _getCurrentAddressData() {
    switch (_currentAddressType) {
      case AddressType.bip21:
        return _bip21Address;
      case AddressType.btc:
        return _btcAddress;
      case AddressType.ark:
        return _arkAddress;
    }
  }

  String _getAddressTypeLabel() {
    switch (_currentAddressType) {
      case AddressType.bip21:
        return 'BIP21';
      case AddressType.btc:
        return 'BTC Address';
      case AddressType.ark:
        return 'Ark Address';
    }
  }

  IconData _getAddressTypeIcon() {
    switch (_currentAddressType) {
      case AddressType.bip21:
        return Icons.currency_bitcoin;
      case AddressType.btc:
        return Icons.currency_bitcoin;
      case AddressType.ark:
        return Icons.water_drop;
    }
  }

  void _showAmountBottomSheet() {
    final theme = AppTheme.of(context, listen: false);
    // Initialize controllers with current amount if set
    _satController.text = _currentAmount?.toString() ?? '';
    _btcController.text = '';
    _currController.text = '';

    arkBottomSheet(
      context: context,
      height: MediaQuery.of(context).size.height * 0.5,
      backgroundColor: theme.primaryBlack,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            AppLocalizations.of(context)!.setAmount,
            style: TextStyle(
              color: theme.primaryWhite,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.close, color: theme.primaryWhite),
              onPressed: () {
                // Reset controllers on cancel
                _satController.text = _currentAmount?.toString() ?? '';
                _btcController.clear();
                _currController.clear();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              // Amount Widget
              Padding(
                padding: const EdgeInsetsGeometry.symmetric(
                    vertical: 32, horizontal: 24),
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

              const SizedBox(height: 16),

              // Apply Button
              SizedBox(
                width: 24 * 12,
                child: ElevatedButton(
                  onPressed: () {
                    final amountText = _satController.text.trim();
                    if (amountText.isEmpty) {
                      setState(() {
                        _currentAmount = null;
                      });
                      _fetchAddresses();
                    } else {
                      final amount = int.tryParse(amountText);
                      if (amount != null && amount > 0) {
                        setState(() {
                          _currentAmount = amount;
                        });
                        _fetchAddresses();
                      }
                    }
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber[600],
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.apply,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      _satController.text = '';
      _btcController.clear();
      _currController.clear();
    });
  }

  final GlobalKey _qrKey = GlobalKey();

  Future<void> _handleShare() async {
    try {
      String addressToShare = _getCurrentAddressData();
      String addressType = _getAddressTypeLabel();

      // Share the text address
      await Share.share(
        addressToShare,
        subject: 'My $addressType',
      );
    } catch (e) {
      logger.e("Error sharing address: $e");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${AppLocalizations.of(context)!.errorSharing}: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final isDarkTheme = themeProvider.currentThemeType == ThemeType.dark;
    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.receiveLower,
          style: TextStyle(
              color: theme.primaryWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.secondaryBlack,
            height: 1.0,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Payment monitoring status
            if (_waitingForPayment)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!
                            .monitoringForIncomingPayment,
                        style: TextStyle(
                          color: Colors.amber[300],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            Center(
              child: RepaintBoundary(
                key: _qrKey,
                child: Column(
                  children: [
                    CustomPaint(
                      foregroundPainter:
                          isDarkTheme ? BorderPainter() : BorderPainterBlack(),
                      child: Container(
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: PrettyQrView.data(
                            data: _getCurrentAddressData(),
                            decoration: const PrettyQrDecoration(
                              shape: PrettyQrSmoothSymbol(roundFactor: 1),
                              // TODO: Add logo here
                              // Example: image: PrettyQrDecorationImage(
                              //   image: AssetImage('assets/images/ark_logo.png'),
                              // ),
                            ),
                            errorCorrectLevel: QrErrorCorrectLevel.H,
                          ),
                        ),
                      ),
                    ),
                    GlassContainer(
                      opacity: 0.2,
                      borderRadius: BorderRadius.circular(24),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 0,
                      ),
                      child: InkWell(
                        onTap: _handleShare,
                        borderRadius: BorderRadius.circular(24),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.share_rounded,
                                color: theme.primaryWhite,
                                size: 22,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                AppLocalizations.of(context)!.share,
                                style: TextStyle(
                                  color: theme.primaryWhite,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            ArkListTile(
              text: AppLocalizations.of(context)!.address,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.copy, color: theme.mutedText),
                  Text(_trimAddress(_getCurrentAddressData())),
                ],
              ),
              onTap: _copyCurrentAddress,
            ),

            ArkListTile(
              text: AppLocalizations.of(context)!.amount,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: theme.mutedText),
                  const SizedBox(width: 8),
                  Text(
                    _currentAmount != null
                        ? '$_currentAmount sats'
                        : 'Change Amount',
                    style: TextStyle(color: theme.primaryWhite),
                  ),
                ],
              ),
              onTap: _showAmountBottomSheet,
            ),

            ArkListTile(
              text: AppLocalizations.of(context)!.type,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getAddressTypeIcon(), color: theme.mutedText),
                  Text(
                    _getAddressTypeLabel(),
                    style: TextStyle(color: theme.primaryWhite),
                  ),
                ],
              ),
              onTap: _cycleAddressType,
            ),

            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  AppLocalizations.of(context)!.errorLoadingAddresses,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _trimAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 10)}';
  }
}
