import 'package:hive/hive.dart';

part 'list_model.g.dart';

@HiveType(typeId: 1)
class ListModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String? description;

  @HiveField(3)
  List<String> itemIds; // References to items

  @HiveField(4)
  DateTime createdAt;

  @HiveField(5)
  DateTime? lastModified;

  @HiveField(6)
  bool isDefault; // For favorites list

  ListModel({
    required this.id,
    required this.name,
    this.description,
    required this.itemIds,
    required this.createdAt,
    this.lastModified,
    this.isDefault = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'itemIds': itemIds,
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  factory ListModel.fromJson(Map<String, dynamic> json) {
    return ListModel(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      itemIds: List<String>.from(json['itemIds']),
      createdAt: DateTime.parse(json['createdAt']),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'])
          : null,
      isDefault: json['isDefault'] ?? false,
    );
  }
}