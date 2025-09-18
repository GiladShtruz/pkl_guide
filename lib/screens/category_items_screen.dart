
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
  bool _isSelectionMode = false;
  late ListsService _listsService;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _loadItems();
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

    // Apply sorting
    final sortingMethod = appProvider.getSortingMethod(widget.category);
    _sortItems(sortingMethod);
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

  void _addToLists() async {
    final appProvider = context.read<AppProvider>();
    final selectedItems = appProvider.selectedItems.toList();

    if (selectedItems.isEmpty) return;

    // Show dialog for single or multiple items
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
  }  @override
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
          title: Text(widget.classification ?? widget.category.displayName),
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
                icon: const Icon(Icons.bookmark_border),
                onPressed: _toggleSelectionMode,
                tooltip: 'הוסף לרשימה',
              ),
              // lib/screens/category_screen.dart - CONTINUATION
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
        body: ListView(
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
        floatingActionButton: FloatingActionButton(
          onPressed: _isSelectionMode
              ? _addToLists
              : () => _addNewItem(),
          child: Icon(
            _isSelectionMode
                ? Icons.bookmark_add
                : Icons.add,
          ),
          backgroundColor: _isSelectionMode
              ? Colors.blue
              : Theme.of(context).primaryColor,
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
        builder: (context) => AddItemScreen(category: widget.category),
      ),
    ).then((_) {
      setState(() {
        _loadItems();
      });
    });
  }
}