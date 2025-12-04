import 'package:flutter/material.dart';

class SettingsController extends ChangeNotifier {
  String _currentTab = 'main';

  String get currentTab => _currentTab;

  void switchTab(String newTab) {
    _currentTab = newTab;
    notifyListeners();
  }

  void resetToMain() {
    _currentTab = 'main';
    notifyListeners();
  }
}
