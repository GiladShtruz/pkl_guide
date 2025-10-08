
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pkl_guide/models/element_model.dart';
import 'package:pkl_guide/services/json_service.dart';
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

  Future<void> saveAllData(List<ItemModel> items) async {
    final entries = {for (var item in items) item.id: item};
    await appDataBox.putAll(entries);
  }

  // Future<void> saveAppData(List<ItemModel> items) async {
  //   appDataBox.putAll(entries);
  //
  //
  //   for (var item in items) {
  //     if (appDataBox.containsKey(item.id)) {
  //       ItemModel existingItem = appDataBox.get(item.id)!;
  //       existingItem.updateItemFromOnline(item);
  //
  //       await appDataBox.put(item.id, item);
  //     } else {
  //       await appDataBox.put(item.id, item);
  //     }
  //   }
  // }

  List<ItemModel> getAppData() {
    return appDataBox.values.toList();
  }

  // Add new item (can be user created or app data)
  Future<void> addItem(ItemModel item) async {
    await appDataBox.put(item.id, item);
  }

  // Delete item
  Future<void> deleteItem(int itemId) async {
    await appDataBox.delete(itemId);
  }

  // Update item title
  Future<void> updateItemTitle(int itemId, String newTitle) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.updateTitle(newTitle);
      await item.save();
    }
  }

  // Update item detail
  Future<void> updateItemDetail(int itemId, String? newDetail) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.updateDetail(newDetail);
      await item.save();
    }
  }

  // Update item link
  Future<void> updateItemLink(int itemId, String? newLink) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.updateLink(newLink);
      await item.save();
    }
  }

  // Update item classification
  Future<void> updateItemClassification(
    int itemId,
    String? newClassification,
  ) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.updateClassification(newClassification);
      await item.save();
    }
  }

  // Update item equipment
  Future<void> updateItemEquipment(int itemId, String? newEquipment) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.updateEquipment(newEquipment);
      await item.save();
    }
  }

  // Add user element to existing item
  Future<void> addUserElement(int itemId, String newItem) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.addElement(newItem, isUserCreated: true);
      await item.save();
    }
  }

  // Remove element from item
  Future<void> removeElement(int itemId, ElementModel element) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.removeElementByText(element.text);
      await item.save();
    }
  }

  // Reset methods
  Future<void> resetItemTitle(int itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetTitle();
      await item.save();
    }
  }

  Future<void> resetItemDetail(int itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetDetail();
      await item.save();
    }
  }

  Future<void> resetItemLink(int itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetLink();
      await item.save();
    }
  }

  Future<void> resetItemClassification(int itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetClassification();
      await item.save();
    }
  }

  Future<void> resetItemEquipment(int itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetEquipment();
      await item.save();
    }
  }

  Future<void> resetElements(int itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetElements();
      await item.save();
    }
  }

  Future<void> resetItem(int itemId) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.resetAll();
      await item.save();
    }
  }

  // Settings Methods
  Future<void> saveSortingMethod(
    CategoryType category,
    SortingMethod method,
  ) async {
    await settingsBox.put('sorting_${category.name}', method.name);
  }

  SortingMethod getSortingMethod(CategoryType category) {
    // TODO: check why return SortingMethod.original and if it works
    final methodName = settingsBox.get('sorting_${category.name}');
    if (methodName != null) {
      return SortingMethod.values.firstWhere(
        (m) => m.name == methodName,
        orElse: () => SortingMethod.original,
      );
    }
    return SortingMethod.lastAccessed;
  }
  Future<void> saveAboutText(String aboutText) async {
    await settingsBox.put('about_text', aboutText);
  }

  String? getAboutText() {
    return settingsBox.get('about_text');
  }

  Future<void> saveVersion(int dataVersion) async {
    await settingsBox.put('json_version', dataVersion);
  }

  int? getVersion() {
    return settingsBox.get('json_version');
  }

  // set isElementsChanged
  Future<void> setElementsChanged(int itemId, bool isChanged) async {
    final item = appDataBox.get(itemId);
    if (item != null) {
      item.isElementsChanged = isChanged;
      await item.save();
    }
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
    return appDataBox.values
        .where((item) => !item.isUserCreated && !item.isUserChanged)
        .toList();
  }


  Future<void> updateFromOnline(Map<String, dynamic> jsonData) async {
    final categories = jsonData['categories'] ?? {};
    JsonService jsonService = JsonService(this);
    Set<int> idsRemovedFromData = appDataBox.keys.cast<int>().toSet();
    categories.forEach((categoryName, categoryItems) async {
      final categoryHebName = getCategoryType(categoryName);

      if (categoryItems is List) {
        for (var itemData in categoryItems) {
          final newItem = jsonService.parseItem(itemData, categoryHebName);
          if (newItem != null) {
            idsRemovedFromData.remove(newItem.id);
            // update elements:
            final oldItem = appDataBox.get(newItem.id);
            if (oldItem == null){ // its new item
              await appDataBox.put(newItem.id, newItem);
              continue;
            }
            // update item:
            // set old item name:
            oldItem.originalTitle = oldItem.name;
            oldItem.originalDetail = oldItem.detail;
            oldItem.originalLink = oldItem.link;
            oldItem.originalClassification = oldItem.classification;
            oldItem.originalEquipment = oldItem.equipment;
            // set elements:
            if (oldItem.isElementsChanged) {
              // in order to get smallest run time

              Set<String> curOriginalTexts = oldItem.originalElements.map((e) => e.text).toSet();
              Set<String> newOriginalTexts = newItem.originalElements.map((e) => e.text).toSet();
              List<String> itemsToDelete = curOriginalTexts.difference(newOriginalTexts).toList();
              List<String> itemsToAdd = newOriginalTexts.difference(curOriginalTexts).toList();
              if (oldItem.name.contains("פנטומימה")) {
              }
              List<ElementModel> result = List<ElementModel>.from(oldItem.elements);
              for (var item in itemsToDelete) {
                result.removeWhere((e) => e.text == item);
              }
              for (var item in itemsToAdd) {
                result.add(ElementModel(item, false));
              }
              oldItem.itemElements = result;
            }
            else{
              oldItem.itemElements = newItem.elements;
            }
            appDataBox.put(oldItem.id, oldItem);
          }
        }
      }
    });
    print("idsRemovedFromData: $idsRemovedFromData");
    for (var id in idsRemovedFromData) {
      appDataBox.delete(id);
    }
  }

  // Export user data to JSON
  Map<String, dynamic> exportUserData() {
    final exportData = <String, dynamic>{
      'exportDate': DateTime.now().toIso8601String(),
      'appVersion': getVersion() ?? '1',
      'data': [],
      'userLists': [],
    };

    // Export items data
    final itemsData = <Map<String, dynamic>>[];

    for (var item in appDataBox.values) {
      if (item.isUserCreated) {
        // User created items - export everything

        // המרה למחרוזת JSON

        itemsData.add({
          'id': item.id,
          'category': item.category,
          'originalTitle': item.originalTitle,
          'userTitle': item.userTitle,
          'originalDetail': item.originalDetail,
          'userDetail': item.userDetail,
          'originalLink': item.originalLink,
          'userLink': item.userLink,
          'originalClassification': item.originalClassification,
          'userClassification': item.userClassification,
          'originalEquipment': item.originalEquipment,
          'userEquipment': item.userEquipment,
          'elements': item.elements.map((e) => e.toJson()).toList(),
          'lastAccessed': item.lastAccessed?.toIso8601String(),
          'clickCount': item.clickCount,
          'isUserCreated': true,
          'isUserChanged': item.isUserChanged,
        });
      } else if (item.isUserChanged) {
        // Modified items - export only user values and metadata
        final modifiedData = <String, dynamic>{
          'id': item.id,
          'category': item.category,
          'lastAccessed': item.lastAccessed?.toIso8601String(),
          'clickCount': item.clickCount,
          'isUserCreated': false,
          'isUserChanged': true,
        };

        // Add only user modified fields
        if (item.userTitle != null) {
          modifiedData['userTitle'] = item.userTitle;
        }
        if (item.userDetail != null) {
          modifiedData['userDetail'] = item.userDetail;
        }
        if (item.userLink != null) {
          modifiedData['userLink'] = item.userLink;
        }
        if (item.userClassification != null) {
          modifiedData['userClassification'] = item.userClassification;
        }
        if (item.userEquipment != null) {
          modifiedData['userEquipment'] = item.userEquipment;
        }
        if (item.isElementsChanged) {
          print(modifiedData['elements']);
          modifiedData['elements'] = item.elements
              .map((e) => e.toJson())
              .toList();
        }

        itemsData.add(modifiedData);
      } else if (item.clickCount > 0 || item.lastAccessed != null) {
        // Items with usage data only
        itemsData.add({
          'id': item.id,
          'category': item.category,
          'lastAccessed': item.lastAccessed?.toIso8601String(),
          'clickCount': item.clickCount,
          'isUserCreated': false,
          'isUserChanged': false,
        });
      }
    }

    exportData['data'] = itemsData;

    return exportData;
  }

  // Import user data from JSON
  Future<void> importUserData(Map<String, dynamic> importData) async {
    try {
      // Import items data
      if (importData['data'] != null) {
        final itemsData = importData['data'] as List;

        for (var itemJson in itemsData) {
          final itemId = itemJson['id'] as int;
          final isUserCreated = itemJson['isUserCreated'] ?? false;
          final isUserChanged = itemJson['isUserChanged'] ?? false;
          final dataElements = itemJson['elements'];
          List<ElementModel> elements = dataElements is List
              ? dataElements
                    .map((e) => ElementModel(e["element"], e["isUserElement"]))
                    .toList()
              : [];

          if (isUserCreated) {
            // Create new user item
            final newItem = ItemModel(
              id: itemId,
              category: itemJson['category'],
              originalTitle: itemJson['originalTitle'] ?? '',
              userTitle: itemJson['userTitle'],
              originalDetail: itemJson['originalDetail'],
              userDetail: itemJson['userDetail'],
              originalLink: itemJson['originalLink'],
              userLink: itemJson['userLink'],
              originalClassification: itemJson['originalClassification'],
              userClassification: itemJson['userClassification'],
              originalEquipment: itemJson['originalEquipment'],
              userEquipment: itemJson['userEquipment'],
              elements: elements,
              lastAccessed: itemJson['lastAccessed'] != null
                  ? DateTime.tryParse(itemJson['lastAccessed'])
                  : null,
              clickCount: itemJson['clickCount'] ?? 0,
              isUserCreated: true,
              isUserChanged: itemJson['isUserChanged'] ?? false,
            );

            await appDataBox.put(itemId, newItem);
          } else if (isUserChanged || itemJson['clickCount'] > 0) {
            // Update existing item with user modifications or usage data
            final existingItem = appDataBox.get(itemId);

            if (existingItem != null) {
              // Update user modifications
              if (itemJson['userTitle'] != null) {
                existingItem.userTitle = itemJson['userTitle'];
              }
              if (itemJson['userDetail'] != null) {
                existingItem.userDetail = itemJson['userDetail'];
              }
              if (itemJson['userLink'] != null) {
                existingItem.userLink = itemJson['userLink'];
              }
              if (itemJson['userClassification'] != null) {
                existingItem.userClassification =
                    itemJson['userClassification'];
              }
              if (itemJson['userEquipment'] != null) {
                existingItem.userEquipment = itemJson['userEquipment'];
              }
              if (itemJson['elements'] != null) {
                List<ElementModel> elements = [];
                final dataElements = itemJson['elements'];
                if (dataElements is List) {
                  elements = dataElements
                      .map(
                        (e) => ElementModel(e["element"], e["isUserElement"]),
                      )
                      .toList();
                }
                existingItem.itemElements = elements;
              }
              // Update usage data
              if (itemJson['clickCount'] != null) {
                existingItem.clickCount = itemJson['clickCount'];
              }
              if (itemJson['lastAccessed'] != null) {
                existingItem.lastAccessed = DateTime.tryParse(
                  itemJson['lastAccessed'],
                );
              }

              existingItem.isUserChanged = isUserChanged;

              await existingItem.save();
            }
          }
        }
      }

      print('Import completed successfully');
    } catch (e) {
      print('Error importing user data: $e');
      throw Exception('Failed to import user data: $e');
    }
  }

  // Update item access
  Future<void> updateItemAccess(int itemId) async {
    ItemModel? item = appDataBox.get(itemId);
    if (item != null) {
      item.lastAccessed = DateTime.now();
      item.clickCount++;
      await item.save();
    }
  }

  // Get item by ID
  ItemModel? getItemById(int itemId) {
    return appDataBox.get(itemId);
  }

  // Check if item exists
  bool itemExists(int itemId) {
    return appDataBox.containsKey(itemId);
  }

  // Get items by category
  List<ItemModel> getItemsByCategory(String category) {
    return appDataBox.values
        .where((item) => item.category == category)
        .toList();
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

  // Restore data from JSON
  // Future<void> restoreFromJson(Map<String, dynamic> backup) async {
  //   if (backup['items'] != null) {
  //     await clearAllData();
  //     final items = (backup['items'] as List)
  //         .map((json) => ItemModel.fromJson(json))
  //         .toList();
  //     for (var item in items) {
  //       await addItem(item);
  //     }
  //   }
  // }
}
