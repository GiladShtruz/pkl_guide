class WrappedData {
  final Map<String, TopItemData> topItemsByCategory; // category -> top item
  final List<RecentItemData> recentItems; // 5 most recent items
  final int totalClicks;
  final DateTime generatedAt;

  WrappedData({
    required this.topItemsByCategory,
    required this.recentItems,
    required this.totalClicks,
    required this.generatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'topItemsByCategory': topItemsByCategory.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'recentItems': recentItems.map((e) => e.toJson()).toList(),
      'totalClicks': totalClicks,
      'generatedAt': generatedAt.toIso8601String(),
    };
  }

  factory WrappedData.fromJson(Map<String, dynamic> json) {
    return WrappedData(
      topItemsByCategory: (json['topItemsByCategory'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, TopItemData.fromJson(value)),
      ),
      recentItems: (json['recentItems'] as List)
          .map((e) => RecentItemData.fromJson(e))
          .toList(),
      totalClicks: json['totalClicks'] ?? 0,
      generatedAt: DateTime.parse(json['generatedAt']),
    );
  }
}

class TopItemData {
  final int itemId;
  final String title;
  final int clickCount;
  final String category;

  TopItemData({
    required this.itemId,
    required this.title,
    required this.clickCount,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'title': title,
      'clickCount': clickCount,
      'category': category,
    };
  }

  factory TopItemData.fromJson(Map<String, dynamic> json) {
    return TopItemData(
      itemId: json['itemId'],
      title: json['title'],
      clickCount: json['clickCount'],
      category: json['category'],
    );
  }
}

class RecentItemData {
  final int itemId;
  final String title;
  final DateTime lastAccessed;
  final String category;

  RecentItemData({
    required this.itemId,
    required this.title,
    required this.lastAccessed,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'title': title,
      'lastAccessed': lastAccessed.toIso8601String(),
      'category': category,
    };
  }

  factory RecentItemData.fromJson(Map<String, dynamic> json) {
    return RecentItemData(
      itemId: json['itemId'],
      title: json['title'],
      lastAccessed: DateTime.parse(json['lastAccessed']),
      category: json['category'],
    );
  }
}

class WrappedQuizAnswer {
  final String category;
  final int? selectedItemId;
  final int correctItemId;
  final bool isCorrect;
  final List<int> options; // 4 option IDs

  WrappedQuizAnswer({
    required this.category,
    this.selectedItemId,
    required this.correctItemId,
    required this.isCorrect,
    required this.options,
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'selectedItemId': selectedItemId,
      'correctItemId': correctItemId,
      'isCorrect': isCorrect,
      'options': options,
    };
  }

  factory WrappedQuizAnswer.fromJson(Map<String, dynamic> json) {
    return WrappedQuizAnswer(
      category: json['category'],
      selectedItemId: json['selectedItemId'],
      correctItemId: json['correctItemId'],
      isCorrect: json['isCorrect'],
      options: List<int>.from(json['options']),
    );
  }
}

class WrappedProgress {
  final int currentPage;
  final Map<String, WrappedQuizAnswer> quizAnswers;
  final List<int>? recentItemsOrder; // User's order for recent items quiz

  WrappedProgress({
    this.currentPage = 0,
    Map<String, WrappedQuizAnswer>? quizAnswers,
    this.recentItemsOrder,
  }) : quizAnswers = quizAnswers ?? {};

  Map<String, dynamic> toJson() {
    return {
      'currentPage': currentPage,
      'quizAnswers': quizAnswers.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'recentItemsOrder': recentItemsOrder,
    };
  }

  factory WrappedProgress.fromJson(Map<String, dynamic> json) {
    Map<String, WrappedQuizAnswer> parsedQuizAnswers = {};

    if (json['quizAnswers'] != null) {
      final quizAnswersData = json['quizAnswers'];
      if (quizAnswersData is Map) {
        quizAnswersData.forEach((key, value) {
          if (value is Map) {
            parsedQuizAnswers[key.toString()] = WrappedQuizAnswer.fromJson(
              Map<String, dynamic>.from(value as Map)
            );
          }
        });
      }
    }

    return WrappedProgress(
      currentPage: json['currentPage'] ?? 0,
      quizAnswers: parsedQuizAnswers,
      recentItemsOrder: json['recentItemsOrder'] != null
          ? List<int>.from(json['recentItemsOrder'])
          : null,
    );
  }
}
