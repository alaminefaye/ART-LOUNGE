import 'package:flutter/material.dart';

enum TableType {
  simple,
  vip,
  espaceJeux;

  static TableType fromString(String value) {
    switch (value) {
      case 'vip':
        return TableType.vip;
      case 'espace_jeux':
        return TableType.espaceJeux;
      default:
        return TableType.simple;
    }
  }

  String get displayName {
    switch (this) {
      case TableType.simple:
        return 'Simple';
      case TableType.vip:
        return 'VIP';
      case TableType.espaceJeux:
        return 'Espace Jeux';
    }
  }
}

enum TableStatus {
  libre,
  occupee,
  reservee,
  enPaiement;

  static TableStatus fromString(String value) {
    switch (value) {
      case 'occupee':
        return TableStatus.occupee;
      case 'reservee':
        return TableStatus.reservee;
      case 'en_paiement':
        return TableStatus.enPaiement;
      default:
        return TableStatus.libre;
    }
  }

  String get displayName {
    switch (this) {
      case TableStatus.libre:
        return 'Libre';
      case TableStatus.occupee:
        return 'Occupée';
      case TableStatus.reservee:
        return 'Réservée';
      case TableStatus.enPaiement:
        return 'En paiement';
    }
  }

  Color get color {
    switch (this) {
      case TableStatus.libre:
        return const Color(0xFF4CAF50);
      case TableStatus.occupee:
        return const Color(0xFFF44336);
      case TableStatus.reservee:
        return const Color(0xFFFF9800);
      case TableStatus.enPaiement:
        return const Color(0xFF2196F3);
    }
  }

  IconData get icon {
    switch (this) {
      case TableStatus.libre:
        return Icons.check_circle_outline;
      case TableStatus.occupee:
        return Icons.people;
      case TableStatus.reservee:
        return Icons.event_available;
      case TableStatus.enPaiement:
        return Icons.payment;
    }
  }
}

class RestaurantTable {
  final int id;
  final String numero;
  final TableType type;
  final int capacite;
  final TableStatus statut;
  final bool actif;

  RestaurantTable({
    required this.id,
    required this.numero,
    required this.type,
    required this.capacite,
    required this.statut,
    this.actif = true,
  });

  factory RestaurantTable.fromJson(Map<String, dynamic> json) {
    String numeroStr;
    if (json['numero'] is int) {
      numeroStr = json['numero'].toString();
    } else if (json['numero'] is String) {
      numeroStr = json['numero'] as String;
    } else {
      numeroStr = json['numero'].toString();
    }

    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return RestaurantTable(
      id: parseInt(json['id']),
      numero: numeroStr,
      type: TableType.fromString(json['type'] as String? ?? 'simple'),
      capacite: parseInt(json['capacite']),
      statut: TableStatus.fromString(json['statut'] as String? ?? 'libre'),
      actif: json['actif'] == 1 || json['actif'] == true,
    );
  }
}
