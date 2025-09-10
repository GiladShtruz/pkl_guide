import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/list_model.dart';
import '../services/lists_service.dart';

class ListEditScreen extends StatefulWidget {
  final ListModel list;

  const ListEditScreen({
    super.key,
    required this.list,
  });

  @override
  State<ListEditScreen> createState() => _ListEditScreenState();
}

class _ListEditScreenState extends State<ListEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late ListsService _listsService;
  bool _isEditingName = false;
  bool _isEditingDescription = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _listsService = context.read<ListsService>();
    _nameController = TextEditingController(text: widget.list.name);
    _descriptionController = TextEditingController(text: widget.list.detail ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    if (_nameController.text.isNotEmpty && !widget.list.isDefault) {
      await _listsService.updateListName(widget.list.id, _nameController.text);
      widget.list.name = _nameController.text;
      setState(() {
        _isEditingName = false;
        _hasChanges = true;
      });
    }
  }

  Future<void> _saveDescription() async {
    await _listsService.updateListDescription(
      widget.list.id,
      _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
    );
    widget.list.detail = _descriptionController.text.isNotEmpty
        ? _descriptionController.text
        : null;
    setState(() {
      _isEditingDescription = false;
      _hasChanges = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasChanges);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text('עריכת רשימה'),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _hasChanges),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'שם הרשימה',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          if (!widget.list.isDefault)
                            IconButton(
                              icon: Icon(
                                _isEditingName ? Icons.check : Icons.edit,
                                color: _isEditingName ? Colors.green : Colors.grey,
                              ),
                              onPressed: _isEditingName
                                  ? _saveName
                                  : () {
                                setState(() {
                                  _isEditingName = true;
                                });
                                // Focus on the text field
                                Future.delayed(const Duration(milliseconds: 100), () {
                                  FocusScope.of(context).requestFocus();
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isEditingName && !widget.list.isDefault)
                        TextField(
                          controller: _nameController,
                          autofocus: true,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: 'הכנס שם לרשימה',
                          ),
                          onSubmitted: (_) => _saveName(),
                        )
                      else
                        Text(
                          widget.list.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Description section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'תיאור הרשימה',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _isEditingDescription ? Icons.check : Icons.edit,
                              color: _isEditingDescription ? Colors.green : Colors.grey,
                            ),
                            onPressed: _isEditingDescription
                                ? _saveDescription
                                : () {
                              setState(() {
                                _isEditingDescription = true;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_isEditingDescription)
                        TextField(
                          controller: _descriptionController,
                          autofocus: true,
                          maxLines: 4,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'הוסף תיאור לרשימה (אופציונלי)',
                          ),
                          onSubmitted: (_) => _saveDescription(),
                        )
                      else
                        Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(minHeight: 50),
                          child: Text(
                            widget.list.detail?.isNotEmpty == true
                                ? widget.list.detail!
                                : 'אין תיאור',
                            style: TextStyle(
                              fontSize: 16,
                              color: widget.list.detail?.isNotEmpty == true
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // List info
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'מידע על הרשימה',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('מספר פריטים:'),
                          Text(
                            '${widget.list.itemIds.length}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('תאריך יצירה:'),
                          Text(
                            '${widget.list.createdAt.day}/${widget.list.createdAt.month}/${widget.list.createdAt.year}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      if (widget.list.lastModified != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('עדכון אחרון:'),
                            Text(
                              '${widget.list.lastModified!.day}/${widget.list.lastModified!.month}/${widget.list.lastModified!.year}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}