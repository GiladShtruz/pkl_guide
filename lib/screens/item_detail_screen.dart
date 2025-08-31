import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../screens/edit_item_screen.dart';
import '../screens/pantomime_game_screen.dart';

class ItemDetailScreen extends StatefulWidget {
  final ItemModel item;

  const ItemDetailScreen({
    super.key,
    required this.item,
  });

  @override
  State<ItemDetailScreen> createState() => _ItemDetailScreenState();
}

class _ItemDetailScreenState extends State<ItemDetailScreen> {
  late bool _isFavorite;

  @override
  void initState() {
    super.initState();
    final storageService = context.read<StorageService>();
    _isFavorite = storageService.isFavorite(widget.item.id);
    storageService.updateItemAccess(widget.item.id);
  }

  void _toggleFavorite() async {
    final storageService = context.read<StorageService>();
    await storageService.toggleFavorite(widget.item.id);
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _openLink() async {
    if (widget.item.link != null && widget.item.link!.isNotEmpty) {
      final uri = Uri.parse(widget.item.link!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
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
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.red : null,
            ),
            onPressed: _toggleFavorite,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.item.description != null &&
                  widget.item.description!.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'תיאור',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.item.description!,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              if (widget.item.content.isNotEmpty) ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getContentTitle(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.item.content.map((content) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(fontSize: 16)),
                              Expanded(
                                child: Text(
                                  content,
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                ),
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
                    builder: (context) => PantomimeGameScreen(item: widget.item),
                  ),
                );
              },
              label: const Text('התחל משחק'),
              icon: const Icon(Icons.play_arrow),
              backgroundColor: Colors.green,
            )
          : null,
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
}



