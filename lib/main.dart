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
import 'providers/app_provider.dart';

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

  // טעינת ערכת הנושא השמורה
  final savedTheme =
      storageService.settingsBox.get('theme_mode', defaultValue: 'system')
          as String;
  final initialThemeMode = _getThemeModeFromString(savedTheme);

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<JsonService>.value(value: jsonService),
        Provider<ListsService>.value(value: listsService),
        ChangeNotifierProvider(
          create: (_) => AppProvider()..setThemeMode(initialThemeMode),
        ),
      ],
      child: const MyApp(),
    ),
  );
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        return MaterialApp(
          title: 'פקד״ל למדריך',
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
              durationUntilAlertAgain: const Duration(
                days: 1
              ), // בודק רק פעם ב
              messages: UpgraderMessages(code: 'he')
            ),
            child: const HomeScreen(),
          ),
        );
      },
    );
  }
}
