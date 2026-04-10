class Serveur {
  final int id;
  final String nom;
  final String? prenom;
  final String? telephone;

  Serveur({
    required this.id,
    required this.nom,
    this.prenom,
    this.telephone,
  });

  factory Serveur.fromJson(Map<String, dynamic> json) {
    return Serveur(
      id: json['id'],
      nom: json['nom'],
      prenom: json['prenom'],
      telephone: json['telephone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'telephone': telephone,
    };
  }
}
