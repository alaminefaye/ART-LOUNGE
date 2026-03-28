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
    return CaisseSession(
      id: json['id'],
      userId: json['user_id'],
      soldeOuverture: (json['solde_ouverture'] as num).toDouble(),
      soldeFermetureReel: json['solde_fermeture_reel'] != null
          ? (json['solde_fermeture_reel'] as num).toDouble()
          : null,
      totalAttendu: json['total_attendu'] != null
          ? (json['total_attendu'] as num).toDouble()
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
