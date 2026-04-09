import '../config/api_config.dart';

class Product {
  final int id;
  final String nom;
  final String? description;
  final double prix;
  final String? image;
  final int categorieId;
  final String? categorieNom;
  final bool disponible;
  final bool actif;

  Product({
    required this.id,
    required this.nom,
    this.description,
    required this.prix,
    this.image,
    required this.categorieId,
    this.categorieNom,
    this.disponible = true,
    this.actif = true,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    double parseDouble(dynamic value) {
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    bool parseBool(dynamic value) {
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) return value.toLowerCase() == 'true' || value == '1';
      return false;
    }

    return Product(
      id: parseInt(json['id']),
      nom: json['nom'] as String? ?? '',
      description: json['description'] as String?,
      prix: parseDouble(json['prix']),
      image: json['image_url'] as String? ?? json['image'] as String?,
      categorieId: parseInt(json['categorie_id']),
      categorieNom: json['categorie']?['nom'] as String?,
      disponible: parseBool(json['disponible']),
      actif: parseBool(json['actif']),
    );
  }

  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image!;
    }
    if (image!.startsWith('/storage/')) {
      final path = image!.substring(1);
      return '${ApiConfig.serverBaseUrl}/$path';
    }
    return '${ApiConfig.serverBaseUrl}/storage/$image';
  }
}
