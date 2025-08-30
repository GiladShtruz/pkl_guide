

class Game {
  final String name;
  final String description;
  final String classification;
  final bool isUserAdded;

  Game({
    required this.name,
    required this.description,
    required this.classification,
    this.isUserAdded = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'classification': classification,
      'isUserAdded': isUserAdded,
    };
  }

  factory Game.fromMap(Map<String, dynamic> map) {
    return Game(
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      classification: map['classification'] ?? '',
      isUserAdded: map['isUserAdded'] ?? false,
    );
  }
}