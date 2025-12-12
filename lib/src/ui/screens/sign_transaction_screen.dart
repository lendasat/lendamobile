import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/ui/screens/transaction_success_screen.dart';

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

  /// Check if the address is a Lightning invoice (BOLT11 format)
  bool _isLightningInvoice(String address) {
    final lower = address.toLowerCase().trim();
    // BOLT11 invoices start with 'ln' followed by network prefix
    // lnbc = mainnet, lntb = testnet, lnbcrt = regtest
    return lower.startsWith('lnbc') ||
        lower.startsWith('lntb') ||
        lower.startsWith('lnbcrt');
  }

  void _handleSign() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isLightning = _isLightningInvoice(widget.address);

      if (isLightning) {
        // Pay Lightning invoice via submarine swap
        logger.i("Paying Lightning invoice: ${widget.address.substring(0, 20)}...");
        final result = await payLnInvoice(invoice: widget.address);
        logger.i("Lightning payment successful! TXID: ${result.txid}");
      } else {
        // Regular Ark/Bitcoin send
        logger.i(
            "Signing transaction to ${widget.address} for ${widget.amount} SATS");
        await send(
            address: widget.address, amountSats: BigInt.from(widget.amount));
      }

      // Navigate to success screen after signing
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
    

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.signTransaction,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _isLoading
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back, color: Theme.of(context).colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: Theme.of(context).colorScheme.surface,
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Row(
        children: [
          Icon(icon, size: 22, color: iconColor ?? Theme.of(context).hintColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: labelColor ?? Theme.of(context).hintColor,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Theme.of(context).colorScheme.onSurface,
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
      color: Theme.of(context).colorScheme.surface,
    );
  }
}
