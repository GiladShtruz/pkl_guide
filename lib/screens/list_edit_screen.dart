import 'dart:math';
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
  bool _isChangingMode = false;

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
        // Pop with special result 'deleted' to signal list was deleted
        Navigator.pop(context, 'deleted');
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



  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Prevent default popping to control it manually
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return; // If already popped, do nothing
        if (_isEditMode) {
          setState(() {
            _isEditMode = false;
            _selectedIndices.clear();
          });
          return; // Prevent popping
        }
        if (_hasChanges) {
          await _saveChanges();
        }
        Navigator.pop(context, true); // Force pop with true to trigger refresh
      },
      child: Scaffold(
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
                      onPressed: _isChangingMode
                          ? null
                          : () async {
                        setState(() {
                          _isChangingMode = true;
                        });

                        await Future.delayed(const Duration(milliseconds: 50));

                        setState(() {
                          _isEditMode = !_isEditMode;
                          if (!_isEditMode) {
                            _selectedIndices.clear();
                          }
                          _isChangingMode = false;
                        });
                      },
                      icon: Icon(_isChangingMode
                          ? Icons.hourglass_bottom_sharp
                          : (_isEditMode ? Icons.check : Icons.edit)),
                      label: Text(_isChangingMode
                          ? 'טוען...'
                          : (_isEditMode ? 'אישור' : 'עריכה')),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _buildItemsList(),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        "הרשימה ריקה",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  ),
                ),
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
            : FloatingActionButton.extended(
          onPressed: () async {
            await _saveChanges();
            Navigator.pop(context, true); // Force refresh
          },
          label: const Text('שמור'),
          icon: const Icon(Icons.save),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildItemsList() {
    if (_isEditMode) {
      // חישוב גובה דינמי - מקסימום חצי מהמסך
      final screenHeight = MediaQuery.of(context).size.height;
      final maxHeight = screenHeight * 0.5;
      final estimatedItemHeight = 88.0; // גובה משוער של ListTile עם subtitle
      final calculatedHeight = min(maxHeight, _currentItems.length * estimatedItemHeight);

      return Card(
        child: SizedBox(
          height: calculatedHeight,
          child: ReorderableListView.builder(
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
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    _getCategoryChip(item.category),
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
        ),
      );
    }

    // Normal view (not edit mode) - נשאר עם הגבלת גובה לרשימות גדולות
    return Card(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: _currentItems.length > 50
              ? MediaQuery.of(context).size.height * 0.5
              : double.infinity,
        ),
        child: ListView.separated(
          shrinkWrap: _currentItems.length <= 50,
          physics: _currentItems.length <= 50
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemCount: _currentItems.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = _currentItems[index];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
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