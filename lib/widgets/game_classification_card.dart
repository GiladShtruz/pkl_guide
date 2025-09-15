// lib/widgets/game_classification_card.dart
import 'package:flutter/material.dart';

class GameClassificationCard extends StatelessWidget {
  final String title;
  final int itemCount;
  final IconData icon;
  final VoidCallback onTap;
  final bool isHighlighted;
  final List<Color>? gradientColors;

  const GameClassificationCard({
    super.key,
    required this.title,
    required this.itemCount,
    required this.icon,
    required this.onTap,
    this.isHighlighted = false,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    final colors = gradientColors ??
        (isHighlighted
            ? [Colors.purple[600]!, Colors.purple[800]!]
            : [Colors.purple[400]!, Colors.purple[600]!]);

    return Card(
      elevation: isHighlighted ? 4 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: colors,
            ),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            splashColor: Colors.white.withOpacity(0.3),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Icon(
                      icon,
                      size: isHighlighted ? 40 : 36,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: isHighlighted ? 16 : 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$itemCount ${_getItemsText(itemCount)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getItemsText(int count) {
    if (count == 1) return 'משחק';
    return 'משחקים';
  }
}