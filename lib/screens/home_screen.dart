import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../services/import_export_service.dart';
import '../services/storage_service.dart';
import '../services/csv_service.dart';
import '../widgets/category_card.dart';
import '../widgets/bottom_nav.dart';
import '../screens/category_screen.dart';
import '../screens/search_screen.dart';
import '../screens/favorites_screen.dart';
import '../dialogs/update_dialog.dart';
import '../dialogs/about_dialog.dart';
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
import 'debug_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _hasUpdate = false;
  Map<String, String>? _updateInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load initial data
      final csvService = context.read<CsvService>();
      await csvService.loadInitialData();

      // Check for updates
      await _checkForUpdates();
    } catch (e) {
      print('Error initializing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _checkForUpdates() async {
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
          // Refresh the data
          await _initializeData();
        },
        onDecline: () {
          // Keep the update button visible
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('טוען נתונים...'),
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
            onSelected: (value) {
              switch (value) {
                case 'import':
                  _handleImport();
                  break;
                case 'debug':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DebugScreen(),
                    ),
                  );
                  break;
                case 'export':
                  _handleExport();
                  break;
                case 'share':
                  _handleShare();
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
                value: 'debug',
                child: Row(
                  children: [
                    Icon(Icons.bug_report),
                    SizedBox(width: 8),
                    Text('Debug'),
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
                    const PopupMenuItem(
                      value: 'debug',
                      child: Row(
                        children: [
                          Icon(Icons.bug_report),
                          SizedBox(width: 8),
                          Text('Debug'),
                        ],
                      ),
                    ),
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
      onRefresh: _initializeData,
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