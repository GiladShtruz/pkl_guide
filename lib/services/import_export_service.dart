// lib/services/import_export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';
import 'lists_service.dart';
import '../utils/category_helper.dart'; // ← הוסף

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
        String addition = '${CategoryHelper.getCategoryDisplayName(item.category)} בשם ${item.userTitle ?? item.originalTitle}'; // ← שינוי כאן

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
        String modification = 'ב${CategoryHelper.getCategoryDisplayName(item.category)} ${item.originalTitle} שיניתי:'; // ← שינוי כאן
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

  // ← מחקנו את _getCategoryDisplayName()

  // Share additions via Google Forms

  Future<bool> shareViaGoogleForms() async {
    try {
      final shareText = generateShareText();

      // בדיקה אם הטקסט ארוך מדי ל-URL
      const maxUrlLength = 1500;

      if (shareText.length > maxUrlLength) {
        print('טקסט ארוך (${shareText.length} תווים) - מנסה POST');
        // ניסיון ראשון: POST
        final postSuccess = await _sendViaPost(shareText);

        if (postSuccess) {
          return true;
        }

        // אם POST נכשל - פתיחה בדפדפן עם טקסט מקוצר
        print('POST נכשל, פותח בדפדפן עם טקסט מקוצר');
        return await _openInBrowserWithTruncation(shareText, maxUrlLength);

      } else {
        // טקסט קצר - פתיחה רגילה בדפדפן
        print('טקסט קצר (${shareText.length} תווים) - פותח בדפדפן');
        return await _openInBrowser(shareText);
      }

    } catch (e) {
      print('Error sharing via Google Forms: $e');
      return false;
    }
  }

