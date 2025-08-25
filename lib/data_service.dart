// שירות לניהול הנתונים
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';

import 'game_play.dart';

class DataService {
  static const String gamesBoxName = 'games';
  static const String riddlesBoxName = 'riddles';
  static const String circlesBoxName = 'circles';
  static const String wordGamesBoxName = 'wordGames';

  static Future<void> loadDataFromCSV() async {
    final csvString = await rootBundle.loadString('assets/pkl.csv');
    List<List<dynamic>> csvTable = const CsvToListConverter().convert(csvString);

    if (csvTable.isEmpty) return;

    // מציאת מיקומי ה-"-" שמפרידים בין קטגוריות
    List<int> separatorIndices = [];
    for (int i = 0; i < csvTable[0].length; i++) {
      if (csvTable[0][i].toString().trim() == '-') {
        separatorIndices.add(i);
      }
    }

    // טיפול במשחקים (עמודות 0-2)
    await _loadGames(csvTable, 0, 3);

    // טיפול במשחקי מילים (פנטומימה ומדבקות)
    await _loadWordGames(csvTable);

    // טיפול בחידות (אחרי ה-"-" הראשון)
    if (separatorIndices.isNotEmpty) {
      int riddlesStart = separatorIndices[0] + 1;
      int riddlesEnd = separatorIndices.length > 1 ? separatorIndices[1] : csvTable[0].length;
      await _loadRiddles(csvTable, riddlesStart, riddlesEnd);
    }

    // טיפול במעגלים (אחרי ה-"-" השני)
    if (separatorIndices.length > 1) {
      int circlesStart = separatorIndices[1] + 1;
      await _loadCircles(csvTable, circlesStart, csvTable[0].length);
    }
  }

  static Future<void> _loadGames(List<List<dynamic>> csvTable, int startCol, int endCol) async {
    final box = await Hive.openBox<Map>(gamesBoxName);
    await box.clear();

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

  static Future<void> _loadWordGames(List<List<dynamic>> csvTable) async {
    final box = await Hive.openBox<Map>(wordGamesBoxName);
    await box.clear();

    // מציאת עמודות פנטומימה ומדבקות
    int pantomimeCol = -1;
    int stickersCol = -1;

    for (int i = 0; i < csvTable[0].length; i++) {
      String header = csvTable[0][i].toString().trim();
      if (header == 'פנטומימה') pantomimeCol = i;
      if (header == 'מדבקות') stickersCol = i;
    }

    // טעינת פנטומימה
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
        await box.put('פנטומימה', WordGame(
          name: 'פנטומימה',
          description: description,
          words: words,
        ).toMap());
      }
    }

    // טעינת מדבקות
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
        await box.put('מדבקות', WordGame(
          name: 'מדבקות',
          description: description,
          words: words,
        ).toMap());
      }
    }
  }

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

  static Future<void> _loadRiddles(List<List<dynamic>> csvTable, int startCol, int endCol) async {
    final box = await Hive.openBox<Map>(riddlesBoxName);
    await box.clear();

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

  static Future<void> _loadCircles(List<List<dynamic>> csvTable, int startCol, int endCol) async {
    final box = await Hive.openBox<Map>(circlesBoxName);
    await box.clear();

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
}