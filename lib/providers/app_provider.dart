import 'package:flutter/material.dart';
import '../models/sorting_method.dart';
import '../models/category.dart';

class AppProvider extends ChangeNotifier {
  final Map<CategoryType, SortingMethod> _sortingMethods = {
    CategoryType.games: SortingMethod.original,
    CategoryType.activities: SortingMethod.original,
    CategoryType.riddles: SortingMethod.original,
    CategoryType.texts: SortingMethod.original,
  };

  bool _isSelectionMode = false;
  final Set<int> _selectedItems = {};

  // ← הוסף את זה
  ThemeMode _themeMode = ThemeMode.system;

  // ← הוסף את זה
  ThemeMode get themeMode => _themeMode;

  // ← הוסף את זה
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }

  SortingMethod getSortingMethod(CategoryType category) {
    return _sortingMethods[category] ?? SortingMethod.lastAccessed;
  }

  void setSortingMethod(CategoryType category, SortingMethod method) {
    _sortingMethods[category] = method;
    notifyListeners();
  }

  bool get isSelectionMode => _isSelectionMode;
  Set<int> get selectedItems => _selectedItems;

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedItems.clear();
    }
    notifyListeners();
  }

  void toggleItemSelection(int itemId) {
    if (_selectedItems.contains(itemId)) {
      _selectedItems.remove(itemId);
    } else {
      _selectedItems.add(itemId);
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedItems.clear();
    notifyListeners();
  }
}