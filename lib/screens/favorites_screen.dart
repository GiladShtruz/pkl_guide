import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../widgets/item_card.dart';
import '../screens/item_detail_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  Map<String, List<ItemModel>> _favoritesByCategory = {};

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  void _loadFavorites() {
    final storageService = context.read<StorageService>();
    final allItems = storageService.getAllItems();

    _favoritesByCategory = {};

    for (var item in allItems) {
      if (storageService.isFavorite(item.id)) {
        _favoritesByCategory.putIfAbsent(item.category, () => []).add(item);
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('מועדפים'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: _favoritesByCategory.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'אין פריטים מועדפים',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'לחץ לחיצה ארוכה על פריט להוספה למועדפים',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () async {
                _loadFavorites();
              },
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 16),
                itemCount: _favoritesByCategory.length,
                itemBuilder: (context, index) {
                  final category = _favoritesByCategory.keys.elementAt(index);
                  final items = _favoritesByCategory[category]!;
                  final categoryType = CategoryType.values.firstWhere(
                    (c) => c.name == category,
                  );

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              categoryType.icon,
                              color: _getCategoryColor(category),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              categoryType.displayName,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getCategoryColor(category),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...items.map((item) => ItemCard(
                        item: item,
                        onTap: () => _openItemDetail(item),
                        onLongPress: () => _removeFavorite(item),
                      )),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),
            ),
    );
  }

  void _openItemDetail(ItemModel item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ItemDetailScreen(item: item),
      ),
    ).then((_) {
      _loadFavorites();
    });
  }

  void _removeFavorite(ItemModel item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הסרה ממועדפים'),
        content: Text('האם להסיר את "${item.name}" מהמועדפים?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              final storageService = context.read<StorageService>();
              await storageService.toggleFavorite(item.id);
              Navigator.pop(context);
              _loadFavorites();
            },
            child: const Text('הסר'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String categoryName) {
    switch (categoryName) {
      case 'games':
        return Colors.purple;
      case 'activities':
        return Colors.blue;
      case 'riddles':
        return Colors.orange;
      case 'texts':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}

