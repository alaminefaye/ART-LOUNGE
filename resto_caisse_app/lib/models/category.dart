class Category {
  final int id;
  final String nom;
  final String? description;
  final int ordre;
  final bool actif;
  final int? produitsCount;

  Category({
    required this.id,
    required this.nom,
    this.description,
    this.ordre = 0,
    this.actif = true,
    this.produitsCount,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Fonction helper pour convertir en int de manière sécurisée
    int? parseInt(dynamic value) {
      if (value == null) return null;
      if (value is int) return value;
      if (value is String) return int.tryParse(value);
      if (value is double) return value.toInt();
      return null;
    }

    // Fonction helper pour convertir en bool de manière sécurisée
    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return Category(
      id: parseInt(json['id']) ?? 0,
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String?,
      ordre: parseInt(json['ordre']) ?? 0,
      actif: parseBool(json['actif']),
      produitsCount: parseInt(json['produits_count']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'description': description,
      'ordre': ordre,
      'actif': actif,
      'produits_count': produitsCount,
    };
  }
}

