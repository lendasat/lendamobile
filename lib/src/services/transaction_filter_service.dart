import 'package:flutter/material.dart';

class TransactionFilterService extends ChangeNotifier {
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
