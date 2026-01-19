import 'dart:async';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/logger/logger.dart';
import 'package:ark_flutter/src/models/wallet_activity_item.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart';
import 'package:ark_flutter/src/services/analytics_service.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/payment_monitoring_service.dart';
import 'package:ark_flutter/src/services/recipient_storage_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    double? btcPrice,
  }) async {
    final id = 'pending-${_uuid.v4()}';
    final pending = PendingTransaction(
      id: id,
      address: address,
      amountSats: amountSats,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      btcPrice: btcPrice,
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

      // Track send transaction for analytics
      final recipientType =
          RecipientStorageService.determineType(pending.address);
      final transactionType =
          recipientType == RecipientType.onchain ? 'onchain' : 'offchain';
      await AnalyticsService().trackSendTransaction(
        amountSats: pending.amountSats,
        transactionType: transactionType,
        txId: txid,
      );

      // Update pending status
      pending.status = PendingTransactionStatus.success;
      pending.txid = txid;
      notifyListeners();

      // Trigger wallet refresh to show the new transaction
      PaymentMonitoringService().triggerWalletRefresh();

      // Show success bottom sheet
      _showCompletionBottomSheet(pending, btcPrice: pending.btcPrice);

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
      _showCompletionBottomSheet(pending, btcPrice: pending.btcPrice);

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
  void _showCompletionBottomSheet(PendingTransaction pending,
      {double? btcPrice}) {
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
      child: _SendCompletionSheet(pending: pending, btcPrice: btcPrice),
    );
  }

  /// Format satoshis for display
  String _formatSats(int sats) {
    if (sats >= BitcoinConstants.satsPerBtc) {
      return '${(sats / BitcoinConstants.satsPerBtc).toStringAsFixed(8)} BTC';
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

  /// Show a success bottom sheet for completed transactions (e.g., Lightning payments)
  /// This can be called directly without going through the pending transaction flow.
  void showSuccessBottomSheet({
    required String address,
    required int amountSats,
    String? txid,
    double? btcPrice,
  }) {
    final pending = PendingTransaction(
      id: 'direct-success',
      address: address,
      amountSats: amountSats,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    pending.status = PendingTransactionStatus.success;
    pending.txid = txid;

    _showCompletionBottomSheet(pending, btcPrice: btcPrice);
  }

  /// Show an error bottom sheet for failed transactions
  void showErrorBottomSheet({
    required String address,
    required int amountSats,
    required String errorMessage,
  }) {
    final pending = PendingTransaction(
      id: 'direct-error',
      address: address,
      amountSats: amountSats,
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    pending.status = PendingTransactionStatus.failed;
    pending.errorMessage = errorMessage;

    _showCompletionBottomSheet(pending);
  }
}

/// Bottom sheet widget showing send completion status
class _SendCompletionSheet extends StatefulWidget {
  final PendingTransaction pending;
  final double? btcPrice;

  const _SendCompletionSheet({required this.pending, this.btcPrice});

  @override
  State<_SendCompletionSheet> createState() => _SendCompletionSheetState();
}

class _SendCompletionSheetState extends State<_SendCompletionSheet> {
  bool _showSats = true;

  @override
  Widget build(BuildContext context) {
    final isSuccess = widget.pending.status == PendingTransactionStatus.success;
    final theme = Theme.of(context);
    final currencyService = context.watch<CurrencyPreferenceService>();

    return Column(
      children: [
        // Main content area - centered
        Expanded(
          child: Center(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Bani image for success, error icon for failure
                  if (isSuccess)
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: Image.asset(
                        'assets/images/bani/bani_success.png',
                        fit: BoxFit.contain,
                      ),
                    )
                  else
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.errorColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 64,
                        color: AppTheme.errorColor,
                      ),
                    ),
                  const SizedBox(height: AppTheme.cardPadding * 1.5),

                  // Amount or error
                  if (isSuccess) ...[
                    GestureDetector(
                      onTap: () => setState(() => _showSats = !_showSats),
                      behavior: HitTestBehavior.opaque,
                      child: _showSats
                          ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _formatSatsNumber(widget.pending.amountSats),
                                  style: theme.textTheme.displaySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Icon(
                                  AppTheme.satoshiIcon,
                                  size: 32,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ],
                            )
                          : Text(
                              _formatFiat(
                                  widget.pending.amountSats, currencyService),
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                    ),
                    const SizedBox(height: AppTheme.elementSpacing),
                    Text(
                      'Transaction Sent',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ] else ...[
                    Text(
                      'Transaction Failed',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.errorColor,
                      ),
                    ),
                    const SizedBox(height: AppTheme.elementSpacing),
                    Text(
                      _cleanErrorMessage(widget.pending.errorMessage),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.hintColor,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Bottom button
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: LongButtonWidget(
              title: 'Done',
              customWidth: double.infinity,
              onTap: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ],
    );
  }

  String _formatSatsNumber(int sats) {
    // Show full amount with thousand separators for clarity
    return _formatWithSeparators(sats);
  }

  String _formatWithSeparators(int number) {
    final str = number.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  String _formatFiat(int sats, CurrencyPreferenceService currencyService) {
    final btcPrice = widget.btcPrice ?? 0;
    if (btcPrice == 0) return '—';

    final btcAmount = sats / BitcoinConstants.satsPerBtc;
    // btcPrice is in USD, formatAmount converts from USD to user's currency
    final usdAmount = btcAmount * btcPrice;
    return currencyService.formatAmount(usdAmount);
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

    // Handle coin selection failures - usually means pending funds aren't confirmed yet
    if (cleaned.contains('failed to select coins') ||
        cleaned.contains('insufficient funds')) {
      if (cleaned.contains('selected = 0')) {
        return 'No confirmed funds available. Your balance may include pending deposits that need to settle first.';
      }
      return 'Insufficient confirmed funds to complete this transaction.';
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
