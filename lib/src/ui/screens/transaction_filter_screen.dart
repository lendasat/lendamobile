import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/src/services/transaction_filter_service.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Filter',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.onSurface),
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
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(AppTheme.paddingM),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showFilterPills) ...[
                  Text(
                    'Filter Options',
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
                      _FilterPill(
                        label: 'Boarding',
                        isSelected:
                            filterService.selectedFilters.contains('Boarding'),
                        onTap: () => filterService.toggleFilter('Boarding'),
                      ),
                      _FilterPill(
                        label: 'Round',
                        isSelected:
                            filterService.selectedFilters.contains('Round'),
                        onTap: () => filterService.toggleFilter('Round'),
                      ),
                      _FilterPill(
                        label: 'Redeem',
                        isSelected:
                            filterService.selectedFilters.contains('Redeem'),
                        onTap: () => filterService.toggleFilter('Redeem'),
                      ),
                      _FilterPill(
                        label: AppLocalizations.of(context)!.sent,
                        isSelected:
                            filterService.selectedFilters.contains('Sent'),
                        onTap: () => filterService.toggleFilter('Sent'),
                      ),
                      _FilterPill(
                        label: AppLocalizations.of(context)!.received,
                        isSelected:
                            filterService.selectedFilters.contains('Received'),
                        onTap: () => filterService.toggleFilter('Received'),
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
                                      ? Theme.of(context).colorScheme.onSurface
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
                                      ? Theme.of(context).colorScheme.onSurface
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
                const SizedBox(height: 100),
              ],
            ),
          ),
          Positioned(
            bottom: AppTheme.paddingL,
            left: AppTheme.paddingM,
            right: AppTheme.paddingM,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber[600],
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                AppLocalizations.of(context)!.apply,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    

    return InkWell(
      onTap: onTap,
      child: GlassContainer(
        opacity: isSelected ? 0.2 : 0.1,
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.paddingM,
            vertical: AppTheme.paddingS * 0.75,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Theme.of(context).colorScheme.onSurface : Theme.of(context).hintColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
