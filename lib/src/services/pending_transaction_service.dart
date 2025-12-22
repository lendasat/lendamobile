import 'dart:async';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/models/wallet_activity_item.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// Service to manage pending transactions that are being sent in the background.
///
/// This service:
/// 1. Tracks pending transactions before they are confirmed
/// 2. Executes sends in the background
/// 3. Shows success/failure bottom sheets when complete
/// 4. Removes pending items once the real transaction appears in history
class PendingTransactionService extends ChangeNotifier {
  static final PendingTransactionService _instance =
      PendingTransactionService._internal();
  factory PendingTransactionService() => _instance;
  PendingTransactionService._internal();

  final Map<String, PendingTransaction> _pendingTransactions = {};
  final _uuid = const Uuid();

  /// Get all pending transactions as activity items for display
  List<PendingActivityItem> get pendingItems =>
      _pendingTransactions.values.map((p) => PendingActivityItem(p)).toList();

  /// Check if there are any pending transactions
  bool get hasPending => _pendingTransactions.isNotEmpty;

  /// Add a new pending transaction and start the background send.
  ///
  /// Returns immediately after adding the pending item.
  /// The actual send happens in the background.
  Future<String> addPendingTransaction({
    required String address,
    required int amountSats,
    required Future<String> Function() sendFunction,
  }) async {
    final id = 'pending-${_uuid.v4()}';
    final pending = PendingTransaction(
      id: id,
      address: address,
      amountSats: amountSats,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );

    _pendingTransactions[id] = pending;
    notifyListeners();

    logger.i(
        'PendingTransactionService: Added pending tx $id for $amountSats sats to $address');

    // Execute the send in the background
    _executeSendInBackground(id, sendFunction);

    return id;
  }

  /// Execute the send operation in the background and update status when complete.
  Future<void> _executeSendInBackground(
    String pendingId,
    Future<String> Function() sendFunction,
  ) async {
    final pending = _pendingTransactions[pendingId];
    if (pending == null) return;

    try {
      logger.i(
          'PendingTransactionService: Starting background send for $pendingId');

      // Execute the actual send
      final txid = await sendFunction();

      logger.i('PendingTransactionService: Send successful! txid=$txid');

      // Update pending status
      pending.status = PendingTransactionStatus.success;
      pending.txid = txid;
      notifyListeners();

      // Show success bottom sheet
      _showCompletionBottomSheet(pending);

      // Remove from pending after a short delay (real tx should appear in history)
      Future.delayed(const Duration(seconds: 3), () {
        _removePending(pendingId);
      });
    } catch (e) {
      logger.e('PendingTransactionService: Send failed: $e');

      // Update pending status
      pending.status = PendingTransactionStatus.failed;
      pending.errorMessage = e.toString();
      notifyListeners();

      // Show error bottom sheet
      _showCompletionBottomSheet(pending);

      // Remove failed pending after showing error
      Future.delayed(const Duration(seconds: 5), () {
        _removePending(pendingId);
      });
    }
  }

  /// Remove a pending transaction from tracking
  void _removePending(String id) {
    if (_pendingTransactions.remove(id) != null) {
      logger.i('PendingTransactionService: Removed pending tx $id');
      notifyListeners();
    }
  }

  /// Remove pending transactions that match a real transaction (by txid)
  void reconcileWithRealTransactions(List<Transaction> transactions) {
    final toRemove = <String>[];

    for (final entry in _pendingTransactions.entries) {
      final pending = entry.value;
      if (pending.txid != null) {
        for (final tx in transactions) {
          if (pending.matchesTransaction(tx)) {
            toRemove.add(entry.key);
            break;
          }
        }
      }
    }

    for (final id in toRemove) {
      _pendingTransactions.remove(id);
      logger.i(
          'PendingTransactionService: Reconciled pending tx $id with real tx');
    }

    if (toRemove.isNotEmpty) {
      notifyListeners();
    }
  }

