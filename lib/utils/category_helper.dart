// lib/utils/category_helper.dart
import 'package:flutter/material.dart';
import '../models/category.dart';

class CategoryHelper {
  /// Get color for category
  static Color getCategoryColor(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'games':
      case 'משחקים':
        return Colors.purple;
      case 'activities':
      case 'פעילויות':
        return Colors.blue;
      case 'riddles':
      case 'חידות':
        return Colors.orange;
      case 'texts':
      case 'קטעים':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Get icon for category
  static IconData getCategoryIcon(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'games':
      case 'משחקים':
        return Icons.casino;
      case 'activities':
      case 'פעילויות':
        return Icons.group;
      case 'riddles':
      case 'חידות':
        return Icons.psychology;
      case 'texts':
      case 'קטעים':
        return Icons.description;
      default:
        return Icons.folder;
    }
  }

  /// Get Hebrew display name for category
  static String getCategoryDisplayName(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'games':
        return 'משחק';
      case 'activities':
        return 'פעילות';
      case 'riddles':
        return 'חידות';
      case 'texts':
        return 'טקסט';
      default:
        return categoryName;
    }
  }

  /// Get gradient colors for category card
  static List<Color> getCategoryGradient(CategoryType category) {
    switch (category) {
      case CategoryType.games:
        return [Colors.purple[400]!, Colors.purple[600]!];
      case CategoryType.activities:
        return [Colors.blue[400]!, Colors.blue[600]!];
      case CategoryType.riddles:
        return [Colors.orange[400]!, Colors.orange[600]!];
      case CategoryType.texts:
        return [Colors.green[400]!, Colors.green[600]!];
    }
  }

  /// Get icon for game classification
  static IconData getGameClassificationIcon(String classification) {
    switch (classification.toLowerCase()) {
      case 'כל המשחקים':
      case 'all':
        return Icons.casino;
      case 'משחקי כיסאות':
        return Icons.event_seat;
      case 'משחקים בחוץ':
        return Icons.park;
      case 'משחקים כללייים':
        return Icons.games;
      case 'משחקי אנרגיה':
        return Icons.bolt;
      case 'משחקי דרך':
        return Icons.directions_walk;
      case 'משחקי פתיחה':
        return Icons.celebration;
      case 'odt':
        return Icons.hiking;
      case 'משחקי חברה':
        return Icons.groups;
      case 'אינטראקטיבי':
        return Icons.touch_app;
      case 'כללי':
        return Icons.category;
      default:
        return Icons.category;
    }
  }

  /// Get chip widget for category (for lists)
  static Widget getCategoryChip(String categoryName, {bool compact = true}) {
    return Chip(
      label: Text(
        getCategoryDisplayName(categoryName),
        style: TextStyle(fontSize: compact ? 12 : 14),
      ),
      backgroundColor: getCategoryColor(categoryName).withOpacity(0.2),
      labelStyle: TextStyle(color: getCategoryColor(categoryName)),
      visualDensity: compact ? VisualDensity.compact : null,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: 0,
      ),
    );
  }
}