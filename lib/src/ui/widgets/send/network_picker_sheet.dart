import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_list_tile.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/send/network_icon_widget.dart';
import 'package:ark_flutter/theme.dart';
import 'package:flutter/material.dart';

/// Bottom sheet for selecting a payment network from BIP21 options
class NetworkPickerSheet extends StatelessWidget {
  final Map<String, String> availableNetworks;
  final String? selectedNetwork;
  final Function(String network) onNetworkSelected;

  const NetworkPickerSheet({
    super.key,
    required this.availableNetworks,
    this.selectedNetwork,
    required this.onNetworkSelected,
  });

  /// Get fee description for each network
  String _getNetworkFeeDescription(String network) {
    switch (network) {
      case 'Arkade':
        return 'Instant, lowest fees';
      case 'Lightning':
        return 'Fast, low fees (~0.25%)';
      case 'Onchain':
        return 'Slower, higher fees';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Sort networks: Ark first, then Lightning, then Bitcoin (by fee order)
    final networks = availableNetworks.keys.toList();
    networks.sort((a, b) {
      const order = {'Arkade': 0, 'Lightning': 1, 'Onchain': 2};
      return (order[a] ?? 3).compareTo(order[b] ?? 3);
    });

    return ArkScaffold(
      context: context,
      appBar: BitNetAppBar(
        context: context,
        hasBackButton: false,
        text: l10n.selectNetwork,
        buttonType: ButtonType.transparent,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This recipient supports multiple payment methods. Choose the one that works best for you.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
            const SizedBox(height: AppTheme.cardPadding),
            ...networks.map((network) {
              final isSelected = network == selectedNetwork;
              final feeDescription = _getNetworkFeeDescription(network);

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.elementSpacing),
                child: ArkListTile(
                  margin: EdgeInsets.zero,
                  selected: isSelected,
                  leading: NetworkIconWidget(
                    networkName: network,
                    size: 24,
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).hintColor,
                  ),
                  text: network,
                  subtitle: Text(
                    feeDescription,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).hintColor,
                        ),
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        )
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    onNetworkSelected(network);
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
