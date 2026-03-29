class User {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final List<String> roles;
  /// Points de fidélité (compte client)
  final int pointsFidelite;
  /// Valeur en FCFA d'1 point (pour affichage / paiement)
  final double? valeurFcfa1Point;
  /// Wave activé côté établissement (affichage option client)
  final bool waveEnabled;
  /// Orange Money activé côté établissement (affichage option client)
  final bool orangeMoneyEnabled;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.roles = const [],
    this.pointsFidelite = 0,
    this.valeurFcfa1Point,
    this.waveEnabled = true,
    this.orangeMoneyEnabled = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Helper pour convertir en int de manière sécurisée
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    // Gérer les rôles
    List<String> rolesList = [];
    if (json['roles'] != null) {
      final roles = json['roles'];
      if (roles is List) {
        for (var role in roles) {
          if (role is String) {
            rolesList.add(role);
          } else if (role is Map && role['name'] != null) {
            rolesList.add(role['name'] as String);
          }
        }
      }
    }

    return User(
      id: parseInt(json['id']),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      roles: rolesList,
      pointsFidelite: parseInt(json['points_fidelite']),
      valeurFcfa1Point: parseDouble(json['valeur_fcfa_1_point']),
      waveEnabled: json['wave_enabled'] != false,
      orangeMoneyEnabled: json['orange_money_enabled'] != false,
    );
  }

  /// Construit un User à partir de la réponse complète login/me (user + client + fidelity_settings + payment_method_settings)
  static User fromAuthResponse(Map<String, dynamic> data) {
    final userMap = Map<String, dynamic>.from(data['user'] as Map<String, dynamic>);
    final client = data['client'] as Map<String, dynamic>?;
    final fidelity = data['fidelity_settings'] as Map<String, dynamic>?;
    final paymentMethods = data['payment_method_settings'] as Map<String, dynamic>?;
    if (client != null) {
      userMap['points_fidelite'] = client['points_fidelite'] ?? 0;
    }
    if (fidelity != null && fidelity['valeur_fcfa_1_point'] != null) {
      userMap['valeur_fcfa_1_point'] = fidelity['valeur_fcfa_1_point'];
    }
    if (paymentMethods != null) {
      userMap['wave_enabled'] = paymentMethods['wave_enabled'] ?? true;
      userMap['orange_money_enabled'] = paymentMethods['orange_money_enabled'] ?? true;
    }
    return User.fromJson(userMap);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'roles': roles,
      'points_fidelite': pointsFidelite,
      if (valeurFcfa1Point != null) 'valeur_fcfa_1_point': valeurFcfa1Point,
      'wave_enabled': waveEnabled,
      'orange_money_enabled': orangeMoneyEnabled,
    };
  }

  bool get hasFidelity => pointsFidelite > 0 && (valeurFcfa1Point == null || valeurFcfa1Point! > 0);

  bool hasRole(String role) {
    return roles.contains(role);
  }
}
