import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'game_play.dart';



// מסך פנטומימה מיוחד
class PantomimeScreen extends StatelessWidget {
  final Game game;

  const PantomimeScreen({Key? key, required this.game}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('🎭 פנטומימה 🎭'),
        backgroundColor: Colors.red,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.theater_comedy,
                size: 120,
                color: Colors.red,
              ),
              const SizedBox(height: 32),
              const Text(
                'פנטומימה',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.2),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  game.description.isNotEmpty
                      ? game.description
                      : 'משחק פנטומימה קלאסי - הצג מילים ומושגים ללא דיבור!',
                  style: const TextStyle(
                    fontSize: 18,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// מסך משחק פנטומימה עם טיימר
class PantomimeGameScreen extends StatefulWidget {
  final WordGame wordGame;

  const PantomimeGameScreen({Key? key, required this.wordGame}) : super(key: key);

  @override
  State<PantomimeGameScreen> createState() => _PantomimeGameScreenState();
}

class _PantomimeGameScreenState extends State<PantomimeGameScreen> with TickerProviderStateMixin {
  late AnimationController _timerController;
  late AnimationController _cardController;
  late List<String> _words;
  int _currentWordIndex = 0;
  int _successCount = 0;
  bool _isPlaying = false;
  int _remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.wordGame.words)..shuffle();

    _timerController = AnimationController(
      duration: const Duration(seconds: 60),
      vsync: this,
    );

    _cardController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _timerController.addListener(() {
      setState(() {
        _remainingSeconds = (60 - (_timerController.value * 60)).round();
      });
    });

    _timerController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _endGame();
      }
    });
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _successCount = 0;
      _currentWordIndex = 0;
      _words.shuffle();
    });
    _timerController.forward(from: 0);
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
    });
    _timerController.stop();

    // הצג דיאלוג סיכום
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('הזמן נגמר!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'הצלחתם להציג $_successCount מילים!',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetGame();
            },
            child: const Text('שחק שוב'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('יציאה'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _remainingSeconds = 60;
      _successCount = 0;
      _currentWordIndex = 0;
      _isPlaying = false;
    });
    _timerController.reset();
  }

  void _nextWord(bool success) {
    if (!_isPlaying) return;

    if (success) {
      setState(() {
        _successCount++;
      });
      // אנימציה ירוקה
      _showFeedback(true);
    } else {
      // אנימציה אדומה
      _showFeedback(false);
    }

    setState(() {
      _currentWordIndex = (_currentWordIndex + 1) % _words.length;
    });
  }

  void _showFeedback(bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? '✓ הצלחה!' : '← עובר'),
        backgroundColor: success ? Colors.green : Colors.orange,
        duration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('פנטומימה'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // מונה הצלחות
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 32),
                  const SizedBox(width: 8),
                  Text(
                    'הצלחות: $_successCount',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // כרטיס המילה
            Expanded(
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  if (_isPlaying) {
                    if (details.primaryVelocity! > 0) {
                      // החלקה ימינה - הצלחה
                      _nextWord(true);
                    } else if (details.primaryVelocity! < 0) {
                      // החלקה שמאלה - לא הצליח
                      _nextWord(false);
                    }
                  }
                },
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isPlaying
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _words[_currentWordIndex],
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.swipe_left, color: Colors.orange.shade300, size: 32),
                            const SizedBox(width: 16),
                            const Text(
                              'החלק',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            const SizedBox(width: 16),
                            Icon(Icons.swipe_right, color: Colors.green.shade300, size: 32),
                          ],
                        ),
                      ],
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.theater_comedy,
                          size: 80,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.wordGame.description,
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // טיימר
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
                  Text(
                    '${(_remainingSeconds ~/ 60).toString().padLeft(2, '0')}:${(_remainingSeconds % 60).toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _remainingSeconds <= 10 ? Colors.red : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: _isPlaying ? 1 - _timerController.value : 0,
                    backgroundColor: Colors.grey.shade300,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _remainingSeconds <= 10 ? Colors.red : Colors.blue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // כפתור Play/Stop
            ElevatedButton.icon(
              onPressed: _isPlaying ? _endGame : _startGame,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 32),
              label: Text(
                _isPlaying ? 'עצור' : 'התחל',
                style: const TextStyle(fontSize: 20),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _isPlaying ? Colors.orange : Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timerController.dispose();
    _cardController.dispose();
    super.dispose();
  }
}