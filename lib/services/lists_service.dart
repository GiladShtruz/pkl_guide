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
        id: 'favorites_default',
        name: 'מועדפים',
        description: 'רשימת המועדפים שלי',
        itemIds: [],
        createdAt: DateTime.now(),
        isDefault: true,
      );

      await listsBox.put(favoritesList.id, favoritesList);

      // Migrate existing favorites
      final favoriteIds = storageService.favoritesBox.values.toList();
      if (favoriteIds.isNotEmpty) {
        favoritesList.itemIds = List<String>.from(favoriteIds);
        await favoritesList.save();
      }
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
  Future<ListModel> createList(String name, {String? description}) async {
    final newList = ListModel(
      id: 'list_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      itemIds: [],
      createdAt: DateTime.now(),
    );

    await listsBox.put(newList.id, newList);
    return newList;
  }

  // Delete list
  Future<void> deleteList(String listId) async {
    final list = listsBox.get(listId);
    if (list != null && !list.isDefault) {
      await list.delete();
    }
  }

  // Delete multiple lists
  Future<void> deleteLists(List<String> listIds) async {
    for (final id in listIds) {
      await deleteList(id);
    }
  }

  // Update list name
  Future<void> updateListName(String listId, String newName) async {
    final list = listsBox.get(listId);
    if (list != null && !list.isDefault) {
      list.name = newName;
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Update list description
  Future<void> updateListDescription(String listId, String? description) async {
    final list = listsBox.get(listId);
    if (list != null) {
      list.description = description;
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Add item to list
  Future<void> addItemToList(String listId, String itemId) async {
    final list = listsBox.get(listId);
    if (list != null && !list.itemIds.contains(itemId)) {
      list.itemIds.add(itemId);
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Add item to multiple lists
  Future<void> addItemToLists(List<String> listIds, String itemId) async {
    for (final listId in listIds) {
      await addItemToList(listId, itemId);
    }
  }

  // Remove item from list
  Future<void> removeItemFromList(String listId, String itemId) async {
    final list = listsBox.get(listId);
    if (list != null) {
      list.itemIds.remove(itemId);
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Reorder items in list
  Future<void> reorderListItems(String listId, int oldIndex, int newIndex) async {
    final list = listsBox.get(listId);
    if (list != null) {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = list.itemIds.removeAt(oldIndex);
      list.itemIds.insert(newIndex, item);
      list.lastModified = DateTime.now();
      await list.save();
    }
  }

  // Get items for a list
  List<ItemModel> getListItems(String listId) {
    final list = listsBox.get(listId);
    if (list == null) return [];

    final items = <ItemModel>[];
    for (final itemId in list.itemIds) {
      final item = storageService.appDataBox.get(itemId) ??
          storageService.userAdditionsBox.get(itemId);
      if (item != null) {
        items.add(item);
      }
    }
    return items;
  }

  // Check if item is in list
  bool isItemInList(String listId, String itemId) {
    final list = listsBox.get(listId);
    return list?.itemIds.contains(itemId) ?? false;
  }

  // Get lists containing item
  List<ListModel> getListsContainingItem(String itemId) {
    return listsBox.values
        .where((list) => list.itemIds.contains(itemId))
        .toList();
  }

  // Toggle item in favorites (compatibility method)
  Future<void> toggleFavorite(String itemId) async {
    final favoritesList = getFavoritesList();
    if (favoritesList != null) {
      if (favoritesList.itemIds.contains(itemId)) {
        await removeItemFromList(favoritesList.id, itemId);
      } else {
        await addItemToList(favoritesList.id, itemId);
      }
    }
  }

  // Check if item is favorite (compatibility method)
  bool isFavorite(String itemId) {
    final favoritesList = getFavoritesList();
    return favoritesList?.itemIds.contains(itemId) ?? false;
  }
}