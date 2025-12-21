import 'package:flutter/material.dart';
import '../models/wrapped_data.dart';
import '../models/category.dart';

class WrappedSummaryImage extends StatelessWidget {
  final WrappedData wrappedData;

  const WrappedSummaryImage({
    super.key,
    required this.wrappedData,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1080,
      height: 1920,
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
      child: Padding(
        padding: const EdgeInsets.all(60.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            const SizedBox(height: 100),
            const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 120,
            ),
            const SizedBox(height: 40),
            const Text(
              'סיכום שנה',
              style: TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'פק"ל למדריך 2025',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 48,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 80),

            // Total views
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                children: [
                  const Text(
                    'סה"כ צפיות',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 36,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${wrappedData.totalClicks}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 96,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),

            // Top 3 per category
            ...CategoryType.values.map((category) {
              final topItem = wrappedData.topItemsByCategory[category.name];
              if (topItem == null) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 24),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: category.categoryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: category.categoryColor.withOpacity(0.6),
                    width: 3,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      category.icon,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category.displayName,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 28,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            topItem.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${topItem.clickCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const Spacer(),

            // Footer
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Column(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 56,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'פק"ל למדריך',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'הפלטפורמה לקהילת המדריכים',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 28,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}
