import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/order.dart';
import '../models/cart.dart';
import '../utils/formatters.dart';

class PrinterService {
  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final ByteData data = await rootBundle.load('assets/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  // Impression d'un ticket de caisse depuis le panier
  Future<void> printReceiptFromCart(Cart cart) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (logo != null) pw.Image(logo, width: 60, height: 60),
              pw.SizedBox(height: 10),
              pw.Text('Teranguest Resto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Ticket de Caisse', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),
              ...cart.items.map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text('${item.quantite}x ${item.product.nom}', style: const pw.TextStyle(fontSize: 12))),
                    pw.Text(Formatters.formatCurrency(item.total), style: const pw.TextStyle(fontSize: 12)),
                  ],
                );
              }),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(Formatters.formatCurrency(cart.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Merci de votre visite !', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Ticket_${DateTime.now().millisecondsSinceEpoch}',
    );
  }

  // Impression d'un bon de cuisine depuis une commande
  Future<void> printKitchenTicket(Order order) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Center(child: pw.Text('BON DE CUISINE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Text('Commande #${order.id}', style: const pw.TextStyle(fontSize: 12)),
              if (order.table != null) pw.Text('Table: ${order.table?.numero}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Heure: ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),
              if (order.produits != null)
                ...order.produits!.map((p) => pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${p.quantite}x ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                    pw.Expanded(child: pw.Text(p.produitNom, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14))),
                  ],
                )),
              pw.SizedBox(height: 20),
              pw.Divider(),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Cuisine_${order.id}',
    );
  }

  // Impression d'une facture depuis une commande existante
  Future<void> printOrderReceipt(Order order) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (logo != null) pw.Image(logo, width: 60, height: 60),
              pw.SizedBox(height: 10),
              pw.Text('Teranguest Resto', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
              pw.Text('Ticket de Caisse', style: const pw.TextStyle(fontSize: 12)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),
              pw.Text('Commande #${order.id}', style: const pw.TextStyle(fontSize: 12)),
              if (order.table != null) pw.Text('Table ${order.table!.numero}', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 10),
              if (order.produits != null)
                ...order.produits!.map((item) {
                  return pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(child: pw.Text('${item.quantite}x ${item.produitNom}', style: const pw.TextStyle(fontSize: 12))),
                      pw.Text(Formatters.formatCurrency(item.total), style: const pw.TextStyle(fontSize: 12)),
                    ],
                  );
                }),
              pw.SizedBox(height: 10),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                  pw.Text(Formatters.formatCurrency(order.montantTotal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Text('Merci de votre visite !', style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Facture_${order.id}',
    );
  }

  /// Bon de cuisine SUPPLÉMENT — uniquement les articles nouvellement ajoutés.
  Future<void> printSupplementKitchenTicket({
    required int orderId,
    required String tableNumero,
    required List<Map<String, dynamic>> additions,
  }) async {
    if (additions.isEmpty) return;
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.roll80,
        build: (context) {
          final now = DateTime.now();
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Center(child: pw.Text('★ SUPPLÉMENT CUISINE ★',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 15))),
              pw.Divider(thickness: 2, borderStyle: pw.BorderStyle.solid),
              pw.Text('Commande #$orderId', style: const pw.TextStyle(fontSize: 12)),
              pw.Text('Table : $tableNumero',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.Text(
                  'Heure : ${now.hour.toString().padLeft(2, "0")}:${now.minute.toString().padLeft(2, "0")}',
                  style: const pw.TextStyle(fontSize: 11)),
              pw.Divider(thickness: 1, borderStyle: pw.BorderStyle.dashed),
              pw.SizedBox(height: 8),
              ...additions.map((a) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 4),
                    child: pw.Row(children: [
                      pw.Text('${a["quantite"]}x ',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16)),
                      pw.Expanded(
                          child: pw.Text('${a["nom"]}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16))),
                    ]),
                  )),
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.Center(
                  child: pw.Text('— À préparer en PLUS —',
                      style: const pw.TextStyle(fontSize: 10))),
              pw.SizedBox(height: 20),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Supplement_${orderId}_${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
