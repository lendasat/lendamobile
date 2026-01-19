import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/constants/bitcoin_constants.dart';
import 'package:ark_flutter/src/rust/models/mempool.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/search_field_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/avatar.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for displaying transaction inputs.
class TransactionInputsSheet extends StatefulWidget {
  final BitcoinTransaction transaction;

  const TransactionInputsSheet({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionInputsSheet> createState() => _TransactionInputsSheetState();
}

class _TransactionInputsSheetState extends State<TransactionInputsSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffoldUnsafe(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      context: context,
      appBar: BitNetAppBar(
        context: context,
        hasBackButton: false,
        text: l10n.inputs,
      ),
      body: Padding(
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
                  _searchCtrl.text = v;
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
                        itemCount: widget.transaction.vin
                            .where((v) => v.prevout != null)
                            .length,
                        itemBuilder: (context, index) {
                          final vin = widget.transaction.vin
                              .where((v) => v.prevout != null)
                              .toList()[index];
                          final value = (vin.prevout!.value.toDouble()) /
                              BitcoinConstants.satsPerBtc;
                          final address =
                              vin.prevout?.scriptpubkeyAddress ?? '';

                          if (!address.contains(_searchCtrl.text)) {
                            return const SizedBox();
                          }

                          return TransactionAddressItem(
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
      ),
    );
  }
}

/// Bottom sheet for displaying transaction outputs.
class TransactionOutputsSheet extends StatefulWidget {
  final BitcoinTransaction transaction;

  const TransactionOutputsSheet({
    super.key,
    required this.transaction,
  });

  @override
  State<TransactionOutputsSheet> createState() =>
      _TransactionOutputsSheetState();
}

class _TransactionOutputsSheetState extends State<TransactionOutputsSheet> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffoldUnsafe(
      extendBodyBehindAppBar: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      context: context,
      appBar: BitNetAppBar(
        context: context,
        hasBackButton: false,
        text: l10n.outputs,
      ),
      body: Padding(
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
                  _searchCtrl.text = v;
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
                        itemCount: widget.transaction.vout.length,
                        itemBuilder: (context, index) {
                          final vout = widget.transaction.vout[index];
                          final value = vout.value.toDouble() /
                              BitcoinConstants.satsPerBtc;
                          final address = vout.scriptpubkeyAddress ?? '';

                          if (!address.contains(_searchCtrl.text)) {
                            return const SizedBox();
                          }

                          return TransactionAddressItem(
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
      ),
    );
  }
}

/// Reusable widget for displaying an address with value in transaction lists.
class TransactionAddressItem extends StatelessWidget {
  final String address;
  final double value;
  final bool isInput;

  const TransactionAddressItem({
    super.key,
    required this.address,
    required this.value,
    required this.isInput,
  });

  @override
  Widget build(BuildContext context) {
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
