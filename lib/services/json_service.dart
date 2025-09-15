// lib/services/json_service.dart
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
  }

  Future<void> parseAndSaveJson(Map<String, dynamic> jsonData, {required bool isUpdate}) async {
    try {
      print('Starting JSON parsing...');

      final version = jsonData['version'] ?? 1;
      final categories = jsonData['categories'] ?? {};
      List<ItemModel> appItems = [];

      // Parse each category
      categories.forEach((categoryKey, categoryItems) {
        print('Parsing category: $categoryKey');
        print('Category appItems: $categoryItems');

        final category = _getCategoryType(categoryKey);
        print('Parsing category: $categoryKey as ${category.name}');

        if (categoryItems is List) {
          for (var itemData in categoryItems) {
            final item = _parseItem(itemData, category);
            if (item != null) {
              appItems.add(item);
              print('Added item: ${item.name} with ID: ${item.id}');
            }
          }
        }
      });

      print('Parsed ${appItems.length} appItems total');

      // Save to storage
      await storageService.saveAppData(appItems);
      await storageService.saveVersion(version.toString());

      if (isUpdate) {
        print('Update completed');
        // When updating, preserve user modifications
        // User modifications are already stored in the ItemModel itself
      }

    } catch (e) {
      print('Error parsing JSON: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  ItemModel? _parseItem(Map<String, dynamic> data, CategoryType category) {
    try {
      // Extract ID from JSON
      int? id = data['id'];
      if (id == null || id.isNaN) {
        // Generate ID if not provided
        id = DateTime.now().millisecondsSinceEpoch % 100;
      }

      String? title = data['title'];
      String? detail = data['detail'];
      String? link = data['link'];
      String? classification = data['classification'];
      String? equipment = data['equipment'];
      List<String> elements = [];

      // Parse elements array
      final dataItems = data['elements'];
      if (dataItems is List) {
        elements = dataItems.map((e) => e.toString()).toList();
      }

      if (title == null || title.isEmpty) {
        print('Skipping item with no title');
        return null;
      }

      final item = ItemModel(
        id: id,
        originalTitle: title,
        originalDetail: detail,
        originalLink: link,
        originalClassification: classification,
        originalEquipment: equipment,
        originalElements: elements,
        category: category.name,
        isUserCreated: false,
        isUserChanged: false
      );

      //print('Created item: ${item.name} with ${elements.length} content elements');
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
      // Remove user created items for specific category
      final userItems = storageService.getUserCreatedItems()
          .where((item) => item.category == category.name)
          .toList();

      // for (var item in userItems) {
      //   await storageService.deleteUserCreatedItem(item.id);
      // }

      // Reset modifications in app data items for this category
      final appItems = storageService.getAppData()
          .where((item) => item.category == category.name)
          .toList();

      for (var item in appItems) {
        await storageService.resetItem(item.id);
      }
    } else {
      // Reset all user modifications
      // await storageService.userBox.clear();

      // Reset all modifications in app data
      for (var item in storageService.getAppData()) {
        await storageService.resetItem(item.id);
      }
    }

    // Optionally reload from original data
    // await loadFromLocalJson();
  }
}