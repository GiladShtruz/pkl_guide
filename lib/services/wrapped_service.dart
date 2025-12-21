import 'dart:math';
import 'package:hive/hive.dart';
import '../models/wrapped_data.dart';
import '../models/item_model.dart';
import '../models/category.dart';
import 'storage_service.dart';

class WrappedService {
  final StorageService storageService;
  static const String wrappedBoxName = 'wrappedBox';
  late Box wrappedBox;

  WrappedService(this.storageService);

  Future<void> init() async {
    wrappedBox = await Hive.openBox(wrappedBoxName);
  }

  /// Check if Wrapped should be visible based on date
  /// Visible from Dec 20 to Jan 5
  bool shouldShowWrapped() {
    final now = DateTime.now();
    final year = now.year;

    // Dec 20 of current year to Jan 5 of next year
    final startDate = DateTime(year, 12, 20);
    final endDate = DateTime(year + 1, 1, 5, 23, 59, 59);

    // Also check if we're in Jan 1-5 (from previous year's Dec 20)
    final previousYearStart = DateTime(year - 1, 12, 20);
    final currentYearJanEnd = DateTime(year, 1, 5, 23, 59, 59);

    return (now.isAfter(startDate) && now.isBefore(endDate)) ||
           (now.isAfter(previousYearStart) && now.isBefore(currentYearJanEnd));
  }

  /// Save Wrapped data permanently
  Future<void> saveWrappedData(WrappedData data) async {
    await wrappedBox.put('wrapped_data', data.toJson());
  }

  /// Load saved Wrapped data
  WrappedData? loadSavedWrappedData() {
    final data = wrappedBox.get('wrapped_data');
    if (data != null) {
      try {
        return WrappedData.fromJson(Map<String, dynamic>.from(data));
      } catch (e) {
        print('Error loading saved wrapped data: $e');
        return null;
      }
    }
    return null;
  }

  /// Get or generate Wrapped data
  /// Once generated and saved, it won't change even if user views more content
  WrappedData getOrGenerateWrappedData() {
    // Try to load saved data first
    final savedData = loadSavedWrappedData();
    if (savedData != null) {
      return savedData;
    }

    // Generate new data if not saved
    final newData = generateWrappedData();
    // Save it immediately so it's immutable
    saveWrappedData(newData);
    return newData;
  }

