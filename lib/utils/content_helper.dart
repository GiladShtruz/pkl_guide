// lib/utils/content_helper.dart

class ContentHelper {
  /// Get title for content section based on category
  static String getContentTitle(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'games':
      case 'משחקים':
        return 'תוכן המשחק';
      case 'activities':
      case 'פעילויות':
        return 'תוכן הפעילות';
      case 'riddles':
      case 'חידות':
        return 'חידות';
      case 'texts':
      case 'קטעים':
        return 'תוכן';
      default:
        return 'תוכן';
    }
  }

  /// Get detail label based on category
  static String getDetailLabel(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'games':
      case 'משחקים':
        return 'הסבר משחק';
      case 'activities':
      case 'פעילויות':
        return 'הסבר פעילות';
      default:
        return 'תוכן';
    }
  }

  /// Get hint for adding content
  static String getAddContentHint(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'games':
      case 'משחקים':
        return 'הכנס מילה חדשה...';
      case 'activities':
      case 'פעילויות':
        return 'הכנס פעילות חדשה...';
      case 'riddles':
      case 'חידות':
        return 'הכנס חידה חדשה...';
      case 'texts':
      case 'קטעים':
        return 'הכנס קטע חדש...';
      default:
        return 'הכנס תוכן חדש...';
    }
  }

  /// Get label for content section in edit/add screens
  static String getContentSectionLabel(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'games':
      case 'משחקים':
        return 'מילים';
      case 'activities':
      case 'פעילויות':
        return 'תוכן';
      case 'riddles':
      case 'חידות':
        return 'חידות';
      case 'texts':
      case 'קטעים':
        return 'קטעים';
      default:
        return 'תוכן';
    }
  }

  /// Get title for adding new item
  static String getAddItemTitle(String categoryName) {
    switch (categoryName.toLowerCase()) {
      case 'games':
      case 'משחקים':
        return 'משחק חדש';
      case 'activities':
      case 'פעילויות':
        return 'פעילות חדשה';
      case 'riddles':
      case 'חידות':
        return 'חידה חדשה';
      case 'texts':
      case 'קטעים':
        return 'קטע חדש';
      default:
        return 'פריט חדש';
    }
  }
}