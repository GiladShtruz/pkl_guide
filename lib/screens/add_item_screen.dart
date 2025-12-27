// lib/screens/add_item_screen.dart
import 'package:flutter/material.dart';
import 'package:pkl_guide/models/element_model.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/item_model.dart';
import '../services/storage_service.dart';
import '../utils/content_helper.dart'; // ← הוסף

class AddItemScreen extends StatefulWidget {
  final CategoryType category;
  final String? classification;

  const AddItemScreen({
    super.key,
    required this.category,
    this.classification,
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
    final trimmedText = _contentController.text.trim();
    if (trimmedText.isNotEmpty) {
      setState(() {
        _contentList.add(ElementModel(trimmedText, true));
        _contentController.clear();
      });
    }
  }

  void _removeContent(int index) {
    setState(() {
      _contentList.removeAt(index);
    });
  }

  bool _hasContent() {
    final nameSet = _nameController.text.trim().isNotEmpty;
    final detailSet = _detailController.text.trim().isNotEmpty;
    final linkSet = _linkController.text.trim().isNotEmpty;
    final classificationSet = _classificationController.text.trim().isNotEmpty;
    final classificationSame = _classificationController.text.trim() != widget.classification;
    final equipmentSet = _equipmentController.text.trim().isNotEmpty;
    final listNotEmpty = _contentList.isNotEmpty;

    // הדפסת המצב של כל שדה בנפרד לטרמינל
    print("""
  --- בדיקת תוכן ---
  Name: $nameSet ('${_nameController.text}')
  Detail: $detailSet
  Link: $linkSet
  ClassificationSet: ${(classificationSet )}
  ClassificationSame: ${classificationSame}
  ClassificationAll: ${!(classificationSet || classificationSame)}
  Equipment: $equipmentSet
  List: $listNotEmpty
  ------------------
  """);

    return nameSet ||
        detailSet ||
        linkSet ||
        (classificationSet && classificationSame) ||
        equipmentSet ||
        listNotEmpty;
  }

  // bool _hasContent() {
  //   return _nameController.text.trim().isNotEmpty ||
  //       _detailController.text.trim().isNotEmpty ||
  //       _linkController.text.trim().isNotEmpty ||
  //       (_classificationController.text.trim().isNotEmpty || _classificationController.text.trim() == widget.classification) ||
  //       _equipmentController.text.trim().isNotEmpty ||
  //       _contentList.isNotEmpty;
  // }

  Future<bool> _confirmDiscard() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('יציאה ללא שמירה'),
        content: const Text('הזנת תוכן שלא נשמר. האם לצאת בלי לשמור?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ביטול'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('צא', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final storageService = context.read<StorageService>();

      final id = DateTime.now().millisecondsSinceEpoch % 100000000;

      final trimmedName = _nameController.text.trim();
      final trimmedDetail = _detailController.text.trim();
      final trimmedLink = _linkController.text.trim();
      final trimmedClassification = _classificationController.text.trim();
      final trimmedEquipment = _equipmentController.text.trim();

      final newItem = ItemModel(
        id: id,
        originalTitle: trimmedName,
        originalDetail: trimmedDetail.isNotEmpty ? trimmedDetail : null,
        originalLink: trimmedLink.isNotEmpty ? trimmedLink : null,
        originalClassification: trimmedClassification.isNotEmpty ? trimmedClassification : null,
        originalEquipment: trimmedEquipment.isNotEmpty ? trimmedEquipment : null,
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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        if (_hasContent()) {

          final shouldDiscard = await _confirmDiscard();
          if (shouldDiscard && mounted) {
            Navigator.pop(context);
          }
        } else {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(ContentHelper.getAddItemTitle(widget.category.name)),
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
                  if (value == null || value.trim().isEmpty) {
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
                "${ContentHelper.getContentSectionLabel(widget.category.name)} (אופציונלי)", // ← שינוי כאן
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
                        hintText: ContentHelper.getAddContentHint(widget.category.name), // ← שינוי כאן
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
                    color: Theme.of(context).colorScheme.primary,
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
      ),
    );
  }
}