  /// Generate Wrapped data from user's usage statistics
  WrappedData generateWrappedData() {
    final allItems = storageService.getAppData();

    // Filter items with clicks
    final itemsWithClicks = allItems.where((item) => item.clickCount > 0).toList();

    // Calculate top item per category
    final topItemsByCategory = <String, TopItemData>{};
    for (final categoryType in CategoryType.values) {
      final categoryItems = itemsWithClicks
          .where((item) => item.category == categoryType.name)
          .toList();

      if (categoryItems.isNotEmpty) {
        // Sort by click count
        categoryItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));
        final topItem = categoryItems.first;

        topItemsByCategory[categoryType.name] = TopItemData(
          itemId: topItem.id,
          title: topItem.name,
          clickCount: topItem.clickCount,
          category: topItem.category,
        );
      }
    }

    // Get 5 most recent items
    final itemsWithAccess = allItems
        .where((item) => item.lastAccessed != null)
        .toList();
    itemsWithAccess.sort((a, b) => b.lastAccessed!.compareTo(a.lastAccessed!));
    final recentItems = itemsWithAccess.take(5).map((item) {
      return RecentItemData(
        itemId: item.id,
        title: item.name,
        lastAccessed: item.lastAccessed!,
        category: item.category,
      );
    }).toList();

    // Calculate total clicks
    final totalClicks = itemsWithClicks.fold<int>(
      0,
      (sum, item) => sum + item.clickCount,
    );

    return WrappedData(
      topItemsByCategory: topItemsByCategory,
      recentItems: recentItems,
      totalClicks: totalClicks,
      generatedAt: DateTime.now(),
    );
  }

  /// Generate quiz options for a category
  /// Returns list of 4 item IDs (including the correct one)
  List<int> generateQuizOptions(String category, int correctItemId) {
    final categoryItems = storageService
        .getAllCategoryItems(category: getCategoryType(category))
        .where((item) => item.clickCount > 0)
        .toList();

    if (categoryItems.length < 4) {
      // Not enough items, return what we have
      return categoryItems.map((e) => e.id).toList();
    }

    // Sort by clicks to get top items
    categoryItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));

    // Make sure correct answer is included
    final options = <int>[correctItemId];

    // Add 3 more random top items
    final otherItems = categoryItems
        .where((item) => item.id != correctItemId)
        .take(10) // Take top 10 to randomize from
        .toList();

    otherItems.shuffle(Random());
    options.addAll(otherItems.take(3).map((e) => e.id));

    // Shuffle options
    options.shuffle(Random());

    return options;
  }

  /// Save Wrapped progress
  Future<void> saveProgress(WrappedProgress progress) async {
    await wrappedBox.put('progress', progress.toJson());
  }

  /// Load Wrapped progress
  WrappedProgress? loadProgress() {
    final data = wrappedBox.get('progress');
    if (data != null) {
      return WrappedProgress.fromJson(Map<String, dynamic>.from(data));
    }
    return null;
  }

  /// Save quiz answer
  Future<void> saveQuizAnswer(String category, WrappedQuizAnswer answer) async {
    final progress = loadProgress() ?? WrappedProgress();
    progress.quizAnswers[category] = answer;
    await saveProgress(progress);
  }

  /// Get quiz answer for category
  WrappedQuizAnswer? getQuizAnswer(String category) {
    final progress = loadProgress();
    return progress?.quizAnswers[category];
  }

  /// Save current page
  Future<void> saveCurrentPage(int page) async {
    final progress = loadProgress() ?? WrappedProgress();
    await saveProgress(WrappedProgress(
      currentPage: page,
      quizAnswers: progress.quizAnswers,
      recentItemsOrder: progress.recentItemsOrder,
    ));
  }

  /// Get current page
  int getCurrentPage() {
    return loadProgress()?.currentPage ?? 0;
  }

  /// Save recent items order (for the final quiz)
  Future<void> saveRecentItemsOrder(List<int> order) async {
    final progress = loadProgress() ?? WrappedProgress();
    await saveProgress(WrappedProgress(
      currentPage: progress.currentPage,
      quizAnswers: progress.quizAnswers,
      recentItemsOrder: order,
    ));
  }

  /// Get recent items order
  List<int>? getRecentItemsOrder() {
    return loadProgress()?.recentItemsOrder;
  }

  /// Reset all Wrapped data (for testing or new year)
  Future<void> resetWrapped() async {
    await wrappedBox.clear();
  }

  /// Check if user has completed Wrapped
  bool hasCompletedWrapped() {
    final progress = loadProgress();
    if (progress == null) return false;

    // Check if all quizzes are answered and recent items are ordered
    final wrappedData = generateWrappedData();
    final requiredCategories = wrappedData.topItemsByCategory.keys.toSet();
    final answeredCategories = progress.quizAnswers.keys.toSet();

    return answeredCategories.containsAll(requiredCategories) &&
           progress.recentItemsOrder != null;
  }

  /// Get item by ID
  ItemModel? getItemById(int itemId) {
    return storageService.getItemById(itemId);
  }

  /// Get top 3 items for a specific category
  List<TopItemData> getTop3ItemsByCategory(String categoryName) {
    final categoryItems = storageService
        .getAllCategoryItems(category: getCategoryType(categoryName))
        .where((item) => item.clickCount > 0)
        .toList();

    // Sort by click count (descending)
    categoryItems.sort((a, b) => b.clickCount.compareTo(a.clickCount));

    // Take top 3
    return categoryItems.take(3).map((item) {
      return TopItemData(
        itemId: item.id,
        title: item.name,
        clickCount: item.clickCount,
        category: item.category,
      );
    }).toList();
  }

  /// Convert category name string to CategoryType
  CategoryType getCategoryType(String categoryName) {
    return CategoryType.values.firstWhere(
      (type) => type.name == categoryName,
      orElse: () => CategoryType.games,
    );
  }
}
