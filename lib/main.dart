import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'data_service.dart';
import 'game_play.dart';
import 'madbekot.dart';
import 'pantome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // טעינת הנתונים מה-CSV
  await DataService.loadDataFromCSV();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'פקל למדריך',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Heebo',
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// מסך ראשי עם 4 קטגוריות
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final categories = [
      {'title': 'משחקים', 'icon': Icons.sports_esports, 'color': Colors.blue},
      {'title': 'חידות', 'icon': Icons.psychology, 'color': Colors.purple},
      {'title': 'מעגלים', 'icon': Icons.circle_outlined, 'color': Colors.green},
      {'title': 'קטעים', 'icon': Icons.article, 'color': Colors.orange},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('פקל למדריך'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            return CategoryCard(
              title: categories[index]['title'] as String,
              icon: categories[index]['icon'] as IconData,
              color: categories[index]['color'] as Color,
              onTap: () => _navigateToCategory(context, index),
            );
          },
        ),
      ),
    );
  }

  void _navigateToCategory(BuildContext context, int index) {
    switch (index) {
      case 0: // משחקים
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const GamesListScreen(),
        ));
        break;
      case 1: // חידות
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const RiddlesListScreen(),
        ));
        break;
      case 2: // מעגלים
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const CirclesListScreen(),
        ));
        break;
      case 3: // קטעים
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('קטגוריית קטעים ריקה כרגע')),
        );
        break;
    }
  }
}

// כרטיס קטגוריה
class CategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const CategoryCard({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// מסך רשימת משחקים
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('משחקים'),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // משחקים רגילים
          ...games.map((game) => Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue,
                child: const Icon(Icons.sports_esports, color: Colors.white),
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
          // משחקי מילים
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
              subtitle: Text('${game.words.length} מילים'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                if (game.name == 'פנטומימה') {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (context) => PantomimeGameScreen(wordGame: game),
                  ));
                } else if (game.name == 'מדבקות') {
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

// מסך פרטי משחק
class GameDetailScreen extends StatelessWidget {
  final Game game;

  const GameDetailScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(game.name),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category, color: Colors.blue),
                  const SizedBox(width: 8),
                  Text(
                    'סיווג: ${game.classification}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'תיאור המשחק:',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                game.description,
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// מסך פנטומימה מיוחד
class PantomimeScreen extends StatelessWidget {
  final Game game;

  const PantomimeScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('🎭 פנטומימה 🎭'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.theater_comedy,
                size: 120,
                color: Colors.red,
              ),
              const SizedBox(height: 32),
              const Text(
                'פנטומימה',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  game.description.isNotEmpty
                      ? game.description
                      : 'משחק פנטומימה קלאסי - הצג מילים ומושגים ללא דיבור!',
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// מסך רשימת חידות
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('חידות'),
        backgroundColor: Colors.purple,
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
              leading: const CircleAvatar(
                backgroundColor: Colors.purple,
                child: Icon(Icons.psychology, color: Colors.white),
              ),
              title: Text(
                riddle.category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${riddle.riddles.length} חידות'),
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

// מסך פרטי חידות
class RiddleDetailScreen extends StatelessWidget {
  final Riddle riddle;

  const RiddleDetailScreen({Key? key, required this.riddle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(riddle.category),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: riddle.riddles.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.purple.withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.purple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      riddle.riddles[index],
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// מסך רשימת מעגלים
class CirclesListScreen extends StatefulWidget {
  const CirclesListScreen({Key? key}) : super(key: key);

  @override
  State<CirclesListScreen> createState() => _CirclesListScreenState();
}

class _CirclesListScreenState extends State<CirclesListScreen> {
  List<Circle> circles = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCircles();
  }

  Future<void> _loadCircles() async {
    final loadedCircles = await DataService.getCircles();
    setState(() {
      circles = loadedCircles;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('מעגלים'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : circles.isEmpty
          ? const Center(
        child: Text(
          'אין מעגלים זמינים כרגע',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: circles.length,
        itemBuilder: (context, index) {
          final circle = circles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.circle_outlined, color: Colors.white),
              ),
              title: Text(
                circle.category,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('${circle.items.length} פריטים'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => CircleDetailScreen(circle: circle),
                ));
              },
            ),
          );
        },
      ),
    );
  }
}

// מסך פרטי מעגלים
class CircleDetailScreen extends StatelessWidget {
  final Circle circle;

  const CircleDetailScreen({Key? key, required this.circle}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(circle.category),
        backgroundColor: Colors.green,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: circle.items.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.green.withOpacity(0.2),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      circle.items[index],
                      style: const TextStyle(fontSize: 16, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// מסך חיפוש
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

    // טעינת משחקים רגילים
    final games = await DataService.getGames();
    for (var game in games) {
      items.add(SearchResult(
        title: game.name,
        subtitle: game.description,
        category: 'משחק',
        categoryColor: Colors.blue,
        data: game,
        type: SearchResultType.game,
      ));
    }

    // טעינת משחקי מילים
    final wordGames = await DataService.getWordGames();
    for (var game in wordGames) {
      items.add(SearchResult(
        title: game.name,
        subtitle: '${game.words.length} מילים - ${game.description}',
        category: game.name == 'פנטומימה' ? 'פנטומימה' : 'מדבקות',
        categoryColor: game.name == 'פנטומימה' ? Colors.red : Colors.orange,
        data: game,
        type: SearchResultType.wordGame,
      ));
    }

    // טעינת חידות
    final riddles = await DataService.getRiddles();
    for (var riddle in riddles) {
      for (var riddleText in riddle.riddles) {
        items.add(SearchResult(
          title: riddleText,
          subtitle: riddle.category,
          category: 'חידה',
          categoryColor: Colors.purple,
          data: riddle,
          type: SearchResultType.riddle,
        ));
      }
    }

    // טעינת מעגלים
    final circles = await DataService.getCircles();
    for (var circle in circles) {
      for (var item in circle.items) {
        items.add(SearchResult(
          title: item,
          subtitle: circle.category,
          category: 'מעגל',
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
        title: const Text('חיפוש'),
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
                hintText: 'חפש משחקים, חידות או מעגלים...',
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
                    'לא נמצאו תוצאות',
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
        } else if (game.name == 'מדבקות') {
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// מודל לתוצאות חיפוש
class SearchResult {
  final String title;
  final String subtitle;
  final String category;
  final Color categoryColor;
  final dynamic data;
  final SearchResultType type;

  SearchResult({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.categoryColor,
    required this.data,
    required this.type,
  });
}

enum SearchResultType { game, wordGame, riddle, circle }