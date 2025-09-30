import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:vibration/vibration.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:vibration/vibration.dart';
import '../models/item_model.dart';

class SwitchCardGameScreen extends StatefulWidget {
  final ItemModel item;

  const SwitchCardGameScreen({super.key, required this.item});

  @override
  State<SwitchCardGameScreen> createState() => _SwitchCardGameScreenState();
}

class _SwitchCardGameScreenState extends State<SwitchCardGameScreen>
    with TickerProviderStateMixin {
  late CardSwiperController _controller;
  late List<String> _words;
  late List<String> _usedWords;
  int _currentTeam = 1;
  int _team1Score = 0;
  int _team2Score = 0;
  late List<String> _availableWords;
  late List<String> _allUsedWords;
  int _currentRoundScore = 0;
  bool _isPlaying = false;
  bool _isPaused = false;
  int _remainingSeconds = 10;
  int _totalSeconds = 60;
  Timer? _timer;

  late AnimationController _timerAnimationController;
  late Animation<double> _timerAnimation;
  List<String> _correctWords = [];
  List<String> _skippedWords = [];
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _controller = CardSwiperController();
    _words = List.from(widget.item.strElements);
    _usedWords = [];
    _availableWords = List.from(widget.item.strElements);
    _allUsedWords = [];
    _shuffleWords();

    _timerAnimationController = AnimationController(
      duration: Duration(seconds: _totalSeconds),
      vsync: this,
    );

    _timerAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(_timerAnimationController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timerAnimationController.dispose();
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _showRulesDialog({bool isFirstTime = false}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: Text('איך משחקים:'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.item.detail ?? "",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(widget.item.userDetail ?? ""),
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
                          await prefs.setBool(
                              'card_game_rules_dont_show', true);
                        }
                      },
                    ),
                    const Text('אל תציג שוב'),
                  ],
                ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('הבנתי'),
                ),
              ),
            ],
          ),
    );
  }

  void _showEditScoreDialog(int team) {
    final controller = TextEditingController(
      text: team == 1 ? _team1Score.toString() : _team2Score.toString(),
    );

    showDialog(
      context: context,
      builder: (context) =>
          AlertDialog(
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

  void _startRound() {
    _prepareWordsForNewRound();

    setState(() {
      _isPlaying = true;
      _isPaused = false;
      _remainingSeconds = _totalSeconds;
      _currentRoundScore = 0;
      _correctWords = [];
      _skippedWords = [];
      _usedWords = [];
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

  void _prepareWordsForNewRound() {
    setState(() {
      if (_availableWords.isEmpty) {
        _availableWords = List.from(widget.item.strElements);
        _allUsedWords.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('כל המילים נוגנו - מתחילים מחזור חדש'),
            duration: Duration(seconds: 2),
          ),
        );
      }

      _words = List.from(_availableWords);

      if (_words.isEmpty) {
        _words = List.from(widget.item.strElements);
        _availableWords = List.from(widget.item.strElements);
        _allUsedWords.clear();
      }

      _shuffleWords();
    });
  }

  // פונקציה חדשה לטיפול בסיום הכרטיסים באמצע משחק
  void _reloadCardsIfNeeded() {
    // בודק אם נגמרו הכרטיסים הזמינים
    if (_availableWords.isEmpty) {
      setState(() {
        // מאתחל את כל המילים מחדש
        _availableWords = List.from(widget.item.strElements);
        _allUsedWords.clear();
        _words = List.from(_availableWords);
        _shuffleWords();
      });

      // הודעה למשתמש
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('כל המילים נגמרו - מתחיל מחדש עם כל המילים!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
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
    _audioPlayer.stop();

    setState(() {
      _isPlaying = false;
      _isPaused = false;
      _remainingSeconds = _totalSeconds;
      _currentRoundScore = 0;

      for (String word in _words) {
        if (!_usedWords.contains(word) && !_availableWords.contains(word)) {
          _availableWords.add(word);
        }
      }

      for (String word in _usedWords) {
        _allUsedWords.remove(word);
      }
    });

    _shuffleWords();
  }

  void _endRound() async {
    _timer?.cancel();
    _timerAnimationController.stop();

    setState(() {
      _isPlaying = false;
      _isPaused = false;
      if (_currentTeam == 1) {
        _team1Score += _currentRoundScore;
      } else {
        _team2Score += _currentRoundScore;
      }
    });

    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 500);
    }

    await _audioPlayer.play(AssetSource('sounds/timer_end.mp3'));
    _showRoundSummary();
  }

  void _showRoundSummary() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          AlertDialog(
            title: Text('סיום סיבוב - קבוצה $_currentTeam'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.green, size: 28),
                        const SizedBox(width: 8),
                        Text(
                          'קיבלת $_currentRoundScore נקודות!',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    'ניקוד כולל: $_team1Score - $_team2Score',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),
                  Text(
                    'מילים שנותרו במשחק: ${_availableWords.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  if (_correctWords.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(
                            Icons.check_circle, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'מילים שניחשת (${_correctWords.length}):',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _correctWords.map((word) =>
                              Chip(
                                label: Text(
                                  word,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.green.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                materialTapTargetSize: MaterialTapTargetSize
                                    .shrinkWrap,
                              )).toList(),
                        ),
                      ),
                    ),
                  ],

                  if (_skippedWords.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                            Icons.skip_next, color: Colors.orange, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'מילים שדילגת (${_skippedWords.length}):',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _skippedWords.map((word) =>
                              Chip(
                                label: Text(
                                  word,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: Colors.orange.withOpacity(0.2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8),
                                materialTapTargetSize: MaterialTapTargetSize
                                    .shrinkWrap,
                              )).toList(),
                        ),
                      ),
                    ),
                  ],

                  if (_correctWords.isEmpty && _skippedWords.isEmpty) ...[
                    const SizedBox(height: 12),
                    const Center(
                      child: Text(
                        'לא שיחקת בסיבוב זה',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {
                    _currentTeam = _currentTeam == 1 ? 2 : 1;
                    _correctWords.clear();
                    _skippedWords.clear();
                  });
                },
                child: const Text('אישור'),
              ),
            ],
          ),
    );
  }

  // פונקציה לבדיקה אם יש משחק פעיל
  bool get _hasActiveGame => _isPlaying || _team1Score > 0 || _team2Score > 0;

  // פונקציה לטיפול ביציאה מהמסך
  Future<void> _handlePopInvoked(bool didPop, Object? result) async {
    // אם כבר יצאנו, לא צריך לעשות כלום
    if (didPop) {
      return;
    }

    // בודק אם יש משחק פעיל או נקודות לקבוצות
    if (_hasActiveGame) {
      final shouldExit = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('יציאה מהמשחק'),
          content: const Text(
            'אם תצא עכשיו, המשחק יסתיים וכל הנקודות יאבדו.\n\nהאם אתה בטוח שברצונך לצאת?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('ביטול'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('צא מהמשחק'),
            ),
          ],
        ),
      );

      if (shouldExit == true && context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_hasActiveGame,
        onPopInvokedWithResult: _handlePopInvoked,
        child: Scaffold(
          backgroundColor: Colors.grey[900],

          appBar: AppBar(
            title: Text(widget.item.name, style: TextStyle(color: Colors.white)),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            systemOverlayStyle: const SystemUiOverlayStyle(
              statusBarColor: Colors.deepPurple,
              statusBarIconBrightness: Brightness.light,
              statusBarBrightness: Brightness.dark,
            ),
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

                if (_isPlaying)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 16,
                    ),
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

                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 350,
                      height: 500,
                      child: _isPlaying
                          ? (_words.isNotEmpty
                          ? CardSwiper(
                        controller: _controller,
                        cardsCount: _words.length,
                        numberOfCardsDisplayed: min(3, _words.length),
                        backCardOffset: const Offset(20, 20),
                        padding: const EdgeInsets.all(24.0),
                        cardBuilder: (context,
                            index,
                            horizontalOffsetPercentage,
                            verticalOffsetPercentage,) {
                          final word = _words[index % _words.length];
                          final swipeProgress = horizontalOffsetPercentage.abs();
                          final isSwipingRight = horizontalOffsetPercentage > 0;
                          final isSwipingLeft = horizontalOffsetPercentage < 0;
                          final showIndicator = swipeProgress > 0.1;
                          final isFirstCard = index == 0;

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
                                  child: Stack(
                                    children: [
                                      Center(
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

                                      if (isFirstCard && !showIndicator)
                                        Positioned(
                                          bottom: 30,
                                          left: 0,
                                          right: 0,
                                          child: Center(
                                            child: Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white.withOpacity(
                                                    0.2),
                                                borderRadius: BorderRadius.circular(
                                                    30),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    Icons.arrow_back,
                                                    color: Colors.white.withOpacity(
                                                        0.8),
                                                    size: 24,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.swipe,
                                                    color: Colors.white.withOpacity(
                                                        0.9),
                                                    size: 28,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Icon(
                                                    Icons.arrow_forward,
                                                    color: Colors.white.withOpacity(
                                                        0.8),
                                                    size: 24,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              if (showIndicator && isSwipingRight)
                                const Positioned(
                                  top: 20,
                                  left: 10,
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 100,
                                    color: Colors.green,
                                  ),
                                ),
                              if (showIndicator && isSwipingLeft)
                                const Positioned(
                                  top: 20,
                                  right: 10,
                                  child: Icon(
                                    Icons.cancel,
                                    size: 100,
                                    color: Colors.red,
                                  ),
                                ),
                            ],
                          );
                        },
                        onSwipe: (previousIndex, currentIndex, direction) {
                          final word = _words[previousIndex % _words.length];

                          if (direction == CardSwiperDirection.right) {
                            setState(() {
                              _currentRoundScore++;
                              _correctWords.add(word);
                            });
                            HapticFeedback.lightImpact();
                          } else if (direction == CardSwiperDirection.left) {
                            setState(() {
                              if (_currentRoundScore > 0) {
                                _currentRoundScore--;
                              }
                              _skippedWords.add(word);
                            });
                          }

                          if (previousIndex < _words.length) {
                            _usedWords.add(_words[previousIndex]);
                            _availableWords.remove(_words[previousIndex]);
                            _allUsedWords.add(_words[previousIndex]);
                          }

                          return true;
                        },
                        onEnd: () {
                          // כאן הוספתי את הקריאה לפונקציה החדשה
                          _reloadCardsIfNeeded();
                        },
                      )
                          : Center(
                        child: Text(
                          'אין מילים זמינות',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                          ),
                        ),
                      ))
                          : Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Colors.purple[400]!, Colors.blue[600]!],
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.theater_comedy,
                                size: 80,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'לחץ "התחל סיבוב" כדי להתחיל את המשחק',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.white,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      if (_isPlaying)
                        Column(
                          children: [
                            const SizedBox(height: 10),
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
                                const SizedBox(width: 24),
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
                                            value:
                                            _remainingSeconds / _totalSeconds,
                                            strokeWidth: 8,
                                            backgroundColor: Colors.grey[700],
                                            valueColor:
                                            AlwaysStoppedAnimation<Color>(
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
                                const SizedBox(width: 24),

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
                              onPressed: _startRound,
                              icon: const Icon(Icons.play_arrow, size: 32),
                              label: const Text(
                                'התחל סיבוב',
                                style: TextStyle(fontSize: 20),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
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
        ));
    }

  Widget _buildTeamScore(int team, int score) {
    final isActive = _currentTeam == team;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: isActive ? Colors.blue : Colors.grey[800],
        borderRadius: BorderRadius.circular(15),
        border: isActive
            ? Border.all(color: Colors.blue[300]!, width: 2)
            : null,
        boxShadow: isActive && _isPlaying
            ? [
          BoxShadow(
            color: Colors.blue.withOpacity(0.4),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ]
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
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (isActive && _isPlaying)
            const Icon(Icons.play_arrow, size: 16, color: Colors.white),
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