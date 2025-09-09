import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:vibration/vibration.dart';
// import 'package:flutter_swipable_stack/flutter_swipable_stack.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:swipable_stack/swipable_stack.dart';
import '../models/item_model.dart';

class PantomimeGameScreen extends StatefulWidget {
  final ItemModel item;

  const PantomimeGameScreen({
    super.key,
    required this.item,
  });

  @override
  State<PantomimeGameScreen> createState() => _PantomimeGameScreenState();
}

class _PantomimeGameScreenState extends State<PantomimeGameScreen>
    with TickerProviderStateMixin {
  late SwipableStackController _controller;
  late List<String> _words;
  late List<String> _usedWords;
  int _currentTeam = 1;
  int _team1Score = 0;
  int _team2Score = 0;
  int _currentRoundScore = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  int _remainingSeconds = 60;
  int _totalSeconds = 60;
  Timer? _timer;
  bool _wordsRepeating = false;
  late AnimationController _timerAnimationController;
  late Animation<double> _timerAnimation;
  bool _canSwipe = false;

  @override
  void initState() {
    super.initState();
    _controller = SwipableStackController();
    _words = List.from(widget.item.content);
    _usedWords = [];
    _shuffleWords();

    _timerAnimationController = AnimationController(
      duration: Duration(seconds: _totalSeconds),
      vsync: this,
    );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_timerAnimationController);

    _checkShowRules();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _checkShowRules() async {
    final prefs = await SharedPreferences.getInstance();
    final dontShowAgain = prefs.getBool('pantomime_rules_dont_show') ?? false;

    if (!dontShowAgain && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showRulesDialog(isFirstTime: true);
      });
    }
  }

  void _showRulesDialog({bool isFirstTime = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('חוקי המשחק - פנטומימה'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'המשחק מיועד לשתי קבוצות.\n\n'
                    'כיצד לשחק:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. בחר איזו קבוצה משחקת כעת\n'
                    '2. לחץ על כפתור ההפעלה להתחלת הסיבוב\n'
                    '3. שחקן מהקבוצה מציג את המילה בפנטומימה\n'
                    '4. החלק ימינה - אם הקבוצה ניחשה נכון ✓\n'
                    '5. החלק שמאלה - לעבור למילה הבאה ✗\n'
                    '6. כל סיבוב נמשך דקה\n\n'
                    'הקבוצה עם הכי הרבה ניחושים מנצחת!',
              ),
            ],
          ),
        ),
        actions: [
          if (isFirstTime)
            Row(
              children: [
                Checkbox(
                  value: false,
                  onChanged: (value) async {
                    if (value == true) {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.setBool('pantomime_rules_dont_show', true);
                    }
                    Navigator.pop(context);
                  },
                ),
                const Text('אל תציג שוב'),
              ],
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('הבנתי'),
          ),
        ],
      ),
    );
  }

  void _showEditScoreDialog(int team) {
    final controller = TextEditingController(
        text: team == 1 ? _team1Score.toString() : _team2Score.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('עריכת ניקוד - קבוצה $team'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'ניקוד',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ביטול'),
          ),
          ElevatedButton(
            onPressed: () {
              final newScore = int.tryParse(controller.text) ?? 0;
              setState(() {
                if (team == 1) {
                  _team1Score = newScore;
                } else {
                  _team2Score = newScore;
                }
              });
              Navigator.pop(context);
            },
            child: const Text('שמור'),
          ),
        ],
      ),
    );
  }

  void _shuffleWords() {
    _words.shuffle(Random());
  }

  void _startTimer() {
    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _canSwipe = true;
      _remainingSeconds = _totalSeconds;
      _currentRoundScore = 0;
    });

    _timerAnimationController.forward(from: 0.0);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isPaused) {
        setState(() {
          _remainingSeconds--;
        });

        if (_remainingSeconds <= 0) {
          _endRound();
        }
      }
    });
  }

  void _pauseTimer() {
    setState(() {
      _isPaused = !_isPaused;
    });

    if (_isPaused) {
      _timerAnimationController.stop();
    } else {
      _timerAnimationController.forward();
    }
  }

  void _stopAndReset() {
    _timer?.cancel();
    _timerAnimationController.stop();
    _timerAnimationController.reset();

    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _canSwipe = false;
      _remainingSeconds = _totalSeconds;
      _currentRoundScore = 0;
      _controller.currentIndex = 0;
    });

    _shuffleWords();
  }

  void _endRound() {
    _timer?.cancel();
    _timerAnimationController.stop();

    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _canSwipe = false;
      if (_currentTeam == 1) {
        _team1Score += _currentRoundScore;
      } else {
        _team2Score += _currentRoundScore;
      }
    });

    // Vibrate and play sound
    // if (Vibration.hasVibrator() != null) {
    //   Vibration.vibrate(duration: 500);
    // }

    _showRoundSummary();
  }

  void _showRoundSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('סיום סיבוב - קבוצה $_currentTeam'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ניחשתם $_currentRoundScore מילים!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('ניקוד כולל: $_team1Score - $_team2Score'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentTeam = _currentTeam == 1 ? 2 : 1;
                _controller.currentIndex = 0;
              });
            },
            child: const Text('אישור'),
          ),
        ],
      ),
    );
  }

  void _handleSwipe(SwipeDirection direction) {
    if (!_isPlaying || _isPaused || !_canSwipe) return;

    if (direction == SwipeDirection.right) {
      setState(() {
        _currentRoundScore++;
      });

      // Success animation feedback
      HapticFeedback.lightImpact();
    }

    // Mark word as used
    if (_controller.currentIndex < _words.length) {
      _usedWords.add(_words[_controller.currentIndex]);
    }

    // Check if need to recycle words
    if (_controller.currentIndex >= _words.length - 1) {
      if (!_wordsRepeating) {
        setState(() {
          _wordsRepeating = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('המילים נגמרו - מתחילים מחזור חדש'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      // Reshuffle and reset
      _shuffleWords();
      setState(() {
        _controller.currentIndex = 0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('פנטומימה'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showRulesDialog(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Team scores
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  GestureDetector(
                    onTap: () => _showEditScoreDialog(1),
                    child: _buildTeamScore(1, _team1Score),
                  ),
                  GestureDetector(
                    onTap: () => _showEditScoreDialog(2),
                    child: _buildTeamScore(2, _team2Score),
                  ),
                ],
              ),
            ),

            // Current round score
            if (_isPlaying)
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'סיבוב נוכחי: $_currentRoundScore',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            // Cards area
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 350,
                  height: 500,
                  child: SwipableStack(
                    controller: _controller,
                    stackClipBehaviour: Clip.none,
                    allowVerticalSwipe: false,
                    onSwipeCompleted: _canSwipe ? (index, direction) {
                      _handleSwipe(direction);
                    } : null,
                    horizontalSwipeThreshold: 0.8,
                    detectableSwipeDirections: _canSwipe ? const {
                      SwipeDirection.left,
                      SwipeDirection.right,
                    } : const {},
                    itemCount: _words.length,
                    builder: (context, properties) {
                      final itemIndex = properties.index % _words.length;
                      final word = _words[itemIndex];

                      return Stack(
                        children: [
                          Card(
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.purple[400]!,
                                    Colors.blue[600]!,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  word,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),

                          // Swipe indicators - FIXED
                          if (properties.swipeProgress != 0 && _canSwipe)
                            Positioned.fill(
                              child: AnimatedOpacity(
                                duration: const Duration(milliseconds: 200),
                                opacity: min(properties.swipeProgress.abs(), 0.5),
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: properties.swipeProgress > 0  // Positive = right swipe
                                        ? Colors.green.withOpacity(0.5)  // Right = Success
                                        : Colors.red.withOpacity(0.5),   // Left = Skip
                                  ),
                                  child: Center(
                                    child: Icon(
                                      properties.swipeProgress > 0  // Positive = right swipe
                                          ? Icons.check_circle     // Right swipe = ✓
                                          : Icons.cancel,          // Left swipe = ✗
                                      size: 100,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),

                        ],
                      );
                    },
                  ),
                ),
              ),
            ),


            // Timer and controls
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Timer display
                  if (_isPlaying)
                    Column(
                      children: [
                        AnimatedBuilder(
                          animation: _timerAnimation,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                SizedBox(
                                  width: 80,
                                  height: 80,
                                  child: CircularProgressIndicator(
                                    value: _remainingSeconds / _totalSeconds,
                                    strokeWidth: 8,
                                    backgroundColor: Colors.grey[700],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _remainingSeconds <= 10
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                  ),
                                ),
                                Text(
                                  '$_remainingSeconds',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: _remainingSeconds <= 10
                                        ? Colors.red
                                        : Colors.white,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 20),
                        // Control buttons during game
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              onPressed: _pauseTimer,
                              icon: Icon(
                                _isPaused ? Icons.play_arrow : Icons.pause,
                                size: 32,
                              ),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.orange,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: _stopAndReset,
                              icon: const Icon(Icons.stop, size: 32),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                  // Play button or team selector
                  if (!_isPlaying)
                    Column(
                      children: [
                        Text(
                          'בחר קבוצה:',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[300],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildTeamSelector(1),
                            const SizedBox(width: 20),
                            _buildTeamSelector(2),
                          ],
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _startTimer,
                          icon: const Icon(Icons.play_arrow, size: 32),
                          label: const Text(
                            'התחל סיבוב',
                            style: TextStyle(fontSize: 20),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 15,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamScore(int team, int score) {
    final isActive = _currentTeam == team; // Always show which team is active

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
        border: isActive
            ? Border.all(color: Colors.blue[300]!, width: 2)
            : null,
        boxShadow: isActive && _isPlaying
            ? [BoxShadow(
          color: Colors.blue.withOpacity(0.4),
          blurRadius: 8,
          spreadRadius: 2,
        )]
            : null,
      ),
      child: Column(
        children: [
          Text(
            'קבוצה $team',
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[300],
              fontSize: 14,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '$score',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isActive && _isPlaying)
            Icon(
              Icons.play_arrow,
              size: 16,
              color: Colors.white,
            ),
          if (!_isPlaying)
            Icon(
              Icons.edit,
              size: 16,
              color: Colors.grey[400],
            ),
        ],
      ),
    );
  }

  Widget _buildTeamSelector(int team) {
    final isSelected = _currentTeam == team;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTeam = team;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(15),
          border: isSelected
              ? Border.all(color: Colors.blue[300]!, width: 2)
              : null,
        ),
        child: Text(
          'קבוצה $team',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[400],
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}