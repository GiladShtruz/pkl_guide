// lib/services/csv_service.dart - FINAL FIXED VERSION
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../models/item_model.dart';
import '../models/category.dart';
import 'storage_service.dart';

class CsvService {
  final StorageService storageService;
  static const String onlineCSVUrl =
      'https://drive.google.com/uc?export=download&id=12NHtjEZ1G3xj0APCCo7U1Zs5QFBornf8';

  CsvService(this.storageService);

  Future<void> loadInitialData() async {
    try {
      // Check if we have local data
      final hasLocalData = storageService
          .getAppData()
          .isNotEmpty;

      if (!hasLocalData) {
        // Load from local CSV file first time
        await loadFromLocalCSV();
      }

      // Check for updates in background
      checkForUpdates();
    } catch (e) {
      print('Error loading initial data: $e');
    }
  }

  Future<void> loadFromLocalCSV() async {
    try {
      // Load CSV from assets
      final csvString = await rootBundle.loadString('assets/pkl.csv');
      await parseAndSaveCSV(csvString, isUpdate: false);
    } catch (e) {
      print('Error loading local CSV: $e');
    }
  }

  Future<Map<String, String>?> checkForUpdates() async {
    try {
      final response = await http.get(Uri.parse(onlineCSVUrl));
      if (response.statusCode == 200) {
        final csvString = utf8.decode(response.bodyBytes);

        // Try to parse first line for version info
        final firstLine = csvString
            .split('\n')
            .first;
        if (firstLine.contains(',')) {
          // Regular CSV format, check first cell
          final cells = firstLine.split(',');
          if (cells.isNotEmpty) {
            final version = cells[0].replaceAll('"', '').trim();
            final currentVersion = storageService.getVersion();

            if (currentVersion != version && version.isNotEmpty) {
              return {
                'version': version,
                'url': '', // URL might be in second row
                'csv': csvString,
              };
            }
          }
        }
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
    return null;
  }

  Future<void> updateFromOnline(String csvString, String version) async {
    await parseAndSaveCSV(csvString, isUpdate: true);
    await storageService.saveVersion(version);
  }

  Future<void> parseAndSaveCSV(String csvContent,
      {required bool isUpdate}) async {
    try {
      print('Starting CSV parsing...');

      // Parse CSV into a 2D array
      final List<List<dynamic>> rows = const CsvToListConverter().convert(
          csvContent);

      if (rows.isEmpty) {
        print('CSV is empty');
        return;
      }

      List<ItemModel> items = [];

      // The CSV is organized by COLUMNS, not rows
      // Row 0 contains headers/categories
      // Separators (-) are in specific columns

      // Find separator positions in first row
      List<int> separatorPositions = [];
      for (int col = 0; col < rows[0].length; col++) {
        if (rows[0][col]?.toString().trim() == '-') {
          separatorPositions.add(col);
          print('Found separator at column $col');
        }
      }

      // Parse sections based on separators
      int startCol = 0;
      CategoryType? currentCategory;

      for (int sepIndex = 0; sepIndex <=
          separatorPositions.length; sepIndex++) {
        int endCol = sepIndex < separatorPositions.length
            ? separatorPositions[sepIndex]
            : rows[0].length;

        // Determine category based on position
        if (startCol == 0) {
          // First section: Games (columns 0-6)
          currentCategory = CategoryType.games;
          print('Parsing games from columns $startCol to ${endCol - 1}');
          items.addAll(_parseGamesSection(rows, startCol, endCol));
        }
        else if (separatorPositions.indexOf(startCol - 1) == 0) {
          // After first separator: Activities
          currentCategory = CategoryType.activities;
          print('Parsing activities from columns $startCol to ${endCol - 1}');
          items.addAll(_parseActivitiesSection(rows, startCol, endCol));
        }
        else if (separatorPositions.indexOf(startCol - 1) == 1) {
          // After second separator: Texts
          currentCategory = CategoryType.texts;
          print('Parsing texts from columns $startCol to ${endCol - 1}');
          items.addAll(_parseTextsSection(rows, startCol, endCol));
        }
        else if (separatorPositions.indexOf(startCol - 1) == 2) {
          // After third separator: Riddles
          currentCategory = CategoryType.riddles;
          print('Parsing riddles from columns $startCol to ${endCol - 1}');
          items.addAll(_parseRiddlesSection(rows, startCol, endCol));
        }

        startCol = endCol + 1; // Move past the separator
      }

      print('Parsed ${items.length} items total');
      for (var category in CategoryType.values) {
        final count = items
            .where((item) => item.category == category.name)
            .length;
        print('  ${category.displayName}: $count items');
      }

      // Save to storage
      if (isUpdate) {
        await mergeWithUserData(items);
      } else {
        await storageService.saveAppData(items);
      }
    } catch (e) {
      print('Error parsing CSV: $e');
      print('Stack trace: ${StackTrace.current}');
    }
  }

  List<ItemModel> _parseGamesSection(List<List<dynamic>> rows, int startCol,
      int endCol) {
    List<ItemModel> items = [];

    // Part 1: First 4 columns (list format)
    // Columns: משחק, הסבר, קישור, סיווג
    for (int row = 1; row < rows.length; row++) {
      if (rows[row].length > startCol &&
          rows[row][startCol] != null &&
          rows[row][startCol]
              .toString()
              .trim()
              .isNotEmpty) {
        final name = rows[row][startCol].toString().trim();
        final description = (rows[row].length > startCol + 1 &&
            rows[row][startCol + 1] != null)
            ? rows[row][startCol + 1].toString().trim()
            : '';
        final link = (rows[row].length > startCol + 2 &&
            rows[row][startCol + 2] != null)
            ? rows[row][startCol + 2].toString().trim()
            : '';
        final classification = (rows[row].length > startCol + 3 &&
            rows[row][startCol + 3] != null)
            ? rows[row][startCol + 3].toString().trim()
            : '';

        if (name.isNotEmpty) {
          items.add(ItemModel(
            id: 'games_${DateTime
                .now()
                .millisecondsSinceEpoch}_${items.length}',
            name: name,
            description: description.isNotEmpty ? description : null,
            link: link.isNotEmpty ? link : null,
            classification: classification.isNotEmpty ? classification : null,
            content: [],
            category: CategoryType.games.name,
          ));
          print('Added game from list format: $name');
        }
      }
    }

    // Part 2: Column format games (columns 4-6)
    for (int col = startCol + 4; col < endCol; col++) {
      if (rows[0].length > col && rows[0][col] != null) {
        final name = rows[0][col].toString().trim();

        if (name.isNotEmpty && name != '-') {
          String? link;
          String? description;
          List<String> content = [];

          // Row 1: link
          if (rows.length > 1 && rows[1].length > col && rows[1][col] != null) {
            final value = rows[1][col].toString().trim();
            if (value.startsWith('http')) {
              link = value;
            } else if (value.isNotEmpty) {
              description = value;
            }
          }

          // Row 2: description (if not already set)
          if (description == null && rows.length > 2 && rows[2].length > col &&
              rows[2][col] != null) {
            description = rows[2][col].toString().trim();
          }

          // Rest: content
          for (int row = 3; row < rows.length; row++) {
            if (rows[row].length > col && rows[row][col] != null) {
              final value = rows[row][col].toString().trim();
              if (value.isNotEmpty) {
                content.add(value);
              }
            }
          }

          items.add(ItemModel(
            id: 'games_${DateTime
                .now()
                .millisecondsSinceEpoch}_${items.length}',
            name: name,
            description: description,
            link: link,
            content: content,
            category: CategoryType.games.name,
          ));
          print('Added game from column format: $name with ${content
              .length} items');
        }
      }
    }

    return items;
  }

