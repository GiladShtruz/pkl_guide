import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_model.dart';
import '../models/item_model.dart';
import '../services/lists_service.dart';
import '../services/storage_service.dart';
import '../screens/item_detail_screen.dart';
import '../screens/list_edit_screen.dart';

class ListDetailScreen extends StatefulWidget {
  final ListModel list;

  const ListDetailScreen({
    super.key,
    required this.list,
  });

  @override
  State<ListDetailScreen> createState() => _ListDetailScreenState();
}

class _ListDetailScreenState extends State<ListDetailScreen> {
  bool _isEditMode = false;
  bool _isReorderMode = false;
  final Set<String> _selectedItems = {};
  late ListsService _listsService;
  late List<ItemModel> _items;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _loadItems();
  }

  void _loadItems() {
    _items = _listsService.getListItems(widget.list.id);
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedItems.clear();
      }
    });
  }

  void _toggleReorderMode() {
    setState(() {
      _isReorderMode = !_isReorderMode;
    });
  }

  void _deleteSelectedItems() async {
    if (_selectedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הסרה מהרשימה'),
        content: Text('האם להסיר ${_selectedItems.length} פריטים מהרשימה?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('הסר', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      for (final itemId in _selectedItems) {
        await _listsService.removeItemFromList(widget.list.id, itemId);
      }
      setState(() {
        _selectedItems.clear();
        _isEditMode = false;
        _loadItems();
      });
    }
  }

  void _openListEditScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListEditScreen(list: widget.list),
      ),
    ).then((_) {
      setState(() {}); // Refresh to show updated name/description
    });
  }

  void _deleteList() async {
    if (widget.list.isDefault) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת רשימה'),
        content: const Text('האם למחוק את הרשימה לצמיתות?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('מחק', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _listsService.deleteList(widget.list.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isEditMode) {
          _toggleEditMode();
          return false;
        }
        if (_isReorderMode) {
          _toggleReorderMode();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: Text(widget.list.name),
          centerTitle: true,
          actions: [
            if (!widget.list.isDefault)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteList,
              ),
            if (_items.isNotEmpty && !_isReorderMode)
              IconButton(
                icon: Icon(_isEditMode ? Icons.close : Icons.checklist),
                onPressed: _toggleEditMode,
              ),
            if (_items.isNotEmpty && !_isEditMode)
              IconButton(
                icon: Icon(_isReorderMode ? Icons.check : Icons.swap_vert),
                onPressed: _toggleReorderMode,
              ),
          ],
        ),
        body: _items.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'הרשימה ריקה',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        )
            : Column(
          children: [
            // List description card - clickable to edit
            if (!widget.list.isDefault &&
                (widget.list.description != null && widget.list.description!.isNotEmpty))
              GestureDetector(
                onTap: _openListEditScreen,
                child: Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'תיאור הרשימה',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.edit,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.list.description!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Items list
            Expanded(
              child: _isReorderMode
                  ? ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                onReorder: (oldIndex, newIndex) async {
                  await _listsService.reorderListItems(
                    widget.list.id,
                    oldIndex,
                    newIndex,
                  );
                  setState(() {
                    _loadItems();
                  });
                },
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Card(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(item.name),
                      subtitle: item.description != null
                          ? Text(
                        item.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          : null,
                      trailing: CircleAvatar(
                        backgroundColor: _getCategoryColor(item.category),
                        child: Icon(
                          _getCategoryIcon(item.category),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  );
                },
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final isSelected = _selectedItems.contains(item.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: isSelected
                          ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                          : BorderSide.none,
                    ),
                    child: ListTile(
                      leading: _isEditMode
                          ? Checkbox(
                        value: isSelected,
                        onChanged: (_) {
                          setState(() {
                            if (isSelected) {
                              _selectedItems.remove(item.id);
                            } else {
                              _selectedItems.add(item.id);
                            }
                          });
                        },
                      )
                          : CircleAvatar(
                        backgroundColor: _getCategoryColor(item.category),
                        child: Icon(
                          _getCategoryIcon(item.category),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(item.name),
                      subtitle: item.description != null
                          ? Text(
                        item.description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: _isEditMode
                          ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedItems.remove(item.id);
                          } else {
                            _selectedItems.add(item.id);
                          }
                        });
                      }
                          : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(item: item),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        floatingActionButton: _isEditMode
            ? FloatingActionButton(
          onPressed: _selectedItems.isNotEmpty ? _deleteSelectedItems : null,
          backgroundColor: _selectedItems.isNotEmpty ? Colors.red : Colors.grey,
          child: const Icon(Icons.delete),
        )
            : !widget.list.isDefault
            ? FloatingActionButton(
          onPressed: _openListEditScreen,
          child: const Icon(Icons.edit),
        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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