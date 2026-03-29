class CaisseSession {
  final int id;
  final int userId;
  final double soldeOuverture;
  final double? soldeFermetureReel;
  final double? totalAttendu;
  final String statut; // 'ouverte', 'fermee'
  final DateTime openedAt;
  final DateTime? closedAt;
  final String? notes;

  CaisseSession({
    required this.id,
    required this.userId,
    required this.soldeOuverture,
    this.soldeFermetureReel,
    this.totalAttendu,
    required this.statut,
    required this.openedAt,
    this.closedAt,
    this.notes,
  });

  factory CaisseSession.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return CaisseSession(
      id: json['id'] is String ? int.parse(json['id']) : json['id'],
      userId: json['user_id'] is String ? int.parse(json['user_id']) : json['user_id'],
      soldeOuverture: parseDouble(json['solde_ouverture']),
      soldeFermetureReel: json['solde_fermeture_reel'] != null
          ? parseDouble(json['solde_fermeture_reel'])
          : null,
      totalAttendu: json['total_attendu'] != null
          ? parseDouble(json['total_attendu'])
          : null,
      statut: json['statut'],
      openedAt: DateTime.parse(json['opened_at']),
      closedAt: json['closed_at'] != null ? DateTime.parse(json['closed_at']) : null,
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'solde_ouverture': soldeOuverture,
      'solde_fermeture_reel': soldeFermetureReel,
      'total_attendu': totalAttendu,
      'statut': statut,
      'opened_at': openedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
      'notes': notes,
    };
  }

  bool get isOuverte => statut == 'ouverte';
}
