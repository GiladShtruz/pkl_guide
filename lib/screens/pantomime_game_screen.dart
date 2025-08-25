import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '/models/game.dart';
import '/models/riddle.dart';
import '/models/circle.dart';
import '/models/word_game.dart';
import '/models/search_result.dart';
import '/services/data_service.dart';
import '/app.dart';
import '/screens/home_screen.dart';
import '/widgets/category_card.dart';
import '/screens/games_list_screen.dart';
import '/screens/game_detail_screen.dart';
import '/screens/stickers_game_screen.dart';
import '/screens/riddles_list_screen.dart';
import '/screens/riddle_detail_screen.dart';
import '/screens/circles_list_screen.dart';
import '/screens/circle_detail_screen.dart';
import '/screens/search_screen.dart';

class PantomimeGameScreen extends StatefulWidget {
  final WordGame wordGame;

  const PantomimeGameScreen({Key? key, required this.wordGame}) : super(key: key);

  @override
  State<PantomimeGameScreen> createState() => _PantomimeGameScreenState();
}

class _PantomimeGameScreenState extends State<PantomimeGameScreen> with TickerProviderStateMixin {
  late AnimationController _timerController;
  late CardSwiperController _cardController;
  late List<String> _words;
  int _successCount = 0;
  bool _isPlaying = false;
  int _remainingSeconds = 60;

  @override
  void initState() {
    super.initState();
    _words = List.from(widget.wordGame.allWords)..shuffle();
    _cardController = CardSwiperController();

    _timerController = AnimationController(
      duration: const Duration(seconds: 60),
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
      _words.shuffle();
    });
    _timerController.forward(from: 0);
  }

  void _endGame() {
    setState(() {
      _isPlaying = false;
    });
    _timerController.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Time\'s Up!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_off, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'You presented $_successCount words!',
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
            child: const Text('Play Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }

  void _resetGame() {
    setState(() {
      _remainingSeconds = 60;
      _successCount = 0;
      _isPlaying = false;
    });
    _timerController.reset();
  }

  void _showAddWordsDialog() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Words to Pantomime'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Enter words separated by comma',
            hintText: 'chair, table, computer',
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty) {
                final words = controller.text.split(',')
                    .map((w) => w.trim())
                    .where((w) => w.isNotEmpty)
                    .toList();

                await DataService.addWordsToGame('פנטומימה', words);
                Navigator.pop(context);

                // Refresh words
                setState(() {
                  _words = [...widget.wordGame.words, ...words];
                  _words.shuffle();
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${words.length} words')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red.shade50,
      appBar: AppBar(
        title: const Text('Pantomime'),
        backgroundColor: Colors.red,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showAddWordsDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Success counter
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
                    'Success: $_successCount',
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Swipeable word cards
            Expanded(
              child: _isPlaying
                  ? CardSwiper(
                      controller: _cardController,
                      cardsCount: _words.length,
                      numberOfCardsDisplayed: 3,
                      backCardOffset: const Offset(20, 20),
                      padding: const EdgeInsets.all(24.0),
                      cardBuilder: (context, index, horizontalOffsetPercentage, verticalOffsetPercentage) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _words[index % _words.length],
                              style: const TextStyle(
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      },
                      onSwipe: (previousIndex, currentIndex, direction) {
                        if (direction == CardSwiperDirection.right) {
                          setState(() {
                            _successCount++;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('✓ Success!'),
                              backgroundColor: Colors.green,
                              duration: Duration(milliseconds: 500),
                            ),
                          );
                        } else if (direction == CardSwiperDirection.left) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('← Pass'),
                              backgroundColor: Colors.orange,
                              duration: Duration(milliseconds: 500),
                            ),
                          );
                        }
                        return true;
                      },
                      onEnd: () {
                        // When cards run out, shuffle and restart
                        setState(() {
                          _words.shuffle();
                        });
                      },
                    )
                  : Container(
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
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.theater_comedy,
                              size: 80,
                              color: Colors.red,
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text(
                                widget.wordGame.description,
                                style: const TextStyle(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            const SizedBox(height: 24),

            // Timer
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

            // Play/Stop button
            ElevatedButton.icon(
              onPressed: _isPlaying ? _endGame : _startGame,
              icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow, size: 32),
              label: Text(
                _isPlaying ? 'Stop' : 'Start',
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
    super.dispose();
  }
}
