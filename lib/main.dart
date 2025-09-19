import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pkl_guide/app_theme.dart';
import 'package:provider/provider.dart';
import 'models/element_model.dart';
import 'screens/home_screen.dart';
import 'services/storage_service.dart';
import 'services/json_service.dart';
import 'services/lists_service.dart';
import 'providers/app_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Initialize services
  final storageService = StorageService();
  await storageService.init();

  final listsService = ListsService(storageService);
  await listsService.init();


  final jsonService = JsonService(storageService);
  // Don't load data here - let HomeScreen handle it with loading state

  runApp(
    MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storageService),
        Provider<JsonService>.value(value: jsonService),
        Provider<ListsService>.value(value: listsService),
        ChangeNotifierProvider(create: (_) => AppProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'פק״ל למדריך',
      debugShowCheckedModeBanner: false,
      locale: const Locale('he', 'IL'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('he', 'IL'),
      ],
      // theme: ThemeData(
      //   primarySwatch: Colors.blue,
      //   fontFamily: 'Heebo',
      //   appBarTheme: const AppBarTheme(
      //     backgroundColor: Colors.white,
      //     foregroundColor: Colors.black,
      //     elevation: 1,
      //   ),
      //   useMaterial3: true,
      // ),
      theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // or .light / .dark
      home: const HomeScreen(),
    );
  }
}