import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_model.dart';
import '../services/lists_service.dart';
import '../screens/list_detail_screen.dart';
import '../dialogs/create_list_dialog.dart';

enum ListSortMethod {
  original('סדר מקורי'),
  lastModified('עריכה אחרונה');

  final String displayName;
  const ListSortMethod(this.displayName);
}

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  bool _isEditMode = false;
  final Set<int> _selectedLists = {};
  late ListsService _listsService;
  ListSortMethod _sortMethod = ListSortMethod.original;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
  }

  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedLists.clear();
      }
    });
  }

  void _createNewList() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const CreateListDialog(),
    );

    if (result != null && result['name'] != null) {
      await _listsService.createList(
        result['name']!,
        detail: result['detail'],
      );
      setState(() {});
    }
  }

  void _deleteSelectedLists() async {
    if (_selectedLists.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת רשימות'),
        content: Text('האם למחוק ${_selectedLists.length} רשימות?'),
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
      await _listsService.deleteLists(_selectedLists.toList());
      setState(() {
        _selectedLists.clear();
        _isEditMode = false;
      });
    }
  }

  List<ListModel> _getSortedLists() {
    var lists = _listsService.getAllLists();

    // Separate favorites from other lists
    final favoritesList = lists.firstWhere((l) => l.isDefault);
    final otherLists = lists.where((l) => !l.isDefault).toList();

    // Sort non-favorite lists
    switch (_sortMethod) {
      case ListSortMethod.lastModified:
        otherLists.sort((a, b) {
          final aDate = a.lastModified ?? a.createdAt;
          final bDate = b.lastModified ?? b.createdAt;
          return bDate.compareTo(aDate);
        });
        break;
      case ListSortMethod.original:
      // Keep original order (by creation date)
        otherLists.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
    }

    // Favorites always first
    return [favoritesList, ...otherLists];
  }

  @override
  Widget build(BuildContext context) {
    final lists = _getSortedLists();

    return PopScope(
      canPop: true, // Allows popping by default
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // If already popped, do nothing
        if (_isEditMode) {
          _toggleEditMode();
          return; // Prevent popping
        }
        // Allow default pop behavior when not in edit mode
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('רשימות',
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            // Sort button
            PopupMenuButton<ListSortMethod>(
              icon: const Icon(Icons.sort),
              onSelected: (method) {
                setState(() {
                  _sortMethod = method;
                });
              },
              itemBuilder: (context) => ListSortMethod.values
                  .map((method) => PopupMenuItem(
                value: method,
                child: Row(
                  children: [
                    Radio<ListSortMethod>(
                      value: method,
                      groupValue: _sortMethod,
                      onChanged: null,
                    ),
                    Text(method.displayName),
                  ],
                ),
              ))
                  .toList(),
            ),
            if (lists.length > 1) // Only show if there are custom lists
              IconButton(
                icon: Icon(_isEditMode ? Icons.close : Icons.edit),
                onPressed: _toggleEditMode,
              ),
          ],
        ),
        body: lists.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.bookmark_border,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'אין רשימות',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'לחץ על + כדי ליצור רשימה חדשה',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: lists.length,
          itemBuilder: (context, index) {
            final list = lists[index];
            final itemCount = list.categoryItemIds.length;
            final isSelected = _selectedLists.contains(list.id);
            final canSelect = !list.isDefault; // Can't select favorites

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              elevation: list.isDefault ? 4 : 2,
              color: (list.isDefault &&  Theme.of(context).brightness == Brightness.light) ? Colors.red[50] : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? BorderSide(color: Theme.of(context).primaryColor, width: 2)
                    : BorderSide.none,
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onLongPress: canSelect && !_isEditMode
                    ? () {
                  setState(() {
                    _isEditMode = true;
                    _selectedLists.add(list.id);
                  });
                }
                    : null,
                onTap: () {
                  if (_isEditMode) {
                    if (canSelect) {
                      setState(() {
                        if (_selectedLists.contains(list.id)) {
                          _selectedLists.remove(list.id);
                        } else {
                          _selectedLists.add(list.id);
                        }
                      });
                    }
                    // Do nothing if it's favorites in edit mode
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ListDetailScreen(list: list),
                      ),
                    ).then((_) => setState(() {}));
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      if (_isEditMode && canSelect)
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) {
                            setState(() {
                              if (_selectedLists.contains(list.id)) {
                                _selectedLists.remove(list.id);
                              } else {
                                _selectedLists.add(list.id);
                              }
                            });
                          },
                        ),
                      Icon(
                        list.isDefault ? Icons.favorite : Icons.bookmark,
                        color: list.isDefault ? Colors.red : Colors.blue,
                        size: 32,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              list.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface
                              ),
                            ),
                            // Don't show description for favorites list
                            if (!list.isDefault && list.detail != null && list.detail!.isNotEmpty)
                              Text(
                                list.detail!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '$itemCount',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (!_isEditMode)
                            const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        floatingActionButton: _isEditMode
            ? FloatingActionButton(
          onPressed: _selectedLists.isNotEmpty ? _deleteSelectedLists : null,
          backgroundColor: _selectedLists.isNotEmpty ? Colors.red : Colors.grey,
          child: const Icon(Icons.delete),
        )
            : FloatingActionButton(
          onPressed: _createNewList,
          child: const Icon(Icons.add),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }
}