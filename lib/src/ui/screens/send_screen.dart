import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/sign_transaction_screen.dart';
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
  final TextEditingController _amountController = TextEditingController();
  double _usdAmount = 0.0;
  // Mock BTC to USD conversion rate - would be fetched from an API
  final double _btcToUsdRate = 60000.0;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _updateUsdAmount(String satsAmount) {
    if (satsAmount.isEmpty) {
      setState(() {
        _usdAmount = 0.0;
      });
      return;
    }

    try {
      final double sats = double.parse(satsAmount);
      final double btc = sats / 100000000;
      setState(() {
        _usdAmount = btc * _btcToUsdRate;
      });
    } catch (e) {
      setState(() {
        _usdAmount = 0.0;
      });
    }
  }

  void _handleContinue() {
    if (_addressController.text.isEmpty || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                AppLocalizations.of(context)!.pleaseEnterBothAddressAndAmount)),
      );
      return;
    }

    double? amount = double.tryParse(_amountController.text);
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

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.sendLower,
          style: TextStyle(color: theme.primaryWhite),
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Recipient address
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
                        hintText:
                            AppLocalizations.of(context)!.bitcoinOrArkAddress,
                        hintStyle: TextStyle(color: theme.mutedText),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.qr_code_scanner, color: theme.mutedText),
                    onPressed: () {
                      // TODO: Implement QR code scanning
                      logger.i("QR scan requested");
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.amount,
                  style: TextStyle(
                    color: theme.mutedText,
                    fontSize: 16,
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
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: theme.secondaryBlack,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Text(
                    'SATS',
                    style: TextStyle(
                      color: theme.mutedText,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.right,
                      onChanged: _updateUsdAmount,
                      style: TextStyle(color: theme.primaryWhite),
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 16),
                        hintText: '0',
                        hintStyle: TextStyle(color: theme.mutedText),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Text(
                      _usdAmount.toStringAsFixed(2),
                      style: TextStyle(
                        color: theme.mutedText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Continue button
            ElevatedButton(
              onPressed: _handleContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[500],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.contin,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
