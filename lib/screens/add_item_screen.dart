// lib/screens/add_item_screen.dart

import 'package:flutter/material.dart';
import 'package:pkl_guide/models/element_model.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';

class AddItemScreen extends StatefulWidget {
  final CategoryType category;
  final String? classification;

  const AddItemScreen({
    super.key,
    required this.category,
    this.classification
  });

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _detailController = TextEditingController();
  final _linkController = TextEditingController();
  late final _classificationController = TextEditingController(text: widget.classification ?? "");
  final _equipmentController = TextEditingController();
  final _contentController = TextEditingController();
  final List<ElementModel> _contentList = [];

  @override
  void dispose() {
    _nameController.dispose();
    _detailController.dispose();
    _linkController.dispose();
    _classificationController.dispose();
    _equipmentController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _addContent() {
    if (_contentController.text.isNotEmpty) {
      setState(() {
        _contentList.add(ElementModel(_contentController.text, true));
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
      final id = DateTime.now().millisecondsSinceEpoch % 100000000;

      final newItem = ItemModel(
        id: id,
        originalTitle: _nameController.text,
        originalDetail: _detailController.text.isNotEmpty
            ? _detailController.text
            : null,
        originalLink: _linkController.text.isNotEmpty
            ? _linkController.text
            : null,
        originalClassification: _classificationController.text.isNotEmpty
            ? _classificationController.text
            : null,
        originalEquipment: _equipmentController.text.isNotEmpty
            ? _equipmentController.text
            : null,
        elements: _contentList,

        category: widget.category.name,
        isUserCreated: true,
        lastAccessed: DateTime.now(),
      );

      await storageService.addItem(newItem);

      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getCategoryAddName()),
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
                textInputAction: TextInputAction.next,
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

              // Add equipment field
              TextFormField(
                controller: _equipmentController,
                decoration: const InputDecoration(
                  labelText: 'ציוד נדרש (אופציונלי)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.sports_soccer),
                  hintText: 'לדוגמה: כדור, חבל, נייר וצבעים',
                ),
                maxLines: 2,
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
                    hintText: 'לדוגמה: כיתה, בחוץ, שטח',
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Text(
                "${_getContentLabel()} (אופציונלי)",
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
                      onEditingComplete: _addContent,
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
                        title: Text(_contentList[_contentList.length - index - 1].text),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _removeContent(_contentList.length - index - 1),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
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

  String _getCategoryAddName() {
    switch (widget.category) {
      case CategoryType.games:
        return 'משחק חדש';
      case CategoryType.activities:
        return 'פעילות חדשה';
      case CategoryType.riddles:
        return 'חידה חדשה';
      case CategoryType.texts:
        return 'קטע חדש';
    }
  }

}