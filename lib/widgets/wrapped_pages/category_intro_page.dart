import 'package:flutter/material.dart';
import '../../models/category.dart';

class CategoryIntroPage extends StatelessWidget {
  final CategoryType category;
  final VoidCallback onNext;

  const CategoryIntroPage({
    super.key,
    required this.category,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onNext,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              category.categoryColor.withOpacity(0.8),
              category.categoryColor,
              category.categoryColor.withOpacity(0.6),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Category icon
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      category.icon,
                      color: Colors.white,
                      size: 80,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Category name
                  const Text(
                    'בקטגוריית',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 24,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
