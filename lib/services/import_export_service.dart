// lib/services/import_export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'storage_service.dart';
import 'lists_service.dart';
import 'package:url_launcher/url_launcher.dart';


class ImportExportService {
  final StorageService storageService;
  final ListsService listsService;

  ImportExportService({
    required this.storageService,
    required this.listsService,
  });



  String generateShareText() {
    final StringBuffer buffer = StringBuffer();
    final List<String> additions = [];
    final List<String> modifications = [];

    // Process all items
    for (var item in storageService.appDataBox.values) {
      if (item.isUserCreated) {
        // User created items
        String addition = '${_getCategoryDisplayName(item.category)} בשם ${item.userTitle ?? item.originalTitle}';

        // Add detail if exists
        String? detail = item.userDetail ?? item.originalDetail;
        if (detail != null && detail.isNotEmpty) {
          addition += '\nתיאור: $detail';
        }

        // Add link if exists
        String? link = item.userLink ?? item.originalLink;
        if (link != null && link.isNotEmpty) {
          addition += '\nקישור: $link';
        }

        // Add classification if exists
        String? classification = item.userClassification ?? item.originalClassification;
        if (classification != null && classification.isNotEmpty) {
          addition += '\nסיווג: $classification';
        }

        // Add equipment if exists
        String? equipment = item.userEquipment ?? item.originalEquipment;
        if (equipment != null && equipment.isNotEmpty) {
          addition += '\nציוד: $equipment';
        }

        // Add elements if exist
        if (item.userElements.isNotEmpty) {
          List<String> strUserElements = item.userElements.map((element) => element.text).toList();
          addition += '\nפריטים: ${strUserElements.join(', ')}';
        }

        additions.add(addition);

      } else if (item.isUserChanged) {
        // Modified items
        String modification = 'ב${_getCategoryDisplayName(item.category)} ${item.originalTitle} שיניתי:';
        bool hasChanges = false;

        // Check each field for modifications
        if (item.userTitle != null) {
          modification += '\nבכותרת: ${item.userTitle}';
          hasChanges = true;
        }

        if (item.userDetail != null) {
          modification += '\nבתיאור: ${item.userDetail}';
          hasChanges = true;
        }

        if (item.userLink != null) {
          modification += '\nבקישור: ${item.userLink}';
          hasChanges = true;
        }

        if (item.userClassification != null) {
          modification += '\nבסיווג: ${item.userClassification}';
          hasChanges = true;
        }

        if (item.userEquipment != null) {
          modification += '\nבציוד: ${item.userEquipment}';
          hasChanges = true;
        }

        if (item.userElements.isNotEmpty) {
          List<String> strUserElements = item.userElements.map((element) => element.text).toList();

          modification += '\nהוספתי פריטים: ${strUserElements.join(', ')}';
          hasChanges = true;
        }

        if (hasChanges) {
          modifications.add(modification);
        }
      }
    }

    // Build final text
    if (additions.isNotEmpty) {
      buffer.writeln('דברים שהוספתי:');
      for (var addition in additions) {
        buffer.writeln(addition);
        buffer.writeln(); // Empty line between items
      }
    }

    if (modifications.isNotEmpty) {
      if (additions.isNotEmpty) {
        buffer.writeln(); // Separator between sections
      }
      buffer.writeln('דברים ששיניתי:');
      for (var modification in modifications) {
        buffer.writeln(modification);
        buffer.writeln(); // Empty line between items
      }
    }

    if (additions.isEmpty && modifications.isEmpty) {
      return '';
    }

    return buffer.toString().trim();
  }

// Helper function to get display name for category
  String _getCategoryDisplayName(String category) {
    switch (category.toLowerCase()) {
      case 'games':
        return 'משחק';
      case 'activities':
        return 'פעילות';
      case 'riddles':
        return 'חידה';
      case 'texts':
        return 'טקסט';
      default:
        return category;
    }
  }

// Share additions via Google Forms
  Future<bool> shareViaGoogleForms() async {
    try {
      // Generate the share text
      final shareText = generateShareText();

      if (shareText.isEmpty) {
        throw Exception('אין תוספות או שינויים לשיתוף');
      }

      // Encode the text for URL
      final encodedText = Uri.encodeComponent(shareText);

      // Build the pre-filled Google Forms URL
      final formUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSekLHYUHcYodOSpctkVPhGM_pq5ypXi0rk_NIL9W5H34OijJw/viewform?usp=pp_url&entry.498602657=$encodedText';

      // Parse the URL
      final uri = Uri.parse(formUrl);

      // Try to launch with external application mode first
      try {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );

        if (!launched) {
          // Try with platform default if external fails
          return await launchUrl(
            uri,
            mode: LaunchMode.platformDefault,
          );
        }

        return launched;

      } catch (e) {
        print('Error launching URL with external mode: $e');

        // Try alternative launch mode
        try {
          return await launchUrl(
            uri,
            mode: LaunchMode.inAppWebView,
          );
        } catch (e2) {
          print('Error launching URL with in-app mode: $e2');
          return false;
        }
      }

    } catch (e) {
      print('Error sharing via Google Forms: $e');
      return false;
    }
  }
