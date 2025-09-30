// lib/screens/edit_item_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pkl_guide/models/category.dart';
import 'package:pkl_guide/models/element_model.dart';

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
  bool _isInitializing = true;
  bool _isChangingMode = false;

  late TextEditingController _nameController;
  late TextEditingController _detailController;
  late TextEditingController _linkController;
  late TextEditingController _equipmentController;
  late TextEditingController _classificationController;
  late TextEditingController _newItemController;

  final FocusNode _addElementsFocusNode = FocusNode();

  final Set<int> _selectedIndices = {};
  bool _isEditMode = false;
  bool _hasChanges = false;
  bool _isChangeElements = false;
  late StorageService _storageService;

  // Keep a local copy of elements for reordering
  late List<ElementModel> _currentElements;

  @override
  void initState() {
    super.initState();
    _storageService = context.read<StorageService>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }
  Future<void> _initializeData() async {
    // Initialize elements list
    _currentElements = List.from(widget.item.elements);

    // Initialize controllers
    _nameController = TextEditingController(text: widget.item.name);
    _detailController = TextEditingController(text: widget.item.detail ?? '');
    _linkController = TextEditingController(text: widget.item.link ?? '');
    _equipmentController = TextEditingController(
      text: widget.item.equipment ?? '',
    );
    _classificationController = TextEditingController(
      text: widget.item.classification ?? '',
    );
    _newItemController = TextEditingController();

    // Add listeners
    _nameController.addListener(_markChanged);
    _detailController.addListener(_markChanged);
    _linkController.addListener(_markChanged);
    _equipmentController.addListener(_markChanged);
    _classificationController.addListener(_markChanged);

    setState(() {
      _isInitializing = false;
    });
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
    _equipmentController.dispose();
    _classificationController.dispose();
    _newItemController.dispose();
    _addElementsFocusNode.dispose();
    super.dispose();
  }



  Future<void> _saveChanges() async {
    // Save title changes
    if (_nameController.text != widget.item.originalTitle) {
      await _storageService.updateItemTitle(
        widget.item.id,
        _nameController.text,
      );
    }

    // Save detail changes
    if (_detailController.text != (widget.item.originalDetail ?? '')) {
      await _storageService.updateItemDetail(
        widget.item.id,
        _detailController.text.isNotEmpty ? _detailController.text : null,
      );
    }

    // Save link changes
    if (_linkController.text != (widget.item.originalLink ?? '')) {
      await _storageService.updateItemLink(
        widget.item.id,
        _linkController.text.isNotEmpty ? _linkController.text : null,
      );
    }

    // Save equipment changes
    if (_equipmentController.text != (widget.item.originalEquipment ?? '')) {
      await _storageService.updateItemEquipment(
        widget.item.id,
        _equipmentController.text.isNotEmpty ? _equipmentController.text : null,
      );
    }

    // Save classification changes
    if (_classificationController.text != (widget.item.originalClassification ?? '')) {
      await _storageService.updateItemClassification(
        widget.item.id,
        _classificationController.text.isNotEmpty ? _classificationController.text : null,
      );
    }

    // Save elements order if changed
    // if (_currentElements != widget.item.elements)
    if (_isChangeElements) {
      widget.item.itemElements = _currentElements;
      widget.item.isElementsChanged = true;
      widget.item.isUserChanged = true;
      await widget.item.save();
    }

    setState(() {
      _hasChanges = false;
    });
  }

  void _resetData(
      CategoryEntry categoryEntry,
      String title,
      String content,
      ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
      switch (categoryEntry) {
        case CategoryEntry.title:
          await _storageService.resetItemTitle(widget.item.id);
          setState(() {
            _nameController.text = widget.item.originalTitle;
          });
          break;
        case CategoryEntry.detail:
          await _storageService.resetItemDetail(widget.item.id);
          setState(() {
            _detailController.text = widget.item.originalDetail ?? '';
          });
          break;
        case CategoryEntry.link:
          await _storageService.resetItemLink(widget.item.id);
          setState(() {
            _linkController.text = widget.item.originalLink ?? '';
          });
          break;
        case CategoryEntry.equipment:
          await _storageService.resetItemEquipment(widget.item.id);
          setState(() {
            _equipmentController.text = widget.item.originalEquipment ?? '';
          });
          break;
        case CategoryEntry.classification:
          await _storageService.resetItemClassification(widget.item.id);
          setState(() {
            _classificationController.text = widget.item.originalClassification ?? '';
          });
          break;
        case CategoryEntry.elements:
        // await _storageService.resetElements(widget.item.id);
        // _isChangeElements = false;
          setState(() {
            _currentElements = List.from(widget.item.elements);
            _isChangeElements = false;
          });
          break;
        default:
        // Handle other cases if needed
      }
    }
  }

  void _addContent() async {
    if (_newItemController.text.isNotEmpty) {
      // Add to the beginning of the list
      setState(() {
        _currentElements.insert(0, ElementModel(_newItemController.text, true));
        _hasChanges = true;
        _isChangeElements = true;
      });

      _newItemController.clear();
      // Keep focus on the text field
      FocusScope.of(context).requestFocus(_addElementsFocusNode);
    }
  }

  void _deleteItem() async {
    // Can only delete if this is a user-created item
    if (widget.item.isUserCreated) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('מחיקת פריט'),
          content: const Text('האם למחוק את הפריט?'),
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
        await _storageService.deleteItem(widget.item.id);
        if (mounted) {
          // Pop twice: once from edit screen, once from detail screen
          Navigator.pop(context, true); // Return to detail screen with result
          Navigator.pop(context, true); // Return to category items screen with result
        }
      }
    }
  }
  void _deleteSelectedElements() async {
    if (_selectedIndices.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('מחיקת פריטים'),
        content: Text('האם למחוק ${_selectedIndices.length} פריטים?'),
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
      // Sort indices in reverse to remove from end to beginning
      final sortedIndices = _selectedIndices.toList()
        ..sort((a, b) => b.compareTo(a));

      for (int index in sortedIndices) {
        _currentElements.removeAt(index);
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
        final element = _currentElements.removeAt(index);
        _currentElements.insert(0, element);
        _hasChanges = true;
        _isChangeElements = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true, // Allows popping by default
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
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('עריכת פריט'),
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
              Navigator.pop(context);
            },
          ),
          actions: [
            if (widget.item.isUserCreated)
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: _deleteItem,
              ),
          ],
        ),
        body: _isInitializing
            ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
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
                      onPressed: () => _resetData(
                        CategoryEntry.title,
                        "שחזר כותרת",
                        "האם לשחזר את הכותרת המקורית?",
                      ),
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
                      onPressed: () => _resetData(
                        CategoryEntry.detail,
                        "שחזר תיאור",
                        "האם לשחזר את התיאור המקורי?",
                      ),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('שחזר למקור'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Link field with reset button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: 'קישור',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.link),
                    ),
                  ),
                  if (widget.item.userLink != null)
                    TextButton.icon(
                      onPressed: () => _resetData(
                        CategoryEntry.link,
                        "שחזר קישור",
                        "האם לשחזר את הקישור המקורי?",
                      ),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('שחזר למקור'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Equipment field with reset button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _equipmentController,
                    decoration: const InputDecoration(
                      labelText: 'ציוד נדרש',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.sports_soccer),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null, // מאפשר שורות רבות
                  ),
                  if (widget.item.userEquipment != null)
                    TextButton.icon(
                      onPressed: () => _resetData(
                        CategoryEntry.equipment,
                        "שחזר רשימת ציוד",
                        "האם לשחזר את רשימת הציוד המקורית?",
                      ),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('שחזר למקור'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Classification (מיקום) field with reset button
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _classificationController,
                    decoration: const InputDecoration(
                      labelText: 'סיווג',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  if (widget.item.userClassification != null)
                    TextButton.icon(
                      onPressed: () => _resetData(
                        CategoryEntry.classification,
                        "שחזר סיווג",
                        "האם לשחזר את המיקום המקורי?",
                      ),
                      icon: const Icon(Icons.restore, size: 16),
                      label: const Text('שחזר למקור'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Add new content section
              if (widget.item.category != 'texts') ..._buildContentSection(),

              const SizedBox(height: 80),
            ],
          ),
        ),
        floatingActionButton: _isEditMode
            ? FloatingActionButton(
          onPressed: _selectedIndices.isNotEmpty
              ? _deleteSelectedElements
              : null,
          backgroundColor: _selectedIndices.isNotEmpty
              ? Colors.red
              : Colors.grey,
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

  List<Widget> _buildContentSection() {
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
              textInputAction: TextInputAction.next,
              onEditingComplete: _addContent,
              controller: _newItemController,
              focusNode: _addElementsFocusNode,
              decoration: InputDecoration(
                hintText: _getAddContentHint(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: const OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(onPressed: _addContent, child: const Text('הוסף')),
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
              if (_isChangeElements)
                TextButton.icon(
                  onPressed: () => _resetData(
                    CategoryEntry.elements,
                    "שחזר שינויים",
                    "האם לחזור למצב שהיה לפני השינויים?",
                  ),
                  icon: const Icon(Icons.restore, size: 16),
                  label: const Text('שחזר שינויים'),
                  style: TextButton.styleFrom(foregroundColor: Colors.orange),
                ),
              TextButton.icon(
                onPressed: _isChangingMode
                    ? null :   () async {
                  setState(() {
                    _isChangingMode = true;
                  });
                  // TODO: maybe delete it
                  await Future.delayed(const Duration(milliseconds: 50));

                  setState(() {
                    _isEditMode = !_isEditMode;
                    if (!_isEditMode) {
                      _selectedIndices.clear();

                    }
                    _isChangingMode = false;
                  });
                },
                icon: Icon(_isChangingMode ? Icons.hourglass_bottom_sharp : _isEditMode ? Icons.check : Icons.edit),
                label:  Text(_isChangingMode
                    ? 'טוען...'
                    : (_isEditMode ? 'אישור' : 'עריכה')),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 8),

      // Content list


      _buildElementsList(),
    ];
  }

  Widget _buildElementsList() {
    if (_currentElements.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              "אין תוכן. הוסף משלך!",
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
        ),
      );
    }

    if (_isEditMode) {
      // חישוב גובה דינמי - מקסימום חצי מהמסך
      final screenHeight = MediaQuery.of(context).size.height;
      final maxHeight = screenHeight * 0.5;
      final estimatedItemHeight = 72.0; // גובה משוער של ListTile
      final calculatedHeight = min(maxHeight, _currentElements.length * estimatedItemHeight);

      return Card(
        child: SizedBox(
          height: calculatedHeight,
          child: ReorderableListView.builder(
            itemCount: _currentElements.length,
            onReorder: (oldIndex, newIndex) {
              setState(() {
                if (newIndex > oldIndex) {
                  newIndex -= 1;
                }
                final element = _currentElements.removeAt(oldIndex);
                _currentElements.insert(newIndex, element);
                _isChangeElements = true;
                _hasChanges = true;
              });
            },
            itemBuilder: (context, index) {
              final element = _currentElements[index];
              final isSelected = _selectedIndices.contains(index);
              final canDelete = element.isUserElement;

              return ListTile(
                contentPadding: EdgeInsets.only(left: 0, right: 5),
                key: ValueKey('$index-${element.text}'),
                leading: Icon(Icons.drag_handle, color: Colors.grey[600]),
                title: Text(element.text),
                trailing: Wrap(
                  spacing: 0,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_upward),
                      onPressed: index > 0 ? () => _moveToTop(index) : null,
                      tooltip: 'הזז לראש הרשימה',
                    ),
                    if (canDelete)
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
                onTap: canDelete
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
      );
    }

    // Normal view (not edit mode) - נשאר כמו שהיה
    return Card(
      child: Container(
        // הגבל את הגובה גם במצב רגיל לרשימות גדולות
        constraints: BoxConstraints(
          maxHeight: _currentElements.length > 50
              ? MediaQuery.of(context).size.height * 0.5
              : double.infinity,
        ),
        child: ListView.builder(
          shrinkWrap: _currentElements.length <= 50,
          physics: _currentElements.length <= 50
              ? const NeverScrollableScrollPhysics()
              : const AlwaysScrollableScrollPhysics(),
          itemCount: _currentElements.length,
          itemBuilder: (context, index) {
            final element = _currentElements[index];
            final isUserElement = element.isUserElement;

            return Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.symmetric(horizontal: 5),
                  leading: CircleAvatar(
                    backgroundColor: isUserElement
                        ? Colors.blue[100]
                        : Colors.grey[200],
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: isUserElement ? Colors.blue : Colors.grey[700],
                      ),
                    ),
                  ),
                  title: Text(element.text),
                  trailing: isUserElement
                      ? const Chip(
                    label: Text('נוסף', style: TextStyle(fontSize: 12)),
                    backgroundColor: Colors.blue,
                    labelStyle: TextStyle(color: Colors.white),
                  )
                      : null,
                ),
                if (index < _currentElements.length - 1)
                  const Divider(height: 1),
              ],
            );
          },
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