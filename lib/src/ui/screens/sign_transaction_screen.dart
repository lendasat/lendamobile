import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/transaction_success_screen.dart';

class SignTransactionScreen extends StatefulWidget {
  final String aspId;
  final String address;
  final double amount;

  const SignTransactionScreen({
    Key? key,
    required this.aspId,
    required this.address,
    required this.amount,
  }) : super(key: key);

  @override
  _SignTransactionScreenState createState() => _SignTransactionScreenState();
}

class _SignTransactionScreenState extends State<SignTransactionScreen> {
  bool _isLoading = false;

  void _handleSign() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Simulate transaction signing
      logger.i(
          "Signing transaction to ${widget.address} for ${widget.amount} SATS");
      await send(
          address: widget.address, amountSats: BigInt.from(widget.amount));

      // Navigate to success screen after simulated signing
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionSuccessScreen(
              aspId: widget.aspId,
              amount: widget.amount,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Transaction failed: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text(
          'Sign transaction',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isLoading
            ? null
            : IconButton(
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7E71F0)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Transaction details
                  _buildDetailRow(
                    Icons.account_balance_wallet_outlined,
                    'Address',
                    widget.address.length > 20
                        ? '${widget.address.substring(0, 10)}...${widget.address.substring(widget.address.length - 10)}'
                        : widget.address,
                    iconColor: Colors.grey,
                    labelColor: Colors.grey,
                    valueColor: Colors.white,
                  ),
                  _buildDivider(),

                  _buildDetailRow(
                    Icons.swap_horiz_outlined,
                    'Direction',
                    'Paying inside Ark',
                    iconColor: Colors.grey,
                    labelColor: Colors.grey,
                    valueColor: Colors.white,
                  ),
                  _buildDivider(),

                  _buildDetailRow(
                    Icons.attach_money_outlined,
                    'Amount',
                    '${widget.amount.toInt()} SATS',
                    iconColor: Colors.grey,
                    labelColor: Colors.grey,
                    valueColor: Colors.white,
                  ),
                  _buildDivider(),

                  _buildDetailRow(
                    Icons.account_balance_outlined,
                    'Network fees',
                    '0 SATS',
                    iconColor: Colors.grey,
                    labelColor: Colors.grey,
                    valueColor: Colors.white,
                  ),
                  _buildDivider(),

                  _buildDetailRow(
                    Icons.summarize_outlined,
                    'Total',
                    '${widget.amount.toInt()} SATS',
                    iconColor: Colors.grey,
                    labelColor: Colors.grey,
                    valueColor: Colors.white,
                    isLast: true,
                  ),

                  const Spacer(),

                  // Sign button
                  ElevatedButton(
                    onPressed: _handleSign,
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
                      'TAP TO SIGN',
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

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
    Color iconColor = Colors.grey,
    Color labelColor = Colors.grey,
    Color valueColor = Colors.black,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.grey[800],
    );
  }
}
