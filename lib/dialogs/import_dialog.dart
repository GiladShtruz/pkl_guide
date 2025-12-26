import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/import_export_service.dart';

enum ImportStatus {
  loading,
  success,
  error,
}

enum ImportType {
  lists,
  generalBackup,
}

class ImportDialog extends StatefulWidget {
  final String jsonData;

  const ImportDialog({
    super.key,
    required this.jsonData,
  });

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  ImportStatus _status = ImportStatus.loading;
  String _message = 'טוען קובץ...';
  List<String> _importedListNames = [];
  int _listsImported = 0;
  int _customGamesImported = 0;
  ImportType? _importType;

  // Stats for general backup
  int _itemsImported = 0;
  int _userListsImported = 0;

  @override
  void initState() {
    super.initState();
    _performImport();
  }

  Future<void> _performImport() async {
    try {
      final importExportService = context.read<ImportExportService>();

      // Simulate a brief loading period for UX
      await Future.delayed(const Duration(milliseconds: 500));

      // Detect import type
      final importType = _detectImportType(widget.jsonData);
      _importType = importType;

      if (importType == ImportType.lists) {
        // Lists export format
        final result = await importExportService.importSelectedListsFromJson(widget.jsonData);

        setState(() {
          _status = ImportStatus.success;
          _listsImported = result['listsImported'] as int;
          _customGamesImported = result['customGamesImported'] as int;
          _importedListNames = result['listNames'] as List<String>;
          _message = 'הייבוא הושלם בהצלחה!';
        });
      } else {
        // General backup format
        await importExportService.importFromJson(widget.jsonData);

        // Get import stats from validation
        final validation = importExportService.validateImportData(widget.jsonData);

        setState(() {
          _status = ImportStatus.success;
          _itemsImported = validation['itemsCount'] as int;
          _userListsImported = validation['listsCount'] as int;
          _message = 'הייבוא הושלם בהצלחה!';
        });
      }
    } catch (e) {
      setState(() {
        _status = ImportStatus.error;
        _message = 'שגיאה בייבוא: ${e.toString()}';
      });
    }
  }

  ImportType _detectImportType(String jsonData) {
    try {
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(const JsonDecoder().convert(jsonData));

      // Check if it's a lists export (has 'type' field with specific value)
      if (data['type'] == 'pkl_guide_lists_export') {
        return ImportType.lists;
      }

      // Otherwise, it's a general backup (has 'data' field)
      return ImportType.generalBackup;
    } catch (e) {
      // Default to general backup on parse error
      return ImportType.generalBackup;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon based on status
            if (_status == ImportStatus.loading)
              const CircularProgressIndicator()
            else if (_status == ImportStatus.success)
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              )
            else
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 64,
              ),

            const SizedBox(height: 16),

            // Title
            Text(
              _status == ImportStatus.loading
                  ? 'מייבא נתונים'
                  : _status == ImportStatus.success
                      ? 'ייבוא הושלם!'
                      : 'שגיאה בייבוא',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Message
            Text(
              _message,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),

            // Success details
            if (_status == ImportStatus.success) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Lists import type
                    if (_importType == ImportType.lists) ...[
                      if (_listsImported > 0)
                        Row(
                          children: [
                            const Icon(Icons.bookmark, size: 20, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'יובאו $_listsImported רשימות',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      if (_customGamesImported > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.games, size: 20, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'יובאו $_customGamesImported משחקים מותאמים אישית',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (_importedListNames.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'רשימות שיובאו:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...(_importedListNames.map((name) => Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.check, size: 16, color: Colors.green),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ))),
                      ],
                    ],
                    // General backup import type
                    if (_importType == ImportType.generalBackup) ...[
                      Row(
                        children: [
                          const Icon(Icons.backup, size: 20, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'יובאו $_itemsImported פריטים',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      if (_userListsImported > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.bookmark, size: 20, color: Colors.green),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'יובאו $_userListsImported רשימות',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Close button (only show when not loading)
            if (_status != ImportStatus.loading)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    _status == ImportStatus.success ? _importType : null,
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _status == ImportStatus.success
                        ? Colors.green
                        : Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'סגור',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
