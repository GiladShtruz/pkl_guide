// lib/screens/edit_item_screen.dart
import 'package:flutter/material.dart';
import 'package:pkl_guide/models/category.dart';
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
  late TextEditingController _equipmentController;
  late TextEditingController _newItemController;

  final FocusNode _addElementsFocusNode = FocusNode();



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
    _equipmentController = TextEditingController(text: widget.item.equipment ?? '');
    _newItemController = TextEditingController();

    // Add listeners for changes
    _nameController.addListener(_markChanged);
    _detailController.addListener(_markChanged);
    _linkController.addListener(_markChanged);
    _equipmentController.addListener(_markChanged);
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
    _newItemController.dispose();

    _addElementsFocusNode.dispose();

    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if(_isSelectionMode){
      setState(() {
        _isSelectionMode = false;
        _selectedIndices.clear();
      });
      return false;
    }
    if (_hasChanges) {
      await _saveChanges();
    }
    // if (_hasChanges) {
    //   bool toSave = false;
    //   showDialog(context: context, builder: (context)  =>
    //     AlertDialog(
    //         title: Text("האם לשמור?"),
    //         actions: [
    //           TextButton(
    //             child: Text('אל תשמור'),
    //             onPressed: () {
    //               Navigator.of(context).pop();
    //             },
    //           ),
    //
    //           TextButton(
    //             child: Text('שמור'),
    //             onPressed: () {
    //                toSave = true;
    //               Navigator.of(context).pop();
    //             },
    //           ),
    //         ]
    //     ));
    //   if(toSave){
    //     await _saveChanges();
    //   }
    // }
    return true;
  }


  Future<void> _saveChanges() async {
    // Save title changes
    if (_nameController.text != widget.item.originalTitle) {
      await _storageService.updateItemTitle(widget.item.id, _nameController.text);
    }

    // Save detail changes
    if (_detailController.text != (widget.item.originalDetail ?? '')) {
      await _storageService.updateItemDetail(
          widget.item.id,
          _detailController.text.isNotEmpty ? _detailController.text : null
      );
    }

    // Save link changes
    if (_linkController.text != (widget.item.originalLink ?? '')) {
      await _storageService.updateItemLink(
          widget.item.id,
          _linkController.text.isNotEmpty ? _linkController.text : null
      );
    }

    // Save equipment changes
    if (_equipmentController.text != (widget.item.originalEquipment ?? '')) {
      await _storageService.updateItemEquipment(
          widget.item.id,
          _equipmentController.text.isNotEmpty ? _equipmentController.text : null
      );
    }

    setState(() {
      _hasChanges = false;
    });
  }


  void _resetData(CategoryEntry categoryEntry, String title, String content) async {
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
        case CategoryEntry.elements:
          if (widget.item.userElements.isEmpty) return;
          await _storageService.resetElements(widget.item.id);
          setState(() {});
          break;
        default:
          // Handle other cases if needed

      }
    }
  }
  //
  // void _resetTitle() async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('שחזר כותרת'),
  //       content: const Text('האם לשחזר את הכותרת המקורית?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('ביטול'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('שחזר', style: TextStyle(color: Colors.orange)),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirmed == true) {
  //     await _storageService.resetItemTitle(widget.item.id);
  //     setState(() {
  //       _nameController.text = widget.item.originalTitle;
  //     });
  //   }
  // }
  // void _resetDetail() async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('שחזר תיאור'),
  //       content: const Text('האם לשחזר את התיאור המקורי?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('ביטול'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('שחזר', style: TextStyle(color: Colors.orange)),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirmed == true) {
  //     await _storageService.resetItemDetail(widget.item.id);
  //     setState(() {
  //       _detailController.text = widget.item.originalDetail ?? '';
  //     });
  //   }
  // }
  //
  // void _resetLink() async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('שחזר קישור'),
  //       content: const Text('האם לשחזר את הקישור המקורי?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('ביטול'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('שחזר', style: TextStyle(color: Colors.orange)),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirmed == true) {
  //     await _storageService.resetItemLink(widget.item.id);
  //     setState(() {
  //       _linkController.text = widget.item.originalLink ?? '';
  //     });
  //   }
  // }
  //
  // void _resetEquipment() async {
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('שחזר ציוד'),
  //       content: const Text('האם לשחזר את הציוד המקורי?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('ביטול'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('שחזר', style: TextStyle(color: Colors.orange)),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirmed == true) {
  //     await _storageService.resetItemEquipment(widget.item.id);
  //     setState(() {
  //       _equipmentController.text = widget.item.originalEquipment ?? '';
  //     });
  //   }
  // }
  //
  // void _resetUserItems() async {
  //   if (widget.item.userElements.isEmpty) return;
  //
  //   final confirmed = await showDialog<bool>(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: const Text('שחזר תוכן'),
  //       content: Text('האם למחוק את כל ${widget.item.userElements.length} הפריטים שנוספו?'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, false),
  //           child: const Text('ביטול'),
  //         ),
  //         TextButton(
  //           onPressed: () => Navigator.pop(context, true),
  //           child: const Text('מחק', style: TextStyle(color: Colors.red)),
  //         ),
  //       ],
  //     ),
  //   );
  //
  //   if (confirmed == true) {
  //     await _storageService.resetElements(widget.item.id);
  //     setState(() {});
  //   }
  // }

  void _addContent() async {
    if (_newItemController.text.isNotEmpty) {
      await _storageService.addUserElement(
          widget.item.id,
          _newItemController.text
      );

      setState(() {
        _hasChanges = true;
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
          Navigator.pop(context);
        }
      }
    }
  }

  void _deleteSelectedUserItems() async {
    if (_selectedIndices.isEmpty) return;

    // Get indices of user added items
    // final userElementsStartIndex = widget.item.originalElements.length;
    // final selectedUserIndices = _selectedIndices
    //     .where((index) => index >= userElementsStartIndex)
    //     .map((index) => index - userElementsStartIndex)
    //     .toList();

    // if (_selectedIndices.isEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(
    //       content: Text('ניתן למחוק רק פריטים שהוספת'),
    //       backgroundColor: Colors.orange,
    //     ),
    //   );
    //   return;
    // }


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
      for (int index in _selectedIndices) {
          final itemToRemove = widget.item.userElements[widget.item.userElements.length - index - 1];
          await _storageService.removeUserElement(widget.item.id, itemToRemove);
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
                if (_hasChanges) {
                  await _saveChanges();
                }
                Navigator.pop(context);
              },
            ),
            actions: [
              ...[
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
                      onPressed:() => _resetData(CategoryEntry.title, "שחזר כותרת", "האם לשחזר את הכותרת המקורית?"),
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
                      onPressed:() => _resetData(CategoryEntry.detail, "שחזר תיאור", "האם לשחזר את התיאור המקורי?"),
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
                      onPressed:() => _resetData(CategoryEntry.link, "שחזר קישור", "האם לשחזר את הקישור המקורי?"),
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
                maxLines: 2,
              ),
              if (widget.item.userEquipment != null)
          TextButton.icon(
            onPressed:() => _resetData(CategoryEntry.equipment, "שחזר רשימת ציוד", "האם לשחזר את רשימת הציוד המקורית?"),
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
    final userElements = widget.item.userElements;
    final userItemCount = widget.item.userElements.length;

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
              if (widget.item.userElements.isNotEmpty)
                TextButton.icon(
                  onPressed:() => _resetData(CategoryEntry.elements, "מחק פריטים", "האם למחוק את הפריטים שהוספת?"),
                  icon: const Icon(Icons.restore, size: 16),
                  label: Text('מחק הכל'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orange,
                  ),
                ),
              if (userElements.isNotEmpty)
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
        child: userElements.isEmpty
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
          itemCount: userElements.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final isSelected = _selectedIndices.contains(index);
            // final isUserAdded = index >= userItemCount;
            // final canDelete = isUserAdded || widget.item.isUserCreated;

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
                }
                ,
              )
                  : CircleAvatar(
                backgroundColor: Colors.blue[100],
                    // : Colors.grey[200],
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: Colors.blue,
                        // : Colors.grey[700],
                  ),
                ),
              ),
              title: Text(userElements[userElements.length - index - 1]),
              // trailing: const Chip(
              //   label: Text('נוסף', style: TextStyle(fontSize: 12)),
              //   backgroundColor: Colors.blue,
              //   labelStyle: TextStyle(color: Colors.white),
              // ),
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