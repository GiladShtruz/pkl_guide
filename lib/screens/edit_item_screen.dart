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
  late TextEditingController _newContentController;
  late List<String> _content;
  late List<bool> _isUserAdded;
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _detailController = TextEditingController(text: widget.item.detail ?? '');
    _linkController = TextEditingController(text: widget.item.link ?? '');
    _newContentController = TextEditingController();
    _content = List.from(widget.item.items);

    // Track which content items are user-added
    _isUserAdded = List.generate(_content.length, (index) => false);

    // Check if this is a user-added item
    if (widget.item.isUserAdded) {
      _isUserAdded = List.filled(_content.length, true);
    }

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
    _newContentController.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_hasChanges) {
      await _saveChanges();
    }
    return true;
  }

  Future<void> _saveChanges() async {
    final storageService = context.read<StorageService>();

    // Update item properties
    widget.item.name = _nameController.text;
    widget.item.detail = _detailController.text;
    widget.item.link = _linkController.text;
    widget.item.items = _content;

    await widget.item.save();
  }

  void _addContent() {
    if (_newContentController.text.isNotEmpty) {
      setState(() {
        _content.add(_newContentController.text);
        _isUserAdded.add(true);
        _hasChanges = true;
      });
      _newContentController.clear();
      // Keep focus on the text field
      FocusScope.of(context).requestFocus();
    }
  }

  void _deleteItem() async {
    if (widget.item.isUserAdded) {
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
        await widget.item.delete();
        if (mounted) {
          Navigator.pop(context);
        }
      }
    }
  }

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת פריטים'),
        content: Text('האם למחוק ${_selectedIndices.length} פריטים?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () async {
              final storageService = context.read<StorageService>();

              // Remove items in reverse order to maintain indices
              final sortedIndices = _selectedIndices.toList()
                ..sort((a, b) => b.compareTo(a));
              for (int index in sortedIndices) {
                if (!_isUserAdded[index]) {
                  // Mark original content as deleted
                  await storageService.markAsDeleted(
                    '${widget.item.id}_content_$index',
                  );
                }
                _content.removeAt(index);
                _isUserAdded.removeAt(index);
              }

              setState(() {
                _selectedIndices.clear();
                _isSelectionMode = false;
                _hasChanges = true;
              });

              Navigator.pop(context);
            },
            child: const Text('מחק', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
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
                    if (_hasChanges) {
                      await _saveChanges();
                    }
                    Navigator.pop(context);
                  },
                ),
          actions: [
            if (!_isSelectionMode) ...[
              if (widget.item.isUserAdded)
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
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'שם',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'תיאור',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'קישור',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 24),

              // Add new content section
              if (widget.item.category != 'texts')
                ...addSection(),
              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton(
                onPressed: _selectedIndices.isNotEmpty ? _deleteSelected : null,
                backgroundColor: _selectedIndices.isNotEmpty
                    ? Colors.red
                    : Colors.grey,
                child: const Icon(Icons.delete),
              )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  List<Widget> addSection(){
    return [
      Row(
        children: [
          const Text(
            'הוסף תוכן:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _newContentController,
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

      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _getContentSectionTitle(),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_content.isNotEmpty)
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
              label: Text(_isSelectionMode ? 'ביטול' : 'מחיקה מרובה'),
            ),
        ],
      ),
      const SizedBox(height: 8),
      Card(
        child: _content.isEmpty
            ? Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              'אין תוכן',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        )
            : ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _content.length,
          separatorBuilder: (context, index) =>
          const Divider(height: 1),
          itemBuilder: (context, index) {
            final isSelected = _selectedIndices.contains(index);

            return ListTile(
              leading: _isSelectionMode
                  ? Checkbox(
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
              )
                  : CircleAvatar(
                backgroundColor: _isUserAdded[index]
                    ? Colors.blue[100]
                    : Colors.grey[200],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: _isUserAdded[index]
                        ? Colors.blue
                        : Colors.grey[700],
                  ),
                ),
              ),
              title: Text('${index + 1}. ${_content[index]}'),
              trailing: _isUserAdded[index]
                  ? const Chip(
                label: Text(
                  'נוסף',
                  style: TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue,
                labelStyle: TextStyle(color: Colors.white),
              )
                  : null,
              onTap: _isSelectionMode
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
        return 'הכנס תוכן חדש...';
      case 'riddles':
        return 'הכנס חידה חדשה...';
      case 'texts':
        return 'הכנס קטע חדש...';
      default:
        return 'הכנס תוכן חדש...';
    }
  }
}
