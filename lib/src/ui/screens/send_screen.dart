import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/utility/amount_widget.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/sign_transaction_screen.dart';
import 'package:ark_flutter/src/ui/screens/qr_scanner_screen.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';
import 'package:ark_flutter/app_theme.dart';

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

class SendScreenState extends State<SendScreen> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _btcController = TextEditingController();
  final TextEditingController _satController = TextEditingController();
  final TextEditingController _currController = TextEditingController();
  final FocusNode _amountFocusNode = FocusNode();

  // Mock BTC to USD conversion rate - would be fetched from an API
  final double _btcToUsdRate = 60000.0;

  @override
  void dispose() {
    _addressController.dispose();
    _btcController.dispose();
    _satController.dispose();
    _currController.dispose();
    _amountFocusNode.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (_addressController.text.isEmpty || _satController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.pleaseEnterBothAddressAndAmount)),
      );
      return;
    }

    double? amount = double.tryParse(_satController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(AppLocalizations.of(context)!.pleaseEnterAValidAmount)),
      );
      return;
    }

    if (amount > widget.availableSats) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(AppLocalizations.of(context)!.insufficientFunds)),
      );
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

  Future<void> _handleQRScan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const QrScannerScreen(),
      ),
    );

    if (result != null && result is String) {
      setState(() {
        _addressController.text = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          AppLocalizations.of(context)!.sendLower,
          style: TextStyle(
            color: theme.primaryWhite,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.primaryWhite),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 100,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.amount,
                        style: TextStyle(
                          color: theme.mutedText,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${widget.availableSats.toStringAsFixed(0)} SATS ${AppLocalizations.of(context)!.available}',
                        style: TextStyle(
                          color: theme.mutedText,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  Center(
                    child: AmountWidget(
                      enabled: () => true,
                      btcController: _btcController,
                      satController: _satController,
                      currController: _currController,
                      focusNode: _amountFocusNode,
                      bitcoinUnit: CurrencyType.sats,
                      swapped: false,
                      autoConvert: true,
                      bitcoinPrice: _btcToUsdRate,
                      lowerBound: 0,
                      upperBound: widget.availableSats.toInt(),
                      boundType: CurrencyType.sats,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                  Text(
                    AppLocalizations.of(context)!.recipientAddress,
                    style: TextStyle(
                      color: theme.mutedText,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.secondaryBlack,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addressController,
                            style: TextStyle(color: theme.primaryWhite),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                              hintText: AppLocalizations.of(context)!
                                  .bitcoinOrArkAddress,
                              hintStyle: TextStyle(color: theme.mutedText),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.qr_code_scanner,
                              color: theme.primaryWhite),
                          onPressed: _handleQRScan,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          theme.primaryBlack.withValues(alpha: 0.0),
                          theme.primaryBlack,
                        ],
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.primaryBlack,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: GestureDetector(
                        onTap: _handleContinue,
                        child: Container(
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.amber[600]!,
                                Colors.amber[400]!,
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.amber[600]!.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              AppLocalizations.of(context)!.contin,
                              style: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
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
}
