// lib/screens/list_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_model.dart';
import '../models/item_model.dart';
import '../services/lists_service.dart';
import '../screens/item_detail_screen.dart';
import '../screens/list_edit_screen.dart';
import '../utils/category_helper.dart'; // ← הוסף

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
  late ListsService _listsService;
  late List<ItemModel> _items;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _items = _listsService.getListItems(widget.list.id);
    });
  }

  void _openListEditScreen() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListEditScreen(list: widget.list),
      ),
    );

    if (result == 'deleted') {
      if (mounted) {
        Navigator.pop(context);
      }
      return;
    }

    if (result == true) {
      if (!_listsService.listExists(widget.list.id)) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }
    }

    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.list.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _openListEditScreen,
            tooltip: 'עריכת רשימה',
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
            const SizedBox(height: 8),
            Text(
              'לחץ על כפתור העריכה להוספת פריטים',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: () async {
          _loadItems();
        },
        child: Column(
          children: [
            // List description card if exists
            if (widget.list.detail != null && widget.list.detail!.isNotEmpty)
              Card(
                margin: const EdgeInsets.all(16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 20,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'תיאור הרשימה',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.list.detail!,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

            // Items count and info
            if (_items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'סה״כ ${_items.length} פריטים',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),

            // Items list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  final item = _items[index];

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                      leading: CircleAvatar(
                        backgroundColor: CategoryHelper.getCategoryColor(item.category), // ← שינוי כאן
                        child: Icon(
                          CategoryHelper.getCategoryIcon(item.category), // ← שינוי כאן
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        item.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
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
                          if (item.hasUserModifications)
                            Icon(
                              Icons.edit_note,
                              size: 16,
                              color: Colors.blue[400],
                            ),
                          const SizedBox(width: 8),
                          const Icon(Icons.arrow_forward_ios, size: 16),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ItemDetailScreen(item: item),
                          ),
                        ).then((_) {
                          setState(() {
                            // Refresh in case item was modified
                          });
                        });
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}