import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/api/mempool_api.dart' as mempool_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/blinking_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

/// Bottom sheet widget for displaying transaction details.
class TransactionDetailSheet extends StatefulWidget {
  final String? txid;
  final int? amountSats;
  final int? createdAt;
  final String? transactionType;
  final String? networkType;
  final bool? isConfirmed;
  final bool isSettleable;

  const TransactionDetailSheet({
    super.key,
    this.txid,
    this.amountSats,
    this.createdAt,
    this.transactionType,
    this.networkType,
    this.isConfirmed,
    this.isSettleable = false,
  });

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  BitcoinTransaction? transactionModel;
  bool isLoading = true;
  bool hasError = false;
  String? txID;
  bool _isSettling = false;

  @override
  void initState() {
    super.initState();
    txID = widget.txid;
    if (txID != null) {
      _loadTransaction();
    } else {
      isLoading = false;
    }
  }

  Future<void> _loadTransaction() async {
    try {
      final esploraUrl = await SettingsService().getEsploraUrl();
      final tx = await mempool_api.getTransaction(
        txid: txID!,
        baseUrl: esploraUrl,
      );
      if (mounted) {
        setState(() {
          transactionModel = tx;
          isLoading = false;
          hasError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
      }
    }
  }

  Future<void> _handleSettlement(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isSettling = true;
    });

    try {
      await ark_api.settleBoarding();

      if (mounted) {
        setState(() {
          _isSettling = false;
        });

        OverlayService().showSuccess(l10n.transactionSettledSuccessfully);
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSettling = false;
        });

        OverlayService()
            .showError('${l10n.failedToSettleTransaction} ${e.toString()}');
      }
    }
  }

  String _formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'just now';
    }
  }

  String _formatPrice(String amount) {
    final value = int.tryParse(amount) ?? 0;
    final formatter = NumberFormat('#,###');
    return formatter.format(value);
  }

  /// Format amount with auto sats/BTC switching based on threshold
  (String, String, bool) _formatAmountWithUnit(int amountSats) {
    final absAmount = amountSats.abs();
    if (absAmount >= BitcoinConstants.satsPerBtc) {
      final btc = absAmount / BitcoinConstants.satsPerBtc;
      return (btc.toStringAsFixed(8), 'BTC', false);
    } else {
      final formatter = NumberFormat('#,###');
      return (formatter.format(absAmount), 'sats', true);
    }
  }

  bool _isSent(int? amountSats) {
    if (amountSats == null) return false;
    return amountSats < 0;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timezoneService =
        Provider.of<TimezoneService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    BigInt outputTotal = BigInt.zero;
    if (transactionModel != null) {
      for (var vout in transactionModel!.vout) {
        outputTotal += vout.value;
      }
    }

    final isSent = _isSent(widget.amountSats);
    final displayAmountSats = widget.amountSats ?? outputTotal.toInt();
    final (formattedAmount, unit, isSatsUnit) =
        _formatAmountWithUnit(displayAmountSats);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.cardPadding),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.transactionDetails,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Flexible(
            child: isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(AppTheme.cardPadding * 2),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.cardPadding,
                    ),
                    child: Column(
                      children: [
                        // Amount display
                        _buildAmountHeader(
                          context,
                          formattedAmount,
                          unit,
                          isSatsUnit,
                          isSent,
                          isDark,
                        ),
                        const SizedBox(height: AppTheme.cardPadding),
                        // Details
                        _buildDetailsCard(
                          context,
                          l10n,
                          timezoneService,
                          isDark,
                        ),
                        const SizedBox(height: AppTheme.cardPadding),
                      ],
                    ),
                  ),
          ),
          // Settle button
          if (widget.isSettleable)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.cardPadding),
                child: LongButtonWidget(
                  title: _isSettling ? l10n.settlingTransaction : l10n.settle,
                  customWidth: double.infinity,
                  customHeight: 48,
                  isLoading: _isSettling,
                  onTap: _isSettling ? null : () => _handleSettlement(context),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAmountHeader(
    BuildContext context,
    String formattedAmount,
    String unit,
    bool isSatsUnit,
    bool isSent,
    bool isDark,
  ) {
    return GlassContainer(
      borderRadius: AppTheme.cardRadiusBig,
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.cardPadding),
        child: Column(
          children: [
            // Direction icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (isSent ? AppTheme.errorColor : AppTheme.successColor)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isSent ? Icons.north_east : Icons.south_west,
                size: 32,
                color: isSent ? AppTheme.errorColor : AppTheme.successColor,
              ),
            ),
            const SizedBox(height: AppTheme.elementSpacing),
            // Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${isSent ? "-" : "+"}$formattedAmount',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isSent ? AppTheme.errorColor : AppTheme.successColor,
                      ),
                ),
                if (isSatsUnit)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      AppTheme.satoshiIcon,
                      size: 24,
                      color: isSent ? AppTheme.errorColor : AppTheme.successColor,
                    ),
                  )
                else
                  Text(
                    ' $unit',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: isSent ? AppTheme.errorColor : AppTheme.successColor,
                        ),
                  ),
              ],
            ),
            const SizedBox(height: AppTheme.elementSpacing * 0.5),
            Text(
              isSent ? 'Sent' : 'Received',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.white60 : AppTheme.black60,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsCard(
    BuildContext context,
    AppLocalizations l10n,
    TimezoneService timezoneService,
    bool isDark,
  ) {
    return GlassContainer(
      borderRadius: AppTheme.cardRadiusBig,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: AppTheme.elementSpacing,
        ),
        child: Column(
          children: [
            // Transaction ID
            if (txID != null)
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: l10n.transactionId,
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: txID!));
                  if (context.mounted) {
                    OverlayService().showSuccess(l10n.copiedToClipboard);
                  }
                },
                trailing: Row(
                  children: [
                    Icon(
                      Icons.copy,
                      color: isDark ? AppTheme.white60 : AppTheme.black60,
                      size: AppTheme.cardPadding * 0.75,
                    ),
                    const SizedBox(width: AppTheme.elementSpacing / 2),
                    SizedBox(
                      width: AppTheme.cardPadding * 5,
                      child: Text(
                        txID!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            // Status
            ArkListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              text: l10n.status,
              trailing: Row(
                children: [
                  BlinkingDot(
                    color: (widget.isConfirmed == true ||
                            transactionModel?.status.confirmed == true)
                        ? AppTheme.successColor
                        : AppTheme.colorBitcoin,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (widget.isConfirmed == true ||
                            transactionModel?.status.confirmed == true)
                        ? l10n.confirmed
                        : l10n.pending,
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                          color: (widget.isConfirmed == true ||
                                  transactionModel?.status.confirmed == true)
                              ? AppTheme.successColor
                              : AppTheme.colorBitcoin,
                        ),
                  ),
                ],
              ),
            ),
            // Transaction Type
            if (widget.transactionType != null)
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: l10n.type,
                trailing: Text(
                  widget.transactionType!,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            // Network
            ArkListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing,
                vertical: AppTheme.elementSpacing * 0.5,
              ),
              text: l10n.network,
              trailing: Row(
                children: [
                  Image.asset(
                    "assets/images/bitcoin.png",
                    width: AppTheme.cardPadding * 1,
                    height: AppTheme.cardPadding * 1,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.currency_bitcoin,
                        color: AppTheme.colorBitcoin,
                      );
                    },
                  ),
                  const SizedBox(width: AppTheme.elementSpacing / 2),
                  Text(
                    widget.networkType ?? 'Onchain',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            // Block (if available)
            if (transactionModel != null)
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: l10n.block,
                trailing: Text(
                  "${transactionModel!.status.blockHeight ?? "--"}",
                  style: Theme.of(context).textTheme.titleMedium!.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            // Time
            if (widget.createdAt != null ||
                (transactionModel?.status.confirmed == true &&
                    transactionModel?.status.blockTime != null))
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: 'Time',
                trailing: Builder(
                  builder: (context) {
                    final loc = timezoneService.location;
                    final timestamp = transactionModel?.status.blockTime?.toInt() ??
                        widget.createdAt;
                    if (timestamp == null) return const Text('--');

                    final datetime = DateTime.fromMillisecondsSinceEpoch(
                      timestamp * 1000,
                    ).toUtc().add(Duration(
                        milliseconds: loc.currentTimeZone.offset));

                    return Text(
                      '${DateFormat('MMM d, HH:mm').format(datetime)} (${_formatTimeAgo(datetime)})',
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  },
                ),
              ),
            // Fee (if available)
            if (transactionModel != null)
              ArkListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                  vertical: AppTheme.elementSpacing * 0.5,
                ),
                text: l10n.fee,
                trailing: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _formatPrice(transactionModel!.fee.toString()),
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'sats',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
