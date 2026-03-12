import 'package:flutter/material.dart';

enum PaymentMethod {
  especes('especes', 'Espèces', '💵'),
  wave('wave', 'Wave', '🌊'),
  orangeMoney('orange_money', 'Orange Money', '🟠'),
  carteBancaire('carte_bancaire', 'Carte Bancaire', '💳'),
  pointsFidelite('points_fidelite', 'Points de fidélité', '⭐');

  final String value;
  final String displayName;
  final String emoji;

  const PaymentMethod(this.value, this.displayName, this.emoji);

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (method) => method.value == value,
      orElse: () => PaymentMethod.especes,
    );
  }
}

enum PaymentStatus {
  enAttente('en_attente', 'En attente'),
  valide('valide', 'Validé'),
  echoue('echoue', 'Échoué'),
  annule('annule', 'Annulé');

  final String value;
  final String displayName;

  const PaymentStatus(this.value, this.displayName);

  static PaymentStatus fromString(String value) {
    return PaymentStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => PaymentStatus.enAttente,
    );
  }

  Color get color {
    switch (this) {
      case PaymentStatus.valide:
        return const Color(0xFF4CAF50); // Green
      case PaymentStatus.enAttente:
        return const Color(0xFFFF9800); // Orange
      case PaymentStatus.echoue:
        return const Color(0xFFF44336); // Red
      case PaymentStatus.annule:
        return const Color(0xFF9E9E9E); // Grey
    }
  }
}

class Payment {
  final int id;
  final int commandeId;
  final int? userId;
  final double montant;
  final PaymentMethod moyenPaiement;
  final PaymentStatus statut;
  final String? transactionId;
  final double? montantRecu;
  final double? monnaieRendue;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Payment({
    required this.id,
    required this.commandeId,
    this.userId,
    required this.montant,
    required this.moyenPaiement,
    required this.statut,
    this.transactionId,
    this.montantRecu,
    this.monnaieRendue,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    // Helper pour parser double
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    // Helper pour parser int
    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      if (value is double) return value.toInt();
      return 0;
    }

    return Payment(
      id: parseInt(json['id']),
      commandeId: parseInt(json['commande_id']),
      userId: json['user_id'] != null ? parseInt(json['user_id']) : null,
      montant: parseDouble(json['montant']),
      moyenPaiement: PaymentMethod.fromString(json['moyen_paiement'] as String? ?? 'especes'),
      statut: PaymentStatus.fromString(json['statut'] as String? ?? 'en_attente'),
      transactionId: json['transaction_id'] as String?,
      montantRecu: json['montant_recu'] != null ? parseDouble(json['montant_recu']) : null,
      monnaieRendue: json['monnaie_rendue'] != null ? parseDouble(json['monnaie_rendue']) : null,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commande_id': commandeId,
      'moyen_paiement': moyenPaiement.value,
      if (transactionId != null) 'transaction_id': transactionId,
      if (montantRecu != null) 'montant_recu': montantRecu,
      if (notes != null) 'notes': notes,
    };
  }
}
