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
import '/screens/stickers_game_screen.dart';
import '/screens/riddle_detail_screen.dart';
import '/screens/circles_list_screen.dart';
import '/screens/circle_detail_screen.dart';
import '/screens/search_screen.dart';

class RiddlesListScreen extends StatefulWidget {
  const RiddlesListScreen({Key? key}) : super(key: key);

  @override
  State<RiddlesListScreen> createState() => _RiddlesListScreenState();
}

class _RiddlesListScreenState extends State<RiddlesListScreen> {
  List<Riddle> riddles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRiddles();
  }

  Future<void> _loadRiddles() async {
    final loadedRiddles = await DataService.getRiddles();
    setState(() {
      riddles = loadedRiddles;
      isLoading = false;
    });
  }

  void _showAddRiddleCategoryDialog() {
    final categoryController = TextEditingController();
    final riddlesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Riddle Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: riddlesController,
                decoration: const InputDecoration(
                  labelText: 'Riddles (one per line)',
                  hintText: 'First riddle\nSecond riddle\nThird riddle',
                ),
                maxLines: 5,
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
              if (categoryController.text.isNotEmpty &&
                  riddlesController.text.isNotEmpty) {
                final riddlesList = riddlesController.text
                    .split('\n')
                    .where((r) => r.trim().isNotEmpty)
                    .map((r) => r.trim())
                    .toList();

                await DataService.addRiddleCategory(
                  categoryController.text,
                  riddlesList,
                );

                Navigator.pop(context);
                _loadRiddles();
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
      appBar: AppBar(
        title: const Text('Riddles'),
        backgroundColor: Colors.purple,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddRiddleCategoryDialog,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: riddles.length,
              itemBuilder: (context, index) {
                final riddle = riddles[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: riddle.isUserAdded ? Colors.green : Colors.purple,
                      child: Icon(
                        riddle.isUserAdded ? Icons.person_add : Icons.psychology,
                        color: Colors.white,
                      ),
                    ),
                    title: Text(
                      riddle.category,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text('${riddle.riddles.length} riddles'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                        builder: (context) => RiddleDetailScreen(riddle: riddle),
                      ));
                    },
                  ),
                );
              },
            ),
    );
  }
}
