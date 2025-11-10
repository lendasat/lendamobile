import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/app_theme.dart';

class TransactionSuccessScreen extends StatelessWidget {
  final String aspId;
  final double amount;

  const TransactionSuccessScreen({
    super.key,
    required this.aspId,
    required this.amount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);

    return Scaffold(
      backgroundColor: theme.primaryBlack,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          AppLocalizations.of(context)!.success,
          style: TextStyle(color: theme.primaryWhite),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: theme.secondaryBlack,
            height: 1.0,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Success icon
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.amber[500],
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF7E71F0)
                              .withAlpha((0.5 * 255).round()),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check,
                      color: theme.primaryWhite,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Transaction details
                  Text(
                    '${amount.toInt()} SATS ${AppLocalizations.of(context)!.sentSuccessfully}',
                    style: TextStyle(
                      color: theme.primaryWhite,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Back to wallet button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Navigate back to the dashboard/wallet
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  logger.i(AppLocalizations.of(context)!
                      .returningToWalletAfterSuccessfulTransaction);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.secondaryBlack,
                  foregroundColor: theme.primaryWhite,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  AppLocalizations.of(context)!.backToWallet,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
