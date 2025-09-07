
import 'package:flutter/material.dart';

enum CategoryType {
  games('משחקים', Icons.sports_esports),
  activities('פעילויות', Icons.assignment),
  riddles('חידות', Icons.psychology),
  texts('קטעים', Icons.description);

  final String displayName;
  final IconData icon;

  const CategoryType(this.displayName, this.icon);
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