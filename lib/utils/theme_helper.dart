// lib/utils/theme_helper.dart
import 'package:flutter/material.dart';

class ThemeHelper {
  /// Convert string to ThemeMode
  static ThemeMode getThemeModeFromString(String theme) {
    switch (theme.toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Convert ThemeMode to string
  static String getStringFromThemeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }

  /// Get Hebrew name for theme
  static String getThemeNameInHebrew(String theme) {
    switch (theme.toLowerCase()) {
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

  /// Get icon for theme mode
  static IconData getThemeIcon(String theme) {
    switch (theme.toLowerCase()) {
      case 'light':
        return Icons.light_mode;
      case 'dark':
        return Icons.dark_mode;
      case 'system':
        return Icons.settings_suggest;
      default:
        return Icons.brightness_auto;
    }
  }
}