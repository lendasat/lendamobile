import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../logger/logger.dart';

class TransactionDetailsDialog extends StatelessWidget {
  final String txid;
  final int createdAt;
  final int? confirmedAt;
  final int amountSats;
  final bool isSettled;
  final String dialogTitle;

  const TransactionDetailsDialog({
    super.key,
    required this.dialogTitle,
    required this.txid,
    required this.createdAt,
    this.confirmedAt,
    required this.amountSats,
    required this.isSettled,
  });

  Future<void> _handleSettlement(BuildContext context) async {
    
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.colorBitcoin),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.of(context)!.settlingTransaction,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
            ],
          ),
        ),
      );

      // Perform settlement
      await settle();
      logger.i("Transaction settled successfully");

      // Close loading dialog and show success
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              AppLocalizations.of(context)!.success,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            content: Text(
              AppLocalizations.of(context)!.transactionSettledSuccessfully,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close success dialog
                  Navigator.of(context).pop(); // Close transaction details
                },
                child: Text(
                  AppLocalizations.of(context)!.goToHome,
                  style: TextStyle(color: AppTheme.colorBitcoin),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Close loading dialog and show error
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              AppLocalizations.of(context)!.error,
              style: const TextStyle(color: Colors.red),
            ),
            content: Text(
              '${AppLocalizations.of(context)!.failedToSettleTransaction} ${e.toString()}',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  AppLocalizations.of(context)!.ok,
                  style: TextStyle(color: AppTheme.colorBitcoin),
                ),
              ),
            ],
          ),
        );
      }
      logger.e("Error settling transaction: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    
    final timezoneService = context.watch<TimezoneService>();

    final confirmedTime = confirmedAt != null
        ? timezoneService.toSelectedTimezone(
            DateTime.fromMillisecondsSinceEpoch(confirmedAt! * 1000,
                isUtc: true))
        : null;
    final formattedDate = confirmedTime != null
        ? DateFormat('MMMM d, y - h:mm a').format(confirmedTime)
        : AppLocalizations.of(context)!.pendingConfirmation;

    final createdTimeUtc =
        DateTime.fromMillisecondsSinceEpoch(createdAt * 1000, isUtc: true);
    final createdTime = timezoneService.toSelectedTimezone(createdTimeUtc);
    final formattedCreatedAtDate =
        DateFormat('MMMM d, y - h:mm a').format(createdTime);
    final amountBtc = amountSats.toDouble() / 100000000;

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  dialogTitle,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            Divider(color: Theme.of(context).hintColor),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    context, AppLocalizations.of(context)!.transactionId, txid),
                _buildDetailRow(
                    context,
                    AppLocalizations.of(context)!.status,
                    isSettled
                        ? AppLocalizations.of(context)!.confirmed
                        : AppLocalizations.of(context)!.pending),
                _buildDetailRow(
                    context,
                    '${AppLocalizations.of(context)!.amount} (BTC)',
                    '₿${amountBtc.toStringAsFixed(8)}'),
                _buildDetailRow(context, AppLocalizations.of(context)!.date,
                    formattedCreatedAtDate),
                if (confirmedAt != null)
                  _buildDetailRow(context,
                      AppLocalizations.of(context)!.confirmedAt, formattedDate),
              ],
            ),
            const SizedBox(height: 24),
            if (!isSettled)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.colorBitcoin.withAlpha((0.2 * 200).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppLocalizations.of(context)!
                          .transactionPendingFundsWillBeNonReversibleAfterSettlement,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  LongButtonWidget(
                    title: AppLocalizations.of(context)!.settle,
                    customWidth: double.infinity,
                    customHeight: 48,
                    onTap: () => _handleSettlement(context),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).hintColor,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
