class Product {
  const Product({
    required this.id,
    required this.categorieId,
    required this.nom,
    required this.prix,
    this.description,
    this.imageUrl,
    this.disponible = true,
  });

  final int id;
  final int categorieId;
  final String nom;
  final double prix;
  final String? description;
  final String? imageUrl;
  final bool disponible;

  factory Product.fromJson(Map<String, dynamic> json) {
    final imageUrl = (json['image_url'] ?? json['imageUrl'])?.toString();
    return Product(
      id: _toInt(json['id']),
      categorieId: _toInt(json['categorie_id']),
      nom: (json['nom'] ?? '').toString(),
      description: json['description']?.toString(),
      prix: _toDouble(json['prix']),
      imageUrl: imageUrl,
      disponible: json['disponible'] != false,
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final v = value.trim();
      final n = int.tryParse(v);
      if (n != null) return n;
      final asNum = double.tryParse(v.replaceAll(' ', '').replaceAll(',', '.'));
      if (asNum != null) return asNum.toInt();
    }
    return 0;
  }

  static double _toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) {
      final cleaned = value.trim().replaceAll(' ', '').replaceAll(',', '.');
      final n = double.tryParse(cleaned);
      if (n != null) return n;
    }
    return 0.0;
  }
}
