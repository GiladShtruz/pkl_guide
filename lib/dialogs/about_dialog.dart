import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  void _launchPrivacyPolicy() async {
    final uri = Uri.parse('https://drive.google.com/file/d/1_qDY-4Oit85Vz5225CNzrd7VbGc3N_qg/view?usp=sharing'); // Replace with actual URL
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
              'שלום לכולם, אני גילעד שטרוזמן ואני פיתחתי את האפליקציה שלפניכם.\nאפליקציה לשמירת ושימוש במשחקים, חידות, פעילויות וקטעים למדריכים.',
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
              '• מועדפים ורשימות אישיות\n'
              '• חיפוש מהיר\n'
              '• משחקים ייחודיים אינטראקטיביים\n'
              '• ייבוא וייצוא תכנים',
              style: TextStyle(fontSize: 14),
            ),
            // const SizedBox(height: 16),
            // const Divider(),
            // const SizedBox(height: 8),
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

