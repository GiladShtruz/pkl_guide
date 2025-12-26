import 'package:flutter/material.dart';

class HomeNavigationProvider extends ChangeNotifier {
  int _pendingNavigationIndex = -1;

  int get pendingNavigationIndex => _pendingNavigationIndex;

  void navigateToTab(int index) {
    _pendingNavigationIndex = index;
    notifyListeners();
  }

  void clearPendingNavigation() {
    _pendingNavigationIndex = -1;
  }
}
