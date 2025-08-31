import 'package:hive/hive.dart';

part 'item_model.g.dart';

@HiveType(typeId: 0)
class ItemModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  String? link;

  @HiveField(4)
  List<String> content;

  @HiveField(5)
  String category;

  @HiveField(6)
  bool isUserAdded;

  @HiveField(7)
  DateTime? lastAccessed;

  @HiveField(8)
  int clickCount;

  @HiveField(9)
  bool isFavorite;

  @HiveField(10)
  String? classification;

  ItemModel({
    required this.id,
    required this.name,
    this.description,
    this.link,
    required this.content,
    required this.category,
    this.isUserAdded = false,
    this.lastAccessed,
    this.clickCount = 0,
    this.isFavorite = false,
    this.classification,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'link': link,
      'content': content,
      'category': category,
      'isUserAdded': isUserAdded,
      'lastAccessed': lastAccessed?.toIso8601String(),
      'clickCount': clickCount,
      'isFavorite': isFavorite,
      'classification': classification,
    };
  }

  factory ItemModel.fromJson(Map<String, dynamic> json) {
    return ItemModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      link: json['link'],
      content: List<String>.from(json['content']),
      category: json['category'],
      isUserAdded: json['isUserAdded'] ?? false,
      lastAccessed: json['lastAccessed'] != null
          ? DateTime.parse(json['lastAccessed'])
          : null,
      clickCount: json['clickCount'] ?? 0,
      isFavorite: json['isFavorite'] ?? false,
      classification: json['classification'],
    );
  }
}

