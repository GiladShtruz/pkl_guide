// lib/main.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pkl_guide/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:upgrader/upgrader.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/json_service.dart';
import 'services/lists_service.dart';
import 'services/import_export_service.dart';
import 'providers/app_provider.dart';
import 'utils/theme_helper.dart';
import 'dialogs/import_dialog.dart';
import 'providers/home_navigation_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final listsService = ListsService(storageService);
  await listsService.init();

  final jsonService = JsonService(storageService);

  final importExportService = ImportExportService(
    storageService: storageService,
    listsService: listsService,
  );

  // טעינת ערכת הנושא השמורה
  final savedTheme =
  storageService.settingsBox.get('theme_mode', defaultValue: 'system')
  as String;
  final initialThemeMode = ThemeHelper.getThemeModeFromString(savedTheme); // ← שינוי כאן

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<JsonService>.value(value: jsonService),
        Provider<ListsService>.value(value: listsService),
        Provider<ImportExportService>.value(value: importExportService),
        ChangeNotifierProvider(
          create: (_) => AppProvider()..setThemeMode(initialThemeMode),
        ),
        ChangeNotifierProvider(
          create: (_) => HomeNavigationProvider(),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

// ← מחקנו את _getThemeModeFromString()

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    _handleIncomingIntent();
  }

  Future<void> _handleIncomingIntent() async {
    // Support both Android and iOS
    if (!Platform.isAndroid && !Platform.isIOS) return;

    // Wait a bit for the app to fully initialize
    await Future.delayed(const Duration(milliseconds: 500));

    try {
      const platform = MethodChannel('com.gilad.pklGuide/intent');
      final String? sharedData = await platform.invokeMethod('getSharedData');

      if (sharedData != null && sharedData.isNotEmpty) {
        // We have incoming data, show the import dialog
        _showImportDialog(sharedData);
      }
    } catch (e) {
      print('Error handling incoming intent: $e');
    }
  }

  Future<void> _showImportDialog(String jsonData) async {
    final context = navigatorKey.currentContext;
    if (context != null) {
      final result = await showDialog<ImportType?>(
        context: context,
        barrierDismissible: false,
        builder: (context) => ImportDialog(jsonData: jsonData),
      );

      // If lists were imported successfully, navigate to Lists tab
      if (result == ImportType.lists && context.mounted) {
        final navProvider = context.read<HomeNavigationProvider>();
        navProvider.navigateToTab(2); // Lists tab is index 2
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey,
          title: 'פק"ל למדריך',
          debugShowCheckedModeBanner: false,
          locale: const Locale('he', 'IL'),
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('he', 'IL')],
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: appProvider.themeMode,
          builder: (context, child) {
            return GestureDetector(
              onTap: () {
                FocusManager.instance.primaryFocus?.unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: child,
            );
          },
          home: UpgradeAlert(
            upgrader: Upgrader(
              durationUntilAlertAgain: const Duration(days: 1),
              messages: UpgraderMessages(code: 'he'),
            ),
            child: const HomeScreen(),
          ),
        );
      },
    );
  }
}