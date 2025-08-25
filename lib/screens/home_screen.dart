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
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'share') {
                final shareText = await DataService.generateShareText();
                if (shareText.trim().isNotEmpty) {
                  // Create temporary file
                  final directory = await getTemporaryDirectory();
                  final file = File('${directory.path}/user_additions.txt');
                  await file.writeAsString(shareText);

                  // Share file
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    subject: 'PKL Guide Additions',
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No additions to share')),
                  );
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: Row(
                  children: [
                    Icon(Icons.share, color: Colors.black54),
                    SizedBox(width: 8),
                    Text('Share Additions'),
                  ],
                ),
              ),
            ],
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
      case 0: // Games
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const GamesListScreen(),
        ));
        break;
      case 1: // Riddles
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const RiddlesListScreen(),
        ));
        break;
      case 2: // Circles
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => const CirclesListScreen(),
        ));
        break;
      case 3: // Segments
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Segments category is empty')),
        );
        break;
    }
  }
}
