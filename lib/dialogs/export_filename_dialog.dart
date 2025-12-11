import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ExportFilenameDialog extends StatefulWidget {
  final String? suggestedName;

  const ExportFilenameDialog({
    super.key,
    this.suggestedName,
  });

  @override
  State<ExportFilenameDialog> createState() => _ExportFilenameDialogState();
}

class _ExportFilenameDialogState extends State<ExportFilenameDialog> {
  late TextEditingController _controller;
  String _errorMessage = '';

  // Characters that are not allowed in filenames
  static const invalidChars = r'<>:"/\|?*';

  @override
  void initState() {
    super.initState();
    final cleanName = widget.suggestedName != null
        ? _sanitizeFilename(widget.suggestedName!)
        : '';
    _controller = TextEditingController(text: cleanName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _sanitizeFilename(String filename) {
    // Remove invalid characters
    String cleaned = filename;
    for (int i = 0; i < invalidChars.length; i++) {
      cleaned = cleaned.replaceAll(invalidChars[i], '');
    }
    // Remove leading/trailing spaces and dots
    cleaned = cleaned.trim().replaceAll(RegExp(r'^\.+|\.+$'), '');
    // Replace multiple spaces with single space
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');
    return cleaned;
  }

  bool _validateFilename(String filename) {
    if (filename.trim().isEmpty) {
      setState(() {
        _errorMessage = 'שם הקובץ לא יכול להיות ריק';
      });
      return false;
    }

    // Check for invalid characters
    for (int i = 0; i < invalidChars.length; i++) {
      if (filename.contains(invalidChars[i])) {
        setState(() {
          _errorMessage = 'שם הקובץ מכיל תווים לא חוקיים';
        });
        return false;
      }
    }

    // Check if it starts with a dot (hidden file on Unix)
    if (filename.startsWith('.')) {
      setState(() {
        _errorMessage = 'שם הקובץ לא יכול להתחיל בנקודה';
      });
      return false;
    }

    setState(() {
      _errorMessage = '';
    });
    return true;
  }

  void _onTextChanged(String value) {
    _validateFilename(value);
  }

  void _onConfirm() {
    final filename = _controller.text;
    if (_validateFilename(filename)) {
      Navigator.pop(context, filename);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title
            const Text(
              'שם הקובץ',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'בחר שם לקובץ הייצוא',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Text field
            TextField(
              controller: _controller,
              autofocus: true,
              textAlign: TextAlign.right,
              decoration: InputDecoration(
                labelText: 'שם הקובץ',
                hintText: 'לדוגמה: הרשימות שלי',
                errorText: _errorMessage.isNotEmpty ? _errorMessage : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixText: '.json',
                suffixStyle: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.deny(
                  RegExp('[$invalidChars]'),
                ),
              ],
              onChanged: _onTextChanged,
              onSubmitted: (_) => _onConfirm(),
            ),

            const SizedBox(height: 8),

            // Info text
            Text(
              'התווים הבאים אינם מותרים: < > : " / \\ | ? *',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'ביטול',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'אישור',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
