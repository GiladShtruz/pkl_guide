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
    return AboutDialog(
      children: [
        const Text(
          'שלום, אני גילעד שטרוזמן ואני מפתח האפליקציה שלפניכם.\n'
              'האפליקציה מיועדת לכל המדריכים באשר הם. כאן תוכלו למצוא מאגר עשיר של חידות, משחקים והפעלות עבור פעולות שאתם מעבירים לחניכים שלכם.',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        const Text(
          'בין האפשרויות שהאפליקציה מציעה:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '• עריכה ויצירה של תכנים קיימים וחדשים\n'
              '• סימון תכנים מועדפים לנגישות מהירה\n'
              '• יצירת רשימות מותאמות אישית ממספר תכנים\n'
              '• חיפוש מהיר ונוח\n'
              '• משחקים אינטראקטיביים ייחודיים\n'
              '• ייבוא וייצוא תכנים – להעברה נוחה בין מכשירים או לשיתוף עם חברים',
          style: TextStyle(fontSize: 14),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _launchPrivacyPolicy,
          child: const Text('Privacy Policy'),
        ),
      ],
    );
  }
}

