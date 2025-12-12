import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/rust/api/mempool_api.dart' as mempool_api;
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/services/settings_service.dart';
import 'package:ark_flutter/src/services/timezone_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_app_bar.dart';
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

class SingleTransactionScreen extends StatefulWidget {
  final String? txid;

  const SingleTransactionScreen({super.key, this.txid});

  @override
  State<SingleTransactionScreen> createState() =>
      _SingleTransactionScreenState();
}

class _SingleTransactionScreenState extends State<SingleTransactionScreen> {
  final TextEditingController inputCtrl = TextEditingController();
  final TextEditingController outputCtrl = TextEditingController();

  BitcoinTransaction? transactionModel;
  bool isLoading = true;
  String? txID;

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
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final timezoneService =
        Provider.of<TimezoneService>(context, listen: false);

    BigInt outputTotal = BigInt.zero;

    if (transactionModel != null) {
      for (var vout in transactionModel!.vout) {
        outputTotal += vout.value;
      }
    }

    return ArkScaffold(
      context: context,
      extendBodyBehindAppBar: true,
      appBar: ArkAppBar(
        text: l10n.transactionDetails,
        context: context,
        onTap: () {
          Navigator.pop(context);
        },
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : transactionModel == null
              ? Center(child: Text(l10n.errorLoadingTransaction))
              : SingleChildScrollView(
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Column(
                                              children: [
                                                Avatar(
                                                  size:
                                                      AppTheme.cardPadding *
                                                          4,
                                                  onTap: () {
                                                    _showInputsBottomSheet(
                                                        context);
                                                  },
                                                  isNft: false,
                                                ),
                                                const SizedBox(
                                                  height: AppTheme
                                                          .elementSpacing *
                                                      0.5,
                                                ),
                                                Text(
                                                  "Sender (${transactionModel?.vin.where((v) => v.prevout != null).length})",
                                                ),
                                              ],
                                            ),
                                            const SizedBox(
                                              width: AppTheme.cardPadding *
                                                  0.75,
                                            ),
                                            Icon(
                                              Icons.double_arrow_rounded,
                                              size:
                                                  AppTheme.cardPadding * 2.5,
                                              color: Theme.of(context)
                                                          .brightness ==
                                                      Brightness.dark
                                                  ? AppTheme.white80
                                                  : AppTheme.black60,
                                            ),
                                            const SizedBox(
                                              width: AppTheme.cardPadding *
                                                  0.75,
                                            ),
                                            Column(
                                              children: [
                                                Avatar(
                                                  size:
                                                      AppTheme.cardPadding *
                                                          4,
                                                  isNft: false,
                                                  onTap: () {
                                                    _showOutputsBottomSheet(
                                                        context);
                                                  },
                                                ),
                                                const SizedBox(
                                                  height: AppTheme
                                                          .elementSpacing *
                                                      0.5,
                                                ),
                                                Text(
                                                  "Receiver (${transactionModel?.vout.length})",
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
                                      horizontal:
                                          AppTheme.elementSpacing * 0.5,
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            // Transaction Volume
                                            ArkListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    AppTheme.elementSpacing *
                                                        0.75,
                                                vertical:
                                                    AppTheme.elementSpacing *
                                                        0.5,
                                              ),
                                              text: 'Transaction Volume',
                                              trailing: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    '${(outputTotal.toDouble() / 100000000).toStringAsFixed(8)} BTC',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Transaction ID
                                            ArkListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    AppTheme.elementSpacing *
                                                        0.75,
                                                vertical:
                                                    AppTheme.elementSpacing *
                                                        0.5,
                                              ),
                                              text: l10n.transactionId,
                                              onTap: () async {
                                                await Clipboard.setData(
                                                  ClipboardData(text: txID!),
                                                );
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                        l10n.copiedToClipboard,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                              trailing: Row(
                                                children: [
                                                  Icon(
                                                    Icons.copy,
                                                    color: AppTheme.white60,
                                                    size: AppTheme
                                                            .cardPadding *
                                                        0.75,
                                                  ),
                                                  const SizedBox(
                                                    width: AppTheme
                                                            .elementSpacing /
                                                        2,
                                                  ),
                                                  SizedBox(
                                                    width: AppTheme
                                                            .cardPadding *
                                                        5,
                                                    child: Text(
                                                      txID!,
                                                      style: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Block information
                                            ArkListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    AppTheme.elementSpacing *
                                                        0.75,
                                                vertical:
                                                    AppTheme.elementSpacing *
                                                        0.5,
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
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Status
                                            ArkListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    AppTheme.elementSpacing *
                                                        0.75,
                                                vertical:
                                                    AppTheme.elementSpacing *
                                                        0.5,
                                              ),
                                              text: l10n.status,
                                              trailing: Row(
                                                children: [
                                                  BlinkingDot(
                                                    color: transactionModel!
                                                            .status.confirmed
                                                        ? AppTheme
                                                            .successColor
                                                        : AppTheme
                                                            .errorColor,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    transactionModel!
                                                            .status.confirmed
                                                        ? l10n.confirmed
                                                        : l10n.pending,
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium!
                                                        .copyWith(
                                                          color: transactionModel!
                                                                  .status
                                                                  .confirmed
                                                              ? AppTheme
                                                                  .successColor
                                                              : AppTheme
                                                                  .errorColor,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Payment Network
                                            ArkListTile(
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    AppTheme.elementSpacing *
                                                        0.75,
                                                vertical:
                                                    AppTheme.elementSpacing *
                                                        0.5,
                                              ),
                                              text: l10n.network,
                                              trailing: Row(
                                                children: [
                                                  Image.asset(
                                                    "assets/images/bitcoin.png",
                                                    width: AppTheme
                                                            .cardPadding *
                                                        1,
                                                    height: AppTheme
                                                            .cardPadding *
                                                        1,
                                                    errorBuilder: (context,
                                                        error, stackTrace) {
                                                      return const Icon(
                                                        Icons.currency_bitcoin,
                                                        color: AppTheme
                                                            .colorBitcoin,
                                                      );
                                                    },
                                                  ),
                                                  const SizedBox(
                                                    width: AppTheme
                                                            .elementSpacing /
                                                        2,
                                                  ),
                                                  Text(
                                                    'Onchain',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleMedium,
                                                  ),
                                                ],
                                              ),
                                            ),

                                            // Time
                                            if (transactionModel!
                                                    .status.confirmed &&
                                                transactionModel!
                                                        .status.blockTime !=
                                                    null)
                                              ArkListTile(
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: AppTheme
                                                          .elementSpacing *
                                                      0.75,
                                                  vertical: AppTheme
                                                          .elementSpacing *
                                                      0.5,
                                                ),
                                                text: 'Time',
                                                leading: Icon(
                                                  Icons.access_time,
                                                  size:
                                                      AppTheme.cardPadding *
                                                          0.75,
                                                  color: Theme.of(context)
                                                              .brightness ==
                                                          Brightness.dark
                                                      ? AppTheme.white60
                                                      : AppTheme.black60,
                                                ),
                                                trailing: Builder(
                                                  builder: (context) {
                                                    final loc = timezoneService
                                                        .location;
                                                    final datetime = DateTime
                                                        .fromMillisecondsSinceEpoch(
                                                      transactionModel!
                                                              .status.blockTime!
                                                              .toInt() *
                                                          1000,
                                                    ).toUtc().add(Duration(
                                                        milliseconds: loc
                                                            .currentTimeZone
                                                            .offset));
                                                    return SizedBox(
                                                      width: AppTheme
                                                              .cardPadding *
                                                          7,
                                                      child: Text(
                                                        '${DateFormat('yyyy-MM-dd HH:mm').format(datetime)}'
                                                        ' (${_formatTimeAgo(datetime)})',
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 2,
                                                        textAlign:
                                                            TextAlign.end,
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
                                              contentPadding:
                                                  const EdgeInsets.symmetric(
                                                horizontal:
                                                    AppTheme.elementSpacing *
                                                        0.75,
                                                vertical:
                                                    AppTheme.elementSpacing *
                                                        0.5,
                                              ),
                                              text: l10n.fee,
                                              trailing: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Text(
                                                    _formatPrice(
                                                      transactionModel!.fee
                                                          .toString(),
                                                    ),
                                                    overflow:
                                                        TextOverflow.ellipsis,
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
        appBar: ArkAppBar(
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
                                final value =
                                    (vin.prevout!.value.toDouble()) / 100000000;
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
        appBar: ArkAppBar(
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
                                final value = vout.value.toDouble() / 100000000;
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
                  color: isInput
                      ? AppTheme.errorColor
                      : AppTheme.successColor,
                ),
          ),
        ],
      ),
    );
  }
}
