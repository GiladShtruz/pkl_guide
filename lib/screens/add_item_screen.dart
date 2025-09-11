// lib/screens/add_item_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';

class AddItemScreen extends StatefulWidget {
  final CategoryType category;

  const AddItemScreen({
    super.key,
    required this.category,
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  final _linkController = TextEditingController();
  final _classificationController = TextEditingController();
  final _contentController = TextEditingController();
  final List<String> _contentList = [];

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _linkController.dispose();
    _classificationController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addContent() {
    if (_contentController.text.isNotEmpty) {
      setState(() {
        _contentList.add(_contentController.text);
        _contentController.clear();
      });
    }
  }

  void _removeContent(int index) {
    setState(() {
      _contentList.removeAt(index);
    });
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final storageService = context.read<StorageService>();

      // Generate unique ID for user-created item
      final id = 'USER-${widget.category.name}-${DateTime.now().millisecondsSinceEpoch}';

      final newItem = ItemModel(
        id: id,
        originalTitle: _nameController.text,
        originalDetail: _detailController.text.isNotEmpty
            ? _detailController.text
            : null,
        link: _linkController.text.isNotEmpty
            ? _linkController.text
            : null,
        classification: _classificationController.text.isNotEmpty
            ? _classificationController.text
            : null,
        originalItems: [],
        userAddedItems: _contentList,
        category: widget.category.name,
        isUserCreated: true,
      );

      await storageService.addUserCreatedItem(newItem);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.category.displayName} חדש'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'שם',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'נא להזין שם';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _detailController,
                decoration: const InputDecoration(
                  labelText: 'תיאור (אופציונלי)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _linkController,
                decoration: const InputDecoration(
                  labelText: 'קישור (אופציונלי)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const SizedBox(height: 16),

              // Add classification field for games and activities
              if (widget.category == CategoryType.games ||
                  widget.category == CategoryType.activities) ...[
                TextFormField(
                  controller: _classificationController,
                  decoration: const InputDecoration(
                    labelText: 'סיווג (אופציונלי)',
                    border: OutlineInputBorder(),
                    hintText: 'לדוגמא: כיתה, בחוץ, שטח',
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                _getContentLabel(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _contentController,
                      decoration: InputDecoration(
                        hintText: _getContentHint(),
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _addContent(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _addContent,
                    icon: const Icon(Icons.add_circle),
                    iconSize: 32,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_contentList.isNotEmpty)
                Card(
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _contentList.length,
                    separatorBuilder: (context, index) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue[100],
                          child: Text('${index + 1}'),
                        ),
                        title: Text(_contentList[index]),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeContent(index),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveItem,
        label: const Text('שמור'),
        icon: const Icon(Icons.save),
      ),
    );
  }

  String _getContentLabel() {
    switch (widget.category) {
      case CategoryType.games:
        return 'מילים למשחק';
      case CategoryType.activities:
        return 'תוכן הפעילות';
      case CategoryType.riddles:
        return 'חידות';
      case CategoryType.texts:
        return 'קטעים';
    }
  }

  String _getContentHint() {
    switch (widget.category) {
      case CategoryType.games:
        return 'הוסף מילה...';
      case CategoryType.activities:
        return 'הוסף תוכן...';
      case CategoryType.riddles:
        return 'הוסף חידה...';
      case CategoryType.texts:
        return 'הוסף קטע...';
    }
  }
}