import 'package:hive_flutter/hive_flutter.dart';
import '../models/list_model.dart';
import '../models/item_model.dart';
import 'storage_service.dart';

class ListsService {
  static const String listsBoxName = 'listsBox';
  late Box<ListModel> listsBox;
  final StorageService storageService;

  ListsService(this.storageService);

  Future<void> init() async {
    // Register adapter if not already registered
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(ListModelAdapter());
    }

    // Open box
    listsBox = await Hive.openBox<ListModel>(listsBoxName);

    // Create default favorites list if not exists
    await _createDefaultLists();
  }

  Future<void> _createDefaultLists() async {
    final hasFavorites = listsBox.values.any((list) => list.isDefault);

    if (!hasFavorites) {
      final favoritesList = ListModel(
        id: 1,
        name: 'מועדפים',
        detail: 'רשימת המועדפים שלי',
        categoryItemIds: [],
        createdAt: DateTime.now(),
        isDefault: true,
      );

      await listsBox.put(favoritesList.id, favoritesList);

      // // Migrate existing favorites
      // final favoriteIds = storageService.favoritesBox.values.toList();
      // if (favoriteIds.isNotEmpty) {
      //   favoritesList.categoryItemIds = List<String>.from(favoriteIds);
      //   await favoritesList.save();
      // }
    }
  }

  // Get all lists
  List<ListModel> getAllLists() {
    final lists = listsBox.values.toList();
    // Sort: favorites first, then by creation date
    lists.sort((a, b) {
      if (a.isDefault && !b.isDefault) return -1;
      if (!a.isDefault && b.isDefault) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });
    return lists;
  }

  // Get favorites list
  ListModel? getFavoritesList() {
    return listsBox.values.firstWhere(
          (list) => list.isDefault,
      orElse: () => listsBox.values.first,
    );
  }

  // Create new list
  Future<ListModel> createList(String name, {String? detail}) async {
    final newList = ListModel(
      id: DateTime.now().millisecondsSinceEpoch % 100000000,
      name: name,
      detail: detail,
      categoryItemIds: [],
      createdAt: DateTime.now(),
    );

    await listsBox.put(newList.id, newList);
    return newList;
  }

  // Delete list
  Future<void> deleteList(int listId) async {
    final list = listsBox.get(listId);
    if (list != null && !list.isDefault) {
      await list.delete();
    }
  }

  // Delete multiple lists
  Future<void> deleteLists(List<int> listIds) async {
    for (final id in listIds) {
      await deleteList(id);
    }
  }

  // Update list name
  Future<void> updateListName(int listId, String newName) async {
    final list = listsBox.get(listId);
    if (list != null && !list.isDefault) {
      list.name = newName;
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Update list description
  Future<void> updateListDescription(int listId, String? description) async {
    final list = listsBox.get(listId);
    if (list != null) {
      list.detail = description;
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Add item to list
  Future<void> addItemToList(int listId, int itemId) async {
    final list = listsBox.get(listId);
    if (list != null && !list.categoryItemIds.contains(itemId)) {
      list.categoryItemIds.add(itemId);
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Add item to multiple lists
  Future<void> addItemToLists(List<int> listIds, int itemId) async {
    for (final listId in listIds) {
      await addItemToList(listId, itemId);
    }
  }

  // Remove item from list
  Future<void> removeItemFromList(int listId, int itemId) async {
    final list = listsBox.get(listId);
    if (list != null) {
      list.categoryItemIds.remove(itemId);
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Reorder items in list
  Future<void> reorderListItems(int listId, int oldIndex, int newIndex) async {
    final list = listsBox.get(listId);
    if (list != null) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = list.categoryItemIds.removeAt(oldIndex);
      list.categoryItemIds.insert(newIndex, item);
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Get items for a list
  List<ItemModel> getListItems(int listId) {
    final list = listsBox.get(listId);
    if (list == null) return [];

    final items = <ItemModel>[];
    for (final itemId in list.categoryItemIds) {
      final item = storageService.appDataBox.get(itemId);
          // storageService.userBox.get(itemId);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  // Check if item is in list
  bool isItemInList(int listId, int itemId) {
    final list = listsBox.get(listId);
    return list?.categoryItemIds.contains(itemId) ?? false;
  }

  // Get lists containing item
  List<ListModel> getListsContainingItem(int itemId) {
    return listsBox.values
        .where((list) => list.categoryItemIds.contains(itemId))
        .toList();
  }

  // Toggle item in favorites (compatibility method)
  Future<void> toggleFavorite(int itemId) async {
    final favoritesList = getFavoritesList();
    if (favoritesList != null) {
      if (favoritesList.categoryItemIds.contains(itemId)) {
        await removeItemFromList(favoritesList.id, itemId);
      } else {
        await addItemToList(favoritesList.id, itemId);
      }
    }
  }

  // Check if item is favorite (compatibility method)
  bool isFavorite(int itemId) {
    final favoritesList = getFavoritesList();
    return favoritesList?.categoryItemIds.contains(itemId) ?? false;
  }

// Export lists to JSON format
  List<Map<String, dynamic>> exportLists() {
    final listsData = <Map<String, dynamic>>[];

    for (var list in listsBox.values) {
      listsData.add({
        'id': list.id,
        'name': list.name,
        'detail': list.detail,
        'categoryItemIds': list.categoryItemIds,
        'createdAt': list.createdAt.toIso8601String(),
        'lastModified': list.lastModified?.toIso8601String(),
        'isDefault': list.isDefault,
      });
    }

    return listsData;
  }

// Import lists from JSON
  Future<void> importLists(List<dynamic> listsData) async {
    try {
      for (var listJson in listsData) {
        final listId = listJson['id'] as int;

        // Check if list already exists
        final existingList = listsBox.get(listId);

        if (existingList != null) {
          // Update existing list
          existingList.name = listJson['name'];
          existingList.detail = listJson['detail'];
          existingList.categoryItemIds = List<int>.from(listJson['categoryItemIds']);
          existingList.lastModified = listJson['lastModified'] != null
              ? DateTime.tryParse(listJson['lastModified'])
              : null;
          await existingList.save();
        } else {
          // Create new list
          final newList = ListModel(
            id: listId,
            name: listJson['name'],
            detail: listJson['detail'],
            categoryItemIds: List<int>.from(listJson['categoryItemIds']),
            createdAt: DateTime.parse(listJson['createdAt']),
            lastModified: listJson['lastModified'] != null
                ? DateTime.tryParse(listJson['lastModified'])
                : null,
            isDefault: listJson['isDefault'] ?? false,
          );

          await listsBox.put(listId, newList);
        }
      }

      print('Lists import completed successfully');
    } catch (e) {
      print('Error importing lists: $e');
      throw Exception('Failed to import lists: $e');
    }
  }

}