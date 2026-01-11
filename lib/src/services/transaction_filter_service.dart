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

  /// Check if a network type is enabled (visible)
  /// Returns true if no network filters are set (all visible) or if this network is selected
  bool isNetworkEnabled(String network) {
    if (!hasNetworkFilter) return true; // No filters = all enabled
    return _selectedFilters.contains(network);
  }

  /// Check if a direction is enabled (visible)
  /// Returns true if no direction filters are set (all visible) or if this direction is selected
  bool isDirectionEnabled(String direction) {
    if (!hasDirectionFilter) return true; // No filters = all enabled
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

  /// Toggle a network filter with "all enabled by default" logic
  /// First click on any network pill will disable just that network
  void toggleNetworkFilter(String network) {
    if (!hasNetworkFilter) {
      // No network filters set = all are visible
      // User wants to hide this one, so enable all EXCEPT this one
      for (final n in networkFilters) {
        if (n != network) {
          _selectedFilters.add(n);
        }
      }
    } else if (_selectedFilters.contains(network)) {
      // This network is enabled, disable it
      _selectedFilters.remove(network);
      // If no networks left, clear all network filters (back to "all visible")
      if (!hasNetworkFilter) {
        // All network filters removed, which means show all
      }
    } else {
      // This network is disabled, enable it
      _selectedFilters.add(network);
      // If all networks are now enabled, clear them (back to default "all visible")
      if (networkFilters.every((n) => _selectedFilters.contains(n))) {
        for (final n in networkFilters) {
          _selectedFilters.remove(n);
        }
      }
    }
    notifyListeners();
  }

  /// Toggle a direction filter with "all enabled by default" logic
  void toggleDirectionFilter(String direction) {
    if (!hasDirectionFilter) {
      // No direction filters set = all are visible
      // User wants to hide this one, so enable all EXCEPT this one
      for (final d in directionFilters) {
        if (d != direction) {
          _selectedFilters.add(d);
        }
      }
    } else if (_selectedFilters.contains(direction)) {
      // This direction is enabled, disable it
      _selectedFilters.remove(direction);
    } else {
      // This direction is disabled, enable it
      _selectedFilters.add(direction);
      // If all directions are now enabled, clear them (back to default)
      if (directionFilters.every((d) => _selectedFilters.contains(d))) {
        for (final d in directionFilters) {
          _selectedFilters.remove(d);
        }
      }
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

  Future<DateTime?> selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2009),
      lastDate: DateTime(2101),
    );
    return picked;
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
