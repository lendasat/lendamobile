import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/transaction_filter_service.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/filter_pill.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TransactionFilterScreen extends StatelessWidget {
  final bool showFilterPills;

  const TransactionFilterScreen({
    super.key,
    this.showFilterPills = true,
  });

  @override
  Widget build(BuildContext context) {
    final filterService = context.watch<TransactionFilterService>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: BitNetAppBar(
        context: context,
        text: 'Filter',
        customLeading: IconButton(
          icon:
              Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: () {
              filterService.clearAllFilters();
            },
            child: Text(
              AppLocalizations.of(context)!.clear,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.paddingM),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showFilterPills) ...[
                    // Network/Type section
                    Text(
                      'Network',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    Wrap(
                      spacing: AppTheme.paddingS,
                      runSpacing: AppTheme.paddingS,
                      children: [
                        FilterPill(
                          label: 'Onchain',
                          isSelected: filterService.isNetworkEnabled('Onchain'),
                          onTap: () =>
                              filterService.toggleNetworkFilter('Onchain'),
                        ),
                        FilterPill(
                          label: 'Lightning',
                          isSelected:
                              filterService.isNetworkEnabled('Lightning'),
                          onTap: () =>
                              filterService.toggleNetworkFilter('Lightning'),
                        ),
                        FilterPill(
                          label: 'Arkade',
                          isSelected: filterService.isNetworkEnabled('Arkade'),
                          onTap: () =>
                              filterService.toggleNetworkFilter('Arkade'),
                        ),
                        FilterPill(
                          label: 'Swap',
                          isSelected: filterService.isNetworkEnabled('Swap'),
                          onTap: () =>
                              filterService.toggleNetworkFilter('Swap'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingL),
                    // Direction section
                    Text(
                      'Direction',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: AppTheme.paddingM),
                    Wrap(
                      spacing: AppTheme.paddingS,
                      runSpacing: AppTheme.paddingS,
                      children: [
                        FilterPill(
                          label: AppLocalizations.of(context)!.sent,
                          isSelected: filterService.isDirectionEnabled('Sent'),
                          onTap: () =>
                              filterService.toggleDirectionFilter('Sent'),
                        ),
                        FilterPill(
                          label: AppLocalizations.of(context)!.received,
                          isSelected:
                              filterService.isDirectionEnabled('Received'),
                          onTap: () =>
                              filterService.toggleDirectionFilter('Received'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.paddingL * 1.5),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Time Frame',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (filterService.hasTimeframeFilter)
                        IconButton(
                          icon: Icon(
                            Icons.clear,
                            size: 20,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          onPressed: () {
                            filterService.resetTimeframe();
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.paddingM),
                  Row(
                    children: [
                      Expanded(
                        child: GlassContainer(
                          child: InkWell(
                            onTap: () async {
                              final selected =
                                  await filterService.selectDate(context);
                              if (selected != null) {
                                filterService.setStartDate(selected);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.paddingS),
                              child: Center(
                                child: Text(
                                  filterService.startDate != null
                                      ? DateFormat('dd-MM-yyyy')
                                          .format(filterService.startDate!)
                                      : 'Start Date',
                                  style: TextStyle(
                                    color: filterService.startDate != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context).hintColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.paddingS),
                        child: Text(
                          'to',
                          style: TextStyle(color: Theme.of(context).hintColor),
                        ),
                      ),
                      Expanded(
                        child: GlassContainer(
                          child: InkWell(
                            onTap: () async {
                              final selected =
                                  await filterService.selectDate(context);
                              if (selected != null) {
                                filterService.setEndDate(selected);
                              }
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(AppTheme.paddingS),
                              child: Center(
                                child: Text(
                                  filterService.endDate != null
                                      ? DateFormat('dd-MM-yyyy')
                                          .format(filterService.endDate!)
                                      : 'End Date',
                                  style: TextStyle(
                                    color: filterService.endDate != null
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                        : Theme.of(context).hintColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: AppTheme.paddingM,
              right: AppTheme.paddingM,
              bottom: MediaQuery.of(context).padding.bottom + AppTheme.paddingS,
            ),
            child: LongButtonWidget(
              title: AppLocalizations.of(context)!.apply,
              customWidth: double.infinity,
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
