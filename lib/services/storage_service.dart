import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import '../models/sorting_method.dart';
import '../models/category.dart';

class StorageService {
  static const String appDataBoxName = 'appData';
  static const String settingsBoxName = 'settingsBox';

  late Box<ItemModel> appDataBox;
  late Box settingsBox;

  Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ItemModelAdapter());
    }

    // Open boxes
    appDataBox = await Hive.openBox<ItemModel>(appDataBoxName);
    settingsBox = await Hive.openBox(settingsBoxName);
  }

  // App Data Methods
  Future<void> saveAppData(List<ItemModel> items) async {
    await appDataBox.clear();
    for (var item in items) {
      await appDataBox.put(item.id, item);
    }
  }

  List<ItemModel> getAppData() {
    return appDataBox.values.toList();
  }

  // Add new item (can be user created or app data)
  Future<void> addItem(ItemModel item) async {
    await appDataBox.put(item.id, item);
  }

  // Delete item
  Future<void> deleteItem(String itemId) async {
    await appDataBox.delete(itemId);
  }

  // Update item title
  Future<void> updateItemTitle(String itemId, String newTitle) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.updateTitle(newTitle);
      await item.save();
    }
  }

  // Update item detail
  Future<void> updateItemDetail(String itemId, String? newDetail) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.updateDetail(newDetail);
      await item.save();
    }
  }

  // Update item link
  Future<void> updateItemLink(String itemId, String? newLink) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.updateLink(newLink);
      await item.save();
    }
  }

  // Add user item to existing item
  Future<void> addUserItemToExisting(String itemId, String newItem) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.addUserItem(newItem);
      await item.save();
    }
  }

  // Remove user item from existing item
  Future<void> removeUserItem(String itemId, String itemToRemove) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.removeUserItem(itemToRemove);
      await item.save();
    }
  }

  // Reset methods
  Future<void> resetItemTitle(String itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetTitle();
      await item.save();
    }
  }

  Future<void> resetItemDetail(String itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetDetail();
      await item.save();
    }
  }

  Future<void> resetItemLink(String itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetLink();
      await item.save();
    }
  }

  Future<void> resetItemUserItems(String itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetItems();
      await item.save();
    }
  }

  Future<void> resetItem(String itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetAll();
      await item.save();
    }
  }

  // Settings Methods
  Future<void> saveSortingMethod(CategoryType category, SortingMethod method) async {
    await settingsBox.put('sorting_${category.name}', method.name);
  }

  SortingMethod getSortingMethod(CategoryType category) {
    final methodName = settingsBox.get('sorting_${category.name}');
    if (methodName != null) {
      return SortingMethod.values.firstWhere(
            (m) => m.name == methodName,
        orElse: () => SortingMethod.original,
      );
    }
    return SortingMethod.original;
  }

  Future<void> saveVersion(String version) async {
    await settingsBox.put('json_version', version);
  }

  String? getVersion() {
    return settingsBox.get('json_version');
  }

  // Get all items (now from single box)
  List<ItemModel> getAllCategoryItems({CategoryType? category}) {
    return appDataBox.values.where((item) {
      if (category != null && item.category != category.name) return false;
      return true;
    }).toList();
  }

  // Get user created items only
  List<ItemModel> getUserCreatedItems() {
    return appDataBox.values.where((item) => item.isUserCreated).toList();
  }

  // Get user modified items only
  List<ItemModel> getUserModifiedItems() {
    return appDataBox.values.where((item) => item.isUserChanged).toList();
  }

  // Get original app data items only (not user created and not modified)
  List<ItemModel> getOriginalAppDataItems() {
    return appDataBox.values.where((item) => !item.isUserCreated && !item.isUserChanged).toList();
  }

  // Update item access
  Future<void> updateItemAccess(String itemId) async {
    ItemModel? item = appDataBox.get(itemId);
    if (item != null) {
      item.lastAccessed = DateTime.now();
      item.clickCount++;
      await item.save();
    }
  }

  // Get item by ID
  ItemModel? getItemById(String itemId) {
    return appDataBox.get(itemId);
  }

  // Check if item exists
  bool itemExists(String itemId) {
    return appDataBox.containsKey(itemId);
  }

  // Get items by category
  List<ItemModel> getItemsByCategory(String category) {
    return appDataBox.values.where((item) => item.category == category).toList();
  }

  // Get items count
  int getItemsCount() {
    return appDataBox.length;
  }

  // Get user created items count
  int getUserCreatedItemsCount() {
    return appDataBox.values.where((item) => item.isUserCreated).length;
  }

  // Get user modified items count
  int getUserModifiedItemsCount() {
    return appDataBox.values.where((item) => item.isUserChanged).length;
  }

  // Clear all data
  Future<void> clearAllData() async {
    await appDataBox.clear();
  }

  // Backup data to JSON
  Map<String, dynamic> backupToJson() {
    final items = appDataBox.values.map((item) => item.toJson()).toList();
    return {
      'items': items,
      'timestamp': DateTime.now().toIso8601String(),
      'version': getVersion(),
    };
  }

  // Restore data from JSON
  Future<void> restoreFromJson(Map<String, dynamic> backup) async {
    if (backup['items'] != null) {
      await clearAllData();
      final items = (backup['items'] as List)
          .map((json) => ItemModel.fromJson(json))
          .toList();
      for (var item in items) {
        await addItem(item);
      }
    }
  }
}