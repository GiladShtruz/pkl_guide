class JsonDataModel {
  final int version;
  final Map<String, List<dynamic>> categories;

  JsonDataModel({
    required this.version,
    required this.categories,
  });

  factory JsonDataModel.fromJson(Map<String, dynamic> json) {
    return JsonDataModel(
      version: json['version'] ?? 1,
      categories: Map<String, List<dynamic>>.from(json['category'] ?? {}),
    );
  }
}