import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../models/item_model.dart';
import '../models/category.dart';
import '../models/json_data_model.dart';
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
        await loadFromLocalJson();
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
    // Clear existing data
    await storageService.appDataBox.clear();

    // Parse and save new data
    await parseAndSaveJson(jsonData, isUpdate: true);
    await storageService.saveVersion(version);

    // Merge with user data
    await mergeWithUserData();
  }

  Future<void> parseAndSaveJson(Map<String, dynamic> jsonData, {required bool isUpdate}) async {
    try {
      print('Starting JSON parsing...');

      final data = JsonDataModel.fromJson(jsonData);
      List<ItemModel> items = [];

      // Parse each category
      data.categories.forEach((categoryName, categoryItems) {
        final category = _getCategoryType(categoryName);

        for (var itemData in categoryItems) {
          final item = _parseItem(itemData, category);
          if (item != null) {
            items.add(item);
          }
        }
      });

      print('Parsed ${items.length} items total');

      // Save to storage
      if (isUpdate) {
        await mergeWithUserData();
      }
      await storageService.saveAppData(items);

    } catch (e) {
      print('Error parsing JSON: $e');
    }
  }

  ItemModel? _parseItem(Map<String, dynamic> data, CategoryType category) {
    try {
      String? name;
      String? description;
      String? link;
      String? classification;
      List<String> content = [];

      switch (category) {
        case CategoryType.games:
          name = data['game'];
          description = data['description'];
          link = data['link'];
          classification = data['classify'];
          content = List<String>.from(data['words'] ?? []);
          break;

        case CategoryType.activities:
          name = data['activity'];
          description = data['description'];
          link = data['link'];
          classification = data['classify'];
          content = List<String>.from(data['words'] ?? []);
          break;

        case CategoryType.riddles:
          name = data['name'];
          content = List<String>.from(data['riddles'] ?? []);
          break;

        case CategoryType.texts:
          name = data['name'];
          description = data['description'];
          link = data['link'];
          classification = data['classify'];
          break;
      }

      if (name == null || name.isEmpty) return null;

      return ItemModel(
        id: '${category.name}_${DateTime.now().millisecondsSinceEpoch}_${name.hashCode}',
        name: name,
        description: description,
        link: link,
        classification: classification,
        content: content,
        category: category.name,
      );

    } catch (e) {
      print('Error parsing item: $e');
      return null;
    }
  }

  CategoryType _getCategoryType(String categoryName) {
    switch (categoryName) {
      case 'משחקים':
        return CategoryType.games;
      case 'פעילויות':
        return CategoryType.activities;
      case 'חידות':
        return CategoryType.riddles;
      case 'קטעים':
        return CategoryType.texts;
      default:
        return CategoryType.games;
    }
  }

  Future<void> mergeWithUserData() async {
    // User additions are handled separately by StorageService.getAllItems()
    print('Merging with user data completed');
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
      await storageService.userAdditionsBox.clear();
      await storageService.deletedByUserBox.clear();
    }

    // Reload from original data
    await loadFromLocalJson();
  }
}