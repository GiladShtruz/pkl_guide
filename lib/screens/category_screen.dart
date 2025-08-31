import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item_model.dart';
import '../models/sorting_method.dart';
import '../services/storage_service.dart';
import '../providers/app_provider.dart';
import '../widgets/item_card.dart';
import '../screens/item_detail_screen.dart';
import '../screens/add_item_screen.dart';

class CategoryScreen extends StatefulWidget {
  final CategoryType category;

  const CategoryScreen({
    super.key,
    required this.category,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late List<ItemModel> _items;
  late List<ItemModel> _favoriteItems;
  late List<ItemModel> _regularItems;
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    final storageService = context.read<StorageService>();
    final appProvider = context.read<AppProvider>();

    // Get all items for this category
    _items = storageService.getAllItems(category: widget.category);

    // Separate favorites and regular items
    _favoriteItems = _items.where((item) =>
        storageService.isFavorite(item.id)).toList();
    _regularItems = _items.where((item) =>
        !storageService.isFavorite(item.id)).toList();

    // Apply sorting
    final sortingMethod = appProvider.getSortingMethod(widget.category);
    _sortItems(sortingMethod);

    // Update access count
    for (var item in _items) {
      storageService.updateItemAccess(item.id);
    }
  }

  void _sortItems(SortingMethod method) {
    switch (method) {
      case SortingMethod.mostUsed:
        _favoriteItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));
        _regularItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));
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
        break;
      case SortingMethod.original:
        // Keep original order
        break;
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        context.read<AppProvider>().clearSelection();
      }
    });
  }

  void _toggleFavorites() async {
    final appProvider = context.read<AppProvider>();
    final storageService = context.read<StorageService>();

    for (var itemId in appProvider.selectedItems) {
      await storageService.toggleFavorite(itemId);
    }

    appProvider.clearSelection();
    setState(() {
      _isSelectionMode = false;
      _loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();

    return WillPopScope(
      onWillPop: () async {
        if (_isSelectionMode) {
          _toggleSelectionMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.category.displayName),
          centerTitle: true,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                )
              : null,
          actions: [
            if (!_isSelectionMode) ...[
              IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: _toggleSelectionMode,
                tooltip: 'הוסף למועדפים',
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
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _loadItems();
            });
          },
          child: ListView(
            children: [
              if (_favoriteItems.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'מועדפים',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[700],
                    ),
                  ),
                ),
                ..._favoriteItems.map((item) => ItemCard(
                  item: item,
                  showCheckbox: _isSelectionMode,
                  onTap: () => _openItemDetail(item),
                  onLongPress: _toggleSelectionMode,
                )),
              ],
              if (_regularItems.isNotEmpty) ...[
                if (_favoriteItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'כל הפריטים',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ..._regularItems.map((item) => ItemCard(
                  item: item,
                  showCheckbox: _isSelectionMode,
                  onTap: () => _openItemDetail(item),
                  onLongPress: _toggleSelectionMode,
                )),
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _isSelectionMode
              ? _toggleFavorites
              : () => _addNewItem(),
          child: Icon(
            _isSelectionMode
                ? Icons.favorite
                : Icons.add,
          ),
          backgroundColor: _isSelectionMode
              ? Colors.red
              : Theme.of(context).primaryColor,
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
      setState(() {
        _loadItems();
      });
    });
  }

  void _addNewItem() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddItemScreen(category: widget.category),
      ),
    ).then((_) {
      setState(() {
        _loadItems();
      });
    });
  }
}



