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

    // נתוני חיפוש מסודרים לפי עדיפות
    final List<SearchResult> titleResults = [];
    final List<SearchResult> detailResults = [];
    final List<SearchResult> itemsResults = [];

    final queryLower = query.toLowerCase();

    for (var categoryItem in allCategoryItems) {
      bool foundInTitle = false;
      bool foundInDetail = false;

      // 1. חיפוש בכותרת (עדיפות ראשונה)
      String titleToSearch = categoryItem.userTitle ?? categoryItem.originalTitle;
      if (titleToSearch.toLowerCase().contains(queryLower)) {
        titleResults.add(SearchResult(
          item: categoryItem,
          matchType: MatchType.title,
          matchedText: _getDisplayDetail(categoryItem),
          priority: 1,
        ));
        foundInTitle = true;
      }

      // 2. חיפוש בתיאור (עדיפות שנייה) - רק אם לא נמצא בכותרת
      if (!foundInTitle) {
        String? detailToSearch = categoryItem.userDetail ?? categoryItem.originalDetail;
        if (detailToSearch != null && detailToSearch.toLowerCase().contains(queryLower)) {
          detailResults.add(SearchResult(
            item: categoryItem,
            matchType: MatchType.detail,
            matchedText: _truncateText(detailToSearch, 100),
            priority: 2,
          ));
          foundInDetail = true;
        }
      }

      // 3. חיפוש ברשימת פריטים (עדיפות שלישית) - רק אם לא נמצא בכותרת או תיאור
      if (!foundInTitle && !foundInDetail) {
        // חפש קודם ב-userAddedItems ואז ב-originalItems
        String? matchedItem = _searchInItems(categoryItem, queryLower);
        if (matchedItem != null) {
          itemsResults.add(SearchResult(
            item: categoryItem,
            matchType: MatchType.items,
            matchedText: matchedItem,
            priority: 3,
          ));
        }
      }
    }

    // איחוד התוצאות לפי סדר עדיפויות
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
    // חפש קודם ב-userAddedItems
    for (var item in categoryItem.userAddedElements) {
      if (item.toLowerCase().contains(queryLower)) {
        return item;
      }
    }

    // אם לא נמצא, חפש ב-originalItems
    for (var item in categoryItem.originalElements) {
      if (item.toLowerCase().contains(queryLower)) {
        return item;
      }
    }

    return null;
  }

  String _getDisplayDetail(ItemModel categoryItem) {
    // מחזיר תיאור או פריט ראשון להצגה
    String? detail = categoryItem.userDetail ?? categoryItem.originalDetail;
    if (detail != null && detail.isNotEmpty) {
      return _truncateText(detail, 100);
    }

    // אם אין תיאור, הראה פריט ראשון
    List<String> allItems = [...categoryItem.userAddedElements, ...categoryItem.originalElements];
    if (allItems.isNotEmpty) {
      return _truncateText(allItems.first, 100);
    }

    return '';
  }

  String _truncateText(String text, int maxLength) {
    return text.length > maxLength
        ? '${text.substring(0, maxLength)}...'
        : text;
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
                    result.item.userTitle ?? result.item.originalTitle,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                // Show modification indicators
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
                Text(
                  result.matchedText,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _getPriorityChip(result.matchType),
                    const SizedBox(width: 8),
                    Text(
                      result.item.category,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(result.item.category),
              child: Icon(
                _getCategoryIcon(result.item.category),
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

  Widget _getPriorityChip(MatchType matchType) {
    switch (matchType) {
      case MatchType.title:
        return const Chip(
          label: Text('כותרת'),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white, fontSize: 10),
        );
      case MatchType.detail:
        return const Chip(
          label: Text('תיאור'),
          backgroundColor: Colors.blue,
          labelStyle: TextStyle(color: Colors.white, fontSize: 10),
        );
      case MatchType.items:
        return const Chip(
          label: Text('פריטים'),
          backgroundColor: Colors.orange,
          labelStyle: TextStyle(color: Colors.white, fontSize: 10),
        );
    }
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

enum MatchType { title, detail, items }

class SearchResult {
  final ItemModel item;
  final MatchType matchType;
  final String matchedText;
  final int priority;

  SearchResult({
    required this.item,
    required this.matchType,
    required this.matchedText,
    required this.priority,
  });
}