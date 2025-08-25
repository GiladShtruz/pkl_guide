import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '/models/game.dart';
import '/models/riddle.dart';
import '/models/circle.dart';
import '/models/search_result.dart';
import '/services/data_service.dart';
import '/app.dart';
import '/screens/home_screen.dart';
import '/widgets/category_card.dart';
import '/screens/games_list_screen.dart';
import '/screens/game_detail_screen.dart';
import '/screens/pantomime_game_screen.dart';
import '/screens/stickers_game_screen.dart';
import '/screens/riddles_list_screen.dart';
import '/screens/riddle_detail_screen.dart';
import '/screens/circles_list_screen.dart';
import '/screens/circle_detail_screen.dart';
import '/screens/search_screen.dart';

class WordGame {
  final String name;
  final String description;
  final List<String> words;
  final List<String> userAddedWords;

  WordGame({
    required this.name,
    required this.description,
    required this.words,
    this.userAddedWords = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'words': words,
      'userAddedWords': userAddedWords,
    };
  }

  factory WordGame.fromMap(Map<String, dynamic> map) {
    return WordGame(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      words: List<String>.from(map['words'] ?? []),
      userAddedWords: List<String>.from(map['userAddedWords'] ?? []),
    );
  }

  List<String> get allWords => [...words, ...userAddedWords];
}
