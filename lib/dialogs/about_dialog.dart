import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';

class AboutDialogWidget extends StatelessWidget {
  const AboutDialogWidget({super.key});

  void _launchPrivacyPolicy() async {
    final uri = Uri.parse('https://drive.google.com/file/d/1_qDY-4Oit85Vz5225CNzrd7VbGc3N_qg/view?usp=sharing');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context, listen: false);

    // טקסט ברירת מחדל במקרה שאין טקסט ב-storage
    const defaultAboutText =
        'שלום, אני גילעד שטרוזמן ואני מפתח האפליקציה שלפניכם.\n'
        'האפליקציה מיועדת לכל המדריכים באשר הם. כאן תוכלו למצוא מאגר עשיר של חידות, משחקים והפעלות עבור פעולות שאתם מעבירים לחניכים שלכם.\n\n'
        'בין האפשרויות שהאפליקציה מציעה:\n'
        '• עריכה ויצירה של תכנים קיימים וחדשים\n'
        '• סימון תכנים מועדפים לנגישות מהירה\n'
        '• יצירת רשימות מותאמות אישית ממספר תכנים\n'
        '• חיפוש מהיר ונוח\n'
        '• משחקים אינטראקטיביים ייחודיים\n'
        '• ייבוא וייצוא תכנים – להעברה נוחה בין מכשירים או לשיתוף עם חברים';

    final aboutText = storageService.getAboutText() ?? defaultAboutText;

    return AboutDialog(
      children: [
        Text(
          aboutText,
          style: const TextStyle(fontSize: 14),
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