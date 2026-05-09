class Category {
  const Category({required this.id, required this.nom, this.description});

  final int id;
  final String nom;
  final String? description;

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: (json['id'] as num).toInt(),
      nom: (json['nom'] ?? '').toString(),
      description: json['description']?.toString(),
    );
  }
}
