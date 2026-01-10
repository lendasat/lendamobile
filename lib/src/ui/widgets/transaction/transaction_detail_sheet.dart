import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/api/mempool_api.dart' as mempool_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
import 'package:ark_flutter/src/services/user_preferences_service.dart';
import 'package:ark_flutter/src/services/recipient_storage_service.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_bottom_sheet.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:ark_flutter/src/ui/widgets/blinking_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bottom sheet widget for displaying transaction details.
/// Uses the exact same UI as SingleTransactionScreen.
class TransactionDetailSheet extends StatefulWidget {
  final String? txid;
  final int? amountSats;
  final int? createdAt;
  final String? transactionType;
  final String? networkType;
  final bool? isConfirmed;
  final bool isSettleable;
  final double? bitcoinPrice;

  const TransactionDetailSheet({
    super.key,
    this.txid,
    this.amountSats,
    this.createdAt,
    this.transactionType,
    this.networkType,
    this.isConfirmed,
    this.isSettleable = false,
    this.bitcoinPrice,
  });

  @override
  State<TransactionDetailSheet> createState() => _TransactionDetailSheetState();
}

class _TransactionDetailSheetState extends State<TransactionDetailSheet> {
  final TextEditingController inputCtrl = TextEditingController();
  final TextEditingController outputCtrl = TextEditingController();

  BitcoinTransaction? transactionModel;
  // Start with isLoading = false - show basic info immediately, load details in background
  bool isLoading = false;
  bool hasError = false;
  String? txID;
  bool _isSettling = false;
  String? _recipientAddress;

  // Copy feedback states
  bool _showTxIdCopied = false;
  bool _showAddressCopied = false;

  @override
  void initState() {
    super.initState();
    txID = widget.txid;
    if (txID != null) {
      // Load transaction details in background - don't block UI
      // The fallback view shows immediately with basic info
      _loadTransaction();
      _loadRecipientAddress();
    }
  }

  Future<void> _loadRecipientAddress() async {
    if (txID == null) return;

    try {
      final recipients = await RecipientStorageService.getRecipients();
      // Find recipient by txid
      final match = recipients.where((r) => r.txid == txID).firstOrNull;
      if (match != null && mounted) {
        setState(() {
          _recipientAddress = match.address;
        });
      }
    } catch (e) {
      // Silently fail - address is optional
    }
  }

