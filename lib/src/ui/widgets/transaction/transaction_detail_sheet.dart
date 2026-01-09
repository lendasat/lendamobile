import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/api/ark_api.dart' as ark_api;
import 'package:ark_flutter/src/rust/api/mempool_api.dart' as mempool_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/currency_preference_service.dart';
import 'package:ark_flutter/src/services/overlay_service.dart';
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
  bool isLoading = true;
  bool hasError = false;
  String? txID;
  bool _isSettling = false;
  String? _recipientAddress;

  @override
  void initState() {
    super.initState();
    txID = widget.txid;
    if (txID != null) {
      _loadTransaction();
      _loadRecipientAddress();
    } else {
      isLoading = false;
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
      bottomSheet: widget.isSettleable
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
                        // Transaction header with sender and receiver
                        Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: AppTheme.cardPadding * 0.75,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      Avatar(
                                        size: AppTheme.cardPadding * 4,
                                        onTap: () {
                                          _showInputsBottomSheet(context);
                                        },
                                        isNft: false,
                                      ),
                                      const SizedBox(
                                        height: AppTheme.elementSpacing * 0.5,
                                      ),
                                      Text(
                                        "${l10n.sender} (${transactionModel?.vin.where((v) => v.prevout != null).length})",
                                      ),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: AppTheme.cardPadding * 0.75,
                                  ),
                                  Icon(
                                    Icons.double_arrow_rounded,
                                    size: AppTheme.cardPadding * 2.5,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.white80
                                        : AppTheme.black60,
                                  ),
                                  const SizedBox(
                                    width: AppTheme.cardPadding * 0.75,
                                  ),
                                  Column(
                                    children: [
                                      Avatar(
                                        size: AppTheme.cardPadding * 4,
                                        isNft: false,
                                        onTap: () {
                                          _showOutputsBottomSheet(context);
                                        },
                                      ),
                                      const SizedBox(
                                        height: AppTheme.elementSpacing * 0.5,
                                      ),
                                      Text(
                                        "${l10n.receiver} (${transactionModel?.vout.length})",
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
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
                                  // Transaction Volume (tappable to toggle currency)
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.transactionVolume,
                                    onTap: widget.bitcoinPrice != null
                                        ? () => currencyService
                                            .toggleShowCoinBalance()
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (showCoinBalance) ...[
                                          Text(
                                            '${isSent ? '-' : '+'}$formattedAmount',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          if (isSatsUnit)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 2),
                                              child: Icon(
                                                AppTheme.satoshiIcon,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            )
                                          else
                                            Text(
                                              ' $unit',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                        ] else ...[
                                          Text(
                                            '${isSent ? '-' : '+'}${currencyService.formatAmount(fiatAmount)}',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Direction
                                  if (widget.amountSats != null)
                                    ArkListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.direction,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSent
                                                ? Icons.north_east
                                                : Icons.south_west,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isSent ? l10n.sent : l10n.received,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Transaction ID
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.transactionId,
                                    onTap: () async {
                                      await Clipboard.setData(
                                          ClipboardData(text: txID!));
                                      if (context.mounted) {
                                        OverlayService().showSuccess(
                                            l10n.copiedToClipboard);
                                      }
                                    },
                                    trailing: Row(
                                      children: [
                                        SizedBox(
                                          width: AppTheme.cardPadding * 5,
                                          child: Text(
                                            txID!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(
                                            width: AppTheme.elementSpacing / 2),
                                        Icon(
                                          Icons.copy,
                                          color: AppTheme.white60,
                                          size: AppTheme.cardPadding * 0.75,
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
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.address,
                                      onTap: () async {
                                        await Clipboard.setData(
                                            ClipboardData(text: _recipientAddress!));
                                        if (context.mounted) {
                                          OverlayService().showSuccess(
                                              l10n.copiedToClipboard);
                                        }
                                      },
                                      trailing: Row(
                                        children: [
                                          SizedBox(
                                            width: AppTheme.cardPadding * 5,
                                            child: Text(
                                              _recipientAddress!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppTheme.elementSpacing / 2),
                                          Icon(
                                            Icons.copy,
                                            color: AppTheme.white60,
                                            size: AppTheme.cardPadding * 0.75,
                                          ),
                                        ],
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
                                          color:
                                              transactionModel!.status.confirmed
                                                  ? AppTheme.successColor
                                                  : AppTheme.colorBitcoin,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          transactionModel!.status.confirmed
                                              ? l10n.confirmed
                                              : l10n.pending,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                color: transactionModel!
                                                        .status.confirmed
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
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.type,
                                      trailing: Text(
                                        widget.transactionType!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
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
                                          final loc = timezoneService.location;
                                          final datetime = DateTime
                                              .fromMillisecondsSinceEpoch(
                                            transactionModel!.status.blockTime!
                                                    .toInt() *
                                                1000,
                                          ).toUtc().add(Duration(
                                              milliseconds:
                                                  loc.currentTimeZone.offset));
                                          return SizedBox(
                                            width: AppTheme.cardPadding * 7,
                                            child: Text(
                                              '${DateFormat('yyyy-MM-dd HH:mm').format(datetime)}'
                                              ' (${_formatTimeAgo(datetime)})',
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
    final (formattedAmount, unit, isSatsUnit) =
        _formatAmountWithUnit(displayAmountSats);

    // Calculate fiat value - formatAmount handles currency conversion
    final btcAmount = displayAmountSats.abs() / BitcoinConstants.satsPerBtc;
    final btcPrice = widget.bitcoinPrice ?? 0.0;
    final fiatAmount = btcAmount * btcPrice;

    String formattedDate = '--';
    if (widget.createdAt != null) {
      final loc = timezoneService.location;
      final datetime = DateTime.fromMillisecondsSinceEpoch(
        widget.createdAt! * 1000,
      ).toUtc().add(Duration(milliseconds: loc.currentTimeZone.offset));
      formattedDate =
          '${DateFormat('yyyy-MM-dd HH:mm').format(datetime)} (${_formatTimeAgo(datetime)})';
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
                        // Transaction header
                        Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: AppTheme.cardPadding * 0.75,
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Column(
                                    children: [
                                      const Avatar(
                                        size: AppTheme.cardPadding * 4,
                                        isNft: false,
                                      ),
                                      const SizedBox(
                                        height: AppTheme.elementSpacing * 0.5,
                                      ),
                                      Text(l10n.sender),
                                    ],
                                  ),
                                  const SizedBox(
                                    width: AppTheme.cardPadding * 0.75,
                                  ),
                                  Icon(
                                    Icons.double_arrow_rounded,
                                    size: AppTheme.cardPadding * 2.5,
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? AppTheme.white80
                                        : AppTheme.black60,
                                  ),
                                  const SizedBox(
                                    width: AppTheme.cardPadding * 0.75,
                                  ),
                                  Column(
                                    children: [
                                      const Avatar(
                                        size: AppTheme.cardPadding * 4,
                                        isNft: false,
                                      ),
                                      const SizedBox(
                                        height: AppTheme.elementSpacing * 0.5,
                                      ),
                                      Text(l10n.receiver),
                                    ],
                                  ),
                                ],
                              ),
                            ],
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
                                  // Transaction Volume (tappable to toggle currency)
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.transactionVolume,
                                    onTap: widget.bitcoinPrice != null
                                        ? () => currencyService
                                            .toggleShowCoinBalance()
                                        : null,
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (showCoinBalance) ...[
                                          Text(
                                            '${isSent ? '-' : '+'}$formattedAmount',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                          if (isSatsUnit)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 2),
                                              child: Icon(
                                                AppTheme.satoshiIcon,
                                                size: 16,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                              ),
                                            )
                                          else
                                            Text(
                                              ' $unit',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                        ] else ...[
                                          Text(
                                            '${isSent ? '-' : '+'}${currencyService.formatAmount(fiatAmount)}',
                                            overflow: TextOverflow.ellipsis,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),

                                  // Direction
                                  if (widget.amountSats != null)
                                    ArkListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.direction,
                                      trailing: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            isSent
                                                ? Icons.north_east
                                                : Icons.south_west,
                                            size: 18,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            isSent ? l10n.sent : l10n.received,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Transaction ID
                                  ArkListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal:
                                          AppTheme.elementSpacing * 0.75,
                                      vertical: AppTheme.elementSpacing * 0.5,
                                    ),
                                    text: l10n.transactionId,
                                    onTap: txID != null
                                        ? () async {
                                            await Clipboard.setData(
                                              ClipboardData(text: txID!),
                                            );
                                            if (context.mounted) {
                                              OverlayService().showSuccess(
                                                  l10n.copiedToClipboard);
                                            }
                                          }
                                        : null,
                                    trailing: Row(
                                      children: [
                                        SizedBox(
                                          width: AppTheme.cardPadding * 5,
                                          child: Text(
                                            txID ?? '--',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (txID != null)
                                          const SizedBox(
                                            width: AppTheme.elementSpacing / 2,
                                          ),
                                        if (txID != null)
                                          Icon(
                                            Icons.copy,
                                            color: AppTheme.white60,
                                            size: AppTheme.cardPadding * 0.75,
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
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.address,
                                      onTap: () async {
                                        await Clipboard.setData(
                                            ClipboardData(text: _recipientAddress!));
                                        if (context.mounted) {
                                          OverlayService().showSuccess(
                                              l10n.copiedToClipboard);
                                        }
                                      },
                                      trailing: Row(
                                        children: [
                                          SizedBox(
                                            width: AppTheme.cardPadding * 5,
                                            child: Text(
                                              _recipientAddress!,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(
                                              width: AppTheme.elementSpacing / 2),
                                          Icon(
                                            Icons.copy,
                                            color: AppTheme.white60,
                                            size: AppTheme.cardPadding * 0.75,
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Transaction Type
                                  if (widget.transactionType != null)
                                    ArkListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal:
                                            AppTheme.elementSpacing * 0.75,
                                        vertical: AppTheme.elementSpacing * 0.5,
                                      ),
                                      text: l10n.type,
                                      trailing: Row(
                                        children: [
                                          Text(
                                            widget.transactionType!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Status
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
                                          color: widget.isConfirmed == true
                                              ? AppTheme.successColor
                                              : AppTheme.colorBitcoin,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          widget.isConfirmed == true
                                              ? l10n.confirmed
                                              : l10n.pending,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium!
                                              .copyWith(
                                                color:
                                                    widget.isConfirmed == true
                                                        ? AppTheme.successColor
                                                        : AppTheme.colorBitcoin,
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
