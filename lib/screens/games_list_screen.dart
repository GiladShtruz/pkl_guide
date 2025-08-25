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
import '/services/data_service.dart';
import '/app.dart';
import '/screens/home_screen.dart';
import '/widgets/category_card.dart';
import '/screens/game_detail_screen.dart';
import '/screens/pantomime_game_screen.dart';
import '/screens/stickers_game_screen.dart';
import '/screens/riddles_list_screen.dart';
import '/screens/riddle_detail_screen.dart';
import '/screens/circles_list_screen.dart';
import '/screens/circle_detail_screen.dart';
import '/screens/search_screen.dart';

class GamesListScreen extends StatefulWidget {
  const GamesListScreen({Key? key}) : super(key: key);

  @override
  State<GamesListScreen> createState() => _GamesListScreenState();
}

class _GamesListScreenState extends State<GamesListScreen> {
  List<Game> games = [];
  List<WordGame> wordGames = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  Future<void> _loadGames() async {
    final loadedGames = await DataService.getGames();
    final loadedWordGames = await DataService.getWordGames();
    setState(() {
      games = loadedGames;
      wordGames = loadedWordGames;
      isLoading = false;
    });
  }

  void _showAddGameDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String classification = 'כיתה';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Game'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Game Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                DropdownButton<String>(
                  value: classification,
                  isExpanded: true,
                  items: ['כיתה', 'בחוץ', 'שטח'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      classification = value!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isNotEmpty) {
                  await DataService.addGame(Game(
                    name: nameController.text,
                    description: descController.text,
                    classification: classification,
                    isUserAdded: true,
                  ));
                  Navigator.pop(context);
                  _loadGames();
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Games'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddGameDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Regular games
                ...games.map((game) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: game.isUserAdded ? Colors.green : Colors.blue,
                      child: Icon(
                        game.isUserAdded ? Icons.person_add : Icons.sports_esports,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      game.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(game.classification),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => GameDetailScreen(game: game),
                      ));
                    },
                  ),
                )),
                // Word games
                ...wordGames.map((game) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: game.name == 'פנטומימה' ? Colors.red : Colors.orange,
                      child: Icon(
                        game.name == 'פנטומימה' ? Icons.theater_comedy : Icons.sticky_note_2,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      game.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${game.allWords.length} words'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      if (game.name == 'פנטומימה') {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => PantomimeGameScreen(wordGame: game),
                        ));
                      } else {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (context) => StickersGameScreen(wordGame: game),
                        ));
                      }
                    },
                  ),
                )),
              ],
            ),
    );
  }
}
