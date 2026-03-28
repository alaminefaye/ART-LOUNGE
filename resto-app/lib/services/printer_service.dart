import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../config/app_brand.dart';
import '../models/invoice.dart';
import '../models/payment.dart';
import '../utils/formatters.dart';

class PrinterService {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getDevices() async {
    return await bluetooth.getBondedDevices();
  }

  Future<bool> isConnected() async {
    return await bluetooth.isConnected ?? false;
  }

  Future<void> printReceipt(Invoice invoice) async {
    bool? isConnected = await bluetooth.isConnected;
    if (isConnected != true) {
      // Pour les terminaux Android POS, l'imprimante est souvent déjà couplée
      List<BluetoothDevice> devices = await bluetooth.getBondedDevices();
      BluetoothDevice? printer = devices.firstWhere(
        (d) =>
            d.name?.toLowerCase().contains('printer') == true ||
            d.name?.toLowerCase().contains('pos') == true ||
            d.name?.toLowerCase().contains('a7n') == true,
        orElse: () => devices.isNotEmpty ? devices.first : throw Exception('Aucune imprimante trouvée'),
      );
      
      await bluetooth.connect(printer);
    }

    // Configuration du profil (80mm)
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Chargement du logo
    try {
      final ByteData data = await rootBundle.load('assets/logo.png');
      final Uint8List bytesImg = data.buffer.asUint8List();
      final img.Image? decodedImage = img.decodeImage(bytesImg);
      if (decodedImage != null) {
        final img.Image resized = img.copyResize(decodedImage, width: 200);
        bytes += generator.imageRaster(resized, align: PosAlign.center);
      }
    } catch (e) {
      debugPrint('Erreur chargement logo impression: $e');
    }
    bytes += generator.feed(1);

    // En-tête
    bytes += generator.text(
        Formatters.sanitizeThermalText(AppBrand.displayName),
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ));
    bytes += generator.feed(1);
    
    bytes += generator.text('RECU DE PAIEMENT',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(Formatters.sanitizeThermalText(invoice.numeroFacture),
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(
        Formatters.sanitizeThermalText(Formatters.formatDateTime(invoice.createdAt)),
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // Infos Commande
    if (invoice.commande != null) {
      if (invoice.commande!.table != null) {
        bytes += generator.text('Table: ${invoice.commande!.table!.numero}',
            styles: const PosStyles(bold: true));
      }
      bytes += generator.text('Commande #${invoice.commande!.id}');
    }
    bytes += generator.hr();

    final clientNom = invoice.commande?.client?.nomComplet;
    if (clientNom != null && clientNom.trim().isNotEmpty) {
      bytes += generator.text(
        Formatters.sanitizeThermalText('Client: $clientNom'),
        styles: const PosStyles(align: PosAlign.center, bold: true),
      );
      bytes += generator.feed(1);
    }

    // Articles
    bytes += generator.row([
      PosColumn(text: 'Art.', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qté', width: 2, styles: const PosStyles(bold: true, align: PosAlign.center)),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    if (invoice.commande?.produits != null) {
      for (var item in invoice.commande!.produits!) {
        bytes += generator.row([
          PosColumn(
              text: Formatters.sanitizeThermalText(item.produitNom), width: 6),
          PosColumn(text: '${item.quantite}', width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(
              text: Formatters.formatCurrencyThermal(item.total),
              width: 4,
              styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }
    bytes += generator.hr();

    // Totaux
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size1, width: PosTextSize.size1)),
      PosColumn(
          text: Formatters.formatCurrencyThermal(invoice.montantTotal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size1, width: PosTextSize.size1)),
    ]);

    if (invoice.paiement != null) {
      final p = invoice.paiement!;
      bytes += generator.text(
        Formatters.sanitizeThermalText(
            'Paye par: ${p.moyenPaiement.displayName}'),
        styles: const PosStyles(align: PosAlign.right),
      );
      if (p.moyenPaiement == PaymentMethod.especes) {
        final recu = p.montantRecu;
        var aRendre = p.monnaieRendue;
        if (aRendre == null && recu != null) {
          aRendre = (recu - p.montant);
          if (aRendre < 0) aRendre = 0;
        }
        if (recu != null) {
          bytes += generator.text(
            Formatters.sanitizeThermalText(
              'Montant recu: ${Formatters.formatCurrencyThermal(recu)}',
            ),
            styles: const PosStyles(align: PosAlign.right),
          );
        }
        if (aRendre != null) {
          bytes += generator.text(
            Formatters.sanitizeThermalText(
              'A rendre: ${Formatters.formatCurrencyThermal(aRendre)}',
            ),
            styles: const PosStyles(align: PosAlign.right),
          );
        }
      }
    }

    bytes += generator.feed(1);
    bytes += generator.hr();
    final caissier = invoice.paiement?.caissierName;
    if (caissier != null && caissier.trim().isNotEmpty) {
      bytes += generator.text(
        Formatters.sanitizeThermalText('Caissier: $caissier'),
        styles: const PosStyles(align: PosAlign.center),
      );
      bytes += generator.feed(1);
    }
    bytes += generator.text('MERCI DE VOTRE VISITE', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('A bientot !', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut();

    await bluetooth.writeBytes(Uint8List.fromList(bytes));
  }
}
