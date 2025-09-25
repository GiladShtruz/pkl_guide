
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
  games('משחקים', Icons.casino, Colors.purple),
  activities('פעילויות', Icons.group, Colors.blue),
  riddles('חידות', Icons.psychology, Colors.orange),
  texts('קטעי קריאה', Icons.description, Colors.green);

  final String displayName;
  final IconData icon;
  final Color categoryColor;

  const CategoryType(this.displayName, this.icon, this.categoryColor);
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