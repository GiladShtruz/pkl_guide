import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import '../models/sorting_method.dart';
import '../models/category.dart';

class StorageService {
  static const String appDataBoxName = 'appDataBox';
  static const String userAdditionsBoxName = 'userAdditionsBox';
  static const String deletedByUserBoxName = 'deletedByUserBox';
  static const String favoritesBoxName = 'favoritesBox';
  static const String settingsBoxName = 'settingsBox';

  late Box<ItemModel> appDataBox;
  late Box<ItemModel> userAdditionsBox;
  late Box<String> deletedByUserBox;
  late Box<String> favoritesBox;
  late Box settingsBox;

  Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ItemModelAdapter());
    }

    // Open boxes
    appDataBox = await Hive.openBox<ItemModel>(appDataBoxName);
    userAdditionsBox = await Hive.openBox<ItemModel>(userAdditionsBoxName);
    deletedByUserBox = await Hive.openBox<String>(deletedByUserBoxName);
    favoritesBox = await Hive.openBox<String>(favoritesBoxName);
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

  // User Additions Methods
  Future<void> addUserItem(ItemModel item) async {
    item.isUserAdded = true;
    await userAdditionsBox.put(item.id, item);
  }

  List<ItemModel> getUserAdditions() {
    return userAdditionsBox.values.toList();
  }

  // Deleted Items Methods
  Future<void> markAsDeleted(String itemId) async {
    await deletedByUserBox.add(itemId);
  }

  bool isDeleted(String itemId) {
    return deletedByUserBox.values.contains(itemId);
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
    await settingsBox.put('csv_version', version);
  }

  String? getVersion() {
    return settingsBox.get('csv_version');
  }

  // Get all items (merged)
  List<ItemModel> getAllItems({CategoryType? category}) {
    final List<ItemModel> allItems = [];

    // Add app data
    allItems.addAll(appDataBox.values.where((item) {
      if (isDeleted(item.id)) return false;
      if (category != null && item.category != category.name) return false;
      return true;
    }));

    // Add user additions
    allItems.addAll(userAdditionsBox.values.where((item) {
      if (category != null && item.category != category.name) return false;
      return true;
    }));

    return allItems;
  }

  // Update item access
  Future<void> updateItemAccess(String itemId) async {
    ItemModel? item = appDataBox.get(itemId) ?? userAdditionsBox.get(itemId);
    if (item != null) {
      item.lastAccessed = DateTime.now();
      item.clickCount++;
      await item.save();
    }
  }

  // Get item by ID
  ItemModel? getItemById(String itemId) {
    return appDataBox.get(itemId) ?? userAdditionsBox.get(itemId);
  }
}
