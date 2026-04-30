import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  // --- Gestion de l'imprimante par défaut ---

  static const String _kDefaultPrinterKey = 'default_printer_name';

  Future<List<Printer>> getAvailablePrinters() async {
    return await Printing.listPrinters();
  }

  Future<void> setDefaultPrinter(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultPrinterKey, name);
  }

  Future<String?> getDefaultPrinterName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_kDefaultPrinterKey);
  }

  // Format thermique optimisé pour imprimantes POS80 (72mm de large, DPI 203)
  static final _thermalFormat = PdfPageFormat(
    72 * PdfPageFormat.mm,
    double.infinity,
    marginAll: 4 * PdfPageFormat.mm,
  );

  // Méthode générique pour imprimer (Silencieux si configuré, sinon dialogue)
  Future<void> _dispatchPrint(pw.Document pdf, String jobName) async {
    final defaultName = await getDefaultPrinterName();
    
    if (defaultName != null && defaultName.isNotEmpty) {
      final printers = await getAvailablePrinters();
      Printer? targetPrinter;
      
      try {
        targetPrinter = printers.firstWhere((p) => p.name == defaultName);
      } catch (e) {
        targetPrinter = null;
      }

      if (targetPrinter != null) {
        await Printing.directPrintPdf(
          printer: targetPrinter,
          onLayout: (PdfPageFormat format) async => pdf.save(),
          name: jobName,
        );
        return;
      }
    }

    // Comportement par défaut : Boîte de dialogue standard
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: jobName,
      format: _thermalFormat,
    );
  }

  // Impression d'un ticket de caisse depuis le panier
  Future<void> printReceiptFromCart(Cart cart) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: _thermalFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              if (logo != null) pw.Image(logo, width: 50, height: 50, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 4),
              pw.Text('Art Restaurant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black)),
              pw.Text('Ticket de Caisse', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
              pw.SizedBox(height: 4),
              ...cart.items.map((item) {
                return pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(child: pw.Text('${item.quantite}x ${item.product.nom}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black))),
                    pw.Text(Formatters.formatCurrency(item.total), style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                  ],
                );
              }),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                  pw.Text(Formatters.formatCurrency(cart.total), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                ],
              ),
              pw.SizedBox(height: 8),
              pw.Text('Merci de votre visite !', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              pw.SizedBox(height: 4),
              pw.Text('Nimzatt Point de la Source', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              pw.Text('Tél: 0708792031', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    await _dispatchPrint(pdf, 'Ticket_${DateTime.now().millisecondsSinceEpoch}');
  }

  // Impression d'un bon de cuisine depuis une commande
  Future<void> printKitchenTicket(Order order) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: _thermalFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              pw.Center(child: pw.Text('BON DE CUISINE', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black))),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
              pw.Text('Commande #${order.id}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
              if (order.table != null) pw.Text('Table: ${order.table?.numero}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
              if (order.serveur != null) pw.Text('Serveur: ${order.serveur?.prenom != null ? '${order.serveur?.prenom} ' : ''}${order.serveur?.nom}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.black)),
              pw.Text('Heure: ${order.createdAt.hour}:${order.createdAt.minute.toString().padLeft(2, '0')}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
              pw.SizedBox(height: 6),
              if (order.produits != null)
                ...order.produits!.map((p) => pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${p.quantite}x ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                    pw.Expanded(child: pw.Text(p.produitNom, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black))),
                  ],
                )),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.black),
            ],
          );
        },
      ),
    );

    await _dispatchPrint(pdf, 'Cuisine_${order.id}');
  }

  // Impression d'une facture depuis une commande existante
  Future<void> printOrderReceipt(Order order, {String? cashierName}) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();

    pdf.addPage(
      pw.Page(
        pageFormat: _thermalFormat,
        build: (context) {
          final bool hasClient = order.client != null && order.client!.nomComplet.isNotEmpty;
          final bool hasFidelite = order.reductionFidelite > 0 && order.pointsUtilises > 0;
          final double netAPayer = order.montantTotal - order.reductionFidelite;

          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            mainAxisSize: pw.MainAxisSize.min,
            children: [
              // === EN-TÊTE ===
              if (logo != null) pw.Image(logo, width: 55, height: 55, fit: pw.BoxFit.contain),
              pw.SizedBox(height: 4),
              pw.Text('Art Restaurant', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: PdfColors.black)),
              pw.Text('Ticket de Caisse', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),

              // === CLIENT (si associé) ===
              if (hasClient) ...[
                pw.SizedBox(height: 4),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
                pw.Text('Client: ${order.client!.nomComplet}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black)),
                if (order.client!.telephone != null && order.client!.telephone!.isNotEmpty)
                  pw.Text('Tél: ${order.client!.telephone}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              ],

              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
              pw.SizedBox(height: 3),
              pw.Text('Commande #${order.id}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
              if (order.table != null)
                pw.Text('Table ${order.table!.numero}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
              if (order.serveur != null)
                pw.Text('Serveur: ${order.serveur!.prenom != null ? '${order.serveur!.prenom} ' : ''}${order.serveur!.nom}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
              pw.Text(
                '${order.createdAt.day.toString().padLeft(2,'0')}/${order.createdAt.month.toString().padLeft(2,'0')}/${order.createdAt.year}  ${order.createdAt.hour.toString().padLeft(2,'0')}:${order.createdAt.minute.toString().padLeft(2,'0')}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.black),
              ),
              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

              // === ARTICLES ===
              pw.SizedBox(height: 3),
              if (order.produits != null)
                ...order.produits!.map((item) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(child: pw.Text('${item.quantite}x ${item.produitNom}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black))),
                        pw.Text(Formatters.formatCurrency(item.total), style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                      ],
                    ),
                  );
                }),

              pw.SizedBox(height: 4),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),

              // === TOTAUX ===
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Sous-total', style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                  pw.Text(Formatters.formatCurrency(order.montantTotal), style: const pw.TextStyle(fontSize: 9, color: PdfColors.black)),
                ],
              ),

              // === SECTION FIDÉLITÉ ===
              if (hasFidelite) ...[
                pw.SizedBox(height: 3),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
                pw.Center(child: pw.Text('★ RÉDUCTION FIDÉLITÉ ★', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black))),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Points utilisés: ${order.pointsUtilises} pts', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
                    pw.Text('- ${Formatters.formatCurrency(order.reductionFidelite)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.black)),
                  ],
                ),
                pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed, color: PdfColors.black),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('NET À PAYER', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                    pw.Text(Formatters.formatCurrency(netAPayer), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                  ],
                ),
              ] else ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                    pw.Text(Formatters.formatCurrency(order.montantTotal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11, color: PdfColors.black)),
                  ],
                ),
              ],

              // === PIED DE PAGE ===
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 0.5, color: PdfColors.black),
              pw.Text('Merci de votre visite !', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              if (cashierName != null && cashierName.isNotEmpty)
                pw.Text('Caissier: $cashierName', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              pw.Text('Nimzatt Point de la Source', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              pw.Text('Tél: 0708792031', style: const pw.TextStyle(fontSize: 8, color: PdfColors.black)),
              pw.SizedBox(height: 8),
            ],
          );
        },
      ),
    );

    await _dispatchPrint(pdf, 'Facture_${order.id}');
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
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                      pw.Expanded(
                          child: pw.Text('${a["nom"]}',
                              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11))),
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
    await _dispatchPrint(pdf, 'Supplement_${orderId}_${DateTime.now().millisecondsSinceEpoch}');
  }

  /// Rapport de clôture de caisse (format thermique 72mm)
  Future<void> printClosingReport({
    required Map<String, dynamic> bilan,
    required String cashierName,
    required DateTime openedAt,
  }) async {
    final pdf = pw.Document();
    final logo = await _loadLogo();
    final now = DateTime.now();

    double parseD(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    String fmt2(int v) => v.toString().padLeft(2, '0');

    final List repartition = bilan['repartition'] ?? [];
    final List transactions = bilan['transactions'] ?? [];
    final double totalVentes = parseD(bilan['total_ventes']);
    final double soldeOuverture = parseD(bilan['solde_ouverture']);

    // Agrégation produits vendus par nom
    final Map<String, Map<String, dynamic>> prodMap = {};
    for (final t in transactions) {
      final commande = t['commande'];
      if (commande == null) continue;
      final produits = commande['produits'] as List? ?? [];
      for (final p in produits) {
        final nom = p['produit']?['nom']?.toString()
            ?? p['produit_nom']?.toString()
            ?? 'Article';
        final qte = (p['quantite'] as num?)?.toInt() ?? 1;
        final prix = parseD(p['prix_unitaire']);
        if (prodMap.containsKey(nom)) {
          prodMap[nom]!['qte'] = (prodMap[nom]!['qte'] as int) + qte;
          prodMap[nom]!['total'] = parseD(prodMap[nom]!['total']) + prix * qte;
        } else {
          prodMap[nom] = {'qte': qte, 'total': prix * qte};
        }
      }
    }

    // Meilleur serveur (par montant vendu)
    final Map<String, double> serveurTotaux = {};
    for (final t in transactions) {
      final serveur = t['commande']?['serveur'];
      if (serveur == null) continue;
      final name = serveur['name']?.toString() ?? '';
      if (name.isEmpty) continue;
      serveurTotaux[name] = (serveurTotaux[name] ?? 0) + parseD(t['montant']);
    }
    String? topServeur;
    double topTotal = 0;
    serveurTotaux.forEach((s, v) {
      if (v > topTotal) { topTotal = v; topServeur = s; }
    });

    pdf.addPage(
      pw.Page(
        pageFormat: _thermalFormat,
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          mainAxisSize: pw.MainAxisSize.min,
          children: [
            // En-tête
            if (logo != null) pw.Image(logo, width: 48, height: 48, fit: pw.BoxFit.contain),
            pw.SizedBox(height: 2),
            pw.Text('Art Restaurant',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
            pw.Text('RAPPORT DE CLÔTURE',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

            // Infos session
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Ouverture: ${fmt2(openedAt.day)}/${fmt2(openedAt.month)}/${openedAt.year}  ${fmt2(openedAt.hour)}:${fmt2(openedAt.minute)}',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text('Caissier: $cashierName',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  pw.Text('Fond ouverture: ${Formatters.formatCurrency(soldeOuverture)}',
                      style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
            ),
            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

            // Produits vendus
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text('PRODUITS VENDUS',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.SizedBox(height: 2),
            if (prodMap.isEmpty)
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('Aucune vente enregistrée', style: const pw.TextStyle(fontSize: 8)),
              )
            else
              ...prodMap.entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(vertical: 1),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Text(
                            '${e.value['qte']}x  ${e.key}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                        ),
                        pw.Text(
                          Formatters.formatCurrency(parseD(e.value['total'])),
                          style: const pw.TextStyle(fontSize: 8),
                        ),
                      ],
                    ),
                  )),

            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

            // Répartition par moyen de paiement
            pw.Align(
              alignment: pw.Alignment.centerLeft,
              child: pw.Text('MOYENS DE PAIEMENT',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
            ),
            pw.SizedBox(height: 2),
            ...repartition.map((item) {
              final String label =
                  item['moyen_paiement']?.toString().toUpperCase() ?? '';
              final double total = parseD(item['total']);
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(vertical: 1),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(label, style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(Formatters.formatCurrency(total),
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold, fontSize: 8)),
                  ],
                ),
              );
            }),

            pw.Divider(thickness: 0.8, borderStyle: pw.BorderStyle.solid),

            // Total général
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL CAISSE',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text(Formatters.formatCurrency(totalVentes),
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
              ],
            ),

            pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),

            // Meilleur serveur
            if (topServeur != null) ...[
              pw.SizedBox(height: 2),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text('TOP SERVEUR DU SHIFT',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 9)),
              ),
              pw.Align(
                alignment: pw.Alignment.centerLeft,
                child: pw.Text(
                  '★ $topServeur — ${Formatters.formatCurrency(topTotal)}',
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, fontSize: 9),
                ),
              ),
              pw.Divider(thickness: 0.5, borderStyle: pw.BorderStyle.dashed),
            ],

            // Pied de page
            pw.SizedBox(height: 4),
            pw.Text(
              'Imprimé le ${fmt2(now.day)}/${fmt2(now.month)}/${now.year} à ${fmt2(now.hour)}:${fmt2(now.minute)}',
              style: const pw.TextStyle(fontSize: 7),
            ),
            pw.Text('Session ouverte par: $cashierName',
                style: const pw.TextStyle(fontSize: 7)),
            pw.SizedBox(height: 8),
          ],
        ),
      ),
    );

    await _dispatchPrint(pdf, 'Cloture_${now.millisecondsSinceEpoch}');
  }
}
