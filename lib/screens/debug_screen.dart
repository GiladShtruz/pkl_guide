import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import '../models/category.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  String _debugInfo = '';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    setState(() {
      _isLoading = true;
    });

    final storageService = context.read<StorageService>();

    String info = 'Debug Information\n';
    info += '=' * 30 + '\n\n';

    // Count items per category
    for (var category in CategoryType.values) {
      final items = storageService.getAllItems(category: category);
      info += '${category.displayName}: ${items.length} items\n';

      // List first 3 items
      for (int i = 0; i < items.length && i < 3; i++) {
        info += '  - ${items[i].name}\n';
        if (items[i].content.isNotEmpty) {
          info += '    Content items: ${items[i].content.length}\n';
        }
      }
      if (items.length > 3) {
        info += '  ... and ${items.length - 3} more\n';
      }
      info += '\n';
    }

    // Storage info
    info += 'Storage Information:\n';
    info += '- App Data Box: ${storageService.appDataBox.length} items\n';
    info += '- User Additions: ${storageService.userAdditionsBox.length} items\n';
    info += '- Favorites: ${storageService.favoritesBox.length} items\n';
    info += '- Deleted Items: ${storageService.deletedByUserBox.length} items\n';

    setState(() {
      _debugInfo = info;
      _isLoading = false;
    });
  }

  Future<void> _reloadCSV() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final csvService = context.read<CsvService>();
      await csvService.loadFromLocalCSV();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CSV נטען מחדש בהצלחה'),
          backgroundColor: Colors.green,
        ),
      );

      await _loadDebugInfo();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בטעינת CSV: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _clearAllData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת כל הנתונים'),
        content: const Text('האם אתה בטוח? פעולה זו תמחק את כל הנתונים השמורים.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('מחק', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final storageService = context.read<StorageService>();
      await storageService.appDataBox.clear();
      await storageService.userAdditionsBox.clear();
      await storageService.favoritesBox.clear();
      await storageService.deletedByUserBox.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('כל הנתונים נמחקו'),
          backgroundColor: Colors.orange,
        ),
      );

      await _loadDebugInfo();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Information'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Action buttons
            Wrap(
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _reloadCSV,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('טען CSV מחדש'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearAllData,
                  icon: const Icon(Icons.delete_forever),
                  label: const Text('מחק הכל'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Debug info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                _debugInfo,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}