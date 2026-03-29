class ClientFid {
  final int id;
  final String nomComplet;
  final String telephone;
  final int pointsFidelite;
  final bool fidelityEnabled;
  final double valeurFcfa1Point;

  ClientFid({
    required this.id,
    required this.nomComplet,
    required this.telephone,
    required this.pointsFidelite,
    required this.fidelityEnabled,
    required this.valeurFcfa1Point,
  });

  factory ClientFid.fromJson(Map<String, dynamic> json) {
    return ClientFid(
      id: json['id'] as int,
      nomComplet: json['nom_complet'] as String,
      telephone: json['telephone'] as String,
      pointsFidelite: json['points_fidelite'] as int,
      fidelityEnabled: json['fidelity_enabled'] as bool? ?? false,
      valeurFcfa1Point: (json['valeur_fcfa_1_point'] as num?)?.toDouble() ?? 0.0,
    );
  }

  double get pointsEnFcfa => pointsFidelite * valeurFcfa1Point;
}
