import 'package:hive/hive.dart';

part 'item_model.g.dart';

@HiveType(typeId: 0)
class ItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String originalTitle;  // Original from JSON

  @HiveField(2)
  String? originalDetail;  // Original from JSON

  @HiveField(3)
  String? link;

  @HiveField(4)
  List<String> originalItems;  // Original from JSON

  @HiveField(5)
  String category;

  @HiveField(6)
  DateTime? lastAccessed;

  @HiveField(7)
  int clickCount;

  @HiveField(8)
  String? classification;

  // User modifications
  @HiveField(9)
  String? userTitle;  // User's modified title

  @HiveField(10)
  String? userDetail;  // User's modified detail

  @HiveField(11)
  List<String> userAddedItems;  // Items added by user

  @HiveField(12)
  bool isUserCreated;  // Entirely created by user

  ItemModel({
    required this.id,
    required this.originalTitle,
    this.originalDetail,
    this.link,
    required this.originalItems,
    required this.category,
    this.lastAccessed,
    this.clickCount = 0,
    this.classification,
    this.userTitle,
    this.userDetail,
    List<String>? userAddedItems,
    this.isUserCreated = false,
  }) : userAddedItems = userAddedItems ?? [];

  // Getters for current values (user values if exist, otherwise original)
  String get name => userTitle ?? originalTitle;
  String? get detail => userDetail ?? originalDetail;
  List<String> get items => [...originalItems, ...userAddedItems];

  // Check if has user modifications
  bool get hasUserModifications =>
      userTitle != null ||
          userDetail != null ||
          userAddedItems.isNotEmpty;

  // Reset specific field
  void resetTitle() {
    userTitle = null;
  }

  void resetDetail() {
    userDetail = null;
  }

  void resetItems() {
    userAddedItems.clear();
  }

  void resetAll() {
    userTitle = null;
    userDetail = null;
    userAddedItems.clear();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': originalTitle,
      'detail': originalDetail,
      'link': link,
      'items': originalItems,
      'category': category,
      'classification': classification,
      'userTitle': userTitle,
      'userDetail': userDetail,
      'userAddedItems': userAddedItems,
      'isUserCreated': isUserCreated,
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json, {String? categoryType}) {
    return ItemModel(
      id: json['id'] ?? 'ID-${DateTime.now().millisecondsSinceEpoch}-${json['title'].hashCode}',
      originalTitle: json['title'] ?? '',
      originalDetail: json['detail'],
      link: json['link'],
      originalItems: json['items'] != null
          ? List<String>.from(json['items'])
          : [],
      category: categoryType ?? json['category'] ?? '',
      classification: json['classification'],
      userTitle: json['userTitle'],
      userDetail: json['userDetail'],
      userAddedItems: json['userAddedItems'] != null
          ? List<String>.from(json['userAddedItems'])
          : [],
      isUserCreated: json['isUserCreated'] ?? false,
    );
  }
}