// Get preview of share content
  Map<String, dynamic> getSharePreview() {
    final shareText = generateShareText();
    int additionsCount = 0;
    int modificationsCount = 0;

    for (var item in storageService.appDataBox.values) {
      if (item.isUserCreated) {
        additionsCount++;
      } else if (item.isUserChanged) {
        modificationsCount++;
      }
    }

    return {
      'text': shareText,
      'additionsCount': additionsCount,
      'modificationsCount': modificationsCount,
      'isEmpty': shareText.isEmpty,
    };
  }

  // Main export function
  // Update exportToJson to accept includeLists parameter
  Future<String> exportToJson({bool includeLists = true}) async {
    try {
      // Get data from storage service
      final userData = storageService.exportUserData();

      // Add lists to export data only if requested
      if (includeLists) {
        final listsData = listsService.exportLists();
        userData['userLists'] = listsData;
      }

      // Convert to JSON string
      final jsonString = const JsonEncoder.withIndent('  ').convert(userData);

      return jsonString;
    } catch (e) {
      print('Error exporting data: $e');
      throw Exception('Failed to export data: $e');
    }
  }

// Update exportToFile to accept includeLists parameter
  Future<File?> exportToFile({bool includeLists = true}) async {
    try {
      final jsonString = await exportToJson(includeLists: includeLists);

      // Get app documents directory
      final directory = await getApplicationDocumentsDirectory();

      // Create filename with timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      // Write to file
      await file.writeAsString(jsonString);

      return file;
    } catch (e) {
      print('Error exporting to file: $e');
      return null;
    }
  }

// Update shareExport to accept includeLists parameter
  Future<void> shareExport({bool includeLists = true}) async {
    try {
      final file = await exportToFile(includeLists: includeLists);
      if (file != null) {
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'גיבוי נתונים',
          text: 'גיבוי נתונים מהאפליקציה',
        );
      }
    } catch (e) {
      print('Error sharing export: $e');
      throw Exception('Failed to share export: $e');
    }
  }
  // Main import function
  Future<void> importFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonString);

      // Validate JSON structure
      if (!importData.containsKey('data')) {
        throw Exception('Invalid JSON format: missing data field');
      }

      // Import items
      await storageService.importUserData(importData);

      // Import lists if present
      if (importData.containsKey('userLists') && importData['userLists'] != null) {
        await listsService.importLists(importData['userLists']);
      }

      print('Import completed successfully');
    } catch (e) {
      print('Error importing data: $e');
      throw Exception('Failed to import data: $e');
    }
  }

  // Import from file picker
  Future<bool> importFromFile() async {
    try {
      // Pick file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();

        // Import the data
        await importFromJson(jsonString);
        return true;
      }

      return false;
    } catch (e) {
      print('Error importing from file: $e');
      return false;
    }
  }

  // Validate import data before importing
  Map<String, dynamic> validateImportData(String jsonString) {
    try {
      final data = json.decode(jsonString);

      final validation = {
        'isValid': true,
        'itemsCount': 0,
        'listsCount': 0,
        'errors': <String>[],
      };

      // Check for data field
      if (!data.containsKey('data')) {
        validation['isValid'] = false;
        validation['errors'] = ['Missing data field'];
        return validation;
      }

      // Count items
      if (data['data'] is List) {
        validation['itemsCount'] = (data['data'] as List).length;
      }

      // Count lists
      if (data.containsKey('userLists') && data['userLists'] is List) {
        validation['listsCount'] = (data['userLists'] as List).length;
      }

      return validation;
    } catch (e) {
      return {
        'isValid': false,
        'itemsCount': 0,
        'listsCount': 0,
        'errors': ['Invalid JSON format: $e'],
      };
    }
  }

  // Get export preview
  Map<String, int> getExportPreview() {
    int userCreatedCount = 0;
    int modifiedCount = 0;
    int usageDataCount = 0;

    for (var item in storageService.appDataBox.values) {
      if (item.isUserCreated) {
        userCreatedCount++;
      } else if (item.isUserChanged) {
        modifiedCount++;
      } else if (item.clickCount > 0 || item.lastAccessed != null) {
        usageDataCount++;
      }
    }

    return {
      'userCreatedItems': userCreatedCount,
      'modifiedItems': modifiedCount,
      'itemsWithUsageData': usageDataCount,
      'totalItems': userCreatedCount + modifiedCount + usageDataCount,
      'lists': listsService.getAllLists().length,
    };
  }


}