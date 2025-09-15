
import 'package:flutter/material.dart';

enum CategoryType {
  games('משחקים', Icons.casino),
  activities('פעילויות', Icons.group),
  riddles('חידות', Icons.psychology),
  texts('קטעים', Icons.description);

  final String displayName;
  final IconData icon;

  const CategoryType(this.displayName, this.icon);
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