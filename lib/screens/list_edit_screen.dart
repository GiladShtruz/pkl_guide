import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_model.dart';
import '../models/item_model.dart';
import '../services/lists_service.dart';
import '../services/storage_service.dart';

class ListEditScreen extends StatefulWidget {
  final ListModel list;

  const ListEditScreen({
    super.key,
    required this.list,
  });

  @override
  State<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends State<ListEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late ListsService _listsService;
  late StorageService _storageService;

  bool _isEditMode = false;
  bool _hasChanges = false;

  final Set<int> _selectedIndices = {};
  late List<ItemModel> _currentItems;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _storageService = context.read<StorageService>();
    _nameController = TextEditingController(text: widget.list.name);
    _descriptionController = TextEditingController(text: widget.list.detail ?? '');
    _loadItems();

    // Add listeners to auto-save on text changes
    _nameController.addListener(_onNameChanged);
    _descriptionController.addListener(_onDescriptionChanged);
  }

  void _loadItems() {
    _currentItems = List.from(_listsService.getListItems(widget.list.id));
  }

  void _onNameChanged() async {
    if (_nameController.text.isNotEmpty &&
        !widget.list.isDefault &&
        _nameController.text != widget.list.name) {
      await _listsService.updateListName(widget.list.id, _nameController.text);
      widget.list.name = _nameController.text;
      setState(() {
        _hasChanges = true;
      });
    }
  }

  void _onDescriptionChanged() async {
    final newDescription = _descriptionController.text.isNotEmpty
        ? _descriptionController.text
        : null;

    if (newDescription != widget.list.detail) {
      await _listsService.updateListDescription(widget.list.id, newDescription);
      widget.list.detail = newDescription;
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    _descriptionController.removeListener(_onDescriptionChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    // Save items order
    final itemIds = _currentItems.map((item) => item.id).toList();
    await _listsService.updateListItemsOrder(widget.list.id, itemIds);

    setState(() {
      _hasChanges = false;
    });


  }

  void _deleteList() async {
    if (widget.list.isDefault) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת רשימה'),
        content: const Text('האם למחוק את הרשימה? פעולה זו אינה ניתנת לביטול.'),
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
        Navigator.pop(context, true); // Return true to indicate list was deleted
        Navigator.pop(context); // Pop back to lists screen
      }
    }
  }

  void _deleteSelectedItems() async {
    if (_selectedIndices.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('הסרה מהרשימה'),
        content: Text('האם להסיר ${_selectedIndices.length} פריטים מהרשימה?'),
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
      // Sort indices in reverse to remove from end to beginning
      final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));

      for (int index in sortedIndices) {
        final itemId = _currentItems[index].id;
        await _listsService.removeItemFromList(widget.list.id, itemId);
        _currentItems.removeAt(index);
      }

      setState(() {
        _selectedIndices.clear();
        _isEditMode = false;
        _hasChanges = true;
      });
    }
  }

  void _moveToTop(int index) {
    if (index > 0) {
      setState(() {
        final item = _currentItems.removeAt(index);
        _currentItems.insert(0, item);
        _hasChanges = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_isEditMode) {
      setState(() {
        _isEditMode = false;
        _selectedIndices.clear();
      });
      return false;
    }

    if (_hasChanges) {
      await _saveChanges();
    }

    Navigator.pop(context, true); // Always return true to force refresh
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('עריכת רשימה'),
          centerTitle: true,
          leading: _isEditMode
              ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isEditMode = false;
                _selectedIndices.clear();
              });
            },
          )
              : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              if (_hasChanges) {
                await _saveChanges();
              }
              Navigator.pop(context, true); // Force refresh
            },
          ),
          actions: [
            if (!widget.list.isDefault)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteList,
                tooltip: 'מחק רשימה',
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'שם הרשימה',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _nameController,
                        enabled: !widget.list.isDefault,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: InputDecoration(
                          border: const UnderlineInputBorder(),
                          hintText: 'הכנס שם לרשימה',
                          suffixIcon: widget.list.isDefault
                              ? const Icon(Icons.lock, color: Colors.grey, size: 20)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'תיאור הרשימה',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          hintText: 'הוסף תיאור לרשימה (אופציונלי)',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // List info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'מידע על הרשימה',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('מספר פריטים:'),
                          Text(
                            '${_currentItems.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('תאריך יצירה:'),
                          Text(
                            '${widget.list.createdAt.day}/${widget.list.createdAt.month}/${widget.list.createdAt.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (widget.list.lastModified != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('עדכון אחרון:'),
                            Text(
                              '${widget.list.lastModified!.day}/${widget.list.lastModified!.month}/${widget.list.lastModified!.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Items section
              if (_currentItems.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'פריטים ברשימה',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isEditMode = !_isEditMode;
                          if (!_isEditMode) {
                            _selectedIndices.clear();
                          }
                        });
                      },
                      icon: Icon(_isEditMode ? Icons.close : Icons.edit),
                      label: Text(_isEditMode ? 'ביטול' : 'עריכה'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildItemsList(),
              ],

              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: _isEditMode
            ? FloatingActionButton(
          onPressed: _selectedIndices.isNotEmpty ? _deleteSelectedItems : null,
          backgroundColor: _selectedIndices.isNotEmpty ? Colors.red : Colors.grey,
          child: const Icon(Icons.delete),
        )
            : FloatingActionButton(
          onPressed: () async {
            await _saveChanges();
            Navigator.pop(context, true); // Force refresh

          },
          backgroundColor: Colors.green,
          child: const Icon(Icons.save),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildItemsList() {
    if (_currentItems.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              "הרשימה ריקה",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    if (_isEditMode) {
      return Card(
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _currentItems.length,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (newIndex > oldIndex) {
                newIndex -= 1;
              }
              final item = _currentItems.removeAt(oldIndex);
              _currentItems.insert(newIndex, item);
              _hasChanges = true;
            });
          },
          itemBuilder: (context, index) {
            final item = _currentItems[index];
            final isSelected = _selectedIndices.contains(index);

            return ListTile(
              contentPadding: const EdgeInsets.only(left: 0, right: 5),
              key: ValueKey('${item.id}'),
              leading: Icon(Icons.drag_handle, color: Colors.grey[600]),
              title: Text(item.name),
              subtitle: item.detail != null
                  ? Text(
                item.detail!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
                  : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _getCategoryChip(item.category),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.arrow_upward),
                    onPressed: index > 0 ? () => _moveToTop(index) : null,
                    tooltip: 'הזז לראש הרשימה',
                  ),
                  Checkbox(
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedIndices.add(index);
                        } else {
                          _selectedIndices.remove(index);
                        }
                      });
                    },
                  ),
                ],
              ),
              onTap: () {
                setState(() {
                  if (_selectedIndices.contains(index)) {
                    _selectedIndices.remove(index);
                  } else {
                    _selectedIndices.add(index);
                  }
                });
              },
            );
          },
        ),
      );
    }

    // Normal view (not edit mode)
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _currentItems.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final item = _currentItems[index];

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: _getCategoryColor(item.category),
              child: Text(
                '${index + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(item.name),
            subtitle: item.detail != null
                ? Text(
              item.detail!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
                : null,
            trailing: _getCategoryChip(item.category),
          );
        },
      ),
    );
  }

  Widget _getCategoryChip(String category) {
    String label;
    switch (category) {
      case 'games':
        label = 'משחק';
        break;
      case 'activities':
        label = 'פעילות';
        break;
      case 'riddles':
        label = 'חידה';
        break;
      case 'texts':
        label = 'טקסט';
        break;
      default:
        label = category;
    }

    return Chip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      backgroundColor: _getCategoryColor(category).withOpacity(0.2),
      labelStyle: TextStyle(color: _getCategoryColor(category)),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
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