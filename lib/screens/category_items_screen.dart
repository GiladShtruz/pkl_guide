import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item_model.dart';
import '../models/sorting_method.dart';
import '../services/storage_service.dart';
import '../services/lists_service.dart';
import '../providers/app_provider.dart';
import '../widgets/item_card.dart';
import '../screens/item_detail_screen.dart';
import '../screens/add_item_screen.dart';
import '../dialogs/add_to_lists_dialog.dart';

class CategoryItemsScreen extends StatefulWidget {
  final CategoryType category;
  final String? classification;

  const CategoryItemsScreen({
    super.key,
    required this.category,
    this.classification,
  });

  @override
  State<CategoryItemsScreen> createState() => _CategoryItemsScreenState();
}

class _CategoryItemsScreenState extends State<CategoryItemsScreen> {
  late List<ItemModel> _items;
  late List<ItemModel> _favoriteItems;
  late List<ItemModel> _regularItems;
  late List<ItemModel> _filteredFavoriteItems;
  late List<ItemModel> _filteredRegularItems;
  bool _isSelectionMode = false;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  late ListsService _listsService;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _loadItems();
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadItems() {
    final storageService = context.read<StorageService>();
    final appProvider = context.read<AppProvider>();

    // Get all items for this category
    _items = storageService.getAllCategoryItems(category: widget.category);

    // Filter by classification if provided
    if (widget.classification != null) {
      _items = _items.where((item) =>
      item.classification == widget.classification
      ).toList();
    }

    // Separate favorites and regular items using ListsService
    _favoriteItems = _items.where((item) =>
        _listsService.isFavorite(item.id)).toList();
    _regularItems = _items.where((item) =>
    !_listsService.isFavorite(item.id)).toList();
    _filteredFavoriteItems = List.from(_favoriteItems);
    _filteredRegularItems = List.from(_regularItems);
    // Apply sorting
    final sortingMethod = appProvider.getSortingMethod(widget.category);
    _sortItems(sortingMethod);
  }

