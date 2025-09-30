// lib/services/json_service.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../models/element_model.dart';
import '../models/item_model.dart';
import '../models/category.dart';
import 'storage_service.dart';

class JsonService {
  final StorageService storageService;

  // Version check URL
  static const String versionCheckUrl =
      'https://drive.google.com/uc?export=download&id=1gx4d_8yPdlaMhlcDzdyK-sCBcT66HD5r';

  JsonService(this.storageService);
// first on open app:
  Future<void> loadFromLocalJson() async {
    try {
      // Load JSON from assets
      final jsonString = await rootBundle.loadString('assets/data.json');
      final jsonData = json.decode(jsonString);

      // parseAndSaveJson
      try {
        print('Starting JSON parsing...');

        final version = jsonData['version'] ?? 1;
        final categories = jsonData['categories'] ?? {};
        List<ItemModel> appItems = [];

        // Parse each category
        categories.forEach((categoryName, categoryItems) {
          print('Parsing category: $categoryName');

          final categoryType = getCategoryType(categoryName);
          //print('Parsing category: $categoryName as ${categoryHebName.name}');

          if (categoryItems is List) {
            for (var itemData in categoryItems) {
              final item = parseItem(itemData, categoryType);
              if (item != null) {
                appItems.add(item);
                print('Added item: ${item.name} with ID: ${item.id}');
              }
            }
          }
        });

        print('Parsed ${appItems.length} appItems total');

        // Save to storage
        await storageService.saveAllData(appItems);
        await storageService.saveVersion(version);
      } catch (e) {
        print('Error parsing JSON: $e');
        print('Stack trace: ${StackTrace.current}');
      }
    } catch (e) {
      print('Error loading local JSON: $e');
    }
  }

  /// Check for updates from online version file (runs in background)
  void checkForOnlineUpdates() {
    // Run in background using compute
    // bool isComputeDoTrouble = false;
    try {
      compute(_checkAndUpdateInBackground, {
        'versionCheckUrl': versionCheckUrl,
        'currentVersion': storageService.getVersion() ?? 1,
      }).then((result) {
        if (result != null && result['shouldUpdate'] == true) {
          // Update found and downloaded - save to storage
          _saveUpdatedData(result['data'], result['version']);
        }
      }).catchError((error) {
        print('Background update check failed: $error');

      });
    }
    catch (e){

    }
    // if (isComputeDoTrouble){
    //   print("start");
    //   checkForOnlineUpdatesSimple();
    // }
  }

  /// Background function for checking and downloading updates
  /// Must be static or top-level for compute
  static Future<Map<String, dynamic>?> _checkAndUpdateInBackground(Map<String, dynamic> params) async {
    try {
      final versionCheckUrl = params['versionCheckUrl'] as String;
      final currentVersion = params['currentVersion'] as int;

      print('Checking for updates in background...');

      // Step 1: Get version info from Google Drive
      final versionResponse = await http.get(Uri.parse(versionCheckUrl));
      if (versionResponse.statusCode != 200) {
        print('Failed to fetch version info');
        return null;
      }

      final versionData = json.decode(utf8.decode(versionResponse.bodyBytes));
      final newVersion = versionData['version'] ?? 1;
      final dataUrl = versionData['dataUrl'];

      print('Current version: $currentVersion, Available version: $newVersion');

      // Step 2: Check if update is needed
      if (newVersion <= currentVersion || dataUrl == null) {
        print('No update needed');
        return null;
      }

      print('Update available! Downloading from: $dataUrl');

      // Step 3: Download new data
      if (newVersion > currentVersion) {
        print("download data!!!");
        final dataResponse = await http.get(Uri.parse(dataUrl));
        if (dataResponse.statusCode != 200) {
          print('Failed to download data');
          return null;
        }

        final jsonData = json.decode(utf8.decode(dataResponse.bodyBytes));

        return {
          'shouldUpdate': true,
          'version': newVersion,
          'data': jsonData,
        };
      }
    }
    catch (e) {
      print('Error in background update check: $e');
      return null;
    }
    return null;
  }

  /// Save update data to storage (runs on main thread)
  Future<void> _saveUpdatedData(Map<String, dynamic> jsonData, int version) async {
    try {
      print('Saving update data with version: $version');
      await storageService.updateFromOnline(jsonData);
      await storageService.saveVersion(version);

      print('Update saved successfully');
    } catch (e) {
      print('Error saving update data: $e');
    }
  }

  /// Alternative: Check for updates without compute (simpler but blocks UI briefly)



  ItemModel? parseItem(Map<String, dynamic> data, CategoryType category) {
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
      List<ElementModel> elements = [];
      final dataElements = data['elements'];
      if (dataElements is List) {
        elements = dataElements.map((e) => ElementModel(e.toString(), false)).toList();
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
          elements: elements,
          category: category.name,
          isUserCreated: false,
          isUserChanged: false
      );

      return item;

    } catch (e) {
      print('Error parsing item: $e');
      return null;
    }
  }



  Future<void> resetToOriginal(CategoryType? category) async {
    if (category != null) {
      // Reset modifications in app data items for this category
      final appItems = storageService.getAppData()
          .where((item) => item.category == category.name)
          .toList();

      for (var item in appItems) {
        await storageService.resetItem(item.id);
      }
    } else {
      // Reset all modifications in app data
      for (var item in storageService.getAppData()) {
        await storageService.resetItem(item.id);
      }
    }
  }
}