import 'order.dart';
import 'payment.dart';

class Invoice {
  final int id;
  final String numeroFacture;
  final int commandeId;
  final int paiementId;
  final double montantTotal;
  final double montantTaxe;
  final String? pdfUrl;
  final DateTime createdAt;
  final Order? commande;
  final Payment? paiement;

  Invoice({
    required this.id,
    required this.numeroFacture,
    required this.commandeId,
    required this.paiementId,
    required this.montantTotal,
    required this.montantTaxe,
    this.pdfUrl,
    required this.createdAt,
    this.commande,
    this.paiement,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
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

    return Invoice(
      id: parseInt(json['id']),
      numeroFacture: json['numero_facture'] as String? ?? '',
      commandeId: parseInt(json['commande_id']),
      paiementId: parseInt(json['paiement_id']),
      montantTotal: parseDouble(json['montant_total']),
      montantTaxe: parseDouble(json['montant_taxe']),
      pdfUrl: json['pdf_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      commande: json['commande'] != null
          ? Order.fromJson(json['commande'] as Map<String, dynamic>)
          : null,
      paiement: json['paiement'] != null
          ? Payment.fromJson(json['paiement'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_facture': numeroFacture,
      'commande_id': commandeId,
      'paiement_id': paiementId,
      'montant_total': montantTotal,
      'montant_taxe': montantTaxe,
      'pdf_url': pdfUrl,
      'created_at': createdAt.toIso8601String(),
      if (commande != null) 'commande': commande!.toJson(),
      if (paiement != null) 'paiement': paiement!.toJson(),
    };
  }
}
