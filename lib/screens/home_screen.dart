import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../services/json_service.dart';
import '../services/lists_service.dart';
import '../services/import_export_service.dart';
import '../widgets/category_card.dart';
import '../widgets/bottom_nav.dart';
import '../screens/category_screen.dart';
import '../screens/games_categories_screen.dart';
import '../screens/search_screen.dart';
import '../screens/lists_screen.dart';
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
  Map<String, dynamic>? _updateInfo;
  bool _isInitialLoad = true;
  final GlobalKey<SearchScreenState> _searchKey = GlobalKey<SearchScreenState>();

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
      // First time - need to load JSON
      setState(() {
        _isInitialLoad = true;
      });

      final jsonService = context.read<JsonService>();
      await jsonService.loadFromLocalJson();
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
      final jsonService = context.read<JsonService>();
      final updateInfo = await jsonService.checkForUpdates();

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
          final jsonService = context.read<JsonService>();
          await jsonService.updateFromOnline(
            _updateInfo!['data'],
            _updateInfo!['version'],
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

    // Reload from JSON
    final jsonService = context.read<JsonService>();
    await jsonService.loadFromLocalJson();

    // Refresh UI
    setState(() {});

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('נתונים נטענו מחדש'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _handleReset() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('איפוס לנתונים מקוריים'),
        content: const Text(
          'פעולה זו תמחק את כל השינויים שביצעת ותחזיר את הנתונים למצב המקורי.\n'
              'הרשימות האישיות שלך יישמרו.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('אפס', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final jsonService = context.read<JsonService>();
      await jsonService.resetToOriginal(null);

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('הנתונים אופסו למצב המקורי'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
                case 'reset':
                  await _handleReset();
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
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.restore, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('אפס לנתונים מקוריים'),
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
          SearchScreen(key: _searchKey),
          const ListsScreen(),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          if (index == 1) { // Search tab index
            print("object");
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchKey.currentState?.focusSearch();
            });
          }
          else{
            _searchKey.currentState?.unfocusSearch();
          }
        },
      ),
    );
  }

  Widget _buildHomeGrid() {
    final storageService = context.read<StorageService>();

    return RefreshIndicator(
      onRefresh: _forceReloadData,
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
            final itemCount = storageService.getAllCategoryItems(category: category).length;

            return CategoryCard(
              category: category,
              itemCount: itemCount,
              onTap: () {
                if (category == CategoryType.games) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GamesCategoriesScreen(),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CategoryScreen(category: category),
                    ),
                  ).then((_) {
                    setState(() {});
                  });
                }
              },
            );
          },
        ),
      ),
    );
  }

  void _handleImport() async {
    // TODO: Update ImportExportService to handle JSON format
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ייבוא JSON בפיתוח'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleExport() async {
    // TODO: Update ImportExportService to export as JSON
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ייצוא JSON בפיתוח'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _handleShare() async {
    // TODO: Update sharing to use JSON format
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('שיתוף JSON בפיתוח'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => const AboutDialogWidget(),
    );
  }
}