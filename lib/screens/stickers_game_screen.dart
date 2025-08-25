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
import '/screens/games_list_screen.dart';
import '/screens/game_detail_screen.dart';
import '/screens/pantomime_game_screen.dart';
import '/screens/riddles_list_screen.dart';
import '/screens/riddle_detail_screen.dart';
import '/screens/circles_list_screen.dart';
import '/screens/circle_detail_screen.dart';
import '/screens/search_screen.dart';

class StickersGameScreen extends StatefulWidget {
  final WordGame wordGame;

  const StickersGameScreen({Key? key, required this.wordGame}) : super(key: key);

  @override
  State<StickersGameScreen> createState() => _StickersGameScreenState();
}

class _StickersGameScreenState extends State<StickersGameScreen> {
  late List<String> _words;

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.wordGame.allWords);
  }

  void _showAddWordsDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Words to ${widget.wordGame.name}'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter words separated by comma',
            hintText: 'word1, word2, word3',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final words = controller.text.split(',')
                    .map((w) => w.trim())
                    .where((w) => w.isNotEmpty)
                    .toList();

                await DataService.addWordsToGame(widget.wordGame.name, words);
                Navigator.pop(context);

                setState(() {
                  _words.addAll(words);
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${words.length} words')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: Text(widget.wordGame.name),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWordsDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          // Game instructions
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.orange.shade100,
            child: Column(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 32,
                  color: Colors.orange,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.wordGame.description,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Words list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _words.length,
              itemBuilder: (context, index) {
                final isUserAdded = index >= widget.wordGame.words.length;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: isUserAdded ? Colors.green.shade50 : Colors.white,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isUserAdded ? Colors.green : Colors.orange,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(
                      _words[index],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: isUserAdded
                        ? const Icon(Icons.person_add, color: Colors.green)
                        : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
