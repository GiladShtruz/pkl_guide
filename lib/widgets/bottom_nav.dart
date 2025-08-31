import 'package:flutter/material.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'בית',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.search),
          label: 'חיפוש',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'מועדפים',
        ),
      ],
      selectedItemColor: Theme.of(context).primaryColor,
      unselectedItemColor: Colors.grey,
    );
  }
}

