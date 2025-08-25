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
import '/models/word_game.dart';
import '/models/search_result.dart';
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

class DataService {
  static const String gamesBoxName = 'games';
  static const String riddlesBoxName = 'riddles';
  static const String circlesBoxName = 'circles';
  static const String wordGamesBoxName = 'wordGames';
  static const String userAdditionsBoxName = 'userAdditions';

  // Load data from CSV file
  static Future<void> loadDataFromCSV() async {
    final csvString = await rootBundle.loadString('assets/pkl.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

    if (csvTable.isEmpty) return;

    // Find separator indices (-)
    List<int> separatorIndices = [];
    for (int i = 0; i < csvTable[0].length; i++) {
      if (csvTable[0][i].toString().trim() == '-') {
        separatorIndices.add(i);
      }
    }

    // Load games (columns 0-2)
    await _loadGames(csvTable, 0, 3);

    // Load word games (Pantomime and Stickers)
    await _loadWordGames(csvTable);

    // Load riddles (after first separator)
    if (separatorIndices.isNotEmpty) {
      int riddlesStart = separatorIndices[0] + 1;
      int riddlesEnd = separatorIndices.length > 1 ? separatorIndices[1] : csvTable[0].length;
      await _loadRiddles(csvTable, riddlesStart, riddlesEnd);
    }

    // Load circles (after second separator)
    if (separatorIndices.length > 1) {
      int circlesStart = separatorIndices[1] + 1;
      await _loadCircles(csvTable, circlesStart, csvTable[0].length);
    }

    // Load user additions
    await _loadUserAdditions();
  }

  // Load games from CSV
  static Future<void> _loadGames(List<List<dynamic>> csvTable, int startCol, int endCol) async {
    final box = await Hive.openBox<Map>(gamesBoxName);

    List<Game> games = [];
    for (int i = 1; i < csvTable.length; i++) {
      if (csvTable[i].length > startCol &&
          csvTable[i][startCol] != null &&
          csvTable[i][startCol].toString().trim().isNotEmpty) {

        String name = csvTable[i][startCol].toString().trim();
        String description = csvTable[i].length > startCol + 1 ?
            csvTable[i][startCol + 1].toString().trim() : '';
        String classification = csvTable[i].length > startCol + 2 ?
            csvTable[i][startCol + 2].toString().trim() : '';

        games.add(Game(
          name: name,
          description: description,
          classification: classification,
        ));
      }
    }

    for (int i = 0; i < games.length; i++) {
      await box.put(i, games[i].toMap());
    }
  }

  // Load word games from CSV
  static Future<void> _loadWordGames(List<List<dynamic>> csvTable) async {
    final box = await Hive.openBox<Map>(wordGamesBoxName);

    // Find Pantomime and Stickers columns
    int pantomimeCol = -1;
    int stickersCol = -1;

    for (int i = 0; i < csvTable[0].length; i++) {
      String header = csvTable[0][i].toString().trim();
      if (header == 'פנטומימה') pantomimeCol = i;
      if (header == 'מדבקות') stickersCol = i;
    }

    // Load Pantomime
    if (pantomimeCol != -1) {
      String description = csvTable[1][pantomimeCol]?.toString().trim() ?? '';
      List<String> words = [];

      for (int row = 2; row < csvTable.length; row++) {
        if (csvTable[row].length > pantomimeCol &&
            csvTable[row][pantomimeCol] != null &&
            csvTable[row][pantomimeCol].toString().trim().isNotEmpty) {
          words.add(csvTable[row][pantomimeCol].toString().trim());
        }
      }

      if (words.isNotEmpty) {
        final existingGame = box.get('פנטומימה');
        List<String> userWords = [];
        if (existingGame != null) {
          userWords = List<String>.from(existingGame['userAddedWords'] ?? []);
        }

        await box.put('פנטומימה', WordGame(
          name: 'פנטומימה',
          description: description,
          words: words,
          userAddedWords: userWords,
        ).toMap());
      }
    }

    // Load Stickers
    if (stickersCol != -1) {
      String description = csvTable[1][stickersCol]?.toString().trim() ?? '';
      List<String> words = [];

      for (int row = 2; row < csvTable.length; row++) {
        if (csvTable[row].length > stickersCol &&
            csvTable[row][stickersCol] != null &&
            csvTable[row][stickersCol].toString().trim().isNotEmpty) {
          words.add(csvTable[row][stickersCol].toString().trim());
        }
      }

      if (words.isNotEmpty) {
        final existingGame = box.get('מדבקות');
        List<String> userWords = [];
        if (existingGame != null) {
          userWords = List<String>.from(existingGame['userAddedWords'] ?? []);
        }

        await box.put('מדבקות', WordGame(
          name: 'מדבקות',
          description: description,
          words: words,
          userAddedWords: userWords,
        ).toMap());
      }
    }
  }

  // Load riddles from CSV
  static Future<void> _loadRiddles(List<List<dynamic>> csvTable, int startCol, int endCol) async {
    final box = await Hive.openBox<Map>(riddlesBoxName);

    for (int col = startCol; col < endCol && col < csvTable[0].length; col++) {
      if (csvTable[0][col] != null && csvTable[0][col].toString().trim().isNotEmpty) {
        String category = csvTable[0][col].toString().trim();
        List<String> riddles = [];

        for (int row = 1; row < csvTable.length; row++) {
          if (csvTable[row].length > col &&
              csvTable[row][col] != null &&
              csvTable[row][col].toString().trim().isNotEmpty) {
            riddles.add(csvTable[row][col].toString().trim());
          }
        }

        if (riddles.isNotEmpty) {
          await box.put(category, Riddle(category: category, riddles: riddles).toMap());
        }
      }
    }
  }

  // Load circles from CSV
  static Future<void> _loadCircles(List<List<dynamic>> csvTable, int startCol, int endCol) async {
    final box = await Hive.openBox<Map>(circlesBoxName);

    for (int col = startCol; col < endCol && col < csvTable[0].length; col++) {
      if (csvTable[0][col] != null && csvTable[0][col].toString().trim().isNotEmpty) {
        String category = csvTable[0][col].toString().trim();
        List<String> items = [];

        for (int row = 1; row < csvTable.length; row++) {
          if (csvTable[row].length > col &&
              csvTable[row][col] != null &&
              csvTable[row][col].toString().trim().isNotEmpty) {
            items.add(csvTable[row][col].toString().trim());
          }
        }

        if (items.isNotEmpty) {
          await box.put(category, Circle(category: category, items: items).toMap());
        }
      }
    }
  }

  // Load user additions
  static Future<void> _loadUserAdditions() async {
    // Initialize user additions box if not exists
    await Hive.openBox<Map>(userAdditionsBoxName);
  }

  // Add new game
  static Future<void> addGame(Game game) async {
    final box = await Hive.openBox<Map>(gamesBoxName);
    final userBox = await Hive.openBox<Map>(userAdditionsBoxName);

    // Save to main database
    final lastKey = box.keys.isEmpty ? -1 : box.keys.cast<int>().reduce((a, b) => a > b ? a : b);
    await box.put(lastKey + 1, game.toMap());

    // Save to user additions
    List<Map> addedGames = List<Map>.from(userBox.get('addedGames') ?? []);
    addedGames.add(game.toMap());
    await userBox.put('addedGames', addedGames);
  }

  // Add riddle category
  static Future<void> addRiddleCategory(String category, List<String> riddles) async {
    final box = await Hive.openBox<Map>(riddlesBoxName);
    final userBox = await Hive.openBox<Map>(userAdditionsBoxName);

    // Save to main database
    await box.put(category, Riddle(
      category: category,
      riddles: riddles,
      isUserAdded: true,
    ).toMap());

    // Save to user additions
    List<Map> addedRiddles = List<Map>.from(userBox.get('addedRiddles') ?? []);
    addedRiddles.add({'category': category, 'riddles': riddles});
    await userBox.put('addedRiddles', addedRiddles);
  }

  // Add words to word game
  static Future<void> addWordsToGame(String gameName, List<String> words) async {
    final box = await Hive.openBox<Map>(wordGamesBoxName);
    final userBox = await Hive.openBox<Map>(userAdditionsBoxName);

    final gameMap = box.get(gameName);
    if (gameMap != null) {
      final game = WordGame.fromMap(Map<String, dynamic>.from(gameMap));
      final updatedGame = WordGame(
        name: game.name,
        description: game.description,
        words: game.words,
        userAddedWords: [...game.userAddedWords, ...words],
      );
      await box.put(gameName, updatedGame.toMap());

      // Save to user additions
      Map<String, List<String>> addedWords = Map<String, List<String>>.from(
        userBox.get('addedWords') ?? {}
      );
      addedWords[gameName] = [...(addedWords[gameName] ?? []), ...words];
      await userBox.put('addedWords', addedWords);
    }
  }

  // Generate share text with all user additions
  static Future<String> generateShareText() async {
    final userBox = await Hive.openBox<Map>(userAdditionsBoxName);
    StringBuffer buffer = StringBuffer();

    buffer.writeln('===== User Additions =====\n');

    // Added games
    final addedGames = List<Map>.from(userBox.get('addedGames') ?? []);
    if (addedGames.isNotEmpty) {
      buffer.writeln('New Games:');
      for (var game in addedGames) {
        buffer.writeln('- ${game['name']}');
        buffer.writeln('  Description: ${game['description']}');
        buffer.writeln('  Classification: ${game['classification']}');
      }
      buffer.writeln();
    }

    // Added riddles
    final addedRiddles = List<Map>.from(userBox.get('addedRiddles') ?? []);
    if (addedRiddles.isNotEmpty) {
      buffer.writeln('New Riddle Categories:');
      for (var riddleCategory in addedRiddles) {
        buffer.writeln('- ${riddleCategory['category']}:');
        for (var riddle in riddleCategory['riddles']) {
          buffer.writeln('  • $riddle');
        }
      }
      buffer.writeln();
    }

    // Added words to games
    final addedWords = Map<String, List<String>>.from(userBox.get('addedWords') ?? {});
    if (addedWords.isNotEmpty) {
      buffer.writeln('Words Added to Games:');
      for (var entry in addedWords.entries) {
        buffer.writeln('To game ${entry.key} added words:');
        for (var word in entry.value) {
          buffer.writeln('  • $word');
        }
      }
    }

    return buffer.toString();
  }

  // Get all games
  static Future<List<Game>> getGames() async {
    final box = await Hive.openBox<Map>(gamesBoxName);
    List<Game> games = [];
    for (var key in box.keys) {
      final map = box.get(key);
      if (map != null) {
        games.add(Game.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    return games;
  }

  // Get all riddles
  static Future<List<Riddle>> getRiddles() async {
    final box = await Hive.openBox<Map>(riddlesBoxName);
    List<Riddle> riddles = [];
    for (var key in box.keys) {
      final map = box.get(key);
      if (map != null) {
        riddles.add(Riddle.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    return riddles;
  }

  // Get all circles
  static Future<List<Circle>> getCircles() async {
    final box = await Hive.openBox<Map>(circlesBoxName);
    List<Circle> circles = [];
    for (var key in box.keys) {
      final map = box.get(key);
      if (map != null) {
        circles.add(Circle.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    return circles;
  }

  // Get all word games
  static Future<List<WordGame>> getWordGames() async {
    final box = await Hive.openBox<Map>(wordGamesBoxName);
    List<WordGame> games = [];
    for (var key in box.keys) {
      final map = box.get(key);
      if (map != null) {
        games.add(WordGame.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    return games;
  }
}

// File: main.dart (continued)
// Main function and app initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Load data from CSV
  await DataService.loadDataFromCSV();

  runApp(const MyApp());
}
