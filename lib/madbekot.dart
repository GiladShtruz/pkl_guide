import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'game_play.dart';

class StickersGameScreen extends StatefulWidget {
  final WordGame wordGame;

  const StickersGameScreen({Key? key, required this.wordGame}) : super(key: key);

  @override
  State<StickersGameScreen> createState() => _StickersGameScreenState();
}

class _StickersGameScreenState extends State<StickersGameScreen> {
  late List<String> _words;
  int _currentWordIndex = 0;

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.wordGame.words)..shuffle();
  }

  void _nextWord() {
    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _words.length;
    });
  }

  void _previousWord() {
    setState(() {
      _currentWordIndex = (_currentWordIndex - 1 + _words.length) % _words.length;
    });
  }

  void _shuffleWords() {
    setState(() {
      _words.shuffle();
      _currentWordIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('מדבקות'),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.shuffle),
            onPressed: _shuffleWords,
            tooltip: 'ערבב מילים',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // הוראות המשחק
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.sticky_note_2,
                    size: 48,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.wordGame.description,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // מונה מילים
            Text(
              'מילה ${_currentWordIndex + 1} מתוך ${_words.length}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            // כרטיס המילה - מעוצב כמו מדבקה
            Expanded(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // צל של המדבקה
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    transform: Matrix4.translationValues(4, 4, 0),
                  ),
                  // המדבקה עצמה
                  Container(
                    width: double.infinity,
                    height: 300,
                    decoration: BoxDecoration(
                      color: Colors.yellow.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.orange.shade300,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.orange.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // קווי נייר
                        Positioned.fill(
                          child: CustomPaint(
                            painter: LinedPaperPainter(),
                          ),
                        ),
                        // הטקסט
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _words[_currentWordIndex],
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: 'Heebo',
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        // פינה מקופלת
                        Positioned(
                          top: 0,
                          right: 0,
                          child: CustomPaint(
                            size: const Size(40, 40),
                            painter: FoldedCornerPainter(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // כפתורי ניווט
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  onPressed: _previousWord,
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.arrow_back),
                  heroTag: 'prev',
                ),
                FloatingActionButton.extended(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('טיפ למשחק'),
                        content: const Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('1. הדבק את המילה על הגב של החבר'),
                            SizedBox(height: 8),
                            Text('2. שאר החברים נותנים רמזים'),
                            SizedBox(height: 8),
                            Text('3. החבר צריך לנחש מה המילה'),
                            SizedBox(height: 8),
                            Text('4. אסור להגיד את המילה עצמה!'),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('הבנתי'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.help_outline),
                  label: const Text('איך משחקים?'),
                  backgroundColor: Colors.blue,
                  heroTag: 'help',
                ),
                FloatingActionButton(
                  onPressed: _nextWord,
                  backgroundColor: Colors.orange,
                  child: const Icon(Icons.arrow_forward),
                  heroTag: 'next',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// צייר קווים על המדבקה
class LinedPaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.shade200.withOpacity(0.3)
      ..strokeWidth = 1;

    for (double i = 30; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(20, i),
        Offset(size.width - 20, i),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// צייר פינה מקופלת
class FoldedCornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width - 40, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, 40)
      ..close();

    final paint = Paint()
      ..color = Colors.orange.shade200
      ..style = PaintingStyle.fill;

    canvas.drawPath(path, paint);

    final shadowPath = Path()
      ..moveTo(size.width - 40, 0)
      ..lineTo(size.width - 40, 40)
      ..lineTo(size.width, 40)
      ..close();

    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    canvas.drawPath(shadowPath, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}