  void _sortItems(SortingMethod method) {
    switch (method) {
      case SortingMethod.mostUsed:
        _favoriteItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));
        _regularItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));
        _filteredFavoriteItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));
        _filteredRegularItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));
        break;
      case SortingMethod.lastAccessed:
        _favoriteItems.sort((a, b) {
          if (a.lastAccessed == null) return 1;
          if (b.lastAccessed == null) return -1;
          return b.lastAccessed!.compareTo(a.lastAccessed!);
        });
        _regularItems.sort((a, b) {
          if (a.lastAccessed == null) return 1;
          if (b.lastAccessed == null) return -1;
          return b.lastAccessed!.compareTo(a.lastAccessed!);
        });
        _filteredFavoriteItems.sort((a, b) {
          if (a.lastAccessed == null) return 1;
          if (b.lastAccessed == null) return -1;
          return b.lastAccessed!.compareTo(a.lastAccessed!);
        });
        _filteredRegularItems.sort((a, b) {
          if (a.lastAccessed == null) return 1;
          if (b.lastAccessed == null) return -1;
          return b.lastAccessed!.compareTo(a.lastAccessed!);
        });
        break;
      case SortingMethod.original:
      // Keep original order
        break;
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredFavoriteItems = List.from(_favoriteItems);
        _filteredRegularItems = List.from(_regularItems);
      } else {
        _filteredFavoriteItems = _favoriteItems.where((item) =>
        item.name.toLowerCase().contains(query) ||
            (item.detail?.toLowerCase().contains(query) ?? false) ||
            (item.userDetail?.toLowerCase().contains(query) ?? false)
        ).toList();

        _filteredRegularItems = _regularItems.where((item) =>
        item.name.toLowerCase().contains(query) ||
            (item.detail?.toLowerCase().contains(query) ?? false) ||
            (item.userDetail?.toLowerCase().contains(query) ?? false)
        ).toList();
      }
    });
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _filterItems();
      }
    });
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        context.read<AppProvider>().clearSelection();
      }
      // יציאה ממצב חיפוש כשנכנסים למצב בחירה
      if (_isSelectionMode && _isSearching) {
        _isSearching = false;
        _searchController.clear();
        _filterItems();
      }
    });
  }

  void _addToLists() async {
    final appProvider = context.read<AppProvider>();
    final selectedItems = appProvider.selectedItems.toList();

    if (selectedItems.isEmpty) return;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddToListsDialog(
        itemIds: selectedItems,
        itemName: selectedItems.length == 1
            ? _items.firstWhere((i) => i.id == selectedItems.first).name
            : null,
      ),
    );

    if (result == true) {
      appProvider.clearSelection();
      setState(() {
        _isSelectionMode = false;
        _loadItems();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            selectedItems.length == 1
                ? 'הפריט עודכן ברשימות'
                : '${selectedItems.length} פריטים עודכנו ברשימות',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    // חישוב אינדקסים ומספר פריטים
    final hasFavorites = _filteredFavoriteItems.isNotEmpty;
    final hasRegular = _filteredRegularItems.isNotEmpty;
    final showRegularTitle = hasFavorites && hasRegular;

    // חישוב מספר הפריטים הכולל כולל כותרות
    int totalItems = 0;
    if (hasFavorites) {
      totalItems += 1; // כותרת מועדפים
      totalItems += _filteredFavoriteItems.length;
    }
    if (showRegularTitle) {
      totalItems += 1; // כותרת כל הפריטים
    }
    if (hasRegular) {
      totalItems += _filteredRegularItems.length;
    }

    return PopScope(  // במקום WillPopScope
      canPop: !_isSearching && !_isSelectionMode,  // מאפשר swipe רק כשלא במצבים מיוחדים
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          if (_isSearching) {
            _toggleSearch();
          } else if (_isSelectionMode) {
            _toggleSelectionMode();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSearching
              ? TextField(
            controller: _searchController,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'חפש פריט...',
              border: InputBorder.none,

            ),

          )
              : Text(widget.classification ?? widget.category.displayName),
          centerTitle: !_isSearching,
          leading: _isSelectionMode
              ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleSelectionMode,
          )
              : _isSearching
              ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: _toggleSearch,
          )
              : null,
          actions: [
            if (!_isSelectionMode) ...[
              if (!_isSearching)
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _toggleSearch,
                  tooltip: 'חיפוש',
                ),
              IconButton(
                icon: const Icon(Icons.bookmark_border),
                onPressed: _toggleSelectionMode,
                tooltip: 'הוסף לרשימה',
              ),
              PopupMenuButton<SortingMethod>(
                icon: const Icon(Icons.sort),
                onSelected: (method) {
                  appProvider.setSortingMethod(widget.category, method);
                  setState(() {
                    _sortItems(method);
                  });
                },
                itemBuilder: (context) => SortingMethod.values
                    .map((method) => PopupMenuItem(
                  value: method,
                  child: Row(
                    children: [
                      Radio<SortingMethod>(
                        value: method,
                        groupValue: appProvider.getSortingMethod(widget.category),
                        onChanged: null,
                      ),
                      Text(method.displayName),
                    ],
                  ),
                ))
                    .toList(),
              ),
            ],
          ],
        ),
        body: totalItems == 0
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _isSearching ? Icons.search_off : Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              Text(
                _isSearching
                    ? 'לא נמצאו תוצאות עבור "${_searchController.text}"'
                    : 'אין פריטים בקטגוריה זו',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          physics: const BouncingScrollPhysics(),
          itemCount: totalItems + 1, // +1 for bottom padding
          itemBuilder: (context, index) {
            // Bottom padding
            if (index == totalItems) {
              return const SizedBox(height: 80);
            }

            int runningIndex = 0;

            // מועדפים
            if (hasFavorites) {
              // כותרת מועדפים
              if (index == runningIndex) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'מועדפים',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                );
              }
              runningIndex++;

              // פריטים מועדפים
              if (index < runningIndex + _filteredFavoriteItems.length) {
                final itemIndex = index - runningIndex;
                if (itemIndex >= 0 && itemIndex < _filteredFavoriteItems.length) {
                  final item = _filteredFavoriteItems[itemIndex];
                  return ItemCard(
                    item: item,
                    showCheckbox: _isSelectionMode,
                    onTap: () => _openItemDetail(item),
                    onLongPress: _toggleSelectionMode,
                  );
                }
              }
              runningIndex += _filteredFavoriteItems.length;
            }

            // כותרת כל הפריטים (רק אם יש גם מועדפים וגם רגילים)
            if (showRegularTitle) {
              if (index == runningIndex) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'כל הפריטים',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                );
              }
              runningIndex++;
            }

            // פריטים רגילים
            if (hasRegular) {
              final itemIndex = index - runningIndex;
              if (itemIndex >= 0 && itemIndex < _filteredRegularItems.length) {
                final item = _filteredRegularItems[itemIndex];
                return ItemCard(
                  item: item,
                  showCheckbox: _isSelectionMode,
                  onTap: () => _openItemDetail(item),
                  onLongPress: _toggleSelectionMode,
                );
              }
            }

            // Fallback - should not reach here
            return const SizedBox.shrink();
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isSelectionMode
              ? _addToLists
              : () => _addNewItem(),
          child: Icon(
            _isSelectionMode
                ? Icons.bookmark_add
                : Icons.add,
          ),
          backgroundColor: _isSelectionMode ? Colors.blue : widget.category.categoryColor,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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
      setState(() {
        _loadItems();
      });
    });
  }

  void _addNewItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(category: widget.category, classification: widget.classification,),
      ),
    ).then((_) {
      setState(() {
        _loadItems();
      });
    });
  }
}