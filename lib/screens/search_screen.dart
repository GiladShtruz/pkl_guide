import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../models/category.dart';
import '../services/storage_service.dart';
import '../screens/item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final storageService = context.read<StorageService>();
    final allItems = storageService.getAllItems();
    final results = <SearchResult>[];

    for (var item in allItems) {
      // Check if query matches title
      if (item.name.toLowerCase().contains(query.toLowerCase())) {
        results.add(SearchResult(
          item: item,
          matchType: MatchType.title,
          matchedText: item.description?.isNotEmpty == true
              ? item.description!.substring(0, item.description!.length.clamp(0, 100))
              : item.content.isNotEmpty
                  ? item.content.first.substring(0, item.content.first.length.clamp(0, 100))
                  : '',
        ));
      } else {
        // Check if query matches content
        for (var content in item.content) {
          if (content.toLowerCase().contains(query.toLowerCase())) {
            results.add(SearchResult(
              item: item,
              matchType: MatchType.content,
              matchedText: content,
            ));
            break;
          }
        }

        // Check if query matches description
        if (item.description?.toLowerCase().contains(query.toLowerCase()) == true) {
          results.add(SearchResult(
            item: item,
            matchType: MatchType.description,
            matchedText: item.description!,
          ));
        }
      }
    }

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'חיפוש משחקים, חידות, פעילויות...',
            border: InputBorder.none,
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch('');
                    },
                  )
                : null,
          ),
          onChanged: _performSearch,
        ),
        automaticallyImplyLeading: false,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isSearching) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_searchController.text.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'הזן טקסט לחיפוש',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'לא נמצאו תוצאות',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final result = _searchResults[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text(
              result.item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              result.matchedText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(result.item.category),
              child: Icon(
                _getCategoryIcon(result.item.category),
                color: Colors.white,
              ),
            ),
            trailing: result.matchType == MatchType.title
                ? const Chip(
                    label: Text('כותרת'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white, fontSize: 12),
                  )
                : null,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ItemDetailScreen(item: result.item),
                ),
              );
            },
          ),
        );
      },
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

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
      case 'games':
        return Icons.sports_esports;
      case 'activities':
        return Icons.assignment;
      case 'riddles':
        return Icons.quiz;
      case 'texts':
        return Icons.description;
      default:
        return Icons.folder;
    }
  }
}

enum MatchType { title, content, description }

class SearchResult {
  final ItemModel item;
  final MatchType matchType;
  final String matchedText;

  SearchResult({
    required this.item,
    required this.matchType,
    required this.matchedText,
  });
}

