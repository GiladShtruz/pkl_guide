// lib/services/json_service.dart - UPDATED FOR NEW JSON STRUCTURE
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/item_model.dart';
import '../models/category.dart';
import 'storage_service.dart';

class JsonService {
  final StorageService storageService;
  static const String onlineJsonUrl =
      'https://your-server.com/data.json'; // Replace with actual URL

  JsonService(this.storageService);

  Future<void> loadInitialData() async {
    try {
      // Check if we have local data
      final hasLocalData = storageService.getAppData().isNotEmpty;
      final currentVersion = storageService.getVersion();

      if (!hasLocalData) {
        // First time - load from local JSON file
        print('First time loading - loading from JSON');
        await loadFromLocalJson();
      } else {
        print('Data already exists in Hive');
      }

      // Check for updates in background
      checkForUpdates();
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> loadFromLocalJson() async {
    try {
      // Load JSON from assets
      final jsonString = await rootBundle.loadString('assets/data.json');
      final jsonData = json.decode(jsonString);
      await parseAndSaveJson(jsonData, isUpdate: false);
    } catch (e) {
      print('Error loading local JSON: $e');
    }
  }

  Future<Map<String, dynamic>?> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(onlineJsonUrl));
      if (response.statusCode == 200) {
        final jsonData = json.decode(utf8.decode(response.bodyBytes));
        final newVersion = jsonData['version'] ?? 0;
        final currentVersion = int.tryParse(storageService.getVersion() ?? '0') ?? 0;

        if (newVersion > currentVersion) {
          return {
            'version': newVersion.toString(),
            'data': jsonData,
          };
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  Future<void> updateFromOnline(Map<String, dynamic> jsonData, String version) async {
    // Clear existing app data (but keep user data)
    await storageService.appDataBox.clear();

    // Parse and save new data
    await parseAndSaveJson(jsonData, isUpdate: true);
    await storageService.saveVersion(version);

    // Merge with user data happens automatically in StorageService.getAllItems()
  }

  Future<void> parseAndSaveJson(Map<String, dynamic> jsonData, {required bool isUpdate}) async {
    try {
      print('Starting JSON parsing...');

      final version = jsonData['version'] ?? 1;
      final categories = jsonData['categories'] ?? {};
      List<ItemModel> items = [];

      // Parse each category
      categories.forEach((categoryKey, categoryItems) {
        final category = _getCategoryType(categoryKey);
        print('Parsing category: $categoryKey as ${category.name}');

        if (categoryItems is List) {
          for (var itemData in categoryItems) {
            final item = _parseItem(itemData, category);
            if (item != null) {
              items.add(item);
              print('Added item: ${item.name}');
            }
          }
        }
      });

      print('Parsed ${items.length} items total');

      // Save to storage
      await storageService.saveAppData(items);
      await storageService.saveVersion(version.toString());

      if (isUpdate) {
        print('Update completed, merging with user data');
      }

    } catch (e) {
      print('Error parsing JSON: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  ItemModel? _parseItem(Map<String, dynamic> data, CategoryType category) {
    try {
      String? name;
      String? detail;
      String? link;
      String? classification;
      List<String> items = [];

      // Common fields
      name = data['title'];
      detail = data['detail'];
      link = data['link']; // null for riddle

      // Category-specific fields
      switch (category) {
        case CategoryType.games:
        case CategoryType.activities:
          classification = data['classification'];
          final dataItems = data['items'];
          if (dataItems is List) {
            items = dataItems.map((e) => e.toString()).toList();
          }
          break;

        case CategoryType.riddles:
          final dataItems = data['items'];
          if (dataItems is List) {
            items = dataItems.map((e) => e.toString()).toList();
          }
          break;

        case CategoryType.texts:
          classification = data['classification'];
          detail = data['detail'];
          // For texts, store detail as content if no items
          // if (detail != null && detail.isNotEmpty) {
          //   items = [detail];
          // }
          break;
      }

      if (name == null || name.isEmpty) {
        print('Skipping item with no name');
        return null;
      }

      final item = ItemModel(
        id: '${category.name}_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
        name: name,
        detail: detail,
        link: link,
        classification: classification,
        items: items,
        category: category.name,
      );

      print('Created item: ${item.name} with ${items.length} content items');
      return item;

    } catch (e) {
      print('Error parsing item: $e');
      return null;
    }
  }

  CategoryType _getCategoryType(String categoryKey) {
    switch (categoryKey.toLowerCase()) {
      case 'games':
      case 'משחקים':
        return CategoryType.games;
      case 'activities':
      case 'פעילויות':
        return CategoryType.activities;
      case 'riddle':
      case 'riddles':
      case 'חידות':
        return CategoryType.riddles;
      case 'texts':
      case 'קטעים':
        return CategoryType.texts;
      default:
        print('Unknown category: $categoryKey, defaulting to games');
        return CategoryType.games;
    }
  }

  Future<void> resetToOriginal(CategoryType? category) async {
    if (category != null) {
      // Remove user modifications for specific category
      final userItems = storageService.getUserAdditions()
          .where((item) => item.category == category.name)
          .toList();

      for (var item in userItems) {
        await item.delete();
      }

      // Clear deleted items for this category
      final deletedItems = storageService.deletedByUserBox.values
          .where((id) => id.startsWith(category.name))
          .toList();

      for (var id in deletedItems) {
        final index = storageService.deletedByUserBox.values.toList().indexOf(id);
        if (index != -1) {
          await storageService.deletedByUserBox.deleteAt(index);
        }
      }
    } else {
      // Reset all user modifications
      await storageService.userBox.clear();
      await storageService.deletedByUserBox.clear();
    }

    // Reload from original data
    await loadFromLocalJson();
  }
}