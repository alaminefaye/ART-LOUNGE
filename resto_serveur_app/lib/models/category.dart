class Category {
  final int id;
  final String nom;
  final String? description;
  final String? image;
  final bool actif;

  Category({
    required this.id,
    required this.nom,
    this.description,
    this.image,
    this.actif = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      return false;
    }

    return Category(
      id: parseInt(json['id']),
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String?,
      image: json['image'] as String?,
      actif: parseBool(json['actif']),
    );
  }
}
