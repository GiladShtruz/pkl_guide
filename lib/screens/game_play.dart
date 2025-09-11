import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';

// מודלים לנתונים
class Game {
  final String name;
  final String description;
  final String classification;

  Game({
    required this.name,
    required this.description,
    required this.classification,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'classification': classification,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      classification: map['classification'] ?? '',
    );
  }
}

class Riddle {
  final String category;
  final List<String> riddles;

  Riddle({required this.category, required this.riddles});

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'riddles': riddles,
    };
  }

  factory Riddle.fromMap(Map<String, dynamic> map) {
    return Riddle(
      category: map['category'] ?? '',
      riddles: List<String>.from(map['riddles'] ?? []),
    );
  }
}

class Circle {
  final String category;
  final List<String> items;

  Circle({required this.category, required this.items});

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'items': items,
    };
  }

  factory Circle.fromMap(Map<String, dynamic> map) {
    return Circle(
      category: map['category'] ?? '',
      items: List<String>.from(map['items'] ?? []),
    );
  }
}

// מודל למשחק מילים (פנטומימה/מדבקות)
class WordGame {
  final String name;
  final String description;
  final List<String> words;

  WordGame({
    required this.name,
    required this.description,
    required this.words,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'words': words,
    };
  }

  factory WordGame.fromMap(Map<String, dynamic> map) {
    return WordGame(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      words: List<String>.from(map['words'] ?? []),
    );
  }
}