import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Light Theme
  static ThemeData get lightTheme {
    const ColorScheme colorScheme = ColorScheme.light(
      primary: Color(0xFF6750A4), // Material 3 purple
      primaryContainer: Color(0xFFEADDFF),
      secondary: Colors.orange,
      // secondaryContainer: Color(0xFFE8DEF8),
      tertiary: Color(0xFF7D5260),
      tertiaryContainer: Color(0xFFFFD8E4),
      error: Color(0xFFBA1A1A),
      errorContainer: Color(0xFFFFDAD6),
      surface: Color(0xFFFEF7FF), // Light purple tint for cards
      background: Color(0xFFF6F2F7), // Soft purple-gray background
      surfaceVariant: Color(0xFFE7E0EC),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onTertiary: Colors.white,
      onSurface: Color(0xFF1C1B1F),
      onBackground: Color(0xFF1C1B1F),
      onError: Colors.white,
      outline: Color(0xFF79747E),
      outlineVariant: Color(0xFFCAC4D0),
      shadow: Colors.black,
      inverseSurface: Color(0xFF313033),
      inversePrimary: Color(0xFFD0BCFF),
      surfaceTint: Color(0xFF6750A4),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Heebo',
      scaffoldBackgroundColor: colorScheme.background,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
        scrolledUnderElevation: 3,

        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.deepPurple, // צבע לחלק העליון (Status Bar)
          statusBarIconBrightness: Brightness.dark, // צבע האייקונים למעלה (אנדרואיד)
          statusBarBrightness: Brightness.dark, // צבע האייקונים (iOS)
        ),
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
          fontFamily: 'Heebo',
        ),
      ),

      // Card Theme - with purple tint
      cardTheme: CardThemeData(
        elevation: 2,
        // color: Colors.white,
        surfaceTintColor: Colors.deepPurple, // בולט
        shadowColor: Colors.black.withOpacity(0.25),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      // בתוך AppTheme.lightTheme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurface.withOpacity(0.7),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        selectedIconTheme: IconThemeData(color: colorScheme.primary, size: 28),
        unselectedIconTheme: IconThemeData(color: colorScheme.onSurface.withOpacity(0.7), size: 24),
        selectedLabelStyle: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer,
        iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: colorScheme.primary);
          }
          return IconThemeData(color: colorScheme.onSurface.withOpacity(0.7));
        }),
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            );
          }
          return TextStyle(color: colorScheme.onSurface.withOpacity(0.7));
        }),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: colorScheme.primary,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary, // Solid purple color
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[200]!,
        selectedColor: Colors.orange[200]!,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.black87),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),

      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
          fontFamily: 'Heebo',
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),

      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: colorScheme.onBackground),
        headlineMedium: TextStyle(color: colorScheme.onBackground),
        headlineSmall: TextStyle(color: colorScheme.onBackground),
        titleLarge: TextStyle(color: colorScheme.onBackground),
        titleMedium: TextStyle(color: colorScheme.onBackground),
        titleSmall: TextStyle(color: colorScheme.onBackground),
        bodyLarge: TextStyle(color: colorScheme.onBackground),
        bodyMedium: TextStyle(color: colorScheme.onBackground),
        bodySmall: TextStyle(color: colorScheme.onSurfaceVariant),
        labelLarge: TextStyle(color: colorScheme.onBackground),
        labelMedium: TextStyle(color: colorScheme.onBackground),
        labelSmall: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }

  // Dark Theme
  static ThemeData get darkTheme {
    const ColorScheme colorScheme = ColorScheme.dark(
      primary: Color(0xFFD0BCFF),
      primaryContainer: Color(0xFF4F378B),
      secondary: Color(0xFFD18907),
      // secondaryContainer: Color(0xFF4A4458),
      tertiary: Color(0xFFEFB8C8),
      tertiaryContainer: Color(0xFF633B48),
      error: Color(0xFFFFB4AB),
      errorContainer: Color(0xFF93000A),
      surface: Color(0xFF1C1B1F), // Dark surface
      background: Color(0xFF141316), // Very dark background
      surfaceVariant: Color(0xFF49454F),
      onPrimary: Color(0xFF381E72),
      onSecondary: Color(0xFF332D41),
      onTertiary: Color(0xFF492532),
      onSurface: Color(0xFFE6E1E5),
      onBackground: Color(0xFFE6E1E5),
      onError: Color(0xFF690005),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      shadow: Colors.black,
      inverseSurface: Color(0xFFE6E1E5),
      inversePrimary: Color(0xFF6750A4),
      surfaceTint: Color(0xFFD0BCFF),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: 'Heebo',
      scaffoldBackgroundColor: colorScheme.background,
      brightness: Brightness.dark,

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
        scrolledUnderElevation: 3,
        surfaceTintColor: colorScheme.surfaceTint,
        centerTitle: true,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: colorScheme.onBackground,
          fontFamily: 'Heebo',
        ),
      ),

      // Card Theme - slightly elevated from background
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.grey[900],
        surfaceTintColor: Colors.deepPurple[200],
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          foregroundColor: colorScheme.onPrimary,
          backgroundColor: colorScheme.primary,
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: colorScheme.primary,
        ),
      ),

      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary, // Solid purple color
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        extendedTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceVariant.withOpacity(0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
      hintStyle: TextStyle(color: colorScheme.onSurfaceVariant.withOpacity(0.6)),
    ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey[800]!,
        selectedColor: Colors.orange[700]!,
        labelStyle: const TextStyle(fontSize: 12, color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withOpacity(0.2),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: colorScheme.surface,
          indicatorColor: colorScheme.primaryContainer,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData>((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: colorScheme.primary); // צבע ברור כשנבחר
            }
            return IconThemeData(color: colorScheme.onSurfaceVariant);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
            if (states.contains(WidgetState.selected)) {
              return TextStyle(
                color: colorScheme.primary, // אותו צבע כמו האייקון
                fontWeight: FontWeight.bold,
              );
            }
            return TextStyle(color: colorScheme.onSurfaceVariant);
          }),
        ),


      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
        ),
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          color: colorScheme.onSurface,
          fontFamily: 'Heebo',
        ),
      ),

      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          color: colorScheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),


      // Text Theme
      textTheme: TextTheme(
        headlineLarge: TextStyle(color: colorScheme.onBackground),
        headlineMedium: TextStyle(color: colorScheme.onBackground),
        headlineSmall: TextStyle(color: colorScheme.onBackground),
        titleLarge: TextStyle(color: colorScheme.onBackground),
        titleMedium: TextStyle(color: colorScheme.onBackground),
        titleSmall: TextStyle(color: colorScheme.onBackground),
        bodyLarge: TextStyle(color: colorScheme.onBackground),
        bodyMedium: TextStyle(color: colorScheme.onBackground),
        bodySmall: TextStyle(color: colorScheme.onSurfaceVariant),
        labelLarge: TextStyle(color: colorScheme.onBackground),
        labelMedium: TextStyle(color: colorScheme.onBackground),
        labelSmall: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
    );
  }
}

// Usage in main.dart:
// MaterialApp(
//   theme: AppTheme.lightTheme,
//   darkTheme: AppTheme.darkTheme,
//   themeMode: ThemeMode.system, // or .light / .dark
//   ...
// )