import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
          backgroundColor: Colors.grey[850],
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              ),
              SizedBox(height: 16),
              Text(
                'Settling transaction...',
                style: TextStyle(color: Colors.white),
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
            backgroundColor: Colors.grey[850],
            title: const Text(
              'Success',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Transaction settled successfully!',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close success dialog
                  Navigator.of(context).pop(); // Close transaction details
                },
                child: const Text(
                  'Go to Home',
                  style: TextStyle(color: Colors.amber),
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
            backgroundColor: Colors.grey[850],
            title: const Text(
              'Error',
              style: TextStyle(color: Colors.red),
            ),
            content: Text(
              'Failed to settle transaction: ${e.toString()}',
              style: const TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.amber),
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
    final confirmedTime = confirmedAt != null
        ? DateTime.fromMillisecondsSinceEpoch(confirmedAt! * 1000)
        : null;
    final formattedDate = confirmedTime != null
        ? DateFormat('MMMM d, y - h:mm a').format(confirmedTime)
        : 'Pending confirmation';
    final createdTime = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
    final formattedCreatedAtDate =
        DateFormat('MMMM d, y - h:mm a').format(createdTime);
    final amountBtc = amountSats.toDouble() / 100000000;

    return Dialog(
      backgroundColor: Colors.grey[850],
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
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.grey),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Transaction ID', txid),
                _buildDetailRow('Status', isSettled ? 'Confirmed' : 'Pending'),
                _buildDetailRow(
                    'Amount (BTC)', '₿${amountBtc.toStringAsFixed(8)}'),
                _buildDetailRow('Date', formattedCreatedAtDate),
                if (confirmedAt != null)
                  _buildDetailRow('Confirmed At', formattedDate),
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
                      color: Colors.amber..withAlpha((0.2 * 255).round()),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Transaction pending. Funds will be non-reversible after settlement.',
                      style: TextStyle(color: Colors.amber, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _handleSettlement(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[500],
                      foregroundColor: Colors.black,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('SETTLE',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
