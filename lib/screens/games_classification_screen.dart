import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../screens/category_screen.dart';

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
      print(game.originalTitle);
      print(game.classification);
      final classification = game.classification ?? 'אחר';
      _classifications.add(classification);

      _categorizedGames.putIfAbsent(classification, () => []).add(game);
    }
    print(allGames);
    print(_classifications);

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
      backgroundColor: Colors.grey[50],
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

          return Card(
            elevation: isAllGames ? 4 : 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(
                      category: CategoryType.games,
                      classification: isAllGames ? null : classification,
                    ),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isAllGames
                        ? [Colors.purple[600]!, Colors.purple[800]!]
                        : [Colors.purple[400]!, Colors.purple[600]!],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isAllGames ? Icons.sports_esports : Icons.category,
                      size: isAllGames ? 40 : 36,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAllGames ? 'כל המשחקים' : classification,
                      style: TextStyle(
                        fontSize: isAllGames ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${games.length} משחקים',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}