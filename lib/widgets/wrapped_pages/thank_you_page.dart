import 'package:flutter/material.dart';
import 'dart:math' as math;

class ThankYouPage extends StatefulWidget {
  final VoidCallback onClose;

  const ThankYouPage({
    super.key,
    required this.onClose,
  });

  @override
  State<ThankYouPage> createState() => _ThankYouPageState();
}

class _ThankYouPageState extends State<ThankYouPage>
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
            Color(0xFFEC4899),
          ],
        ),
      ),
      child: SafeArea(
        child: Stack(
          children: [
            // Animated hearts
            ...List.generate(15, (index) {
              return AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  final offset = (_controller.value + index / 15) % 1.0;
                  final sway = math.sin((offset + index) * math.pi * 2) * 30;
                  return Positioned(
                    right: (index % 5) * MediaQuery.of(context).size.width / 5 + sway,
                    bottom: offset * MediaQuery.of(context).size.height,
                    child: Opacity(
                      opacity: 0.6,
                      child: Icon(
                        Icons.favorite,
                        color: Colors.white,
                        size: 20 + (index % 4) * 8,
                      ),
                    ),
                  );
                },
              );
            }),

            // Main content
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Heart icon
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: 1 + math.sin(_controller.value * 2 * math.pi) * 0.1,
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
                              Icons.favorite,
                              color: Colors.white,
                              size: 80,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 48),

                    // Thank you message
                    const Text(
                      'מדריכים יקרים!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'כיף שאתם\n משתמשים באפליקציה!\n\n שתפו חברים,\nותמשיכו ליהנות! 🎉',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Close button
                    ElevatedButton(
                      onPressed: widget.onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF6366F1),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'סגור',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
