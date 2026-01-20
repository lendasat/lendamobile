import 'package:ark_flutter/src/ui/widgets/utility/inline_calendar.dart';
import 'package:flutter/material.dart';

class TransactionFilterService extends ChangeNotifier {
  // All available network filter types
  static const List<String> networkFilters = [
    'Onchain',
    'Lightning',
    'Arkade',
    'Swap'
  ];

  // All available direction filter types
  static const List<String> directionFilters = ['Sent', 'Received'];

  DateTime? _startDate;
  DateTime? _endDate;
  final List<String> _selectedFilters = [];

  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;
  List<String> get selectedFilters => List.unmodifiable(_selectedFilters);

  int get start => _startDate?.millisecondsSinceEpoch ?? 0;
  int get end => _endDate?.millisecondsSinceEpoch ?? 0;

  bool get hasTimeframeFilter => _startDate != null || _endDate != null;
  bool get hasAnyFilter => _selectedFilters.isNotEmpty || hasTimeframeFilter;

  /// Check if any network filters are explicitly set
  bool get hasNetworkFilter =>
      _selectedFilters.any((f) => networkFilters.contains(f));

  /// Check if any direction filters are explicitly set
  bool get hasDirectionFilter =>
      _selectedFilters.any((f) => directionFilters.contains(f));

  /// Check if a network filter pill should be highlighted
  /// Returns true only if this network is explicitly selected
  /// No selection = no pills highlighted = show all (default)
  bool isNetworkEnabled(String network) {
    return _selectedFilters.contains(network);
  }

  /// Check if a direction filter pill should be highlighted
  /// Returns true only if this direction is explicitly selected
  /// No selection = no pills highlighted = show all (default)
  bool isDirectionEnabled(String direction) {
    return _selectedFilters.contains(direction);
  }

  void setStartDate(DateTime? date) {
    _startDate = date;
    notifyListeners();
  }

  void setEndDate(DateTime? date) {
    _endDate = date;
    notifyListeners();
  }

  void toggleFilter(String filter) {
    if (_selectedFilters.contains(filter)) {
      _selectedFilters.remove(filter);
    } else {
      _selectedFilters.add(filter);
    }
    notifyListeners();
  }

  /// Toggle a network filter - simple on/off toggle
  /// - Highlighted pills = types that will be shown
  /// - No pills highlighted = show all (default)
  /// - Some pills highlighted = show only those types
  void toggleNetworkFilter(String network) {
    if (_selectedFilters.contains(network)) {
      _selectedFilters.remove(network);
    } else {
      _selectedFilters.add(network);
    }
    notifyListeners();
  }

  /// Toggle a direction filter - simple on/off toggle
  /// - Highlighted pills = directions that will be shown
  /// - No pills highlighted = show all (default)
  /// - Some pills highlighted = show only those directions
  void toggleDirectionFilter(String direction) {
    if (_selectedFilters.contains(direction)) {
      _selectedFilters.remove(direction);
    } else {
      _selectedFilters.add(direction);
    }
    notifyListeners();
  }

  void resetTimeframe() {
    _startDate = null;
    _endDate = null;
    notifyListeners();
  }

  void clearAllFilters() {
    _selectedFilters.clear();
    resetTimeframe();
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

  bool isInDateRange(int locktime) {
    if (locktime == 0) return true;

    if (start == 0 && end == 0) return true;

    int startSeconds = start ~/ 1000;
    int endSeconds = end ~/ 1000;

    if (start > 0 && end == 0) {
      return locktime >= startSeconds;
    }

    if (start == 0 && end > 0) {
      return locktime <= endSeconds;
    }

    return locktime >= startSeconds && locktime <= endSeconds;
  }
}
