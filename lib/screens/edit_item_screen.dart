// lib/screens/edit_item_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';

class EditItemScreen extends StatefulWidget {
  final ItemModel item;

  const EditItemScreen({super.key, required this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late TextEditingController _nameController;
  late TextEditingController _detailController;
  late TextEditingController _linkController;
  late TextEditingController _newItemController;
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;
  bool _hasChanges = false;
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();

    // Use current values (user modified or original)
    _nameController = TextEditingController(text: widget.item.name);
    _detailController = TextEditingController(text: widget.item.detail ?? '');
    _linkController = TextEditingController(text: widget.item.link ?? '');
    _newItemController = TextEditingController();

    // Add listeners for changes
    _nameController.addListener(_markChanged);
    _detailController.addListener(_markChanged);
    _linkController.addListener(_markChanged);
  }

  void _markChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _linkController.dispose();
    _newItemController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      // showDialog to save or delete?
      // await _saveChanges();
    }
    return true;
  }

  Future<void> _saveChanges() async {
    // Save title changes
    if (_nameController.text != widget.item.originalTitle) {
      await _storageService.updateItemTitle(widget.item.id,
          _nameController.text);
    }

    // Save detail changes
    if (_detailController.text != (widget.item.originalDetail ?? '')) {
      await _storageService.updateItemDetail(
          widget.item.id,
          _detailController.text.isNotEmpty ? _detailController.text : null
      );
    }

    // Link cannot be edited by user based on requirements

    setState(() {
      _hasChanges = false;
    });
  }

  void _resetTitle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שחזר כותרת'),
        content: const Text('האם לשחזר את הכותרת המקורית?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('שחזר', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.resetItemTitle(widget.item.id);
      setState(() {
        _nameController.text = widget.item.originalTitle;
      });
    }
  }

  void _resetDetail() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שחזר תיאור'),
        content: const Text('האם לשחזר את התיאור המקורי?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('שחזר', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _storageService.resetItemDetail(widget.item.id);
      setState(() {
        _detailController.text = widget.item.originalDetail ?? '';
      });
    }
  }

  void _resetUserItems() async {
    if (widget.item.userAddedItems.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('שחזר תוכן'),
        content: Text('האם למחוק את כל ${widget.item.userAddedItems.length} הפריטים שנוספו?'),
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
      await _storageService.resetItemUserItems(widget.item.id);
      setState(() {});
    }
  }

  void _addContent() async {
    if (_newItemController.text.isNotEmpty) {
      await _storageService.addUserItemToExisting(
          widget.item.id,
          _newItemController.text
      );

      setState(() {
        _hasChanges = true;
      });
      _newItemController.clear();

      // Keep focus on the text field
      FocusScope.of(context).requestFocus();
    }
  }

  void _deleteItem() async {
    // Can only delete if this is a user-created item
    if (widget.item.isUserCreated) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('מחיקת פריט'),
          content: const Text('האם למחוק את הפריט לצמיתות?'),
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
        // await _storageService.deleteUserCreatedItem(widget.item.id);
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  void _deleteSelectedUserItems() async {
    if (_selectedIndices.isEmpty) return;

    // Get indices of user added items
    final userItemsStartIndex = widget.item.originalItems.length;
    final selectedUserIndices = _selectedIndices
        .where((index) => index >= userItemsStartIndex)
        .map((index) => index - userItemsStartIndex)
        .toList();

    if (selectedUserIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ניתן למחוק רק פריטים שהוספת'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת פריטים'),
        content: Text('האם למחוק ${selectedUserIndices.length} פריטים?'),
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
      // Remove items in reverse order to maintain indices
      selectedUserIndices.sort((a, b) => b.compareTo(a));
      for (int index in selectedUserIndices) {
        if (index < widget.item.userAddedItems.length) {
          final itemToRemove = widget.item.userAddedItems[index];
          await _storageService.removeUserItem(widget.item.id, itemToRemove);
        }
      }

      setState(() {
        _selectedIndices.clear();
        _isSelectionMode = false;
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('עריכת פריט'),
          centerTitle: true,
          leading: _isSelectionMode
              ? IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _isSelectionMode = false;
                _selectedIndices.clear();
              });
            },
          )
              : IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () async {
              print("get: $_hasChanges");

              if (_hasChanges) {
                await _saveChanges();
              }
              Navigator.pop(context);
            },
          ),
          actions: [
            if (!_isSelectionMode) ...[
              if (widget.item.isUserCreated)
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: _deleteItem,
                ),
              TextButton(
                onPressed: () async {
                  await _saveChanges();
                  Navigator.pop(context);
                },
                child: const Text('שמור'),
              ),
            ],
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title field with reset button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'שם',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (widget.item.userTitle != null)
                    TextButton.icon(
                      onPressed: _resetTitle,
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('שחזר למקור'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Detail field with reset button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _detailController,
                    decoration: const InputDecoration(
                      labelText: 'תיאור',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  if (widget.item.userDetail != null)
                    TextButton.icon(
                      onPressed: _resetDetail,
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('שחזר למקור'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Link field (read-only for non-user-created items)
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'קישור',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
                readOnly: !widget.item.isUserCreated,
              ),
              const SizedBox(height: 24),

              // Add new content section
              if (widget.item.category != 'texts') ..._buildContentSection(),

              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton(
          onPressed: _deleteSelectedUserItems,
          backgroundColor: Colors.red,
          child: const Icon(Icons.delete),
        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  List<Widget> _buildContentSection() {
    final allItems = widget.item.userAddedItems;
    final originalItemsCount = widget.item.userAddedItems.length;

    return [
      // Add new content
      Row(
        children: [
          const Text(
            'הוסף תוכן:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _newItemController,
              decoration: InputDecoration(
                hintText: _getAddContentHint(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
              ),
              onSubmitted: (_) => _addContent(),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: _addContent,
            child: const Text('הוסף'),
          ),
        ],
      ),
      const SizedBox(height: 16),

      // Content list header
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getContentSectionTitle(),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              if (widget.item.userAddedItems.isNotEmpty)
                TextButton.icon(
                  onPressed: _resetUserItems,
                  icon: const Icon(Icons.restore, size: 16),
                  label: Text('מחק ${widget.item.userAddedItems.length} נוספים'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              if (allItems.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = !_isSelectionMode;
                      if (!_isSelectionMode) {
                        _selectedIndices.clear();
                      }
                    });
                  },
                  icon: Icon(_isSelectionMode ? Icons.close : Icons.delete),
                  label: Text(_isSelectionMode ? 'ביטול' : 'מחיקה'),
                ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),

      // Content list
      Card(
        child: allItems.isEmpty
            ? Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              "אין תוכן. הוסף משלך!",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: allItems.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final isSelected = _selectedIndices.contains(index);
            final isUserAdded = index >= originalItemsCount;
            final canDelete = isUserAdded || widget.item.isUserCreated;

            return ListTile(
              leading: _isSelectionMode
                  ? Checkbox(
                value: isSelected,
                onChanged: canDelete
                    ? (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIndices.add(index);
                    } else {
                      _selectedIndices.remove(index);
                    }
                  });
                }
                    : null,
              )
                  : CircleAvatar(
                backgroundColor: isUserAdded
                    ? Colors.blue[100]
                    : Colors.grey[200],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isUserAdded
                        ? Colors.blue
                        : Colors.grey[700],
                  ),
                ),
              ),
              title: Text('${index + 1}. ${allItems[index]}'),
              trailing: isUserAdded
                  ? const Chip(
                label: Text('נוסף', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.blue,
                labelStyle: TextStyle(color: Colors.white),
              )
                  : null,
              onTap: _isSelectionMode && canDelete
                  ? () {
                setState(() {
                  if (_selectedIndices.contains(index)) {
                    _selectedIndices.remove(index);
                  } else {
                    _selectedIndices.add(index);
                  }
                });
              }
                  : null,
            );
          },
        ),
      ),
    ];
  }

  String _getContentSectionTitle() {
    switch (widget.item.category) {
      case 'games':
        return 'מילים';
      case 'activities':
        return 'תוכן';
      case 'riddles':
        return 'חידות';
      case 'texts':
        return 'קטעים';
      default:
        return 'תוכן';
    }
  }

  String _getAddContentHint() {
    switch (widget.item.category) {
      case 'games':
        return 'הכנס מילה חדשה...';
      case 'activities':
        return 'הכנס פעילות חדשה...';
      case 'riddles':
        return 'הכנס חידה חדשה...';
      case 'texts':
        return 'הכנס קטע חדש...';
      default:
        return 'הכנס תוכן חדש...';
    }
  }

}