  List<ItemModel> _parseActivitiesSection(List<List<dynamic>> rows,
      int startCol, int endCol) {
    List<ItemModel> items = [];

    // Part 1: First 4 columns (list format)
    for (int row = 1; row < rows.length; row++) {
      if (rows[row].length > startCol &&
          rows[row][startCol] != null &&
          rows[row][startCol]
              .toString()
              .trim()
              .isNotEmpty) {
        final name = rows[row][startCol].toString().trim();
        final description = (rows[row].length > startCol + 1 &&
            rows[row][startCol + 1] != null)
            ? rows[row][startCol + 1].toString().trim()
            : '';
        final link = (rows[row].length > startCol + 2 &&
            rows[row][startCol + 2] != null)
            ? rows[row][startCol + 2].toString().trim()
            : '';
        final classification = (rows[row].length > startCol + 3 &&
            rows[row][startCol + 3] != null)
            ? rows[row][startCol + 3].toString().trim()
            : '';

        if (name.isNotEmpty) {
          items.add(ItemModel(
            id: 'activities_${DateTime
                .now()
                .millisecondsSinceEpoch}_${items.length}',
            name: name,
            description: description.isNotEmpty ? description : null,
            link: link.isNotEmpty ? link : null,
            classification: classification.isNotEmpty ? classification : null,
            content: [],
            category: CategoryType.activities.name,
          ));
          print('Added activity from list format: $name');
        }
      }
    }

