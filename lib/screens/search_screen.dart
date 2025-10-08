// lib/screens/search_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../screens/item_detail_screen.dart';
import '../utils/category_helper.dart'; // ← הוספנו import

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

    final storageService = context.read<StorageService>();
    final allCategoryItems = storageService.getAllCategoryItems();

    final List<SearchResult> titleResults = [];
    final List<SearchResult> detailResults = [];
    final List<SearchResult> itemsResults = [];

    final queryLower = query.toLowerCase();

    for (var categoryItem in allCategoryItems) {
      bool foundInTitle = false;
      bool foundInDetail = false;

      // Search in title
      String titleToSearch = categoryItem.userTitle ?? categoryItem.originalTitle;
      if (titleToSearch.toLowerCase().contains(queryLower)) {
        titleResults.add(SearchResult(
          item: categoryItem,
          matchType: MatchType.title,
          matchedText: _getDisplayDetail(categoryItem),
          searchQuery: query,
          priority: 1,
        ));
        foundInTitle = true;
      }

      // Search in detail
      if (!foundInTitle) {
        String? detailToSearch = categoryItem.userDetail ?? categoryItem.originalDetail;
        if (detailToSearch != null && detailToSearch.toLowerCase().contains(queryLower)) {
          detailResults.add(SearchResult(
            item: categoryItem,
            matchType: MatchType.detail,
            matchedText: detailToSearch,
            searchQuery: query,
            priority: 2,
          ));
          foundInDetail = true;
        }
      }

      // Search in items
      if (!foundInTitle && !foundInDetail) {
        String? matchedItem = _searchInItems(categoryItem, queryLower);
        if (matchedItem != null) {
          itemsResults.add(SearchResult(
            item: categoryItem,
            matchType: MatchType.items,
            matchedText: matchedItem,
            searchQuery: query,
            priority: 3,
          ));
        }
      }
    }

    final List<SearchResult> combinedResults = [
      ...titleResults,
      ...detailResults,
      ...itemsResults,
    ];

    setState(() {
      _searchResults = combinedResults;
      _isSearching = false;
    });
  }

  String? _searchInItems(ItemModel categoryItem, String queryLower) {
    for (var element in categoryItem.strElements) {
      if (element.toLowerCase().contains(queryLower)) {
        return element;
      }
    }

    for (var element in categoryItem.originalElements) {
      if (element.text.toLowerCase().contains(queryLower)) {
        return element.text;
      }
    }

    return null;
  }

  String _getDisplayDetail(ItemModel categoryItem) {
    String? detail = categoryItem.userDetail ?? categoryItem.originalDetail;
    if (detail != null && detail.isNotEmpty) {
      return detail;
    }

    List<String> allItems = categoryItem.strElements;
    if (allItems.isNotEmpty) {
      return allItems.first;
    }

    return '';
  }

  Widget _buildHighlightedText(
      String text,
      String query, {
        int maxLines = 2,
        bool isTitle = false,
        double? fontSize,
      }) {
    final defaultStyle = TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
      fontWeight: isTitle ? FontWeight.bold : FontWeight.normal,
      fontSize: fontSize ?? (isTitle ? 18 : 14),
    );

    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return RichText(
        maxLines: maxLines,
        overflow: TextOverflow.ellipsis,
        text: TextSpan(
          text: text,
          style: defaultStyle,
        ),
      );
    }

    final matches = <TextSpan>[];
    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();

    int start = 0;
    int indexOf = lowerText.indexOf(lowerQuery, start);

    while (indexOf != -1) {
      if (indexOf > start) {
        matches.add(TextSpan(
          text: text.substring(start, indexOf),
          style: defaultStyle,
        ));
      }

      matches.add(TextSpan(
        text: text.substring(indexOf, indexOf + query.length),
        style: defaultStyle.copyWith(
          backgroundColor: Colors.yellow,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ));

      start = indexOf + query.length;
      indexOf = lowerText.indexOf(lowerQuery, start);
    }

    if (start < text.length) {
      matches.add(TextSpan(
        text: text.substring(start),
        style: defaultStyle,
      ));
    }

    return RichText(
      maxLines: maxLines,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: defaultStyle,
        children: matches,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                  child: _buildHighlightedText(
                    result.item.userTitle ?? result.item.originalTitle,
                    result.searchQuery,
                    maxLines: 1,
                    isTitle: true,
                  ),
                ),
                const SizedBox(width: 8),
                if (result.item.isUserChanged && !result.item.isUserCreated)
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
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHighlightedText(
                  result.matchedText,
                  result.searchQuery,
                  maxLines: 2,
                  fontSize: 15,
                ),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: CategoryHelper.getCategoryColor(result.item.category), // ← שינוי כאן
              child: Icon(
                CategoryHelper.getCategoryIcon(result.item.category), // ← שינוי כאן
                color: Colors.white,
              ),
            ),
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

// ← מחקנו את הפונקציות _getCategoryColor ו-_getCategoryIcon
}

enum MatchType { title, detail, items }

class SearchResult {
  final ItemModel item;
  final MatchType matchType;
  final String matchedText;
  final String searchQuery;
  final int priority;

  SearchResult({
    required this.item,
    required this.matchType,
    required this.matchedText,
    required this.searchQuery,
    required this.priority,
  });
}