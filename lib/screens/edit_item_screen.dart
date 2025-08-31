import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';

class EditItemScreen extends StatefulWidget {
  final ItemModel item;

  const EditItemScreen({
    super.key,
    required this.item,
  });

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _linkController;
  late List<String> _content;
  late List<bool> _isUserAdded;
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;
  final TextEditingController _newContentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _descriptionController = TextEditingController(text: widget.item.description ?? '');
    _linkController = TextEditingController(text: widget.item.link ?? '');
    _content = List.from(widget.item.content);

    // Track which content items are user-added
    _isUserAdded = List.generate(_content.length, (index) => false);

    // Check if this is a user-added item
    if (widget.item.isUserAdded) {
      _isUserAdded = List.filled(_content.length, true);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    _newContentController.dispose();
    super.dispose();
  }

  void _saveChanges() async {
    final storageService = context.read<StorageService>();

    // Update item properties
    widget.item.name = _nameController.text;
    widget.item.description = _descriptionController.text;
    widget.item.link = _linkController.text;
    widget.item.content = _content;

    await widget.item.save();

    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _addContent() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getAddContentTitle()),
        content: TextField(
          controller: _newContentController,
          decoration: InputDecoration(
            hintText: _getAddContentHint(),
            border: const OutlineInputBorder(),
          ),
          maxLines: 3,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              _newContentController.clear();
              Navigator.pop(context);
            },
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () {
              if (_newContentController.text.isNotEmpty) {
                setState(() {
                  _content.add(_newContentController.text);
                  _isUserAdded.add(true);
                });
                _newContentController.clear();
                Navigator.pop(context);
              }
            },
            child: const Text('הוסף'),
          ),
        ],
      ),
    );
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
              final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
              for (int index in sortedIndices) {
                if (!_isUserAdded[index]) {
                  // Mark original content as deleted
                  await storageService.markAsDeleted('${widget.item.id}_content_$index');
                }
                _content.removeAt(index);
                _isUserAdded.removeAt(index);
              }

              setState(() {
                _selectedIndices.clear();
                _isSelectionMode = false;
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
      onWillPop: () async {
        if (_isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedIndices.clear();
          });
          return false;
        }
        return true;
      },
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
              : null,
          actions: [
            if (!_isSelectionMode)
              TextButton(
                onPressed: _saveChanges,
                child: const Text('שמור'),
              ),
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
                controller: _descriptionController,
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
                        separatorBuilder: (context, index) => const Divider(height: 1),
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
                            title: Text(_content[index]),
                            trailing: _isUserAdded[index]
                                ? const Chip(
                                    label: Text('נוסף', style: TextStyle(fontSize: 12)),
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
              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: _isSelectionMode
            ? FloatingActionButton(
                onPressed: _selectedIndices.isNotEmpty ? _deleteSelected : null,
                backgroundColor: _selectedIndices.isNotEmpty ? Colors.red : Colors.grey,
                child: const Icon(Icons.delete),
              )
            : FloatingActionButton(
                onPressed: _addContent,
                child: const Icon(Icons.add),
              ),
      ),
    );
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

  String _getAddContentTitle() {
    switch (widget.item.category) {
      case 'games':
        return 'הוסף מילה';
      case 'activities':
        return 'הוסף תוכן';
      case 'riddles':
        return 'הוסף חידה';
      case 'texts':
        return 'הוסף קטע';
      default:
        return 'הוסף תוכן';
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