  /// Show a bottom sheet with the completion status
  void _showCompletionBottomSheet(PendingTransaction pending) {
    final context = OverlayService.navigatorKey.currentContext;
    if (context == null) {
      logger.w('PendingTransactionService: No context for bottom sheet');
      // Fall back to overlay
      if (pending.status == PendingTransactionStatus.success) {
        OverlayService().showSuccess(
            'Sent ${_formatSats(pending.amountSats)} successfully!');
      } else {
        OverlayService()
            .showError('Transaction failed: ${pending.errorMessage}');
      }
      return;
    }

    // Use larger height for errors since they may have longer messages
    final isSuccess = pending.status == PendingTransactionStatus.success;
    arkBottomSheet(
      context: context,
      height: isSuccess ? 450 : 500,
      child: _SendCompletionSheet(pending: pending),
    );
  }

  /// Format satoshis for display
  String _formatSats(int sats) {
    if (sats >= 100000000) {
      return '${(sats / 100000000).toStringAsFixed(8)} BTC';
    } else if (sats >= 1000000) {
      return '${(sats / 1000000).toStringAsFixed(2)}M sats';
    } else if (sats >= 1000) {
      return '${(sats / 1000).toStringAsFixed(1)}K sats';
    }
    return '$sats sats';
  }

  /// Clear all pending transactions (e.g., on logout)
  void clear() {
    _pendingTransactions.clear();
    notifyListeners();
  }
}

/// Bottom sheet widget showing send completion status
class _SendCompletionSheet extends StatelessWidget {
  final PendingTransaction pending;

  const _SendCompletionSheet({required this.pending});

  @override
  Widget build(BuildContext context) {
    final isSuccess = pending.status == PendingTransactionStatus.success;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(AppTheme.cardPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status icon
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: isSuccess
                  ? AppTheme.successColor.withValues(alpha: 0.15)
                  : AppTheme.errorColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSuccess ? Icons.check_rounded : Icons.close_rounded,
              size: 40,
              color: isSuccess ? AppTheme.successColor : AppTheme.errorColor,
            ),
          ),
          const SizedBox(height: AppTheme.elementSpacing),

          // Title
          Text(
            isSuccess ? 'Transaction Sent!' : 'Transaction Failed',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: AppTheme.elementSpacing / 2),

          // Amount or error
          if (isSuccess) ...[
            Text(
              _formatSats(pending.amountSats),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: AppTheme.elementSpacing / 2),
            Text(
              'to ${_truncateAddress(pending.address)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ] else ...[
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.cardPadding),
                  child: Text(
                    _cleanErrorMessage(pending.errorMessage),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.errorColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],

          const SizedBox(height: AppTheme.elementSpacing),

          // Close button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done'),
            ),
          ),
        ],
      ),
    );
  }

  String _formatSats(int sats) {
    if (sats >= 100000000) {
      return '${(sats / 100000000).toStringAsFixed(8)} BTC';
    } else if (sats >= 1000000) {
      return '${(sats / 1000000).toStringAsFixed(2)}M sats';
    } else if (sats >= 1000) {
      return '${(sats / 1000).toStringAsFixed(1)}K sats';
    }
    return '$sats sats';
  }

  String _truncateAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 8)}...${address.substring(address.length - 8)}';
  }

  /// Clean up error messages to be more user-friendly
  String _cleanErrorMessage(String? error) {
    if (error == null) return 'Unknown error';

    // Extract the main error message from AnyhowException wrapper
    String cleaned = error;
    if (cleaned.contains('AnyhowException(')) {
      cleaned = cleaned.replaceFirst('AnyhowException(', '');
      if (cleaned.endsWith(')')) {
        cleaned = cleaned.substring(0, cleaned.length - 1);
      }
    }

    // Check for specific known errors and provide user-friendly messages
    if (cleaned.contains('INVALID_PSBT_INPUT') &&
        cleaned.contains('expires after')) {
      return 'Your funds need to be refreshed before sending. Please wait for the next Ark round or try settling your balance first.';
    }

    if (cleaned.contains('minExpiryGap')) {
      return 'Your funds expire too soon to be used in this transaction. Please refresh your balance.';
    }

    // Remove metadata JSON if present
    if (cleaned.contains('metadata:')) {
      final metadataIndex = cleaned.indexOf('metadata:');
      cleaned = cleaned.substring(0, metadataIndex).trim();
    }

    // Trim and limit length
    if (cleaned.length > 200) {
      cleaned = '${cleaned.substring(0, 200)}...';
    }

    return cleaned;
  }
}
