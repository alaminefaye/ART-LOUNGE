import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../config/app_theme.dart';
import '../models/invoice.dart';
import '../models/order.dart';
import '../utils/formatters.dart';

class PrinterService {
  BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;

  Future<List<BluetoothDevice>> getDevices() async {
    return await bluetooth.getBondedDevices();
  }

  Future<bool> isConnected() async {
    return await bluetooth.isConnected ?? false;
  }

  Future<BluetoothDevice?> getConnectedDevice() async {
    final devices = await bluetooth.getBondedDevices();
    return devices.isNotEmpty ? devices.first : null;
  }

  Future<void> connect(BluetoothDevice device) async {
    await bluetooth.connect(device);
  }

  Future<void> disconnect() async {
    await bluetooth.disconnect();
  }

  Future<void> _ensurePrinterConnected() async {
    final isConn = await bluetooth.isConnected;
    if (isConn == true) return;

    final devices = await bluetooth.getBondedDevices();
    if (devices.isEmpty) throw Exception('Aucune imprimante appairée trouvée');

    final printer = devices.firstWhere(
      (d) =>
          d.name?.toLowerCase().contains('printer') == true ||
          d.name?.toLowerCase().contains('pos') == true ||
          d.name?.toLowerCase().contains('a7n') == true ||
          d.name?.toLowerCase().contains('thermal') == true,
      orElse: () => devices.first,
    );
    await bluetooth.connect(printer);
    // Wait for connection
    await Future.delayed(const Duration(milliseconds: 500));
  }

  /// Print a pre-order ticket for the kitchen (table + items)
  /// [newItems]: when provided, only those items are printed (newly added batch).
  /// When null, all items in the order are printed (reprint mode).
  Future<void> printKitchenOrder(
    Order order, {
    String? serveurName,
    List<OrderItem>? newItems,
  }) async {
    await _ensurePrinterConnected();

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    var bytes = <int>[];

    bytes += generator.feed(1);
    bytes += generator.text(
      'BON DE COMMANDE',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.text(
      Formatters.sanitizeThermalText(AppBrand.displayName),
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.hr();

    if (order.table != null) {
      bytes += generator.text(
        'TABLE: ${order.table!.numero}',
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
    }
    bytes += generator.text('Commande #${order.id}');
    bytes += generator.text(
      Formatters.sanitizeThermalText(
        Formatters.formatDateTime(order.createdAt),
      ),
    );
    if (serveurName != null && serveurName.isNotEmpty) {
      bytes += generator.text(
        Formatters.sanitizeThermalText('Serveur: $serveurName'),
      );
    }
    bytes += generator.hr();

    bytes += generator.text('ARTICLES', styles: const PosStyles(bold: true));
    bytes += generator.feed(1);

    // Use newItems (just-added batch) or fallback to all order items (reprint)
    final produits = newItems ?? order.produits;
    if (produits != null && produits.isNotEmpty) {
      for (final item in produits) {
        bytes += generator.text(
          '${item.quantite} x ${Formatters.sanitizeThermalText(item.produitNom)}',
          styles: const PosStyles(bold: true),
        );
        bytes += generator.feed(1);
      }
    } else {
      bytes += generator.text(
        '(Aucun article)',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.feed(2);
    bytes += generator.text(
      '--- FIN BON ---',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    await bluetooth.writeBytes(Uint8List.fromList(bytes));
  }

  /// Print a receipt/invoice (when client asks for bill summary)
  Future<void> printReceipt(Invoice invoice, {String? serveurName}) async {
    await _ensurePrinterConnected();

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);
    List<int> bytes = [];

    // Logo
    try {
      final ByteData data = await rootBundle.load('assets/logo.png');
      final Uint8List bytesImg = data.buffer.asUint8List();
      final img.Image? decoded = img.decodeImage(bytesImg);
      if (decoded != null) {
        final img.Image resized = img.copyResize(decoded, width: 200);
        bytes += generator.imageRaster(resized, align: PosAlign.center);
      }
    } catch (e) {
      debugPrint('Logo print error: $e');
    }
    bytes += generator.feed(1);

    // Header
    bytes += generator.text(
      Formatters.sanitizeThermalText(AppBrand.displayName),
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.feed(1);
    bytes += generator.text(
      'DETAIL DE LA COMMANDE',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      Formatters.sanitizeThermalText(invoice.numeroFacture),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      Formatters.sanitizeThermalText(
        Formatters.formatDateTime(invoice.createdAt),
      ),
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();

    // Table info
    if (invoice.commande != null) {
      if (invoice.commande!.table != null) {
        bytes += generator.text(
          'Table: ${invoice.commande!.table!.numero}',
          styles: const PosStyles(bold: true),
        );
      }
      bytes += generator.text('Commande #${invoice.commande!.id}');
    }
    if (serveurName != null && serveurName.isNotEmpty) {
      bytes += generator.text(
        Formatters.sanitizeThermalText('Serveur: $serveurName'),
      );
    }
    bytes += generator.hr();

    // Items
    bytes += generator.row([
      PosColumn(text: 'Article', width: 6, styles: const PosStyles(bold: true)),
      PosColumn(
        text: 'Qte',
        width: 2,
        styles: const PosStyles(bold: true, align: PosAlign.center),
      ),
      PosColumn(
        text: 'Total',
        width: 4,
        styles: const PosStyles(bold: true, align: PosAlign.right),
      ),
    ]);

    if (invoice.commande?.produits != null) {
      for (var item in invoice.commande!.produits!) {
        bytes += generator.row([
          PosColumn(
            text: Formatters.sanitizeThermalText(item.produitNom),
            width: 6,
          ),
          PosColumn(
            text: '${item.quantite}',
            width: 2,
            styles: const PosStyles(align: PosAlign.center),
          ),
          PosColumn(
            text: Formatters.formatCurrencyThermal(item.total),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
      }
    }
    bytes += generator.hr();

    // Total
    bytes += generator.row([
      PosColumn(
        text: 'TOTAL',
        width: 6,
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
      PosColumn(
        text: Formatters.formatCurrencyThermal(invoice.montantTotal),
        width: 6,
        styles: const PosStyles(
          align: PosAlign.right,
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      ),
    ]);

    bytes += generator.feed(2);
    bytes += generator.hr();
    bytes += generator.text(
      'MERCI DE VOTRE VISITE',
      styles: const PosStyles(align: PosAlign.center, bold: true),
    );
    bytes += generator.text(
      'A bientot !',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.feed(3);
    bytes += generator.cut();

    await bluetooth.writeBytes(Uint8List.fromList(bytes));
  }
}
