import 'package:flutter/material.dart';
import 'dart:math' as math;

class IntroPage extends StatefulWidget {
  final int totalClicks;
  final VoidCallback onNext;

  const IntroPage({
    super.key,
    required this.totalClicks,
    required this.onNext,
  });

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onNext,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF312E81),
              Color(0xFF6366F1),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Animated background particles
              ...List.generate(20, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    final offset = (_controller.value + index / 20) % 1.0;
                    return Positioned(
                      right: (index % 5) * MediaQuery.of(context).size.width / 5,
                      top: offset * MediaQuery.of(context).size.height,
                      child: Opacity(
                        opacity: 0.3,
                        child: Icon(
                          Icons.auto_awesome,
                          color: Colors.white,
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
                      // Animated icon
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: math.sin(_controller.value * 2 * math.pi) * 0.1,
                            child: Transform.scale(
                              scale: 1 + math.sin(_controller.value * 2 * math.pi) * 0.1,
                              child: Container(
                                padding: const EdgeInsets.all(32),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.1),
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
                                  Icons.auto_awesome,
                                  color: Colors.white,
                                  size: 80,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 48),

                      // Title
                      const Text(
                        'סיכום תקופה',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'בפק"ל למדריך!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 48),

                      // Subtitle
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: const Text(
                          'אז מה היה לנו השנה? 🎉',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Stats
                      if (widget.totalClicks > 0)
                        Column(
                          children: [
                            Text(
                              '${widget.totalClicks}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text(
                              'צפיות בתכנים',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),

              // Tap to continue hint
              Positioned(
                bottom: 32,
                left: 0,
                right: 0,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Opacity(
                      opacity: 0.5 + math.sin(_controller.value * 2 * math.pi) * 0.3,
                      child: const Column(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 32,
                          ),
                          Text(
                            'החלק למטה להמשך',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
