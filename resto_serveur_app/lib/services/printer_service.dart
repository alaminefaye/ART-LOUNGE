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
      'BON DE CUISINE',
      styles: const PosStyles(
        align: PosAlign.center,
        bold: true,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
      ),
    );
    bytes += generator.hr();
    bytes += generator.text('Commande #${order.id}');
    if (order.table != null) {
      bytes += generator.text(
        'Table: ${order.table!.numero}',
        styles: const PosStyles(
          bold: true,
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ),
      );
    }
    bytes += generator.text(
      'Heure: ${order.createdAt.hour.toString().padLeft(2, '0')}:${order.createdAt.minute.toString().padLeft(2, '0')}',
    );
    if (serveurName != null && serveurName.isNotEmpty) {
      bytes += generator.text(
        Formatters.sanitizeThermalText('Serveur: $serveurName'),
      );
    }
    bytes += generator.hr();
    bytes += generator.feed(1);

    // Use newItems (just-added batch) or fallback to all order items (reprint)
    final produits = newItems ?? order.produits;
    if (produits != null && produits.isNotEmpty) {
      for (final item in produits) {
        bytes += generator.text(
          '${item.quantite}x ${Formatters.sanitizeThermalText(item.produitNom)}',
          styles: const PosStyles(
            bold: true,
            height: PosTextSize.size2,
            width: PosTextSize.size2,
          ),
        );
      }
    } else {
      bytes += generator.text(
        '(Aucun article)',
        styles: const PosStyles(align: PosAlign.center),
      );
    }

    bytes += generator.feed(2);
    bytes += generator.hr();
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
      'Dolce Vita Palace',
      styles: const PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );
    bytes += generator.text(
      'Ticket de Caisse',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.hr();
    
    // Command Info
    bytes += generator.text('Commande #${invoice.commande?.id ?? ''}');
    if (invoice.commande?.table != null) {
      bytes += generator.text('Table ${invoice.commande!.table!.numero}');
    }
    bytes += generator.text(
      '${invoice.createdAt.day.toString().padLeft(2, '0')}/${invoice.createdAt.month.toString().padLeft(2, '0')}/${invoice.createdAt.year}  ${invoice.createdAt.hour.toString().padLeft(2, '0')}:${invoice.createdAt.minute.toString().padLeft(2, '0')}',
    );
    if (serveurName != null && serveurName.isNotEmpty) {
      bytes += generator.text(
        Formatters.sanitizeThermalText('Serveur: $serveurName'),
      );
    }
    bytes += generator.hr();

    // Items
    if (invoice.commande?.produits != null) {
      for (var item in invoice.commande!.produits!) {
        bytes += generator.row([
          PosColumn(
            text: '${item.quantite}x ${Formatters.sanitizeThermalText(item.produitNom)}',
            width: 8,
          ),
          PosColumn(
            text: Formatters.formatCurrencyThermal(item.total),
            width: 4,
            styles: const PosStyles(align: PosAlign.right),
          ),
        ]);
        bytes += generator.feed(1);
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
    
    // Footer matches caisse exactly
    bytes += generator.text(
      'Merci de votre visite !',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Nimzatt Point de la Source',
      styles: const PosStyles(align: PosAlign.center),
    );
    bytes += generator.text(
      'Tel: 0708792031',
      styles: const PosStyles(align: PosAlign.center),
    );

    bytes += generator.feed(3);
    bytes += generator.cut();

    await bluetooth.writeBytes(Uint8List.fromList(bytes));
  }
}
