import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  void _launchPrivacyPolicy() async {
    final uri = Uri.parse('https://example.com/privacy-policy'); // Replace with actual URL
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('אודות פק״ל למדריך'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'גרסה 1.0.0',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'אפליקציה לשמירת ושימוש במשחקים, חידות, פעילויות וקטעים למדריכים.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Text(
              'האפליקציה מאפשרת:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              '• ארגון תכנים לפי קטגוריות\n'
              '• הוספת תכנים אישיים\n'
              '• סימון מועדפים\n'
              '• חיפוש מהיר\n'
              '• משחק פנטומימה אינטראקטיבי\n'
              '• ייבוא וייצוא תכנים',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '© 2024 כל הזכויות שמורות',
              style: TextStyle(fontSize: 12, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _launchPrivacyPolicy,
          child: const Text('מדיניות פרטיות'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('סגור'),
        ),
      ],
    );
  }
}

