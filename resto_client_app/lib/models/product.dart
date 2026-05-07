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
      id: (json['id'] as num).toInt(),
      categorieId: (json['categorie_id'] as num).toInt(),
      nom: (json['nom'] ?? '').toString(),
      description: json['description']?.toString(),
      prix: (json['prix'] as num).toDouble(),
      imageUrl: imageUrl,
      disponible: json['disponible'] != false,
    );
  }
}

