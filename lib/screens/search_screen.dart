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
import '/screens/riddles_list_screen.dart';
import '/screens/riddle_detail_screen.dart';
import '/screens/circles_list_screen.dart';
import '/screens/circle_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> searchResults = [];
  List<SearchResult> allItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    List<SearchResult> items = [];

    // Load regular games
    final games = await DataService.getGames();
    for (var game in games) {
      items.add(SearchResult(
        title: game.name,
        subtitle: game.description,
        category: 'Game',
        categoryColor: Colors.blue,
        data: game,
        type: SearchResultType.game,
      ));
    }

    // Load word games
    final wordGames = await DataService.getWordGames();
    for (var game in wordGames) {
      items.add(SearchResult(
        title: game.name,
        subtitle: '${game.allWords.length} words - ${game.description}',
        category: game.name == 'פנטומימה' ? 'Pantomime' : 'Stickers',
        categoryColor: game.name == 'פנטומימה' ? Colors.red : Colors.orange,
        data: game,
        type: SearchResultType.wordGame,
      ));
    }

    // Load riddles
    final riddles = await DataService.getRiddles();
    for (var riddle in riddles) {
      for (var riddleText in riddle.riddles) {
        items.add(SearchResult(
          title: riddleText,
          subtitle: riddle.category,
          category: 'Riddle',
          categoryColor: Colors.purple,
          data: riddle,
          type: SearchResultType.riddle,
        ));
      }
    }

    // Load circles
    final circles = await DataService.getCircles();
    for (var circle in circles) {
      for (var item in circle.items) {
        items.add(SearchResult(
          title: item,
          subtitle: circle.category,
          category: 'Circle',
          categoryColor: Colors.green,
          data: circle,
          type: SearchResultType.circle,
        ));
      }
    }

    setState(() {
      allItems = items;
      searchResults = items;
      isLoading = false;
    });
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        searchResults = allItems;
      });
      return;
    }

    setState(() {
      searchResults = allItems.where((item) {
        final lowerQuery = query.toLowerCase();
        return item.title.toLowerCase().contains(lowerQuery) ||
               item.subtitle.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.indigo,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.shade50,
            child: TextField(
              controller: _searchController,
              onChanged: _performSearch,
              decoration: InputDecoration(
                hintText: 'Search games, riddles or circles...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : searchResults.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No results found',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: searchResults.length,
                        itemBuilder: (context, index) {
                          final result = searchResults[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: result.categoryColor.withOpacity(0.2),
                                child: Icon(
                                  _getIconForType(result.type),
                                  color: result.categoryColor,
                                ),
                              ),
                              title: Text(
                                result.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    result.subtitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: result.categoryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      result.category,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: result.categoryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => _navigateToResult(context, result),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(SearchResultType type) {
    switch (type) {
      case SearchResultType.game:
        return Icons.sports_esports;
      case SearchResultType.wordGame:
        return Icons.theater_comedy;
      case SearchResultType.riddle:
        return Icons.psychology;
      case SearchResultType.circle:
        return Icons.circle_outlined;
    }
  }

  void _navigateToResult(BuildContext context, SearchResult result) {
    switch (result.type) {
      case SearchResultType.game:
        final game = result.data as Game;
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => GameDetailScreen(game: game),
        ));
        break;
      case SearchResultType.wordGame:
        final game = result.data as WordGame;
        if (game.name == 'פנטומימה') {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => PantomimeGameScreen(wordGame: game),
          ));
        } else {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => StickersGameScreen(wordGame: game),
          ));
        }
        break;
      case SearchResultType.riddle:
        final riddle = result.data as Riddle;
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => RiddleDetailScreen(riddle: riddle),
        ));
        break;
      case SearchResultType.circle:
        final circle = result.data as Circle;
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => CircleDetailScreen(circle: circle),
        ));
        break;
    }
  }

}
