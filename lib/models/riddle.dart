import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '/models/game.dart';
import '/models/circle.dart';
import '/models/word_game.dart';
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

class Riddle {
  final String category;
  final List<String> riddles;
  final bool isUserAdded;

  Riddle({
    required this.category,
    required this.riddles,
    this.isUserAdded = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'riddles': riddles,
      'isUserAdded': isUserAdded,
    };
  }

  factory Riddle.fromMap(Map<String, dynamic> map) {
    return Riddle(
      category: map['category'] ?? '',
      riddles: List<String>.from(map['riddles'] ?? []),
      isUserAdded: map['isUserAdded'] ?? false,
    );
  }
}