  void _copyTxId() {
    if (txID == null) return;
    Clipboard.setData(ClipboardData(text: txID!));
    HapticFeedback.lightImpact();
    setState(() => _showTxIdCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showTxIdCopied = false);
    });
  }

  void _copyAddress() {
    if (_recipientAddress == null) return;
    Clipboard.setData(ClipboardData(text: _recipientAddress!));
    HapticFeedback.lightImpact();
    setState(() => _showAddressCopied = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showAddressCopied = false);
    });
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

    // If date is in the future, return empty string to avoid "just now" forever bug
    if (difference.isNegative) {
      return '';
    }

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
    final currencyService = context.watch<CurrencyPreferenceService>();

    BigInt outputTotal = BigInt.zero;
    if (transactionModel != null) {
      for (var vout in transactionModel!.vout) {
        outputTotal += vout.value;
      }
    }

    final isSent = _isSent(widget.amountSats);
    final displayAmountSats = widget.amountSats ?? outputTotal.toInt();

    return ArkScaffoldUnsafe(
      context: context,
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: BitNetAppBar(
        text: l10n.transactionDetails,
        context: context,
        hasBackButton: false,
      ),
      // Only show settle button for boarding transactions that can be settled
      bottomSheet: widget.isSettleable &&
              widget.transactionType == l10n.boardingTransaction
          ? Container(
              padding: const EdgeInsets.all(AppTheme.cardPadding),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
              ),
              child: SafeArea(
                top: false,
                child: LongButtonWidget(
                  title: _isSettling ? l10n.settlingTransaction : l10n.settle,
                  customWidth: double.infinity,
                  customHeight: 48,
                  isLoading: _isSettling,
                  onTap: _isSettling ? null : () => _handleSettlement(context),
                ),
              ),
            )
          : null,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactionModel == null
              ? _buildFallbackView(context, l10n, timezoneService,
                  currencyService, displayAmountSats, isSent)
              : _buildFullView(context, l10n, timezoneService, currencyService,
                  displayAmountSats, isSent),
    );
  }

  Widget _buildFullView(
    BuildContext context,
    AppLocalizations l10n,
    TimezoneService timezoneService,
    CurrencyPreferenceService currencyService,
    int displayAmountSats,
    bool isSent,
  ) {
    final showCoinBalance = currencyService.showCoinBalance;
    final userPrefs = context.watch<UserPreferencesService>();
    final isObscured = !userPrefs.balancesVisible;
    final (formattedAmount, unit, isSatsUnit) =
        _formatAmountWithUnit(displayAmountSats);

    // Calculate fiat value - formatAmount handles currency conversion
    final btcAmount = displayAmountSats.abs() / BitcoinConstants.satsPerBtc;
    final btcPrice = widget.bitcoinPrice ?? 0.0;
    final fiatAmount = btcAmount * btcPrice;
    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        // Close bottom sheet when user overscrolls at the top
        if (notification.overscroll < 0 && notification.metrics.pixels == 0) {
          Navigator.of(context).pop();
          return true;
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppTheme.cardPadding * 3,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                ),
                child: GlassContainer(
                  borderRadius: AppTheme.cardRadiusBig,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.elementSpacing,
                      horizontal: AppTheme.elementSpacing,
                    ),
                    child: Column(
                      children: [
                        // Transaction header - Clean amount display
                        GestureDetector(
                          onTap: () => currencyService.toggleShowCoinBalance(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: AppTheme.cardPadding * 1.5,
                            ),
                            child: Column(
                              children: [
                                // Status pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.cardPadding * 0.75,
                                    vertical: AppTheme.elementSpacing * 0.4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isSent
                                            ? AppTheme.errorColor
                                            : AppTheme.successColor)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSent
                                            ? Icons.north_east_rounded
                                            : Icons.south_west_rounded,
                                        size: 14,
                                        color: isSent
                                            ? AppTheme.errorColor
                                            : AppTheme.successColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isSent ? l10n.sent : l10n.received,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: isSent
                                                  ? AppTheme.errorColor
                                                  : AppTheme.successColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppTheme.cardPadding),
                                // Large amount - toggles between sats/BTC and fiat
                                if (isObscured)
                                  Text(
                                    '****',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  )
                                else if (showCoinBalance)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${isSent ? '-' : '+'}$formattedAmount',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (isSatsUnit)
                                        Icon(
                                          AppTheme.satoshiIcon,
                                          size: 48,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        )
                                      else
                                        Text(
                                          unit,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                    ],
                                  )
                                else
                                  Text(
                                    '${isSent ? '-' : '+'}${currencyService.formatAmount(fiatAmount)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Nested details container
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.elementSpacing * 0.5,
                            vertical: AppTheme.elementSpacing,
                          ),
                          child: GlassContainer(
                            opacity: 0.05,
                            borderRadius: AppTheme.cardRadiusSmall,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.elementSpacing,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Transaction ID
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.transactionId,
                                    onTap: _copyTxId,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: AppTheme.cardPadding * 6,
                                          child: _showTxIdCopied
                                              ? Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.end,
                                                  children: [
                                                    const Icon(
                                                      Icons.check,
                                                      color:
                                                          AppTheme.successColor,
                                                      size:
                                                          AppTheme.cardPadding *
                                                              0.75,
                                                    ),
                                                    const SizedBox(
                                                        width: AppTheme
                                                                .elementSpacing /
                                                            2),
                                                    Text(
                                                      l10n.copied,
                                                      style: const TextStyle(
                                                        color: AppTheme
                                                            .successColor,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  mainAxisSize:
                                                      MainAxisSize.max,
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        txID!,
                                                        style: Theme.of(context)
                                                            .textTheme
                                                            .bodyMedium,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                    const SizedBox(
                                                        width: AppTheme
                                                                .elementSpacing /
                                                            2),
                                                    Icon(
                                                      Icons.copy,
                                                      color: AppTheme.white60,
                                                      size:
                                                          AppTheme.cardPadding *
                                                              0.75,
                                                    ),
                                                  ],
                                                ),
                                        ),
                                        const SizedBox(
                                            width: AppTheme.elementSpacing / 2),
                                        InkWell(
                                          onTap: () async {
                                            final url = Uri.parse(
                                                'https://arkade.space/tx/$txID');
                                            if (await canLaunchUrl(url)) {
                                              await launchUrl(url,
                                                  mode: LaunchMode
                                                      .externalApplication);
                                            }
                                          },
                                          child: const Icon(
                                            Icons.open_in_new,
                                            color: AppTheme.colorBitcoin,
                                            size: AppTheme.cardPadding * 0.75,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Recipient Address (if available from storage)
                                  if (_recipientAddress != null)
                                    ArkListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.address,
                                      onTap: _copyAddress,
                                      trailing: SizedBox(
                                        width: AppTheme.cardPadding * 6,
                                        child: _showAddressCopied
                                            ? Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  const Icon(
                                                    Icons.check,
                                                    color:
                                                        AppTheme.successColor,
                                                    size: AppTheme.cardPadding *
                                                        0.75,
                                                  ),
                                                  const SizedBox(
                                                      width: AppTheme
                                                              .elementSpacing /
                                                          2),
                                                  Text(
                                                    l10n.copied,
                                                    style: const TextStyle(
                                                      color:
                                                          AppTheme.successColor,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _recipientAddress!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: AppTheme
                                                              .elementSpacing /
                                                          2),
                                                  Icon(
                                                    Icons.copy,
                                                    color: AppTheme.white60,
                                                    size: AppTheme.cardPadding *
                                                        0.75,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                  // Block
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.block,
                                    trailing: Row(
                                      children: [
                                        Text(
                                          "${transactionModel!.status.blockHeight ?? "--"}",
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Status
                                  // For Arkade transactions, show "Spendable" (green) if not fully
                                  // settled, "Confirmed" (green) if settled. This hides technical
                                  // complexity - users can spend funds immediately in Arkade.
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.status,
                                    trailing: Row(
                                      children: [
                                        BlinkingDot(
                                          color: widget.networkType == 'Arkade'
                                              ? AppTheme.successColor
                                              : (transactionModel!
                                                      .status.confirmed
                                                  ? AppTheme.successColor
                                                  : AppTheme.colorBitcoin),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.networkType == 'Arkade'
                                              ? (widget.isSettleable
                                                  ? l10n.confirmed
                                                  : l10n.spendable)
                                              : (transactionModel!
                                                      .status.confirmed
                                                  ? l10n.confirmed
                                                  : l10n.pending),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                color: widget.networkType ==
                                                        'Arkade'
                                                    ? AppTheme.successColor
                                                    : (transactionModel!
                                                            .status.confirmed
                                                        ? AppTheme.successColor
                                                        : AppTheme
                                                            .colorBitcoin),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Network
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.network,
                                    trailing: Row(
                                      children: [
                                        Image.asset(
                                          "assets/images/bitcoin.png",
                                          width: AppTheme.cardPadding * 1,
                                          height: AppTheme.cardPadding * 1,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.currency_bitcoin,
                                              color: AppTheme.colorBitcoin,
                                            );
                                          },
                                        ),
                                        const SizedBox(
                                            width: AppTheme.elementSpacing / 2),
                                        Text(
                                          widget.networkType ?? 'Onchain',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Time
                                  if (transactionModel!.status.confirmed &&
                                      transactionModel!.status.blockTime !=
                                          null)
                                    ArkListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.time,
                                      trailing: Builder(
                                        builder: (context) {
                                          if (widget.createdAt == null) {
                                            return const SizedBox.shrink();
                                          }
                                          final datetime = DateTime
                                              .fromMillisecondsSinceEpoch(
                                            widget.createdAt! * 1000,
                                          );
                                          final timeAgo =
                                              _formatTimeAgo(datetime);
                                          final formattedDateTime = timeAgo
                                                  .isEmpty
                                              ? DateFormat('yyyy-MM-dd HH:mm')
                                                  .format(datetime)
                                              : '${DateFormat('yyyy-MM-dd HH:mm').format(datetime)} ($timeAgo)';
                                          return SizedBox(
                                            width: AppTheme.cardPadding * 7,
                                            child: Text(
                                              formattedDateTime,
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 2,
                                              textAlign: TextAlign.end,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                            ),
                                          );
                                        },
                                      ),
                                    ),

                                  // Fee
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.fee,
                                    trailing: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _formatPrice(
                                              transactionModel!.fee.toString()),
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'sats',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackView(
    BuildContext context,
    AppLocalizations l10n,
    TimezoneService timezoneService,
    CurrencyPreferenceService currencyService,
    int displayAmountSats,
    bool isSent,
  ) {
    final showCoinBalance = currencyService.showCoinBalance;
    final userPrefs = context.watch<UserPreferencesService>();
    final isObscured = !userPrefs.balancesVisible;
    final (formattedAmount, unit, isSatsUnit) =
        _formatAmountWithUnit(displayAmountSats);

    // Calculate fiat value - formatAmount handles currency conversion
    final btcAmount = displayAmountSats.abs() / BitcoinConstants.satsPerBtc;
    final btcPrice = widget.bitcoinPrice ?? 0.0;
    final fiatAmount = btcAmount * btcPrice;

    String formattedDate = '--';
    if (widget.createdAt != null) {
      final datetime = DateTime.fromMillisecondsSinceEpoch(
        widget.createdAt! * 1000,
      );
      final timeAgo = _formatTimeAgo(datetime);
      formattedDate = timeAgo.isEmpty
          ? DateFormat('yyyy-MM-dd HH:mm').format(datetime)
          : '${DateFormat('yyyy-MM-dd HH:mm').format(datetime)} ($timeAgo)';
    }

    return NotificationListener<OverscrollNotification>(
      onNotification: (notification) {
        // Close bottom sheet when user overscrolls at the top
        if (notification.overscroll < 0 && notification.metrics.pixels == 0) {
          Navigator.of(context).pop();
          return true;
        }
        return false;
      },
      child: SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(
            top: AppTheme.cardPadding * 3,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.elementSpacing,
                ),
                child: GlassContainer(
                  borderRadius: AppTheme.cardRadiusBig,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.elementSpacing,
                      horizontal: AppTheme.elementSpacing,
                    ),
                    child: Column(
                      children: [
                        // Transaction header - Clean amount display
                        GestureDetector(
                          onTap: () => currencyService.toggleShowCoinBalance(),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: AppTheme.cardPadding * 1.5,
                            ),
                            child: Column(
                              children: [
                                // Status pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.cardPadding * 0.75,
                                    vertical: AppTheme.elementSpacing * 0.4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: (isSent
                                            ? AppTheme.errorColor
                                            : AppTheme.successColor)
                                        .withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        isSent
                                            ? Icons.north_east_rounded
                                            : Icons.south_west_rounded,
                                        size: 14,
                                        color: isSent
                                            ? AppTheme.errorColor
                                            : AppTheme.successColor,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        isSent ? l10n.sent : l10n.received,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelMedium
                                            ?.copyWith(
                                              color: isSent
                                                  ? AppTheme.errorColor
                                                  : AppTheme.successColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: AppTheme.cardPadding),
                                // Large amount - toggles between sats/BTC and fiat
                                if (isObscured)
                                  Text(
                                    '****',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  )
                                else if (showCoinBalance)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      Text(
                                        '${isSent ? '-' : '+'}$formattedAmount',
                                        style: Theme.of(context)
                                            .textTheme
                                            .displayMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                      ),
                                      const SizedBox(width: 4),
                                      if (isSatsUnit)
                                        Icon(
                                          AppTheme.satoshiIcon,
                                          size: 48,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        )
                                      else
                                        Text(
                                          unit,
                                          style: Theme.of(context)
                                              .textTheme
                                              .headlineSmall
                                              ?.copyWith(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                                fontWeight: FontWeight.w500,
                                              ),
                                        ),
                                    ],
                                  )
                                else
                                  Text(
                                    '${isSent ? '-' : '+'}${currencyService.formatAmount(fiatAmount)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                  ),
                              ],
                            ),
                          ),
                        ),

                        // Nested details container
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.elementSpacing * 0.5,
                            vertical: AppTheme.elementSpacing,
                          ),
                          child: GlassContainer(
                            opacity: 0.05,
                            borderRadius: AppTheme.cardRadiusSmall,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppTheme.elementSpacing,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Transaction ID
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.transactionId,
                                    onTap: txID != null ? _copyTxId : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: AppTheme.cardPadding * 6,
                                          child: txID != null
                                              ? (_showTxIdCopied
                                                  ? Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      mainAxisAlignment:
                                                          MainAxisAlignment.end,
                                                      children: [
                                                        const Icon(
                                                          Icons.check,
                                                          color: AppTheme
                                                              .successColor,
                                                          size: AppTheme
                                                                  .cardPadding *
                                                              0.75,
                                                        ),
                                                        const SizedBox(
                                                            width: AppTheme
                                                                    .elementSpacing /
                                                                2),
                                                        Text(
                                                          l10n.copied,
                                                          style:
                                                              const TextStyle(
                                                            color: AppTheme
                                                                .successColor,
                                                          ),
                                                        ),
                                                      ],
                                                    )
                                                  : Row(
                                                      mainAxisSize:
                                                          MainAxisSize.max,
                                                      children: [
                                                        Expanded(
                                                          child: Text(
                                                            txID!,
                                                            style: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodyMedium,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: AppTheme
                                                                    .elementSpacing /
                                                                2),
                                                        Icon(
                                                          Icons.copy,
                                                          color:
                                                              AppTheme.white60,
                                                          size: AppTheme
                                                                  .cardPadding *
                                                              0.75,
                                                        ),
                                                      ],
                                                    ))
                                              : Text(
                                                  '--',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodyMedium,
                                                ),
                                        ),
                                        if (txID != null)
                                          const SizedBox(
                                            width: AppTheme.elementSpacing / 2,
                                          ),
                                        if (txID != null)
                                          InkWell(
                                            onTap: () async {
                                              final url = Uri.parse(
                                                  'https://arkade.space/tx/$txID');
                                              if (await canLaunchUrl(url)) {
                                                await launchUrl(url,
                                                    mode: LaunchMode
                                                        .externalApplication);
                                              }
                                            },
                                            child: Icon(
                                              Icons.open_in_new,
                                              color: AppTheme.white60,
                                              size: AppTheme.cardPadding * 0.75,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),

                                  // Recipient Address (if available from storage)
                                  if (_recipientAddress != null)
                                    ArkListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.address,
                                      onTap: _copyAddress,
                                      trailing: SizedBox(
                                        width: AppTheme.cardPadding * 6,
                                        child: _showAddressCopied
                                            ? Row(
                                                mainAxisSize: MainAxisSize.max,
                                                mainAxisAlignment:
                                                    MainAxisAlignment.end,
                                                children: [
                                                  const Icon(
                                                    Icons.check,
                                                    color:
                                                        AppTheme.successColor,
                                                    size: AppTheme.cardPadding *
                                                        0.75,
                                                  ),
                                                  const SizedBox(
                                                      width: AppTheme
                                                              .elementSpacing /
                                                          2),
                                                  Text(
                                                    l10n.copied,
                                                    style: const TextStyle(
                                                      color:
                                                          AppTheme.successColor,
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : Row(
                                                mainAxisSize: MainAxisSize.max,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      _recipientAddress!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                  const SizedBox(
                                                      width: AppTheme
                                                              .elementSpacing /
                                                          2),
                                                  Icon(
                                                    Icons.copy,
                                                    color: AppTheme.white60,
                                                    size: AppTheme.cardPadding *
                                                        0.75,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                  // Status
                                  // For Arkade transactions, show "Spendable" (green) if not fully
                                  // settled, "Confirmed" (green) if settled. This hides technical
                                  // complexity - users can spend funds immediately in Arkade.
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.status,
                                    trailing: Row(
                                      children: [
                                        BlinkingDot(
                                          color: widget.networkType == 'Arkade'
                                              ? AppTheme.successColor
                                              : (widget.isConfirmed == true
                                                  ? AppTheme.successColor
                                                  : AppTheme.colorBitcoin),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.networkType == 'Arkade'
                                              ? (widget.isSettleable
                                                  ? l10n.confirmed
                                                  : l10n.spendable)
                                              : (widget.isConfirmed == true
                                                  ? l10n.confirmed
                                                  : l10n.pending),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                color: widget.networkType ==
                                                        'Arkade'
                                                    ? AppTheme.successColor
                                                    : (widget.isConfirmed ==
                                                            true
                                                        ? AppTheme.successColor
                                                        : AppTheme
                                                            .colorBitcoin),
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Network
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.network,
                                    trailing: Row(
                                      children: [
                                        Image.asset(
                                          "assets/images/bitcoin.png",
                                          width: AppTheme.cardPadding * 1,
                                          height: AppTheme.cardPadding * 1,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return const Icon(
                                              Icons.currency_bitcoin,
                                              color: AppTheme.colorBitcoin,
                                            );
                                          },
                                        ),
                                        const SizedBox(
                                          width: AppTheme.elementSpacing / 2,
                                        ),
                                        Text(
                                          widget.networkType ?? 'Arkade',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium,
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Time
                                  if (widget.createdAt != null)
                                    ArkListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.time,
                                      trailing: SizedBox(
                                        width: AppTheme.cardPadding * 7,
                                        child: Text(
                                          formattedDate,
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                          textAlign: TextAlign.end,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showInputsBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return arkBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      height: MediaQuery.of(context).size.height * 0.6,
      child: ArkScaffoldUnsafe(
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        context: context,
        appBar: BitNetAppBar(
          context: context,
          hasBackButton: false,
          text: l10n.inputs,
        ),
        body: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.cardPadding * 2.5),
                  SearchFieldWidget(
                    hintText: l10n.search,
                    handleSearch: (v) {
                      setState(() {
                        inputCtrl.text = v;
                      });
                    },
                    isSearchEnabled: true,
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: GlassContainer(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: transactionModel?.vin
                                      .where((v) => v.prevout != null)
                                      .length ??
                                  0,
                              itemBuilder: (context, index) {
                                final vin = transactionModel!.vin
                                    .where((v) => v.prevout != null)
                                    .toList()[index];
                                final value = (vin.prevout!.value.toDouble()) /
                                    BitcoinConstants.satsPerBtc;
                                final address =
                                    vin.prevout?.scriptpubkeyAddress ?? '';

                                if (!address.contains(inputCtrl.text)) {
                                  return const SizedBox();
                                }

                                return _buildAddressItem(
                                  context: context,
                                  address: address,
                                  value: value,
                                  isInput: true,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _showOutputsBottomSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return arkBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      height: MediaQuery.of(context).size.height * 0.6,
      child: ArkScaffoldUnsafe(
        extendBodyBehindAppBar: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        context: context,
        appBar: BitNetAppBar(
          context: context,
          hasBackButton: false,
          text: l10n.outputs,
        ),
        body: StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.cardPadding,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.cardPadding * 2.5),
                  SearchFieldWidget(
                    hintText: l10n.search,
                    handleSearch: (v) {
                      setState(() {
                        outputCtrl.text = v;
                      });
                    },
                    isSearchEnabled: true,
                  ),
                  const SizedBox(height: AppTheme.elementSpacing),
                  Expanded(
                    child: MediaQuery.removePadding(
                      context: context,
                      removeTop: true,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: GlassContainer(
                            child: ListView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: transactionModel?.vout.length ?? 0,
                              itemBuilder: (context, index) {
                                final vout = transactionModel!.vout[index];
                                final value = vout.value.toDouble() /
                                    BitcoinConstants.satsPerBtc;
                                final address = vout.scriptpubkeyAddress ?? '';

                                if (!address.contains(outputCtrl.text)) {
                                  return const SizedBox();
                                }

                                return _buildAddressItem(
                                  context: context,
                                  address: address,
                                  value: value,
                                  isInput: false,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAddressItem({
    required BuildContext context,
    required String address,
    required double value,
    required bool isInput,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppTheme.elementSpacing,
        horizontal: AppTheme.elementSpacing * 0.75,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                const Avatar(
                  size: AppTheme.cardPadding * 2,
                  isNft: false,
                ),
                const SizedBox(width: AppTheme.elementSpacing * 0.75),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        address.isNotEmpty
                            ? '${address.substring(0, 8)}...${address.substring(address.length - 8)}'
                            : 'Unknown',
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Image.asset(
                            "assets/images/bitcoin.png",
                            width: AppTheme.cardPadding * 0.75,
                            height: AppTheme.cardPadding * 0.75,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.currency_bitcoin,
                                size: 12,
                                color: AppTheme.colorBitcoin,
                              );
                            },
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Onchain',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Text(
            value.toStringAsFixed(8),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  color: isInput ? AppTheme.errorColor : AppTheme.successColor,
                ),
          ),
        ],
      ),
    );
  }
}
