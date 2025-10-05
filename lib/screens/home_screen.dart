
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../providers/app_provider.dart';
import '../services/import_export_service.dart';
import '../services/storage_service.dart';
import '../services/json_service.dart';
import '../services/lists_service.dart';

import '../widgets/category_card.dart';
import '../widgets/bottom_nav.dart';
import '../screens/category_items_screen.dart';
import '../screens/games_classification_screen.dart';
import '../screens/search_screen.dart';
import '../screens/lists_screen.dart';
import '../dialogs/about_dialog.dart';

//


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final bool _hasUpdate = false;
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

  void _checkForUpdatesInBackground() {
    // Run update check in background without blocking UI
    Future.delayed(Duration(seconds: 1), () {
      if (mounted) {
        final jsonService = context.read<JsonService>();

        // Use the compute version for true background processing
        jsonService.checkForOnlineUpdates();

        // Alternative: Use the simple version if compute causes issues
        // jsonService.checkForOnlineUpdatesSimple();
      }
    });
  }


  Future<void> _showThemeDialog() async {
    final storageService = context.read<StorageService>();
    final appProvider = context.read<AppProvider>();

    final currentTheme = storageService.settingsBox.get('theme_mode', defaultValue: 'system') as String;

    final selectedTheme = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('בחר ערכת נושא'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.light_mode, size: 20),
                  SizedBox(width: 8),
                  Text('בהיר'),
                ],
              ),
              value: 'light',
              groupValue: currentTheme,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.dark_mode, size: 20),
                  SizedBox(width: 8),
                  Text('כהה'),
                ],
              ),
              value: 'dark',
              groupValue: currentTheme,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: const Row(
                children: [
                  Icon(Icons.settings_suggest, size: 20),
                  SizedBox(width: 8),
                  Text('תואם למכשיר'),
                ],
              ),
              value: 'system',
              groupValue: currentTheme,
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
        ],
      ),
    );

    if (selectedTheme != null && selectedTheme != currentTheme) {
      await storageService.settingsBox.put('theme_mode', selectedTheme);

      final themeMode = _getThemeModeFromString(selectedTheme);
      appProvider.setThemeMode(themeMode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ערכת הנושא שונתה ל${_getThemeNameInHebrew(selectedTheme)}'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  String _getThemeNameInHebrew(String theme) {
    switch (theme) {
      case 'light':
        return 'בהיר';
      case 'dark':
        return 'כהה';
      case 'system':
        return 'תואם למכשיר';
      default:
        return '';
    }
  }

  ThemeMode _getThemeModeFromString(String theme) {
    switch (theme) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
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
      appBar: _currentIndex == 0 ? AppBar(
        title: const Text('פק״ל למדריך'),
        centerTitle: true,
        actions: [
          // IconButton(
          //     icon: Icon(Icons.adb_sharp),
          //   onPressed: (){
          //     _checkForUpdatesInBackground();
          // }, ),
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
                case 'theme':
                  _showThemeDialog();
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
                    Text('ייבוא נתונים'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.download),
                    SizedBox(width: 8),
                    Text('ייצוא נתונים'),
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
                value: 'theme',
                child: Row(
                  children: [
                    Icon(Icons.palette_outlined),
                    SizedBox(width: 8),
                    Text('ערכת נושא'),
                  ],
                ),
              ),
              // const PopupMenuItem(
              //   value: 'reload',
              //   child: Row(
              //     children: [
              //       Icon(Icons.refresh),
              //       SizedBox(width: 8),
              //       Text('טען מחדש'),
              //     ],
              //   ),
              // ),
              // const PopupMenuItem(
              //   value: 'reset',
              //   child: Row(
              //     children: [
              //       Icon(Icons.restore, color: Colors.orange),
              //       SizedBox(width: 8),
              //       Text('אפס לנתונים מקוריים'),
              //     ],
              //   ),
              // ),
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
      body: [
        _buildHomeGrid(),
        SearchScreen(key: _searchKey),
        const ListsScreen(),
      ][_currentIndex],
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

    return Padding(
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
                    builder: (context) => const GamesClassificationScreen(),
                  ),
                ).then((_) {
                  setState(() {});
                });
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryItemsScreen(category: category),
                  ),
                ).then((_) {
                  setState(() {});
                });
              }
            },
          );
        },
      ),
    );
  }


// החלף את הפונקציות הקיימות ב-home_screen.dart

  void _handleImport() async {
    try {
      final importExportService = ImportExportService(
        storageService: context.read<StorageService>(),
        listsService: context.read<ListsService>(),
      );

      final success = await importExportService.importFromFile();

      if (success) {
        setState(() {}); // Refresh UI

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('הנתונים יובאו בהצלחה'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ביטול ייבוא'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בייבוא: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleExport() async {
    try {
      final importExportService = ImportExportService(
        storageService: context.read<StorageService>(),
        listsService: context.read<ListsService>(),
      );

      // Show preview dialog
      final preview = importExportService.getExportPreview();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('ייצוא נתונים'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('פריטים שנוספו: ${preview['userCreatedItems']}'),
              Text('פריטים ששונו: ${preview['modifiedItems']}'),
              Text('פריטים עם נתוני שימוש: ${preview['itemsWithUsageData']}'),
              const Divider(),
              Text('סה"כ פריטים: ${preview['totalItems']}'),
              Text('רשימות: ${preview['lists']}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('ייצוא נתונים'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await importExportService.shareExport();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בייצוא: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleShare() async {
    try {
      final importExportService = ImportExportService(
        storageService: context.read<StorageService>(),
        listsService: context.read<ListsService>(),
      );

      // Get preview of what will be shared
      final preview = importExportService.getSharePreview();

      if (preview['isEmpty']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('אין תוספות או שינויים לשיתוף'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Show preview dialog
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('שיתוף תוספות'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('פריטים חדשים: ${preview['additionsCount']}'),
                Text('פריטים ששונו: ${preview['modificationsCount']}'),
                const Divider(),
                const Text(
                  'תצוגה מקדימה:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Text(
                      preview['text'],
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'פתח קישור להצעת הנתונים דרך טופס Google',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ביטול'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('פתח קישור'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        final success = await importExportService.shareViaGoogleForms();

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('הטופס נפתח בדפדפן'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('לא ניתן לפתוח את הטופס'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('שגיאה בשיתוף: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  void _showAbout() {
    showDialog(
      context: context,
      builder: (context) => const AboutDialogWidget(),
    );
  }
}