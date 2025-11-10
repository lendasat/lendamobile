import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/transaction_success_screen.dart';
import 'package:ark_flutter/app_theme.dart';

class SignTransactionScreen extends StatefulWidget {
  final String aspId;
  final String address;
  final double amount;

  const SignTransactionScreen({
    super.key,
    required this.aspId,
    required this.address,
    required this.amount,
  });

  @override
  SignTransactionScreenState createState() => SignTransactionScreenState();
}

class SignTransactionScreenState extends State<SignTransactionScreen> {
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)!.transactionFailed} ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.signTransaction,
          style: TextStyle(color: theme.primaryWhite),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isLoading
            ? null
            : IconButton(
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
                    AppLocalizations.of(context)!.address,
                    widget.address.length > 20
                        ? '${widget.address.substring(0, 10)}...${widget.address.substring(widget.address.length - 10)}'
                        : widget.address,
                  ),
                  _buildDivider(),

                  _buildDetailRow(
                    Icons.attach_money_outlined,
                    AppLocalizations.of(context)!.amount,
                    '${widget.amount.toInt()} SATS',
                  ),
                  _buildDivider(),

                  _buildDetailRow(
                    Icons.account_balance_outlined,
                    AppLocalizations.of(context)!.networkFees,
                    '0 SATS',
                  ),
                  _buildDivider(),

                  _buildDetailRow(
                    Icons.summarize_outlined,
                    AppLocalizations.of(context)!.total,
                    '${widget.amount.toInt()} SATS',
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
                    child: Text(
                      AppLocalizations.of(context)!.tapToSign,
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

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    bool isLast = false,
    Color? iconColor,
    Color? labelColor,
    Color? valueColor,
  }) {
    final theme = AppTheme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor ?? theme.mutedText),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor ?? theme.mutedText,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? theme.primaryWhite,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    final theme = AppTheme.of(context);
    return Container(
      height: 1,
      color: theme.secondaryBlack,
    );
  }
}
