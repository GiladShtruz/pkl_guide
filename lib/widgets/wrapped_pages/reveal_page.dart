import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/category.dart';
import '../../models/wrapped_data.dart';
import '../../services/wrapped_service.dart';

class RevealPage extends StatefulWidget {
  final CategoryType category;
  final TopItemData topItem;
  final WrappedService wrappedService;
  final VoidCallback onNext;

  const RevealPage({
    super.key,
    required this.category,
    required this.topItem,
    required this.wrappedService,
    required this.onNext,
  });

  @override
  State<RevealPage> createState() => _RevealPageState();
}

class _RevealPageState extends State<RevealPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.elasticOut,
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final answer = widget.wrappedService.getQuizAnswer(widget.category.name);
    final wasCorrect = answer?.isCorrect ?? false;

    return GestureDetector(
      onTap: widget.onNext,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              widget.category.categoryColor,
              widget.category.categoryColor.withOpacity(0.7),
              widget.category.categoryColor.withOpacity(0.9),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Confetti effect
              if (wasCorrect)
                ...List.generate(30, (index) {
                  return AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final random = math.Random(index);
                      final startX = random.nextDouble() * MediaQuery.of(context).size.width;
                      final endY = MediaQuery.of(context).size.height * _controller.value;
                      final rotation = _controller.value * 4 * math.pi;

                      return Positioned(
                        right: startX,
                        top: endY,
                        child: Transform.rotate(
                          angle: rotation,
                          child: Icon(
                            Icons.star,
                            color: Colors.white.withOpacity(0.7),
                            size: 20 + (index % 3) * 10,
                          ),
                        ),
                      );
                    },
                  );
                }),

              // Main content
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Result message
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: wasCorrect
                                ? Colors.green.withOpacity(0.3)
                                : Colors.orange.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Text(
                            wasCorrect ? 'כל הכבוד! ✨' : 'כמעט! 💫',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Trophy/Medal icon
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3),
                                blurRadius: 40,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 100,
                          ),
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Category and title
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              '${widget.category.wrappedName} שהכי ${widget.category.viewedName}:',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 20,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              widget.topItem.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Stats
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.visibility,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        '${widget.topItem.clickCount}',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 48,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'צפיות',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