// שליחה ישירה עם POST (לטקסטים ארוכים)
  Future<bool> _sendViaPost(String text) async {
    const formUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSekLHYUHcYodOSpctkVPhGM_pq5ypXi0rk_NIL9W5H34OijJw/formResponse';

    try {
      final response = await http.post(
        Uri.parse(formUrl),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'he-IL,he;q=0.9,en-US;q=0.8,en;q=0.7',
          'Origin': 'https://docs.google.com',
          'Referer': 'https://docs.google.com/forms/d/e/1FAIpQLSekLHYUHcYodOSpctkVPhGM_pq5ypXi0rk_NIL9W5H34OijJw/viewform',
        },
        body: {
          'entry.498602657': text,
        },
      );

      print('POST Status: ${response.statusCode}');

      // Google Forms מחזיר 200, 302, או 303 בהצלחה
      if (response.statusCode == 200 ||
          response.statusCode == 302 ||
          response.statusCode == 303) {
        print('✓ נשלח בהצלחה עם POST');
        return true;
      } else {
        print('⚠ POST נכשל עם סטטוס: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('✗ שגיאה בשליחת POST: $e');
      return false;
    }
  }

// פתיחה בדפדפן עם טקסט מקוצר (fallback לטקסט ארוך)
  Future<bool> _openInBrowserWithTruncation(String fullText, int maxLength) async {
    // יצירת טקסט מקוצר עם הודעה
    final truncatedText = '${fullText.substring(0, maxLength - 150)}\n\n'
        '━━━━━━━━━━━━━━━━\n'
        '⚠️ הטקסט המלא ארוך מדי עבור URL\n'
        'הועתקו רק ${maxLength - 150} תווים ראשונים\n'
        'אורך מלא: ${fullText.length} תווים\n'
        '━━━━━━━━━━━━━━━━';

    return await _openInBrowser(truncatedText);
  }

// פתיחה בדפדפן (לטקסטים רגילים)
  Future<bool> _openInBrowser(String text) async {
    final encodedText = Uri.encodeComponent(text);
    final formUrl = 'https://docs.google.com/forms/d/e/1FAIpQLSekLHYUHcYodOSpctkVPhGM_pq5ypXi0rk_NIL9W5H34OijJw/viewform?usp=pp_url&entry.498602657=$encodedText';

    print('URL length: ${formUrl.length} characters');
    final uri = Uri.parse(formUrl);

    try {
      // ניסיון ראשון: פתיחה באפליקציה חיצונית
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        // ניסיון שני: מצב ברירת מחדל
        return await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
        );
      }

      return launched;

    } catch (e) {
      print('Error launching with external mode: $e');

      try {
        // ניסיון שלישי: WebView פנימי
        return await launchUrl(
          uri,
          mode: LaunchMode.inAppWebView,
        );
      } catch (e2) {
        print('Error launching with in-app mode: $e2');
        return false;
      }
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
  Future<String> exportToJson({bool includeLists = true}) async {
    try {
      final userData = storageService.exportUserData();

      if (includeLists) {
        final listsData = listsService.exportLists();
        userData['userLists'] = listsData;
      }

      final jsonString = const JsonEncoder.withIndent('  ').convert(userData);

      return jsonString;
    } catch (e) {
      print('Error exporting data: $e');
      throw Exception('Failed to export data: $e');
    }
  }

  Future<File?> exportToFile({bool includeLists = true}) async {
    try {
      final jsonString = await exportToJson(includeLists: includeLists);

      final directory = await getApplicationDocumentsDirectory();

      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      return file;
    } catch (e) {
      print('Error exporting to file: $e');
      return null;
    }
  }

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

      if (!importData.containsKey('data')) {
        throw Exception('Invalid JSON format: missing data field');
      }

      await storageService.importUserData(importData);

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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final file = File(result.files.single.path!);
        final jsonString = await file.readAsString();

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

      if (!data.containsKey('data')) {
        validation['isValid'] = false;
        validation['errors'] = ['Missing data field'];
        return validation;
      }

      if (data['data'] is List) {
        validation['itemsCount'] = (data['data'] as List).length;
      }

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

  // Export selected lists to JSON with their custom games
  Future<String> exportSelectedListsToJson(List<int> listIds) async {
    try {
      final exportData = <String, dynamic>{};
      final listsData = <Map<String, dynamic>>[];
      final customGamesData = <Map<String, dynamic>>[];
      final Set<int> processedGameIds = {};

      // Get selected lists
      for (var listId in listIds) {
        final list = listsService.listsBox.get(listId);
        if (list != null) {
          listsData.add({
            'id': list.id,
            'name': list.name,
            'detail': list.detail,
            'categoryItemIds': list.categoryItemIds,
            'createdAt': list.createdAt.toIso8601String(),
            'lastModified': list.lastModified?.toIso8601String(),
            'isDefault': list.isDefault,
          });

          // Check for custom games in this list
          for (var itemId in list.categoryItemIds) {
            if (!processedGameIds.contains(itemId)) {
              final item = storageService.appDataBox.get(itemId);
              if (item != null && item.isUserCreated) {
                // This is a custom game, add it to the export
                customGamesData.add(item.toJson());
                processedGameIds.add(itemId);
              }
            }
          }
        }
      }

      exportData['lists'] = listsData;
      exportData['customGames'] = customGamesData;
      exportData['exportDate'] = DateTime.now().toIso8601String();
      exportData['type'] = 'pkl_guide_lists_export';
      exportData['version'] = '1.0';

      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      return jsonString;
    } catch (e) {
      print('Error exporting selected lists: $e');
      throw Exception('Failed to export selected lists: $e');
    }
  }

  // Export selected lists to file and share
  Future<void> shareExportSelectedLists(List<int> listIds) async {
    try {
      final jsonString = await exportSelectedListsToJson(listIds);

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final fileName = 'lists_export_$timestamp.json';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(jsonString);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'ייצוא רשימות',
        text: 'ייצוא רשימות מאפליקציית פק"ל למדריך',
      );
    } catch (e) {
      print('Error sharing selected lists export: $e');
      throw Exception('Failed to share selected lists: $e');
    }
  }

  // Import selected lists from JSON
  Future<Map<String, dynamic>> importSelectedListsFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> importData = json.decode(jsonString);

      // Validate import data
      if (importData['type'] != 'pkl_guide_lists_export') {
        throw Exception('Invalid file type');
      }

      final result = {
        'listsImported': 0,
        'customGamesImported': 0,
        'listNames': <String>[],
      };

      // Import custom games first
      if (importData.containsKey('customGames') && importData['customGames'] != null) {
        final customGames = importData['customGames'] as List;
        for (var gameJson in customGames) {
          final gameId = gameJson['id'] as int;
          final existingGame = storageService.appDataBox.get(gameId);

          if (existingGame == null) {
            // Only import if game doesn't exist
            await storageService.importUserData({'data': [gameJson]});
            result['customGamesImported'] = (result['customGamesImported'] as int) + 1;
          }
        }
      }

      // Import lists
      if (importData.containsKey('lists') && importData['lists'] != null) {
        await listsService.importLists(importData['lists']);
        result['listsImported'] = (importData['lists'] as List).length;

        // Collect list names for display
        final listNames = result['listNames'] as List<String>;
        for (var listJson in importData['lists']) {
          listNames.add(listJson['name'] as String);
        }
      }

      return result;
    } catch (e) {
      print('Error importing selected lists: $e');
      throw Exception('Failed to import lists: $e');
    }
  }
}