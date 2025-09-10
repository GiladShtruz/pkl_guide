import 'package:hive_flutter/hive_flutter.dart';
import '../models/item_model.dart';
import '../models/sorting_method.dart';
import '../models/category.dart';

class StorageService {
  static const String appDataBoxName = 'appDataBox';
  static const String userBoxName = 'userBox';
  static const String deletedByUserBoxName = 'deletedByUserBox';
  // static const String favoritesBoxName = 'favoritesBox';
  static const String settingsBoxName = 'settingsBox';

  late Box<ItemModel> appDataBox;
  late Box<ItemModel> userBox;
  late Box<String> deletedByUserBox;
  // late Box<String> favoritesBox;
  late Box settingsBox;

  Future<void> init() async {
    // Register adapters
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(ItemModelAdapter());
    }

    // Open boxes
    appDataBox = await Hive.openBox<ItemModel>(appDataBoxName);
    userBox = await Hive.openBox<ItemModel>(userBoxName);
    deletedByUserBox = await Hive.openBox<String>(deletedByUserBoxName);
    // favoritesBox = await Hive.openBox<String>(favoritesBoxName);
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
    await userBox.put(item.id, item);
  }

  List<ItemModel> getUserAdditions() {
    return userBox.values.toList();
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
    await settingsBox.put('json_version', version);
  }

  String? getVersion() {
    return settingsBox.get('json_version');
  }

  // Get all items (merged)
  List<ItemModel> getAllCategoryItems({CategoryType? category}) {
    final List<ItemModel> allCategoryItems = [];

    // Add app data
    allCategoryItems.addAll(appDataBox.values.where((categoryItem) {
      if (isDeleted(categoryItem.id)) return false;
      if (category != null && categoryItem.category != category.name) return false;
      return true;
    }));

    // Add user additions
    allCategoryItems.addAll(userBox.values.where((categoryItem) {
      if (category != null && categoryItem.category != category.name) return false;
      return true;
    }));



    return allCategoryItems;
  }

  void giladDebug(){
    print("gilad");

    print(userBox.values);
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
