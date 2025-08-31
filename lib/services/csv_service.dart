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
        final lines = const CsvToListConverter().convert(csvString);

        if (lines.length >= 2) {
          final version = lines[0][0].toString();
          final csvUrl = lines[1][0].toString();

          final currentVersion = storageService.getVersion();

          if (currentVersion != version) {
            return {
              'version': version,
              'url': csvUrl,
              'csv': csvString,
            };
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

      final lines = const CsvToListConverter().convert(csvContent);
      if (lines.isEmpty) {
        print('CSV is empty');
        return;
      }

      List<ItemModel> items = [];

      // Skip first 2 rows (version and URL)
      int currentRow = 2;
      CategoryType? currentCategory;

      // Parse each section
      while (currentRow < lines.length) {
        final row = lines[currentRow];

        // Check for category separator
        if (row.isNotEmpty && row[0].toString().trim() == '-') {
          print('Found separator at row $currentRow, moving to next category');

          // Determine next category
          if (currentCategory == null) {
            currentCategory = CategoryType.games;
          } else if (currentCategory == CategoryType.games) {
            currentCategory = CategoryType.activities;
          } else if (currentCategory == CategoryType.activities) {
            currentCategory = CategoryType.texts;
          } else if (currentCategory == CategoryType.texts) {
            currentCategory = CategoryType.riddles;
          } else {
            break; // No more categories
          }

          currentRow++;
          continue;
        }

        // Set initial category if not set
        if (currentCategory == null) {
          currentCategory = CategoryType.games;
        }

        print(
            'Processing category: ${currentCategory.name} at row $currentRow');

        // Parse based on category
        if (currentCategory == CategoryType.games ||
            currentCategory == CategoryType.activities) {
          items.addAll(
              _parseGamesOrActivities(lines, currentRow, currentCategory));
          // Move to next section
          currentRow = _findNextSeparator(lines, currentRow);
        } else if (currentCategory == CategoryType.texts) {
          items.addAll(_parseTexts(lines, currentRow));
          // Move to next section
          currentRow = _findNextSeparator(lines, currentRow);
        } else if (currentCategory == CategoryType.riddles) {
          items.addAll(_parseRiddles(lines, currentRow));
          // We've reached the end
          break;
        }
      }

      print('Parsed ${items.length} items total');

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

  List<ItemModel> _parseGamesOrActivities(List<List<dynamic>> lines,
      int startRow, CategoryType category) {
    List<ItemModel> items = [];
    int currentRow = startRow;

    print('Parsing ${category.name} from row $startRow');

    // Part A: First 4 columns (list format)
    while (currentRow < lines.length &&
        lines[currentRow][0].toString().trim() != '-') {
      final row = lines[currentRow];

      // Check if this is still part of the 4-column format
      if (row.length >= 4 && row[0] != null && row[0]
          .toString()
          .isNotEmpty && row[0].toString() != '-') {
        final name = row[0].toString().trim();
        final description = row.length > 1 && row[1] != null ? row[1]
            .toString()
            .trim() : '';
        final link = row.length > 2 && row[2] != null
            ? row[2].toString().trim()
            : '';
        final classification = row.length > 3 && row[3] != null ? row[3]
            .toString()
            .trim() : '';

        if (name.isNotEmpty && name != '-') {
          final item = ItemModel(
            id: '${category.name}_${DateTime
                .now()
                .millisecondsSinceEpoch}_${items.length}',
            name: name,
            description: description.isNotEmpty ? description : null,
            link: link.isNotEmpty ? link : null,
            classification: classification.isNotEmpty ? classification : null,
            content: [],
            category: category.name,
          );
          items.add(item);
          print('Added item from 4-column format: $name');
        }
      }
      currentRow++;

      // Check if we've moved to column format (no more valid 4-column entries)
      if (currentRow < lines.length) {
        final nextRow = lines[currentRow];
        // If next row doesn't have valid first column data, we're done with 4-column format
        if (nextRow.isEmpty || nextRow[0] == null || nextRow[0]
            .toString()
            .isEmpty || nextRow[0].toString() == '-') {
          break;
        }
      }
    }

    // Part B: Column format (starting from column 5)
    // Find the start of column data (where we have the item names)
    int columnStartRow = startRow;

    // Get max columns to check
    int maxColumns = 0;
    for (int r = startRow; r < lines.length &&
        lines[r][0].toString() != '-'; r++) {
      if (lines[r].length > maxColumns) {
        maxColumns = lines[r].length;
      }
    }

    print('Checking columns 4 to $maxColumns for ${category.name}');

    // Parse each column (starting from column index 4)
    for (int col = 4; col < maxColumns; col++) {
      String? name;
      String? link;
      String? description;
      List<String> content = [];

      // Read all rows for this column
      for (int r = startRow; r < lines.length &&
          lines[r][0].toString() != '-'; r++) {
        if (lines[r].length > col && lines[r][col] != null && lines[r][col]
            .toString()
            .isNotEmpty) {
          final value = lines[r][col].toString().trim();

          if (r == startRow) {
            // First row is the name
            name = value;
          } else if (r == startRow + 1) {
            // Second row is the link (if exists)
            link = value;
          } else if (r == startRow + 2) {
            // Third row is the description
            description = value;
          } else {
            // Rest are content items
            if (value.isNotEmpty) {
              content.add(value);
            }
          }
        }
      }

      // Create item if we have a name
      if (name != null && name.isNotEmpty) {
        final item = ItemModel(
          id: '${category.name}_${DateTime
              .now()
              .millisecondsSinceEpoch}_${items.length}',
          name: name,
          description: description,
          link: link,
          content: content,
          category: category.name,
        );
        items.add(item);
        print('Added item from column format: $name with ${content
            .length} content items');
      }
    }

    print('Total ${category.name} items: ${items.length}');
    return items;
  }

  List<ItemModel> _parseTexts(List<List<dynamic>> lines, int startRow) {
    List<ItemModel> items = [];
    int currentRow = startRow;

    print('Parsing texts from row $startRow');

    // Texts are simple: column 0 = name, column 1 = description
    while (currentRow < lines.length &&
        lines[currentRow][0].toString().trim() != '-') {
      final row = lines[currentRow];

      if (row.length >= 2) {
        final name = row[0]?.toString().trim() ?? '';
        final description = row[1]?.toString().trim() ?? '';

        if (name.isNotEmpty && name != '-') {
          final item = ItemModel(
            id: '${CategoryType.texts.name}_${DateTime
                .now()
                .millisecondsSinceEpoch}_${items.length}',
            name: name,
            description: description,
            content: [description],
            // Store description also in content for consistency
            category: CategoryType.texts.name,
          );
          items.add(item);
          print('Added text: $name');
        }
      }
      currentRow++;
    }

    print('Total texts: ${items.length}');
    return items;
  }

  List<ItemModel> _parseRiddles(List<List<dynamic>> lines, int startRow) {
    List<ItemModel> items = [];

    print('Parsing riddles from row $startRow');

    // Get max columns
    int maxColumns = 0;
    for (int r = startRow; r < lines.length; r++) {
      if (lines[r].length > maxColumns) {
        maxColumns = lines[r].length;
      }
    }

    // Each column is a riddle topic
    for (int col = 0; col < maxColumns; col++) {
      String? riddleName;
      List<String> riddles = [];

      // Read all rows for this column
      for (int r = startRow; r < lines.length; r++) {
        if (lines[r].length > col && lines[r][col] != null && lines[r][col]
            .toString()
            .isNotEmpty) {
          final value = lines[r][col].toString().trim();

          if (r == startRow) {
            // First row is the riddle topic name
            riddleName = value;
          } else {
            // Rest are individual riddles
            if (value.isNotEmpty && value != '-') {
              riddles.add(value);
            }
          }
        }
      }

      // Create item if we have a name and riddles
      if (riddleName != null && riddleName.isNotEmpty && riddles.isNotEmpty) {
        final item = ItemModel(
          id: '${CategoryType.riddles.name}_${DateTime
              .now()
              .millisecondsSinceEpoch}_$col',
          name: riddleName,
          content: riddles,
          category: CategoryType.riddles.name,
        );
        items.add(item);
        print('Added riddle topic: $riddleName with ${riddles.length} riddles');
      }
    }

    print('Total riddle topics: ${items.length}');
    return items;
  }

  int _findNextSeparator(List<List<dynamic>> lines, int startRow) {
    for (int i = startRow; i < lines.length; i++) {
      if (lines[i].isNotEmpty && lines[i][0].toString().trim() == '-') {
        return i;
      }
    }
    return lines.length;
  }

  // lib/services/csv_service.dart - CONTINUATION

  Future<void> mergeWithUserData(List<ItemModel> newItems) async {
    // Save new app data
    await storageService.saveAppData(newItems);

    // Merge with user additions is handled by StorageService.getAllItems()
  }

  Future<String> exportUserData() async {
    final userItems = storageService.getUserAdditions();
    if (userItems.isEmpty) return '';

    List<List<dynamic>> csvData = [];

    // Add version and URL rows (empty for user export)
    csvData.add(['User Export Version 1.0']);
    csvData.add(['']);

    // Group items by category
    final Map<String, List<ItemModel>> groupedItems = {};
    for (var item in userItems) {
      groupedItems.putIfAbsent(item.category, () => []).add(item);
    }

    // Process each category in order
    for (var category in CategoryType.values) {
      final items = groupedItems[category.name] ?? [];
      if (items.isEmpty) continue;

      // Add separator
      csvData.add(['-']);

      // Export based on category type
      if (category == CategoryType.games ||
          category == CategoryType.activities) {
        // Export in 4-column format for simplicity
        for (var item in items) {
          csvData.add([
            item.name,
            item.description ?? '',
            item.link ?? '',
            item.classification ?? '',
          ]);

          // If there's content, add it as additional rows
          if (item.content.isNotEmpty) {
            for (var content in item.content) {
              csvData.add(['', '', '', '', content]);
            }
          }
        }
      } else if (category == CategoryType.texts) {
        // Export texts in 2-column format
        for (var item in items) {
          csvData.add([
            item.name,
            item.description ?? item.content.firstOrNull ?? '',
          ]);
        }
      } else if (category == CategoryType.riddles) {
        // Export riddles in column format
        List<List<String>> riddleColumns = [];

        for (var item in items) {
          List<String> column = [item.name];
          column.addAll(item.content);
          riddleColumns.add(column);
        }

        // Transpose to rows
        if (riddleColumns.isNotEmpty) {
          int maxLength = riddleColumns.map((c) => c.length).reduce((a,
              b) => a > b ? a : b);

          for (int i = 0; i < maxLength; i++) {
            List<dynamic> row = [];
            for (var column in riddleColumns) {
              row.add(i < column.length ? column[i] : '');
            }
            csvData.add(row);
          }
        }
      }
    }

    return const ListToCsvConverter().convert(csvData);
  }

  Future<void> importCSV(String csvContent) async {
    try {
      print('Starting CSV import...');

      final lines = const CsvToListConverter().convert(csvContent);
      if (lines.length < 3) {
        print('CSV too short for import');
        return;
      }

      List<ItemModel> importedItems = [];

      // Skip first 2 rows (version and URL)
      int currentRow = 2;
      CategoryType? currentCategory;

      // Parse each section (similar to main parsing)
      while (currentRow < lines.length) {
        final row = lines[currentRow];

        // Check for category separator
        if (row.isNotEmpty && row[0].toString().trim() == '-') {
          // Determine next category
          if (currentCategory == null) {
            currentCategory = CategoryType.games;
          } else if (currentCategory == CategoryType.games) {
            currentCategory = CategoryType.activities;
          } else if (currentCategory == CategoryType.activities) {
            currentCategory = CategoryType.texts;
          } else if (currentCategory == CategoryType.texts) {
            currentCategory = CategoryType.riddles;
          } else {
            break;
          }

          currentRow++;
          continue;
        }

        if (currentCategory == null) {
          currentCategory = CategoryType.games;
        }

        // Parse based on category
        if (currentCategory == CategoryType.games ||
            currentCategory == CategoryType.activities) {
          importedItems.addAll(
              _parseGamesOrActivities(lines, currentRow, currentCategory));
          currentRow = _findNextSeparator(lines, currentRow);
        } else if (currentCategory == CategoryType.texts) {
          importedItems.addAll(_parseTexts(lines, currentRow));
          currentRow = _findNextSeparator(lines, currentRow);
        } else if (currentCategory == CategoryType.riddles) {
          importedItems.addAll(_parseRiddles(lines, currentRow));
          break;
        }
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
