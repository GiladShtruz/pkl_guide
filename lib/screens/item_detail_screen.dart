import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../services/lists_service.dart';
import '../screens/edit_item_screen.dart';
import '../screens/pantomime_game_screen.dart';
import '../dialogs/add_to_lists_dialog.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({super.key, required this.item});

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late ListsService _listsService;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    final storageService = context.read<StorageService>();

    // Update access count
    storageService.updateItemAccess(widget.item.id);
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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(widget.item.name),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              // detail card
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
                              Text(
                              _getContentDetail(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            widget.item.detail!,
                            // style: const TextStyle(fontSize: 16),
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

              // Content section - different display based on category
              if (widget.item.items.isNotEmpty) ...[
                if (widget.item.category == 'riddles') ...[
                  // Riddles display with special design
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'חידות',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${widget.item.items.length} חידות',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Simple list of riddles with special design
                      ...widget.item.items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final riddle = entry.value;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Riddle number
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: Colors.orange,
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
                              // Riddle text
                              Expanded(
                                child: Text(
                                  riddle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ] else if ((widget.item.category == 'games' ||
                        widget.item.category == 'activities') ) ...[
                  // Scrollable list for games and activities with many items
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _getContentTitle(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
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
                                  '${widget.item.items.length} פריטים',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _getCategoryColor(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Scrollable list container
                          Container(
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 1,
                              ),
                            ),
                            child: Scrollbar(
                              thumbVisibility: true,
                              child: ListView.separated(
                                padding: const EdgeInsets.all(12),
                                itemCount: widget.item.items.length,
                                separatorBuilder: (context, index) =>
                                    Divider(color: Colors.grey[300], height: 1),
                                itemBuilder: (context, index) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        // Item number with colored background
                                        Container(
                                          width: 36,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: _getCategoryColor()
                                                .withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${index + 1}',
                                              style: TextStyle(
                                                color: _getCategoryColor(),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Item text
                                        Expanded(
                                          child: Text(
                                            widget.item.items[index],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              height: 1.3,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ]
              ],
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: isPantomime
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PantomimeGameScreen(item: widget.item),
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


//  Color _getCategoryColor() {
//     switch (widget.item.category) {
//       case 'games':
//         return Colors.green;
//       case 'activities':
//         return Colors.blue;
//       case 'riddles':
//         return Colors.purple;
//       case 'texts':
//         return Colors.orange;
//       default:
//         return Colors.grey;
//     }
//   }