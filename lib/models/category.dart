
import 'package:flutter/material.dart';

CategoryType getCategoryType(String categoryKey) {
  switch (categoryKey.toLowerCase()) {
    case 'games':
    case 'משחקים':
      return CategoryType.games;
    case 'activities':
    case 'פעילויות':
      return CategoryType.activities;
    case 'riddle':
    case 'riddles':
    case 'חידות':
      return CategoryType.riddles;
    case 'texts':
    case 'קטעים':
      return CategoryType.texts;
    default:
      print('Unknown category: $categoryKey, defaulting to games');
      return CategoryType.games;
  }
}


enum CategoryType {
  games('משחקים', Icons.casino, Colors.purple, 'המשחק', 'נצפה'),
  activities('פעילויות', Icons.group, Colors.blue, 'הפעילות', 'נצפתה'),
  riddles('חידות', Icons.psychology, Colors.orange, 'החידה', 'נצפתה'),
  texts('קטעי קריאה', Icons.description, Colors.green, 'קטע הקריאה', 'נצפה');

  final String displayName;
  final IconData icon;
  final Color categoryColor;
  final String wrappedName;
  final String viewedName;

  const CategoryType(this.displayName, this.icon, this.categoryColor, this.wrappedName, this.viewedName);
}




enum CategoryEntry {
  title, detail, link, classification, equipment, elements,
}



/*
  games('משחקים', Icons.sports_esports),
      games('משחקים', Icons.casino),
  activities('פעילויות', Icons.assignment),
    activities('פעילויות', Icons.group),
  riddles('חידות', Icons.quiz),
   riddles('חידות', Icons.psychology),
     riddles('חידות', Icons.extension),
  texts('קטעים', Icons.description);


* */