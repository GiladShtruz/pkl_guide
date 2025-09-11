import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import '../models/sorting_method.dart';
import '../models/category.dart';

class StorageService {
  static const String appDataBoxName = 'appDataBox';
  static const String userBoxName = 'userBox';
  static const String settingsBoxName = 'settingsBox';

  late Box<ItemModel> appDataBox;
  late Box<ItemModel> userBox;
  late Box settingsBox;

  Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ItemModelAdapter());
    }

    // Open boxes
    appDataBox = await Hive.openBox<ItemModel>(appDataBoxName);
    userBox = await Hive.openBox<ItemModel>(userBoxName);
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

  // User Created Items
  Future<void> addUserCreatedItem(ItemModel item) async {
    item.isUserCreated = true;
    await userBox.put(item.id, item);
  }

  Future<void> deleteUserCreatedItem(String itemId) async {
    await userBox.delete(itemId);
  }

  List<ItemModel> getUserCreatedItems() {
    return userBox.values.toList();
  }

  // Update methods for existing items
  Future<void> updateItemTitle(String itemId, bool isUserCreated, String newTitle) async {
    final item = isUserCreated ? userBox.get(itemId) : appDataBox.get(itemId);
    if (item != null) {
      item.userTitle = newTitle;
      await item.save();
    }
  }

  Future<void> updateItemDetail(String itemId, bool isUserCreated, String? newDetail) async {
    final item = isUserCreated ? userBox.get(itemId) : appDataBox.get(itemId);
    print("--");
    print(itemId);
    print(item != null);
    if (item != null) {
      print("get in updateItemDetail");
      item.userDetail = newDetail;
      await item.save();
    }
  }

  Future<void> addUserItemToExisting(String itemId, bool isUserCreated, String newItem) async {
    final item = isUserCreated ? userBox.get(itemId) : appDataBox.get(itemId);
    if (item != null) {
      item.userAddedItems.add(newItem);
      await item.save();
    }
  }

  Future<void> removeUserItem(String itemId, String itemToRemove) async {
    final item = userBox.get(itemId);
    if (item != null) {
      item.userAddedItems.remove(itemToRemove);
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

  // Get all items (merged)
  List<ItemModel> getAllCategoryItems({CategoryType? category}) {
    final List<ItemModel> allItems = [];

    // Add app data items
    allItems.addAll(appDataBox.values.where((item) {
      if (category != null && item.category != category.name) return false;
      return true;
    }));

    // Add user created items
    allItems.addAll(userBox.values.where((item) {
      if (category != null && item.category != category.name) return false;
      return true;
    }));

    return allItems;
  }

  // Update item access
  Future<void> updateItemAccess(String itemId) async {
    ItemModel? item = appDataBox.get(itemId) ?? userBox.get(itemId);
    if (item != null) {
      item.lastAccessed = DateTime.now();
      item.clickCount++;
      await item.save();
    }
  }

  // Get item by ID
  ItemModel? getItemById(String itemId) {
    return appDataBox.get(itemId) ?? userBox.get(itemId);
  }
}