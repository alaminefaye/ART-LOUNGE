import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../models/invoice.dart';
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
    bytes += generator.text('RESTO',
        styles: const PosStyles(
          align: PosAlign.center,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
          bold: true,
        ));
    bytes += generator.feed(1);
    
    bytes += generator.text('RECU DE PAIEMENT',
        styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text(invoice.numeroFacture,
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(Formatters.formatDateTime(invoice.createdAt),
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

    // Articles
    bytes += generator.row([
      PosColumn(text: 'Art.', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Qté', width: 2, styles: const PosStyles(bold: true, align: PosAlign.center)),
      PosColumn(text: 'Total', width: 4, styles: const PosStyles(bold: true, align: PosAlign.right)),
    ]);

    if (invoice.commande?.produits != null) {
      for (var item in invoice.commande!.produits!) {
        bytes += generator.row([
          PosColumn(text: item.produitNom, width: 6),
          PosColumn(text: '${item.quantite}', width: 2, styles: const PosStyles(align: PosAlign.center)),
          PosColumn(text: Formatters.formatCurrency(item.total), width: 4, styles: const PosStyles(align: PosAlign.right)),
        ]);
      }
    }
    bytes += generator.hr();

    // Totaux
    bytes += generator.row([
      PosColumn(text: 'TOTAL', width: 6, styles: const PosStyles(bold: true, height: PosTextSize.size1, width: PosTextSize.size1)),
      PosColumn(
          text: Formatters.formatCurrency(invoice.montantTotal),
          width: 6,
          styles: const PosStyles(align: PosAlign.right, bold: true, height: PosTextSize.size1, width: PosTextSize.size1)),
    ]);

    if (invoice.paiement != null) {
      bytes += generator.text('Payé par: ${invoice.paiement!.moyenPaiement.displayName}',
          styles: const PosStyles(align: PosAlign.right));
      if (invoice.paiement!.monnaieRendue != null && invoice.paiement!.monnaieRendue! > 0) {
        bytes += generator.text('Monnaie rendue: ${Formatters.formatCurrency(invoice.paiement!.monnaieRendue!)}',
            styles: const PosStyles(align: PosAlign.right));
      }
    }

    bytes += generator.feed(1);
    bytes += generator.hr();
    bytes += generator.text('MERCI DE VOTRE VISITE', styles: const PosStyles(align: PosAlign.center, bold: true));
    bytes += generator.text('A bientot !', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(3);
    bytes += generator.cut();

    await bluetooth.writeBytes(Uint8List.fromList(bytes));
  }
}
