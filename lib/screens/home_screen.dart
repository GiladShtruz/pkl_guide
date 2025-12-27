// lib/screens/home_screen.dart
import 'package:flutter/services.dart';
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
import '../widgets/wrapped_banner.dart';
import '../screens/category_items_screen.dart';
import '../screens/wrapped_story_screen.dart';
import '../services/wrapped_service.dart';
import '../screens/games_classification_screen.dart';
import '../screens/search_screen.dart';
import '../screens/lists_screen.dart';
import '../dialogs/about_dialog.dart';
import '../dialogs/export_filename_dialog.dart';
import '../utils/theme_helper.dart'; // ← הוסף
import '../providers/home_navigation_provider.dart';
import 'package:intl/intl.dart';

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
  final GlobalKey<ListsScreenState> _listsKey = GlobalKey<ListsScreenState>();
  bool _showWrappedBanner = false;
  late WrappedService _wrappedService;

  @override
  void initState() {
    super.initState();
    _quickInit();
    _initWrapped();
    _setupNavigationListener();
  }

  void _setupNavigationListener() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final navProvider = context.read<HomeNavigationProvider>();
      navProvider.addListener(_onNavigationChanged);
    });
  }

  void _onNavigationChanged() {
    final navProvider = context.read<HomeNavigationProvider>();
    final pendingIndex = navProvider.pendingNavigationIndex;
    if (pendingIndex >= 0 && pendingIndex <= 2) {
      setState(() {
        _currentIndex = pendingIndex;
      });
      navProvider.clearPendingNavigation();
    }
  }

  @override
  void dispose() {
    try {
      final navProvider = context.read<HomeNavigationProvider>();
      navProvider.removeListener(_onNavigationChanged);
    } catch (_) {}
    super.dispose();
  }

  Future<void> _initWrapped() async {
    _wrappedService = WrappedService(context.read<StorageService>());
    await _wrappedService.init();
    setState(() {
      _showWrappedBanner = _wrappedService.shouldShowWrapped();
    });
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

    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;

        // If on Lists tab and in edit mode, exit edit mode first
        if (_currentIndex == 2) {
          final exited = _listsKey.currentState?.exitEditMode() ?? false;
          if (exited) return; // Handled by ListsScreen
        }

        // Otherwise, go to home tab
        setState(() {
          _currentIndex = 0;
        });
        _searchKey.currentState?.unfocusSearch();
      },
      child: Scaffold(
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
        ListsScreen(key: _listsKey),
      ][_currentIndex],
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Wrapped banner above bottom nav
          if (_showWrappedBanner && _currentIndex == 0)
            WrappedBanner(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WrappedStoryScreen(),
                  ),
                );
              },
            ),
          // Bottom navigation
          CustomBottomNav(
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
        ],
      ),
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
        // Generate default filename with today's date
        final dateFormat = DateFormat('dd.MM.yyyy');
        final today = dateFormat.format(DateTime.now());
        final defaultFilename = 'גיבוי פקל למדריך $today';

        // Show filename dialog
        final filename = await showDialog<String>(
          context: context,
          builder: (context) => ExportFilenameDialog(
            suggestedName: defaultFilename,
          ),
        );

        if (filename != null && filename.isNotEmpty) {
          await importExportService.shareExport(
            includeLists: exportLists,
            customFilename: filename,
          );
        }
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


  String generateShareText() {
    final importExportService = ImportExportService(
      storageService: context.read<StorageService>(),
      listsService: context.read<ListsService>(),
    );

    final preview = importExportService.getSharePreview();
    return preview['text'] ?? '';
  }


  void _handleShare() async {
    try {
      final importExportService = ImportExportService(
        storageService: context.read<StorageService>(),
        listsService: context.read<ListsService>(),
      );

      final preview = importExportService.getSharePreview();

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          final shareText = generateShareText(); // קבל את הטקסט המלא
          final isTextTooLong = shareText.length > 1500;

          return AlertDialog(
            title: const Text('שיתוף תוספות'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('פריטים חדשים: ${preview['additionsCount']}'),
                  Text('פריטים ששונו: ${preview['modificationsCount']}'),
                  const Divider(),

                  // אזהרה אם הטקסט ארוך מדי
                  if (isTextTooLong) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade300),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              color: Colors.orange.shade700, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'הטקסט ארוך מדי (${shareText.length} תווים)\nחובה להעתיק את התוכן המלא!',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

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
                  const SizedBox(height: 12),

                  // כפתור העתקה
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await Clipboard.setData(ClipboardData(text: shareText));
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                isTextTooLong
                                    ? 'הועתק! עכשיו הדבק בטופס Google'
                                    : 'הטקסט הועתק ללוח',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('העתק את התוכן המלא'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isTextTooLong
                            ? Colors.orange.shade700
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTextTooLong
                        ? 'לחץ על "פתח קישור" ואז הדבק את התוכן שהעתקת'
                        : 'פתח קישור להצעת הנתונים דרך טופס Google',
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
          );
        },
      );

      if (confirmed == true) {
        final success = await importExportService.shareViaGoogleForms();

        if (!success) {
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