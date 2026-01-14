import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';

class TransactionSuccessScreen extends StatefulWidget {
  final String aspId;
  final double amount;
  final String transactionType; // 'onchain' or 'offchain'
  final String? txId;

  const TransactionSuccessScreen({
    super.key,
    required this.aspId,
    required this.amount,
    this.transactionType = 'offchain',
    this.txId,
  });

  @override
  State<TransactionSuccessScreen> createState() =>
      _TransactionSuccessScreenState();
}

class _TransactionSuccessScreenState extends State<TransactionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    _trackTransaction();
  }

  Future<void> _trackTransaction() async {
    await AnalyticsService().trackSendTransaction(
      amountSats: widget.amount.toInt(),
      transactionType: widget.transactionType,
      txId: widget.txId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: BitNetAppBar(
        context: context,
        hasBackButton: false,
        text: AppLocalizations.of(context)!.success,
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success Bani image
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: Image.asset(
                      'assets/images/bani/bani_success.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: AppTheme.cardPadding * 2),

                  // Transaction details
                  Text(
                    '${widget.amount.toInt()} SATS',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  Text(
                    AppLocalizations.of(context)!.sentSuccessfully,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                ],
              ),
            ),
          ),

          // Back to wallet button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: LongButtonWidget(
              title: AppLocalizations.of(context)!.backToWallet,
              buttonType: ButtonType.transparent,
              customWidth: double.infinity,
              customHeight: 56,
              onTap: () {
                // Navigate back to the dashboard/wallet
                Navigator.of(context).popUntil((route) => route.isFirst);
                logger.i(AppLocalizations.of(context)!
                    .returningToWalletAfterSuccessfulTransaction);
              },
            ),
          ),
        ],
      ),
    );
  }
}
