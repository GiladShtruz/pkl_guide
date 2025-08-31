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
  final Set<String> _selectedItems = {};

  SortingMethod getSortingMethod(CategoryType category) {
    return _sortingMethods[category] ?? SortingMethod.original;
  }

  void setSortingMethod(CategoryType category, SortingMethod method) {
    _sortingMethods[category] = method;
    notifyListeners();
  }

  bool get isSelectionMode => _isSelectionMode;
  Set<String> get selectedItems => _selectedItems;

  void toggleSelectionMode() {
    _isSelectionMode = !_isSelectionMode;
    if (!_isSelectionMode) {
      _selectedItems.clear();
    }
    notifyListeners();
  }

  void toggleItemSelection(String itemId) {
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

