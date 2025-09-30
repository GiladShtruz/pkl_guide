import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_model.dart';
import '../services/lists_service.dart';
import '../services/storage_service.dart';
import 'create_list_dialog.dart';

class AddToListsDialog extends StatefulWidget {
  final List<int> itemIds;
  final String? itemName;

  const AddToListsDialog({
    super.key,
    required this.itemIds,
    this.itemName,
  });

  @override
  State<AddToListsDialog> createState() => _AddToListsDialogState();
}

class _AddToListsDialogState extends State<AddToListsDialog> {
  late ListsService _listsService;
  late StorageService _storageService;
  final Set<int> _selectedLists = {};
  final Set<int> _initiallySelectedLists = {}; // לשמירת המצב ההתחלתי
  List<ListModel> _lists = [];

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _storageService = context.read<StorageService>();
    _loadLists();
  }

  void _loadLists() {
    _lists = _listsService.getAllLists();

    // Pre-select lists based on items
    if (widget.itemIds.length == 1) {
      // Single item: show all lists it's in
      final itemId = widget.itemIds.first;
      for (var list in _lists) {
        if (list.categoryItemIds.contains(itemId)) {
          _selectedLists.add(list.id);
          _initiallySelectedLists.add(list.id);
        }
      }
    } else {
      // Multiple items: show only lists that contain ALL items
      for (var list in _lists) {
        bool containsAll = true;
        for (var itemId in widget.itemIds) {
          if (!list.categoryItemIds.contains(itemId)) {
            containsAll = false;
            break;
          }
        }
        if (containsAll) {
          _selectedLists.add(list.id);
          _initiallySelectedLists.add(list.id);
        }
      }
    }

    setState(() {});
  }

  void _createNewList() async {
    final result = await showDialog<Map<String, String?>>(
      context: context,
      builder: (context) => const CreateListDialog(),
    );

    if (result != null && result['name'] != null) {
      final newList = await _listsService.createList(
        result['name']!,
        detail: result['detail'],
      );
      // Add items to new list
      for (var itemId in widget.itemIds) {
        await _listsService.addItemToList(newList.id, itemId);
      }
      if (mounted) {
        Navigator.pop(context, true);
      }
    }
  }

  void _saveSelections() async {
    // Determine which lists to add to and which to remove from
    final listsToAdd = _selectedLists.difference(_initiallySelectedLists);
    final listsToRemove = _initiallySelectedLists.difference(_selectedLists);

    // Add to new lists
    for (var listId in listsToAdd) {
      for (var itemId in widget.itemIds) {
        await _listsService.addItemToList(listId, itemId);
      }
    }

    // Remove from deselected lists
    for (var listId in listsToRemove) {
      for (var itemId in widget.itemIds) {
        await _listsService.removeItemFromList(listId, itemId);
      }
    }

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  String _getTitle() {
    if (widget.itemIds.length == 1 && widget.itemName != null) {
      return widget.itemName!;
    } else {
      return 'נבחרו ${widget.itemIds.length} פריטים';
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ניהול רשימות'),
          const SizedBox(height: 4),
          Text(
            _getTitle(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Create new list button
            OutlinedButton.icon(
              onPressed: _createNewList,
              icon: const Icon(Icons.add),
              label: const Text('צור רשימה חדשה'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            // Lists
            Flexible(
              child: _lists.isEmpty
                  ? const Center(
                child: Text('אין רשימות זמינות'),
              )
                  : ListView.builder(
                shrinkWrap: true,
                itemCount: _lists.length,
                itemBuilder: (context, index) {
                  final list = _lists[index];
                  final isSelected = _selectedLists.contains(list.id);
                  final wasInitiallySelected = _initiallySelectedLists.contains(list.id);

                  return CheckboxListTile(
                    title: Row(
                      children: [
                        Expanded(child: Text(list.name)),
                        // אינדיקטור למצב שונה מהמקורי
                        if (isSelected != wasInitiallySelected)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.green.shade100 : Colors.red.shade100,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isSelected ? 'חדש' : 'יוסר',
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected ? Colors.green.shade700 : Colors.red.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    subtitle: list.detail != null && list.detail!.isNotEmpty
                        ? Text(
                      list.detail!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                        : null,
                    secondary: Icon(
                      list.isDefault ? Icons.favorite : Icons.bookmark,
                      color: list.isDefault ? Colors.red : Colors.blue,
                    ),
                    value: isSelected,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedLists.add(list.id);
                        } else {
                          _selectedLists.remove(list.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: _saveSelections,
          child: const Text('שמור'),
        ),
      ],
    );
  }
}