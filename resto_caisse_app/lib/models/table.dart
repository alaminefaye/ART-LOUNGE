import 'package:flutter/material.dart';
import '../config/api_config.dart';

enum TableType {
  simple,
  vip,
  espaceJeux;

  static TableType fromString(String value) {
    switch (value) {
      case 'simple':
        return TableType.simple;
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
      case 'libre':
        return TableStatus.libre;
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
        return Colors.green;
      case TableStatus.occupee:
        return Colors.red;
      case TableStatus.reservee:
        return Colors.orange;
      case TableStatus.enPaiement:
        return Colors.blue;
    }
  }
}

class TableReservationInfo {
  final int id;
  final String nomClient;
  final String telephone;
  final String dateReservation;
  final String heureDebut;
  final String? heureFin;
  final int nombrePersonnes;
  final String? notes;

  TableReservationInfo({
    required this.id,
    required this.nomClient,
    required this.telephone,
    required this.dateReservation,
    required this.heureDebut,
    this.heureFin,
    required this.nombrePersonnes,
    this.notes,
  });

  factory TableReservationInfo.fromJson(Map<String, dynamic> json) {
    return TableReservationInfo(
      id: json['id'],
      nomClient: json['nom_client'] ?? '',
      telephone: json['telephone'] ?? '',
      dateReservation: json['date_reservation'] ?? '',
      heureDebut: json['heure_debut'] ?? '',
      heureFin: json['heure_fin'],
      nombrePersonnes: json['nombre_personnes'] ?? 0,
      notes: json['notes'],
    );
  }
}

class Table {
  final int id;
  final String
  numero; // Changé de int à String car peut être "T1", "VIP1", etc.
  final TableType type;
  final int capacite;
  final double? prix;
  final double? prixParHeure;
  final TableStatus statut;
  final String? qrCode;
  final bool actif;
  final TableReservationInfo? reservationActuelle;

  Table({
    required this.id,
    required this.numero,
    required this.type,
    required this.capacite,
    this.prix,
    this.prixParHeure,
    required this.statut,
    this.qrCode,
    this.actif = true,
    this.reservationActuelle,
  });

  factory Table.fromJson(Map<String, dynamic> json) {
    // Gérer numero qui peut être int ou String
    String numeroStr;
    if (json['numero'] is int) {
      numeroStr = json['numero'].toString();
    } else if (json['numero'] is String) {
      numeroStr = json['numero'] as String;
    } else {
      numeroStr = json['numero'].toString();
    }

    // Helper pour convertir en int de manière sécurisée
    int parseInt(dynamic value) {
      if (value is int) return value;
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    // Helper pour convertir en double de manière sécurisée
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value);
      return null;
    }

    return Table(
      id: parseInt(json['id']),
      numero: numeroStr,
      type: TableType.fromString(json['type'] as String? ?? 'simple'),
      capacite: parseInt(json['capacite']),
      prix: parseDouble(json['prix']),
      prixParHeure: parseDouble(json['prix_par_heure']),
      statut: TableStatus.fromString(json['statut'] as String? ?? 'libre'),
      qrCode: json['qr_code'] as String?,
      actif: json['actif'] == 1 || json['actif'] == true,
      reservationActuelle: json['reservation_actuelle'] != null
          ? TableReservationInfo.fromJson(json['reservation_actuelle'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'type': type.name,
      'capacite': capacite,
      'prix': prix,
      'prix_par_heure': prixParHeure,
      'statut': statut.name,
      'qr_code': qrCode,
      'actif': actif,
    };
  }

  String get qrCodeUrl {
    if (qrCode == null) return '';
    if (qrCode!.startsWith('http')) return qrCode!;
    // Utiliser l'URL de base depuis ApiConfig pour être flexible
    return '${ApiConfig.serverBaseUrl}/storage/$qrCode';
  }
}
