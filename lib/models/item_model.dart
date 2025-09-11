import 'package:hive/hive.dart';

part 'item_model.g.dart';

@HiveType(typeId: 0)
class ItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String category;

  @HiveField(2)
  String originalTitle;

  @HiveField(3)
  String? userTitle;

  @HiveField(4)
  String? originalDetail;

  @HiveField(5)
  String? userDetail;

  @HiveField(6)
  String? originalLink;

  @HiveField(7)
  String? userLink;

  @HiveField(8)
  String? classification;

  @HiveField(9)
  List<String> originalItems;

  @HiveField(10)
  List<String> userAddedItems;

  @HiveField(11)
  DateTime? lastAccessed;

  @HiveField(12)
  int clickCount;

  @HiveField(13)
  bool isUserCreated;

  @HiveField(14)
  bool isUserChanged;

  ItemModel({
    required this.id,
    required this.category,
    required this.originalTitle,
    this.userTitle,
    this.originalDetail,
    this.userDetail,
    this.originalLink,
    this.userLink,
    this.classification,
    required this.originalItems,
    List<String>? userAddedItems,
    this.lastAccessed,
    this.clickCount = 0,
    this.isUserCreated = false,
    this.isUserChanged = false,
  }) : userAddedItems = userAddedItems ?? [];

  // Getters for current values (user values if exist, otherwise original)
  String get name => userTitle ?? originalTitle;
  String? get detail => userDetail ?? originalDetail;
  String? get link => userLink ?? originalLink;
  List<String> get items => [...originalItems, ...userAddedItems];

  // Check if has user modifications
  bool get hasUserModifications =>
      userTitle != null ||
          userDetail != null ||
          userLink != null ||
          userAddedItems.isNotEmpty;

  // Reset specific field methods
  void resetTitle() {
    userTitle = null;
    _updateUserChangedStatus();
  }

  void resetDetail() {
    userDetail = null;
    _updateUserChangedStatus();
  }

  void resetLink() {
    userLink = null;
    _updateUserChangedStatus();
  }

  void resetItems() {
    userAddedItems.clear();
    _updateUserChangedStatus();
  }

  void resetAll() {
    userTitle = null;
    userDetail = null;
    userLink = null;
    userAddedItems.clear();
    isUserChanged = false;
  }

  // Update user changed status based on modifications
  void _updateUserChangedStatus() {
    isUserChanged = hasUserModifications;
  }

  // Method to update title and mark as changed
  void updateTitle(String newTitle) {
    userTitle = newTitle;
    isUserChanged = true;
  }

  // Method to update detail and mark as changed
  void updateDetail(String? newDetail) {
    userDetail = newDetail;
    isUserChanged = true;
  }

  // Method to update link and mark as changed
  void updateLink(String? newLink) {
    userLink = newLink;
    isUserChanged = true;
  }

  // Method to add user item and mark as changed
  void addUserItem(String item) {
    userAddedItems.add(item);
    isUserChanged = true;
  }

  // Method to remove user item and mark as changed
  void removeUserItem(String item) {
    userAddedItems.remove(item);
    _updateUserChangedStatus();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'originalTitle': originalTitle,
      'userTitle': userTitle,
      'originalDetail': originalDetail,
      'userDetail': userDetail,
      'originalLink': originalLink,
      'userLink': userLink,
      'classification': classification,
      'originalItems': originalItems,
      'userAddedItems': userAddedItems,
      'lastAccessed': lastAccessed?.toIso8601String(),
      'clickCount': clickCount,
      'isUserCreated': isUserCreated,
      'isUserChanged': isUserChanged,
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json, {String? categoryType}) {
    return ItemModel(
      id: json['id'] ?? 'ID-${DateTime.now().millisecondsSinceEpoch}-${json['originalTitle']?.hashCode ?? 0}',
      category: categoryType ?? json['category'] ?? '',
      originalTitle: json['originalTitle'] ?? json['title'] ?? '',
      userTitle: json['userTitle'],
      originalDetail: json['originalDetail'] ?? json['detail'],
      userDetail: json['userDetail'],
      originalLink: json['originalLink'] ?? json['link'],
      userLink: json['userLink'],
      classification: json['classification'],
      originalItems: json['originalItems'] != null
          ? List<String>.from(json['originalItems'])
          : (json['items'] != null ? List<String>.from(json['items']) : []),
      userAddedItems: json['userAddedItems'] != null
          ? List<String>.from(json['userAddedItems'])
          : [],
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.tryParse(json['lastAccessed'])
          : null,
      clickCount: json['clickCount'] ?? 0,
      isUserCreated: json['isUserCreated'] ?? false,
      isUserChanged: json['isUserChanged'] ?? false,
    );
  }
}