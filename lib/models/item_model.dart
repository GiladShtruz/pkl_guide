import 'package:hive/hive.dart';

part 'item_model.g.dart';

@HiveType(typeId: 0)
class ItemModel extends HiveObject {
  @HiveField(0)
  int id;

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
  String? originalClassification;

  @HiveField(9)
  String? userClassification;

  @HiveField(10)
  String? originalEquipment;

  @HiveField(11)
  String? userEquipment;

  @HiveField(12)
  List<String> originalElements;

  @HiveField(13)
  List<String> userElements;

  @HiveField(14)
  DateTime? lastAccessed;

  @HiveField(15)
  int clickCount;

  @HiveField(16)
  bool isUserCreated;

  @HiveField(17)
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
    this.originalClassification,
    this.userClassification,
    this.originalEquipment,
    this.userEquipment,
    required this.originalElements,
    List<String>? userElements,
    this.lastAccessed,
    this.clickCount = 0,
    this.isUserCreated = false,
    this.isUserChanged = false,
  }) : userElements = userElements ?? [];

  // Getters for current values (user values if exist, otherwise original)
  String get name => userTitle ?? originalTitle;
  String? get detail => userDetail ?? originalDetail;
  String? get link => userLink ?? originalLink;
  String? get classification => userClassification ?? originalClassification;
  String? get equipment => userEquipment ?? originalEquipment;
  List<String> get items => [...originalElements, ...userElements];

  // Check if has user modifications
  bool get hasUserModifications =>
      userTitle != null ||
          userDetail != null ||
          userLink != null ||
          userClassification != null ||
          userEquipment != null ||
          userElements.isNotEmpty;

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

  void resetClassification() {
    userClassification = null;
    _updateUserChangedStatus();
  }

  void resetEquipment() {
    userEquipment = null;
    _updateUserChangedStatus();
  }

  void resetElements() {
    userElements.clear();
    _updateUserChangedStatus();
  }

  void resetAll() {
    userTitle = null;
    userDetail = null;
    userLink = null;
    userClassification = null;
    userEquipment = null;
    userElements.clear();
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

  // Method to update classification and mark as changed
  void updateClassification(String? newClassification) {
    userClassification = newClassification;
    isUserChanged = true;
  }

  // Method to update equipment and mark as changed
  void updateEquipment(String? newEquipment) {
    userEquipment = newEquipment;
    isUserChanged = true;
  }

  // Method to add user element and mark as changed
  void addUserElement(String item) {
    userElements.add(item);
    isUserChanged = true;
  }

  // Method to remove user element and mark as changed
  void removeUserElement(String item) {
    userElements.remove(item);
    _updateUserChangedStatus();
  }

  void updateOriginalOnUpgrade(ItemModel newItem) {
    originalTitle = newItem.originalTitle;
    originalDetail = newItem.originalDetail;
    originalLink = newItem.originalLink;
    originalClassification = newItem.originalClassification;
    originalEquipment = newItem.originalEquipment;
    originalElements = newItem.originalElements;
    category = newItem.category;
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
      'originalClassification': originalClassification,
      'userClassification': userClassification,
      'originalEquipment': originalEquipment,
      'userEquipment': userEquipment,
      'originalElements': originalElements,
      'userElements': userElements,
      'lastAccessed': lastAccessed?.toIso8601String(),
      'clickCount': clickCount,
      'isUserCreated': isUserCreated,
      'isUserChanged': isUserChanged,
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json, {String? categoryType}) {
    return ItemModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch % 100000000,
      category: categoryType ?? json['category'] ?? '',
      originalTitle: json['originalTitle'] ?? json['title'] ?? '',
      userTitle: json['userTitle'],
      originalDetail: json['originalDetail'] ?? json['detail'],
      userDetail: json['userDetail'],
      originalLink: json['originalLink'] ?? json['link'],
      userLink: json['userLink'],
      originalClassification: json['originalClassification'] ?? json['classification'],
      userClassification: json['userClassification'],
      originalEquipment: json['originalEquipment'] ?? json['equipment'],
      userEquipment: json['userEquipment'],
      originalElements: json['originalElements'] != null
          ? List<String>.from(json['originalElements'])
          : (json['originalItems'] != null
          ? List<String>.from(json['originalItems'])
          : (json['items'] != null ? List<String>.from(json['items']) : [])),
      userElements: json['userElements'] != null
          ? List<String>.from(json['userElements'])
          : (json['userAddedItems'] != null
          ? List<String>.from(json['userAddedItems'])
          : []),
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.tryParse(json['lastAccessed'])
          : null,
      clickCount: json['clickCount'] ?? 0,
      isUserCreated: json['isUserCreated'] ?? false,
      isUserChanged: json['isUserChanged'] ?? false,
    );
  }
}