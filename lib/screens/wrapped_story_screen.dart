import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../models/wrapped_data.dart';
import '../services/wrapped_service.dart';
import '../services/storage_service.dart';
import '../widgets/wrapped_pages/intro_page.dart';
import '../widgets/wrapped_pages/category_intro_page.dart';
import '../widgets/wrapped_pages/quiz_page.dart';
import '../widgets/wrapped_pages/reveal_page.dart';
import '../widgets/wrapped_pages/recent_items_quiz_page.dart';
import '../widgets/wrapped_pages/results_summary_page.dart';
import '../widgets/wrapped_pages/thank_you_page.dart';

// Custom ScrollPhysics that can be disabled
class ConditionalScrollPhysics extends ScrollPhysics {
  final bool canScroll;

  const ConditionalScrollPhysics({required this.canScroll, super.parent});

  @override
  ConditionalScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return ConditionalScrollPhysics(
      canScroll: canScroll,
      parent: buildParent(ancestor),
    );
  }

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) {
    if (!canScroll) return false;
    return super.shouldAcceptUserOffset(position);
  }
}

class WrappedStoryScreen extends StatefulWidget {
  const WrappedStoryScreen({super.key});

  @override
  State<WrappedStoryScreen> createState() => _WrappedStoryScreenState();
}

class _WrappedStoryScreenState extends State<WrappedStoryScreen> {
  late PageController _pageController;
  late WrappedService _wrappedService;
  late WrappedData _wrappedData;
  int _currentPage = 0;
  List<Widget> _pages = [];
  bool _canScroll = true; // Track if scrolling is allowed

  @override
  void initState() {
    super.initState();
    _wrappedService = WrappedService(context.read<StorageService>());
    _wrappedService.init().then((_) {
      _wrappedData = _wrappedService.getOrGenerateWrappedData();
      _buildPages();

      // Load saved progress
      final savedPage = _wrappedService.getCurrentPage();
      _currentPage = savedPage;
      _pageController = PageController(initialPage: savedPage);
      setState(() {});
    });
    _pageController = PageController();
  }

  void _buildPages() {
    final pages = <Widget>[];

    // Page 1: Intro
    pages.add(IntroPage(
      totalClicks: _wrappedData.totalClicks,
      onNext: _goToNextPage,
    ));

    // Pages for each category
    for (final categoryType in CategoryType.values) {
      final topItem = _wrappedData.topItemsByCategory[categoryType.name];
      if (topItem == null) continue;

      // Category intro page
      pages.add(CategoryIntroPage(
        category: categoryType,
        onNext: _goToNextPage,
      ));

      // Quiz page
      pages.add(QuizPage(
        category: categoryType,
        topItem: topItem,
        wrappedService: _wrappedService,
        onAnswered: (isCorrect) {
          setState(() {});
          _goToNextPage();
        },
        onScrollStateChanged: (canScroll) {
          setState(() {
            _canScroll = canScroll;
          });
        },
      ));

      // Reveal page
      pages.add(RevealPage(
        category: categoryType,
        topItem: topItem,
        wrappedService: _wrappedService,
        onNext: _goToNextPage,
      ));
    }

    // Recent items quiz - removed per user request

    // Results summary page (shareable)
    pages.add(ResultsSummaryPage(
      wrappedData: _wrappedData,
      wrappedService: _wrappedService,
      onNext: _goToNextPage,
    ));

    // Thank you page
    pages.add(ThankYouPage(
      onClose: () => Navigator.of(context).pop(),
    ));

    setState(() {
      _pages = pages;
    });
  }

  void _goToNextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pages.isEmpty) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Main PageView
          PageView.builder(
            controller: _pageController,
            scrollDirection: Axis.vertical,
            itemCount: _pages.length,
            physics: ConditionalScrollPhysics(canScroll: _canScroll),
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
                _canScroll = true; // Reset to allow scrolling on new page
              });
              _wrappedService.saveCurrentPage(index);
            },
            itemBuilder: (context, index) {
              return _pages[index];
            },
          ),

          // Close button only (no progress bars)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Close button
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),

          // Navigation hints with proper positioning
          if (_currentPage > 0)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              right: 16,
              child: GestureDetector(
                onTap: _goToPreviousPage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

          if (_currentPage < _pages.length - 1)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 32,
              right: 16,
              child: GestureDetector(
                onTap: _goToNextPage,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.arrow_downward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
