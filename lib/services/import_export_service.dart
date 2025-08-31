import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'csv_service.dart';
import 'storage_service.dart';

class ImportExportService {
  final CsvService csvService;
  final StorageService storageService;

  ImportExportService({
    required this.csvService,
    required this.storageService,
  });

  Future<void> importCSV(BuildContext context) async {
    try {
      // Pick CSV file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String csvContent = await file.readAsString();

        // Show progress dialog
        if (context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('מייבא נתונים...'),
                ],
              ),
            ),
          );
        }

        // Import the CSV
        await csvService.importCSV(csvContent);

        if (context.mounted) {
          Navigator.pop(context); // Close progress dialog

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הנתונים יובאו בהצלחה'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close progress dialog if open

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייבוא: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> exportCSV(BuildContext context) async {
    try {
      // Generate CSV content
      String csvContent = await csvService.exportUserData();

      if (csvContent.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('אין תוכן לייצוא'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get directory for saving
      final directory = await getApplicationDocumentsDirectory();
      final fileName = 'pkl_export_${DateTime.now().millisecondsSinceEpoch}.csv';
      final file = File('${directory.path}/$fileName');

      // Write CSV to file
      await file.writeAsString(csvContent);

      if (context.mounted) {
        // Show success dialog with options
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('ייצוא הושלם'),
            content: Text('הקובץ נשמר בשם:\n$fileName'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('סגור'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  // Share the file (platform specific implementation needed)
                },
                child: const Text('שתף'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בייצוא: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> shareAdditions(BuildContext context) async {
    try {
      // Generate CSV content for user additions
      String csvContent = await csvService.exportUserData();

      if (csvContent.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('אין תוספות לשיתוף'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Encode the content for URL
      String encodedContent = Uri.encodeComponent(csvContent);

      // Create Google Form URL with pre-filled data
      String formUrl = 'https://docs.google.com/forms/d/e/'
          '1FAIpQLSekLHYUHcYodOSpctkVPhGM_pq5ypXi0rk_NIL9W5H34OijJw/'
          'viewform?usp=pp_url&entry.498602657=$encodedContent';

      final uri = Uri.parse(formUrl);

      // Launch the URL
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('תודה על השיתוף!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw 'לא ניתן לפתוח את הקישור';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('שגיאה בשיתוף: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}