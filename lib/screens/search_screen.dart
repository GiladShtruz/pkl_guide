// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../screens/item_detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => SearchScreenState();
}

class SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  bool _isSearching = false;

  // Methods called from parent
  void focusSearch() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  void unfocusSearch() {
    _searchFocusNode.unfocus();
  }

  @override
  void initState() {
    super.initState();
    // Auto-focus on search field when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _searchFocusNode.requestFocus();
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
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
    final allCategoryItems = storageService.getAllCategoryItems();
    final results = <SearchResult>[];

    for (var categoryItem in allCategoryItems) {
      // Search in name (use current name which includes user modifications)
      if (categoryItem.name.toLowerCase().contains(query.toLowerCase())) {
        results.add(SearchResult(
          item: categoryItem,
          matchType: MatchType.title,
          matchedText: categoryItem.detail?.isNotEmpty == true
              ? categoryItem.detail!.substring(0, categoryItem.detail!.length.clamp(0, 100))
              : categoryItem.items.isNotEmpty
              ? categoryItem.items.first.substring(0, categoryItem.items.first.length.clamp(0, 100))
              : '',
        ));
      } else {
        // Search in items (includes both original and user-added)
        for (var item in categoryItem.items) {
          if (item.toLowerCase().contains(query.toLowerCase())) {
            results.add(SearchResult(
              item: categoryItem,
              matchType: MatchType.items,
              matchedText: item,
            ));
            break;
          }
        }

        // Search in detail
        if (categoryItem.detail?.toLowerCase().contains(query.toLowerCase()) == true) {
          results.add(SearchResult(
            item: categoryItem,
            matchType: MatchType.detail,
            matchedText: categoryItem.detail!,
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
          focusNode: _searchFocusNode,
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
                _searchFocusNode.requestFocus();
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
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    result.item.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Show modification indicators
                if (result.item.hasUserModifications && !result.item.isUserCreated)
                  const Icon(Icons.edit, size: 14, color: Colors.orange),
                if (result.item.isUserCreated)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'נוסף',
                      style: TextStyle(fontSize: 10, color: Colors.blue),
                    ),
                  ),
              ],
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

enum MatchType { title, items, detail }

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