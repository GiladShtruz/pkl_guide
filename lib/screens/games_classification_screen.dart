import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../screens/category_items_screen.dart';
import '../widgets/game_classification_card.dart';  // Import the new widget

class GamesClassificationScreen extends StatefulWidget {
  const GamesClassificationScreen({super.key});

  @override
  State<GamesClassificationScreen> createState() => _GamesClassificationScreenState();
}

class _GamesClassificationScreenState extends State<GamesClassificationScreen> {
  Map<String, List<ItemModel>> _categorizedGames = {};
  Set<String> _classifications = {};

  @override
  void initState() {
    super.initState();
    _loadGames();
  }

  void _loadGames() {
    final storageService = context.read<StorageService>();
    final allGames = storageService.getAllCategoryItems(category: CategoryType.games);

    _categorizedGames = {'all': allGames};
    _classifications = {'all'};

    // Group games by classification
    for (var game in allGames) {
      // final classification = game.classification ?? 'אחר';

      final classification;
      if (game.classification == null){
        classification = 'כללי';
      }
      else if(game.classification == ""){
        classification = 'כללי';
      }
      else{
        classification = game.classification;
      }


      _classifications.add(classification);
      _categorizedGames.putIfAbsent(classification, () => []).add(game);
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final sortedClassifications = _classifications.toList()
      ..sort((a, b) {
        if (a == 'all') return -1;
        if (b == 'all') return 1;
        if (a == 'אחר') return 1;
        if (b == 'אחר') return -1;
        return a.compareTo(b);
      });

    return Scaffold(
      appBar: AppBar(
        title: const Text('משחקים'),
        centerTitle: true,
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: sortedClassifications.length,
        itemBuilder: (context, index) {
          final classification = sortedClassifications[index];
          final games = _categorizedGames[classification] ?? [];
          final isAllGames = classification == 'all';

          return GameClassificationCard(
            title: isAllGames ? 'כל המשחקים' : classification,
            itemCount: games.length,
            icon: isAllGames ? Icons.sports_esports : Icons.category,
            isHighlighted: isAllGames,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CategoryItemsScreen(
                    category: CategoryType.games,
                    classification: isAllGames ? null : classification,
                  ),
                ),
              ).then((_) {
                // Reload games after returning
                _loadGames();
              });
            },
          );
        },
      ),
    );
  }
}