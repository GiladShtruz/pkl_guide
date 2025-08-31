import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import '../services/import_export_service.dart';
import '../widgets/category_card.dart';
import '../widgets/bottom_nav.dart';
import '../screens/category_screen.dart';
import '../screens/search_screen.dart';
import '../screens/favorites_screen.dart';
import '../dialogs/update_dialog.dart';
import '../dialogs/about_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasUpdate = false;
  Map<String, String>? _updateInfo;
  bool _isInitialLoad = true;

  @override
  void initState() {
    super.initState();
    _quickInit();
  }

  Future<void> _quickInit() async {
    // Quick check if data exists
    final storageService = context.read<StorageService>();
    final hasData = storageService.getAppData().isNotEmpty;

    if (!hasData) {
      // First time - need to load CSV
      setState(() {
        _isInitialLoad = true;
      });

      final csvService = context.read<CsvService>();
      await csvService.loadFromLocalCSV();
    }

    // Data is ready - show UI immediately
    if (mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }

    // Check for updates in background (non-blocking)
    _checkForUpdatesInBackground();
  }

  Future<void> _checkForUpdatesInBackground() async {
    // Small delay to let UI render first
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      final csvService = context.read<CsvService>();
      final updateInfo = await csvService.checkForUpdates();

      if (updateInfo != null && mounted) {
        setState(() {
          _hasUpdate = true;
          _updateInfo = updateInfo;
        });

        _showUpdateDialog();
      }
    } catch (e) {
      print('Error checking for updates: $e');
    }
  }

  void _showUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) => UpdateDialog(
        onConfirm: () async {
          final csvService = context.read<CsvService>();
          await csvService.updateFromOnline(
            _updateInfo!['csv']!,
            _updateInfo!['version']!,
          );
          setState(() {
            _hasUpdate = false;
            _updateInfo = null;
          });
        },
        onDecline: () {
          // Keep the update button visible
        },
      ),
    );
  }

  Future<void> _forceReloadData() async {
    // Clear all data
    final storageService = context.read<StorageService>();
    await storageService.appDataBox.clear();
    await storageService.userAdditionsBox.clear();

    // Reload from CSV
    final csvService = context.read<CsvService>();
    await csvService.loadFromLocalCSV();

    // Refresh UI
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('נתונים נטענו מחדש'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialLoad) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('טוען נתונים ראשוניים...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _currentIndex == 0 ? AppBar(
        title: const Text('פק״ל למדריך'),
        centerTitle: true,
        actions: [
          if (_hasUpdate)
            IconButton(
              icon: const Icon(Icons.update, color: Colors.orange),
              onPressed: _showUpdateDialog,
              tooltip: 'עדכון זמין',
            ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'import':
                  _handleImport();
                  break;
                case 'export':
                  _handleExport();
                  break;
                case 'share':
                  _handleShare();
                  break;
                case 'reload':
                  await _forceReloadData();
                  break;
                case 'about':
                  _showAbout();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import',
                child: Row(
                  children: [
                    Icon(Icons.upload_file),
                    SizedBox(width: 8),
                    Text('ייבוא'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('ייצוא'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.developer_mode),
                    SizedBox(width: 8),
                    Text('שתף תוספות'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'reload',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 8),
                    Text('טען מחדש'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 8),
                    Text('אודות'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ) : null,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeGrid(),
          const SearchScreen(),
          const FavoritesScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHomeGrid() {
    final storageService = context.read<StorageService>();

    return RefreshIndicator(
      onRefresh: () async {
        await _forceReloadData();
      },
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: CategoryType.values.length,
          itemBuilder: (context, index) {
            final category = CategoryType.values[index];
            final itemCount = storageService.getAllItems(category: category).length;

            return CategoryCard(
              category: category,
              itemCount: itemCount,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(category: category),
                  ),
                ).then((_) {
                  setState(() {}); // Refresh counts
                });
              },
            );
          },
        ),
      ),
    );
  }

  void _handleImport() async {
    final importExportService = ImportExportService(
      csvService: context.read<CsvService>(),
      storageService: context.read<StorageService>(),
    );

    await importExportService.importCSV(context);
    setState(() {}); // Refresh UI
  }

  void _handleExport() async {
    final importExportService = ImportExportService(
      csvService: context.read<CsvService>(),
      storageService: context.read<StorageService>(),
    );

    await importExportService.exportCSV(context);
  }

  void _handleShare() async {
    final importExportService = ImportExportService(
      csvService: context.read<CsvService>(),
      storageService: context.read<StorageService>(),
    );

    await importExportService.shareAdditions(context);
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => const AboutDialogWidget(),
    );
  }
}