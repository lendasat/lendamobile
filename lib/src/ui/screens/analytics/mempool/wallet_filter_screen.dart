import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/utility/ark_scaffold.dart';
import 'package:ark_flutter/src/ui/widgets/utility/glass_container.dart';
import 'package:ark_flutter/src/ui/widgets/utility/inline_calendar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/long_button_widget.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/button_types.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Controller for wallet filter state
class WalletFilterController extends ChangeNotifier {
  final Set<String> _selectedFilters = {};
  DateTime? _startDate;
  DateTime? _endDate;
  int start = 0;
  int end = 0;

  Set<String> get selectedFilters => _selectedFilters;
  Rx<DateTime?> get startDate => Rx<DateTime?>(_startDate);
  Rx<DateTime?> get endDate => Rx<DateTime?>(_endDate);

  bool get hasTimeframeFilter => _startDate != null || _endDate != null;

  void toggleFilter(String filter) {
    if (_selectedFilters.contains(filter)) {
      _selectedFilters.remove(filter);
    } else {
      _selectedFilters.add(filter);
    }
    notifyListeners();
  }

  void resetTimeframe() {
    _startDate = null;
    _endDate = null;
    start = 0;
    end = 0;
    notifyListeners();
  }

  void setStartDate(DateTime? date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  Future<DateTime?> selectDate(BuildContext context,
      {DateTime? initialDate}) async {
    return showInlineCalendar(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: DateTime(2009), // Bitcoin genesis
      lastDate: DateTime.now(),
      title: 'Select Date',
    );
  }
}

/// Simple reactive wrapper
class Rx<T> {
  T value;
  Rx(this.value);
}

/// Filter pill label model
class PillLabelModal {
  final String labelText;
  PillLabelModal({required this.labelText});
}

class WalletFilterScreen extends StatefulWidget {
  const WalletFilterScreen({
    this.hideLightning = false,
    this.hideOnchain = false,
    this.hideFilters = false,
    this.forcedFilters,
    this.onApply,
    super.key,
  });

  final bool hideLightning;
  final bool hideOnchain;
  final List<String>? forcedFilters;
  final bool hideFilters;
  final Function(WalletFilterController)? onApply;

  @override
  State<WalletFilterScreen> createState() => _WalletFilterScreenState();
}

class _WalletFilterScreenState extends State<WalletFilterScreen> {
  late final WalletFilterController controller;

  @override
  void initState() {
    super.initState();
    controller = WalletFilterController();
    if (widget.forcedFilters != null) {
      for (var filter in widget.forcedFilters!) {
        controller.toggleFilter(filter);
      }
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ArkScaffold(
      extendBodyBehindAppBar: true,
      context: context,
      appBar: BitNetAppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.elementSpacing,
            ),
            child: LongButtonWidget(
              customWidth: AppTheme.cardPadding * 3.75,
              customHeight: AppTheme.cardPadding * 1.25,
              buttonType: ButtonType.transparent,
              title: l10n.clear,
              onTap: () {
                setState(() {
                  controller.selectedFilters.clear();
                  controller.resetTimeframe();
                  if (widget.forcedFilters != null) {
                    for (var filter in widget.forcedFilters!) {
                      controller.toggleFilter(filter);
                    }
                  }
                });
              },
            ),
          ),
        ],
        hasBackButton: false,
        context: context,
        text: 'Filter',
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.cardPadding,
              vertical: AppTheme.cardPadding * 2,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.cardPadding),
                if (!widget.hideFilters) _buildFilterPills(context, l10n),
                SizedBox(height: AppTheme.cardPadding * 1.75),
                _buildTimeframeSection(context, l10n),
              ],
            ),
          ),
          Positioned(
            bottom: AppTheme.cardPadding,
            left: AppTheme.cardPadding,
            right: AppTheme.cardPadding,
            child: SizedBox(
              width: double.infinity,
              child: LongButtonWidget(
                title: l10n.apply,
                customWidth: double.infinity,
                buttonType: ButtonType.solid,
                onTap: () {
                  if (controller.startDate.value != null) {
                    controller.start =
                        controller.startDate.value!.millisecondsSinceEpoch ~/
                            1000;
                  } else {
                    controller.start = 0;
                  }
                  if (controller.endDate.value != null) {
                    controller.end =
                        controller.endDate.value!.millisecondsSinceEpoch ~/
                            1000;
                  } else {
                    controller.end = 0;
                  }
                  widget.onApply?.call(controller);
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPills(BuildContext context, AppLocalizations l10n) {
    final filters = <PillLabelModal>[
      if (!widget.hideLightning) PillLabelModal(labelText: 'Lightning'),
      if (!widget.hideOnchain) PillLabelModal(labelText: 'Onchain'),
      PillLabelModal(labelText: l10n.sent),
      PillLabelModal(labelText: l10n.received),
      PillLabelModal(labelText: 'Loop'),
      PillLabelModal(labelText: 'Operations'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter Options',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppTheme.elementSpacing),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: filters.map((filter) {
            final isSelected =
                controller.selectedFilters.contains(filter.labelText);
            return GestureDetector(
              onTap: () {
                setState(() {
                  controller.toggleFilter(filter.labelText);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Text(
                  filter.labelText,
                  style: TextStyle(
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimeframeSection(BuildContext context, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time Frame',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (controller.hasTimeframeFilter)
              IconButton(
                icon: Icon(
                  Icons.clear,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    controller.resetTimeframe();
                  });
                },
              ),
          ],
        ),
        const SizedBox(height: AppTheme.elementSpacing),
        Row(
          children: [
            Expanded(
              child: GlassContainer(
                child: InkWell(
                  onTap: () async {
                    final selected = await controller.selectDate(
                      context,
                      initialDate: controller.startDate.value,
                    );
                    if (selected != null) {
                      setState(() {
                        controller.setStartDate(selected);
                        controller.start =
                            selected.millisecondsSinceEpoch ~/ 1000;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.elementSpacing),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.startDate.value != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(controller.startDate.value!)
                              : 'Start date',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: controller.startDate.value != null
                                        ? null
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                horizontal: AppTheme.elementSpacing,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.4),
              ),
            ),
            Expanded(
              child: GlassContainer(
                child: InkWell(
                  onTap: () async {
                    final selected = await controller.selectDate(
                      context,
                      initialDate: controller.endDate.value,
                    );
                    if (selected != null) {
                      setState(() {
                        controller.setEndDate(selected);
                        controller.end =
                            selected.millisecondsSinceEpoch ~/ 1000;
                      });
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(AppTheme.elementSpacing),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 16,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          controller.endDate.value != null
                              ? DateFormat('MMM d, yyyy')
                                  .format(controller.endDate.value!)
                              : 'End date',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: controller.endDate.value != null
                                        ? null
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.5),
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
