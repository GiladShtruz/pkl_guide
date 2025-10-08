// lib/screens/home_screen.dart
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
import '../utils/theme_helper.dart'; // ← הוסף

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
    final storageService = context.read<StorageService>();
    final hasData = storageService.getAppData().isNotEmpty;

    if (!hasData) {
      setState(() {
        _isInitialLoad = true;
      });

      final jsonService = context.read<JsonService>();
      await jsonService.loadFromLocalJson();
    }

    if (mounted) {
      setState(() {
        _isInitialLoad = false;
      });
    }

    _checkForUpdatesInBackground();
  }

  void _checkForUpdatesInBackground() async {
    if (mounted) {
      final jsonService = context.read<JsonService>();
      bool wasUpdated = await jsonService.checkForOnlineUpdates();
      if (wasUpdated) {
        print('העדכון בוצע בהצלחה!');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('נתונים עודכנו'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        print('אין עדכון');
      }
    }
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
              title: Row(
                children: [
                  Icon(ThemeHelper.getThemeIcon('light'), size: 20), // ← שינוי כאן
                  const SizedBox(width: 8),
                  const Text('בהיר'),
                ],
              ),
              value: 'light',
              groupValue: currentTheme,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(ThemeHelper.getThemeIcon('dark'), size: 20), // ← שינוי כאן
                  const SizedBox(width: 8),
                  const Text('כהה'),
                ],
              ),
              value: 'dark',
              groupValue: currentTheme,
              onChanged: (value) => Navigator.pop(context, value),
            ),
            RadioListTile<String>(
              title: Row(
                children: [
                  Icon(ThemeHelper.getThemeIcon('system'), size: 20), // ← שינוי כאן
                  const SizedBox(width: 8),
                  const Text('תואם למכשיר'),
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

      final themeMode = ThemeHelper.getThemeModeFromString(selectedTheme); // ← שינוי כאן
      appProvider.setThemeMode(themeMode);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ערכת הנושא שונתה ל${ThemeHelper.getThemeNameInHebrew(selectedTheme)}'), // ← שינוי כאן
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  // ← מחקנו את _getThemeNameInHebrew() ו-_getThemeModeFromString()

  Future<void> _forceReloadData() async {
    final storageService = context.read<StorageService>();
    await storageService.appDataBox.clear();

    final jsonService = context.read<JsonService>();
    await jsonService.loadFromLocalJson();

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
      return const Scaffold(
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
        title: const Text('פק"ל למדריך'),
        centerTitle: true,
        actions: [
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
          if (index == 1) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _searchKey.currentState?.focusSearch();
            });
          } else {
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

  void _handleImport() async {
    try {
      final importExportService = ImportExportService(
        storageService: context.read<StorageService>(),
        listsService: context.read<ListsService>(),
      );

      final success = await importExportService.importFromFile();

      if (success) {
        setState(() {});

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

      final preview = importExportService.getExportPreview();

      bool exportLists = true;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) => AlertDialog(
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: true,
                      onChanged: null,
                    ),
                    const Expanded(
                      child: Text('תוכן'),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: exportLists,
                      onChanged: (value) {
                        setState(() {
                          exportLists = value ?? true;
                        });
                      },
                    ),
                    Expanded(
                      child: Text('רשימות (${preview['lists']})'),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('ביטול'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context, true);
                },
                child: const Text('ייצא'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true) {
        await importExportService.shareExport(includeLists: exportLists);
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