import 'package:flutter/material.dart';

class UpdateDialog extends StatelessWidget {
  final VoidCallback onConfirm;
  final VoidCallback onDecline;

  const UpdateDialog({
    super.key,
    required this.onConfirm,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.update, color: Colors.orange),
          SizedBox(width: 8),
          Text('עדכון זמין'),
        ],
      ),
      content: const Text(
        'נוספו נתונים חדשים לאפליקציה.\nהאם לטעון נתונים אלו?',
        style: TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDecline();
          },
          child: const Text('לא כעת'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
          ),
          child: const Text('עדכן'),
        ),
      ],
    );
  }
}

