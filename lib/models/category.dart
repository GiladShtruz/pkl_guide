
import 'package:flutter/material.dart';

enum CategoryType {
  games('משחקים', Icons.sports_esports),
  activities('פעילויות', Icons.assignment),
  riddles('חידות', Icons.quiz),
  texts('קטעים', Icons.description);

  final String displayName;
  final IconData icon;

  const CategoryType(this.displayName, this.icon);
}

