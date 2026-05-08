import 'package:resto_client_app/core/api_config.dart';

class Product {
  const Product({
    required this.id,
    required this.categorieId,
    required this.nom,
    required this.prix,
    this.description,
    this.imageUrl,
    this.updatedAt,
    this.disponible = true,
  });

  final int id;
  final int categorieId;
  final String nom;
  final double prix;
  final String? description;
  final String? imageUrl;
  final DateTime? updatedAt;
  final bool disponible;

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawImageUrl = (json['image_url'] ?? json['imageUrl'])?.toString();
    final rawImagePath = json['image']?.toString();
    final imageUrl = _normalizeImageUrl(rawImageUrl, rawImagePath);
    return Product(
      id: _toInt(json['id']),
      categorieId: _toInt(json['categorie_id']),
      nom: (json['nom'] ?? '').toString(),
      description: json['description']?.toString(),
      prix: _toDouble(json['prix']),
      imageUrl: imageUrl,
      updatedAt: _toDateTime(json['updated_at'] ?? json['updatedAt']),
      disponible: json['disponible'] != false,
    );
  }

  String? get imageUrlCacheBusted {
    final raw = imageUrl?.trim();
    if (raw == null || raw.isEmpty) return null;
    final v = updatedAt?.millisecondsSinceEpoch;
    if (v == null) return raw;
    try {
      final uri = Uri.parse(raw);
      final qp = Map<String, String>.from(uri.queryParameters);
      qp['v'] = v.toString();
      return uri.replace(queryParameters: qp).toString();
    } catch (_) {
      return raw;
    }
  }

  static String? _normalizeImageUrl(String? imageUrl, String? imagePath) {
    String? raw = imageUrl?.trim();
    if (raw != null && raw.isEmpty) raw = null;

    final apiBase = Uri.parse(ApiConfig.baseUrl);
    final portPart =
        apiBase.hasPort && apiBase.port != 80 && apiBase.port != 443
        ? ':${apiBase.port}'
        : '';
    final origin = '${apiBase.scheme}://${apiBase.host}$portPart';

    final path = imagePath?.trim();
    if ((raw == null || raw.isEmpty) && path != null && path.isNotEmpty) {
      final cleaned = path.startsWith('public/') ? path.substring(7) : path;
      return '$origin/storage/${cleaned.replaceFirst(RegExp(r"^/+"), "")}';
    }

    if (raw == null) return null;

    try {
      final uri = Uri.parse(raw);
      final host = uri.host.toLowerCase();
      if (host == 'localhost' || host == '127.0.0.1' || host == '0.0.0.0') {
        return Uri.parse(
          origin,
        ).replace(path: uri.path, query: uri.query).toString();
      }
    } catch (_) {}

    if (raw.startsWith('/storage/')) {
      return '$origin$raw';
    }

    return raw;
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

  static DateTime? _toDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) {
      final v = value.trim();
      if (v.isEmpty) return null;
      return DateTime.tryParse(v);
    }
    return null;
  }
}
