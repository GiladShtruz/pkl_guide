// lib/screens/item_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:pkl_guide/screens/switch_card_game_screen.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../services/lists_service.dart';
import '../screens/edit_item_screen.dart';

import '../dialogs/add_to_lists_dialog.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late ListsService _listsService;
  late StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _storageService = context.read<StorageService>();

    // Update access count
    _storageService.updateItemAccess(widget.item.id);
  }

  void _openLink() async {
    if (widget.item.link != null && widget.item.link!.isNotEmpty) {
      final uri = Uri.parse(widget.item.link!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _openListsDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AddToListsDialog(
        itemIds: [widget.item.id],
        itemName: widget.item.name,
      ),
    );

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('עודכן ברשימות'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPantomime = widget.item.name.toLowerCase().contains('פנטומימה');
    final hasModifications = widget.item.hasUserModifications;
    final originalCount = widget.item.originalItems.length;
    final userAddedCount = widget.item.userAddedItems.length;
    final totalItems = widget.item.items.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Column(
          children: [
            Text(widget.item.name),
            if (hasModifications)
              const Text(
                'עודכן',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: _openListsDialog,
          ),
          if (widget.item.link != null && widget.item.link!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.link),
              onPressed: _openLink,
              tooltip: 'פתח קישור',
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditItemScreen(item: widget.item),
                  ),
                ).then((_) {
                  setState(() {});
                });
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit),
                    SizedBox(width: 8),
                    Text('עריכה'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // Fixed header content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // User-created badge
                  if (widget.item.isUserCreated)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.person, size: 16, color: Colors.blue),
                          SizedBox(width: 4),
                          Text(
                            'נוצר על ידך',
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Detail card
                  if (widget.item.detail != null &&
                      widget.item.detail!.isNotEmpty) ...[
                    SizedBox(
                      width: double.infinity,
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _getContentDetail(),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (widget.item.userDetail != null)
                                    const Chip(
                                      label: Text(
                                        'עודכן',
                                        style: TextStyle(fontSize: 10),
                                      ),
                                      backgroundColor: Colors.blue,
                                      labelStyle: TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.item.detail!,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Classification
                  if (widget.item.classification != null &&
                      widget.item.classification!.isNotEmpty) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.grey),
                            const SizedBox(width: 8),
                            const Text(
                              'מיקום: ',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              widget.item.classification!,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Items count header
                  if (totalItems > 0) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getContentTitle(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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
                                  color: _getCategoryColor().withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$originalCount מקוריים',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getCategoryColor(),
                                  ),
                                ),
                              ),
                              if (userAddedCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+$userAddedCount נוספו',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                  ],
                ],
              ),
            ),
          ),
          // Items list - using SliverList.builder for performance
          if (totalItems > 0)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: totalItems,
                itemBuilder: (context, index) {
                  final item = widget.item.items[index];
                  final isUserAdded = index >= originalCount;

                  if (widget.item.category == 'riddles') {
                    // Riddles display
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isUserAdded
                            ? Colors.blue[50]
                            : Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isUserAdded
                              ? Colors.blue[200]!
                              : Colors.orange[200]!,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: isUserAdded ? Colors.blue : Colors.orange,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 16, height: 1.4),
                            ),
                          ),
                          if (isUserAdded)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    );
                  } else {
                    // Games and activities display
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isUserAdded
                                    ? Colors.blue.withOpacity(0.15)
                                    : _getCategoryColor().withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isUserAdded
                                        ? Colors.blue
                                        : _getCategoryColor(),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 16,
                                  height: 1.3,
                                ),
                              ),
                            ),
                            if (isUserAdded)
                              const Icon(
                                Icons.person,
                                size: 16,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    );
                  }
                },
              ),
            ),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: isPantomime
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        SwitchCardGameScreen(item: widget.item),
                  ),
                );
              },
              label: const Text('התחל משחק'),
              icon: const Icon(Icons.play_arrow),
              backgroundColor: Colors.green,
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  String _getContentTitle() {
    switch (widget.item.category) {
      case 'games':
        return 'מילים למשחק';
      case 'activities':
        return 'תוכן הפעילות';
      case 'riddles':
        return 'חידות';
      case 'texts':
        return 'תוכן';
      default:
        return 'תוכן';
    }
  }

  String _getContentDetail() {
    switch (widget.item.category) {
      case 'games':
        return 'הסבר משחק';
      case 'activities':
        return 'הסבר פעילות';
      default:
        return 'תוכן';
    }
  }

  Color _getCategoryColor() {
    switch (widget.item.category) {
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
