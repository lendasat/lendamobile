import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/sign_transaction_screen.dart';
import 'package:ark_flutter/src/ui/utility/amount_widget.dart';
import 'package:ark_flutter/src/services/amount_widget_service.dart';

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
        const SnackBar(content: Text('Please enter both address and amount')),
      );
      return;
    }

    double? amount = double.tryParse(_satController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (amount > widget.availableSats) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient funds')),
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
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Send',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Colors.grey[800],
            height: 1.0,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),

            // Amount section with available balance
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${widget.availableSats.toStringAsFixed(0)} SATS available',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Centered Amount Widget
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

            const SizedBox(height: 16),
            // Recipient address
            const Text(
              'Recipient address',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _addressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        hintText: 'Bitcoin or Ark address',
                        hintStyle: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner, color: Colors.grey),
                    onPressed: () {
                      // TODO: Implement QR code scanning
                      logger.i("QR scan requested");
                    },
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
              child: const Text(
                'CONTINUE',
                style: TextStyle(
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
