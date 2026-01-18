import 'package:ark_flutter/l10n/app_localizations.dart';
import 'package:ark_flutter/theme.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bitnet_app_bar.dart';
import 'package:ark_flutter/src/ui/widgets/bitnet/bottom_action_buttons.dart';
import 'package:ark_flutter/src/ui/widgets/utility/filter_pill.dart';
import 'package:flutter/material.dart';

/// Filter options for loans/contracts
class LoanFilterOptions {
  final Set<String> selectedStatuses;

  const LoanFilterOptions({
    this.selectedStatuses = const {},
  });

  bool get hasFilter => selectedStatuses.isNotEmpty;

  LoanFilterOptions copyWith({Set<String>? selectedStatuses}) {
    return LoanFilterOptions(
      selectedStatuses: selectedStatuses ?? this.selectedStatuses,
    );
  }
}

/// Bottom sheet for filtering loans/contracts
/// Uses the same UI pattern as TransactionFilterScreen
class LoanFilterScreen extends StatefulWidget {
  final LoanFilterOptions initialFilters;
  final void Function(LoanFilterOptions) onApply;

  const LoanFilterScreen({
    super.key,
    required this.initialFilters,
    required this.onApply,
  });

  @override
  State<LoanFilterScreen> createState() => _LoanFilterScreenState();
}

class _LoanFilterScreenState extends State<LoanFilterScreen> {
  late Set<String> _selectedStatuses;

  // Available status filters
  static const List<String> _statusOptions = [
    'Active',
    'Pending',
    'Repayment Confirmed',
    'Closed',
    'Overdue',
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatuses = Set.from(widget.initialFilters.selectedStatuses);
  }

  void _toggleStatus(String status) {
    setState(() {
      if (_selectedStatuses.contains(status)) {
        _selectedStatuses.remove(status);
      } else {
        _selectedStatuses.add(status);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _selectedStatuses.clear();
    });
  }

  bool _isStatusEnabled(String status) {
    // If no filters selected, show all (nothing is "enabled" in the filter sense)
    if (_selectedStatuses.isEmpty) return false;
    return _selectedStatuses.contains(status);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
            onPressed: _clearAll,
            child: Text(
              l10n?.clear ?? 'Clear',
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status section
                  Text(
                    'Status',
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
                    children: _statusOptions.map((status) {
                      return FilterPill(
                        label: status,
                        isSelected: _isStatusEnabled(status),
                        onTap: () => _toggleStatus(status),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          BottomCenterButton(
            title: l10n?.apply ?? 'Apply',
            onTap: () {
              widget.onApply(LoanFilterOptions(
                selectedStatuses: _selectedStatuses,
              ));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