    // Part 2: Column format activities (if any)
    for (int col = startCol + 4; col < endCol; col++) {
      if (rows[0].length > col && rows[0][col] != null) {
        final name = rows[0][col].toString().trim();

        if (name.isNotEmpty && name != '-') {
          String? link;
          String? description;
          List<String> content = [];

          // Similar parsing as games
          if (rows.length > 1 && rows[1].length > col && rows[1][col] != null) {
            final value = rows[1][col].toString().trim();
            if (value.startsWith('http')) {
              link = value;
            } else if (value.isNotEmpty) {
              description = value;
            }
          }

          if (description == null && rows.length > 2 && rows[2].length > col &&
              rows[2][col] != null) {
            description = rows[2][col].toString().trim();
          }

          for (int row = 3; row < rows.length; row++) {
            if (rows[row].length > col && rows[row][col] != null) {
              final value = rows[row][col].toString().trim();
              if (value.isNotEmpty) {
                content.add(value);
              }
            }
          }

          items.add(ItemModel(
            id: 'activities_${DateTime
                .now()
                .millisecondsSinceEpoch}_${items.length}',
            name: name,
            description: description,
            link: link,
            content: content,
            category: CategoryType.activities.name,
          ));
          print('Added activity from column format: $name');
        }
      }
    }

    return items;
  }

  List<ItemModel> _parseTextsSection(List<List<dynamic>> rows, int startCol,
      int endCol) {
    List<ItemModel> items = [];

    // Texts: 2 columns - name and description
    for (int row = 1; row < rows.length; row++) {
      if (rows[row].length > startCol &&
          rows[row][startCol] != null &&
          rows[row][startCol]
              .toString()
              .trim()
              .isNotEmpty) {
        final name = rows[row][startCol].toString().trim();
        final description = (rows[row].length > startCol + 1 &&
            rows[row][startCol + 1] != null)
            ? rows[row][startCol + 1].toString().trim()
            : '';

        if (name.isNotEmpty) {
          items.add(ItemModel(
            id: 'texts_${DateTime
                .now()
                .millisecondsSinceEpoch}_${items.length}',
            name: name,
            description: description,
            content: [description],
            category: CategoryType.texts.name,
          ));
          print('Added text: $name');
        }
      }
    }

    return items;
  }

  List<ItemModel> _parseRiddlesSection(List<List<dynamic>> rows, int startCol,
      int endCol) {
    List<ItemModel> items = [];

    // Each column is a riddle topic
    for (int col = startCol; col < endCol && col < rows[0].length; col++) {
      if (rows[0][col] != null) {
        final riddleName = rows[0][col].toString().trim();

        if (riddleName.isNotEmpty && riddleName != '-' &&
            riddleName != 'null') {
          List<String> riddles = [];

          // Collect riddles from rows
          for (int row = 1; row < rows.length; row++) {
            if (rows[row].length > col && rows[row][col] != null) {
              final riddle = rows[row][col].toString().trim();
              if (riddle.isNotEmpty && riddle != 'null') {
                riddles.add(riddle);
              }
            }
          }

          if (riddles.isNotEmpty) {
            items.add(ItemModel(
              id: 'riddles_${DateTime
                  .now()
                  .millisecondsSinceEpoch}_${items.length}',
              name: riddleName,
              content: riddles,
              category: CategoryType.riddles.name,
            ));
            print('Added riddle topic: $riddleName with ${riddles
                .length} riddles');
          }
        }
      }
    }

    return items;
  }

  Future<void> mergeWithUserData(List<ItemModel> newItems) async {
    // Save new app data
    await storageService.saveAppData(newItems);

    // Merge with user additions is handled by StorageService.getAllItems()
  }

  Future<String> exportUserData() async {
    final userItems = storageService.getUserAdditions();
    if (userItems.isEmpty) return '';

    // Create CSV in similar format to the original
    List<List<dynamic>> csvData = [];

    // Group items by category
    final Map<CategoryType, List<ItemModel>> groupedItems = {};
    for (var item in userItems) {
      final category = CategoryType.values.firstWhere(
            (c) => c.name == item.category,
        orElse: () => CategoryType.games,
      );
      groupedItems.putIfAbsent(category, () => []).add(item);
    }

    // Determine max rows needed
    int maxRows = 1; // At least header row
    for (var items in groupedItems.values) {
      for (var item in items) {
        maxRows = maxRows > item.content.length + 4 ? maxRows : item.content.length + 4;
      }
    }

    // Initialize rows
    for (int i = 0; i < maxRows; i++) {
      csvData.add([]);
    }

    int currentCol = 0;

    // Export each category
    for (var category in CategoryType.values) {
      final items = groupedItems[category] ?? [];
      if (items.isEmpty) continue;

      // Add separator if not first category
      if (currentCol > 0) {
        for (int row = 0; row < maxRows; row++) {
          csvData[row].add('-');
        }
        currentCol++;
      }

      // Add category items
      if (category == CategoryType.games || category == CategoryType.activities) {
        // Add header row
        csvData[0].addAll([
          category == CategoryType.games ? 'משחק' : 'פעילות',
          'הסבר',
          'קישור',
          'סיווג'
        ]);

        // Add items in list format
        for (int i = 0; i < items.length && i < maxRows - 1; i++) {
          final item = items[i];
          csvData[i + 1].addAll([
            item.name,
            item.description ?? '',
            item.link ?? '',
            item.classification ?? ''
          ]);
        }
        currentCol += 4;

      } else if (category == CategoryType.texts) {
        // Add texts
        csvData[0].addAll(['שם הפתק', 'פירוט הפתק']);

        for (int i = 0; i < items.length && i < maxRows - 1; i++) {
          final item = items[i];
          csvData[i + 1].addAll([
            item.name,
            item.description ?? item.content.firstOrNull ?? ''
          ]);
        }
        currentCol += 2;

      } else if (category == CategoryType.riddles) {
        // Add riddles as columns
        for (var item in items) {
          // Header
          csvData[0].add(item.name);

          // Riddles
          for (int i = 0; i < item.content.length && i < maxRows - 1; i++) {
            csvData[i + 1].add(item.content[i]);
          }

          // Fill empty cells
          for (int i = item.content.length + 1; i < maxRows; i++) {
            csvData[i].add('');
          }
          currentCol++;
        }
      }
    }

    // Convert to CSV string
    return const ListToCsvConverter().convert(csvData);
  }

  Future<void> importCSV(String csvContent) async {
    try {
      print('Starting CSV import...');

      // Use the same parsing logic as main CSV
      final List<List<dynamic>> rows = const CsvToListConverter().convert(csvContent);

      if (rows.isEmpty) {
        print('Import CSV is empty');
        return;
      }

      List<ItemModel> importedItems = [];

      // Find separator positions
      List<int> separatorPositions = [];
      for (int col = 0; col < rows[0].length; col++) {
        if (rows[0][col]?.toString().trim() == '-') {
          separatorPositions.add(col);
        }
      }

      // Parse sections
      int startCol = 0;

      for (int sepIndex = 0; sepIndex <= separatorPositions.length; sepIndex++) {
        int endCol = sepIndex < separatorPositions.length
            ? separatorPositions[sepIndex]
            : rows[0].length;

        // Determine category based on content
        if (startCol < rows[0].length) {
          final header = rows[0][startCol]?.toString().toLowerCase() ?? '';

          if (header.contains('משחק')) {
            importedItems.addAll(_parseGamesSection(rows, startCol, endCol));
          } else if (header.contains('פעילות')) {
            importedItems.addAll(_parseActivitiesSection(rows, startCol, endCol));
          } else if (header.contains('פתק')) {
            importedItems.addAll(_parseTextsSection(rows, startCol, endCol));
          } else if (header.contains('חידות')) {
            importedItems.addAll(_parseRiddlesSection(rows, startCol, endCol));
          }
        }

        startCol = endCol + 1;
      }

      print('Imported ${importedItems.length} items');

      // Check for duplicates and merge
      for (var item in importedItems) {
        final existingItems = storageService.getAllItems();

        bool isDuplicate = false;
        for (var existing in existingItems) {
          if (item.category == CategoryType.riddles.name) {
            // Check 80% similarity for riddles
            if (calculateSimilarity(
                item.content.join(' '),
                existing.content.join(' ')) >= 0.8) {
              isDuplicate = true;
              break;
            }
          } else if (item.category == CategoryType.texts.name) {
            // Check name similarity for texts
            if (calculateSimilarity(item.name, existing.name) >= 0.85) {
              isDuplicate = true;
              break;
            }
          } else {
            // For games and activities, check name similarity
            if (calculateSimilarity(item.name, existing.name) >= 0.85) {
              // Merge content instead of replacing
              for (var content in item.content) {
                if (!existing.content.contains(content)) {
                  existing.content.add(content);
                }
              }
              await existing.save();
              isDuplicate = true;
              break;
            }
          }
        }

        if (!isDuplicate) {
          item.isUserAdded = true;
          await storageService.addUserItem(item);
        }
      }

      print('Import completed successfully');
    } catch (e) {
      print('Error importing CSV: $e');
      throw e;
    }
  }

  double calculateSimilarity(String str1, String str2) {
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    int maxLength = str1.length > str2.length ? str1.length : str2.length;
    int distance = levenshteinDistance(str1, str2);

    return 1.0 - (distance / maxLength);
  }

  int levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<List<int>> matrix = List.generate(
      s1.length + 1,
          (i) => List.generate(s2.length + 1, (j) => 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }
}