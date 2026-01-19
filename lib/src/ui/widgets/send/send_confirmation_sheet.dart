import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/loaders/loaders.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/send/network_icon_widget.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Data class holding all information needed for confirmation
class SendConfirmationData {
  final String address;
  final int amountSats;
  final int networkFees;
  final String networkName;
  final bool hasMultipleNetworks;
  final bool isLoadingFees;
  final bool hasLnurlParams;
  final String note;

  const SendConfirmationData({
    required this.address,
    required this.amountSats,
    required this.networkFees,
    required this.networkName,
    this.hasMultipleNetworks = false,
    this.isLoadingFees = false,
    this.hasLnurlParams = false,
    this.note = '',
  });

  int get total => amountSats + networkFees;
}

/// Confirmation bottom sheet for send transactions
class SendConfirmationSheet extends StatelessWidget {
  final SendConfirmationData data;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;
  final VoidCallback? onNetworkTap;
  final VoidCallback? onNoteTap;
  final ValueNotifier<int>? feeUpdateNotifier;

  const SendConfirmationSheet({
    super.key,
    required this.data,
    required this.onConfirm,
    required this.onCancel,
    this.onNetworkTap,
    this.onNoteTap,
    this.feeUpdateNotifier,
  });

  String _truncateAddress(String address) {
    if (address.length <= 20) return address;
    return '${address.substring(0, 10)}...${address.substring(address.length - 8)}';
  }

  String _getFeeText(
      bool isOnChain, bool isLightning, int fees, bool isLoading) {
    if (isOnChain) {
      if (isLoading) return '';
      if (fees > 0) return '~$fees sats';
      return '';
    } else if (isLightning) {
      return '~$fees sats';
    }
    return '0 sats'; // Ark payments are free
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isOnChain = data.networkName == 'Onchain';
    final isLightning = data.networkName == 'Lightning';

    Widget buildContent(int fees, bool isLoading) {
      final feeText = _getFeeText(isOnChain, isLightning, fees, isLoading);
      final total = data.amountSats + fees;

      return Column(
        children: [
          // Scrollable content area
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: AppTheme.cardPadding),
                  // Transaction details
                  GlassContainer(
                    opacity: 0.05,
                    borderRadius: AppTheme.cardRadiusSmall,
                    padding: const EdgeInsets.all(AppTheme.elementSpacing),
                    child: Column(
                      children: [
                        // Address row
                        ArkListTile(
                          margin: EdgeInsets.zero,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.elementSpacing * 0.75,
                            vertical: AppTheme.elementSpacing * 0.5,
                          ),
                          text: l10n.address,
                          trailing: Text(
                            _truncateAddress(data.address),
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        // Amount row
                        ArkListTile(
                          margin: EdgeInsets.zero,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.elementSpacing * 0.75,
                            vertical: AppTheme.elementSpacing * 0.5,
                          ),
                          text: l10n.amount,
                          trailing: Text(
                            '${data.amountSats} sats',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                        // Note row (for LNURL payments)
                        if (data.hasLnurlParams)
                          ArkListTile(
                            margin: EdgeInsets.zero,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: AppTheme.elementSpacing * 0.75,
                              vertical: AppTheme.elementSpacing * 0.5,
                            ),
                            text: l10n.note,
                            trailing: GestureDetector(
                              onTap: onNoteTap,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ConstrainedBox(
                                    constraints: BoxConstraints(
                                      maxWidth:
                                          MediaQuery.of(context).size.width *
                                              0.4,
                                    ),
                                    child: Text(
                                      data.note.isEmpty
                                          ? l10n.addNote
                                          : data.note,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: data.note.isEmpty
                                                ? Theme.of(context).hintColor
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      textAlign: TextAlign.right,
                                    ),
                                  ),
                                  const SizedBox(
                                      width: AppTheme.elementSpacing / 2),
                                  Icon(
                                    CupertinoIcons.pencil,
                                    size: 16,
                                    color: Theme.of(context).hintColor,
                                  ),
                                ],
                              ),
                            ),
                            onTap: onNoteTap,
                          ),
                        // Network row
                        ArkListTile(
                          margin: EdgeInsets.zero,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.elementSpacing * 0.75,
                            vertical: AppTheme.elementSpacing * 0.5,
                          ),
                          text: l10n.network,
                          trailing: data.hasMultipleNetworks
                              ? GestureDetector(
                                  onTap: onNetworkTap,
                                  child: GlassContainer(
                                    opacity: 0.05,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppTheme.elementSpacing,
                                      vertical: AppTheme.elementSpacing / 2,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        NetworkIconWidget(
                                          networkName: data.networkName,
                                          size: AppTheme.cardPadding * 0.75,
                                          color: Theme.of(context).hintColor,
                                        ),
                                        const SizedBox(
                                            width: AppTheme.elementSpacing / 2),
                                        Text(
                                          data.networkName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium,
                                        ),
                                        const SizedBox(
                                            width: AppTheme.elementSpacing / 2),
                                        Icon(
                                          Icons.keyboard_arrow_down,
                                          size: 16,
                                          color: Theme.of(context).hintColor,
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    NetworkIconWidget(
                                      networkName: data.networkName,
                                      size: AppTheme.cardPadding * 0.75,
                                      color: Theme.of(context).hintColor,
                                    ),
                                    const SizedBox(
                                        width: AppTheme.elementSpacing / 2),
                                    Text(
                                      data.networkName,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                          ),
                                    ),
                                  ],
                                ),
                          onTap: data.hasMultipleNetworks ? onNetworkTap : null,
                        ),
                        // Network Fees row
                        ArkListTile(
                          margin: EdgeInsets.zero,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.elementSpacing * 0.75,
                            vertical: AppTheme.elementSpacing * 0.5,
                          ),
                          text: l10n.networkFees,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isLoading)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: dotProgress(context, size: 14.0),
                                ),
                              Text(
                                feeText,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        // Total row
                        ArkListTile(
                          margin: EdgeInsets.zero,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.elementSpacing * 0.75,
                            vertical: AppTheme.elementSpacing * 0.5,
                          ),
                          text: l10n.total,
                          trailing: Text(
                            isLoading
                                ? '${data.amountSats} sats'
                                : '$total sats',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: LongButtonWidget(
                  buttonType: ButtonType.transparent,
                  title: l10n.cancel,
                  onTap: onCancel,
                ),
              ),
              const SizedBox(width: AppTheme.elementSpacing),
              Expanded(
                child: LongButtonWidget(
                  buttonType: ButtonType.solid,
                  title: 'Confirm',
                  onTap: onConfirm,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.cardPadding),
        ],
      );
    }

    return ArkScaffold(
      context: context,
      appBar: BitNetAppBar(
        context: context,
        text: 'Confirm',
        hasBackButton: false,
        buttonType: ButtonType.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
        child: feeUpdateNotifier != null
            ? ValueListenableBuilder<int>(
                valueListenable: feeUpdateNotifier!,
                builder: (context, _, __) {
                  return buildContent(data.networkFees, data.isLoadingFees);
                },
              )
            : buildContent(data.networkFees, data.isLoadingFees),
      ),
    );
  }
}
