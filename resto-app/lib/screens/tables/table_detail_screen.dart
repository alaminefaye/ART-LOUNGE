import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import '../../models/table.dart' as models;
import '../../models/cart.dart';
import '../../utils/formatters.dart';
import '../menu/products_screen.dart';
import '../../widgets/app_header.dart';

class TableDetailScreen extends StatelessWidget {
  final models.Table table;

  const TableDetailScreen({super.key, required this.table});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient
            AppHeader(title: 'Table ${table.numero}'),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            // Card avec infos de la table
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF252525),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.05),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A2A2A),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(2, 2),
                                blurRadius: 4,
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.05),
                                offset: const Offset(-1, -1),
                                blurRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.table_restaurant,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Table ${table.numero}',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2A2A2A),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.white.withValues(
                                        alpha: 0.05,
                                      ),
                                      offset: const Offset(-1, -1),
                                      blurRadius: 2,
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      offset: const Offset(2, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  table.type.displayName,
                                  style: TextStyle(
                                    color: Colors.grey[400],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: table.statut.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: table.statut.color,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: table.statut.color.withValues(
                                  alpha: 0.2,
                                ),
                                offset: const Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Text(
                            table.statut.displayName,
                            style: TextStyle(
                              color: table.statut.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Divider(color: Colors.grey[800], height: 1),
                    const SizedBox(height: 24),
                    _buildInfoRow(
                      context,
                      Icons.people,
                      'Capacité',
                      '${table.capacite} personnes',
                    ),
                    if (table.prix != null)
                      _buildInfoRow(
                        context,
                        Icons.attach_money,
                        'Prix',
                        Formatters.formatCurrency(table.prix!),
                      ),
                    if (table.prixParHeure != null)
                      _buildInfoRow(
                        context,
                        Icons.access_time,
                        'Prix/heure',
                        '${Formatters.formatCurrency(table.prixParHeure!)}/h',
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            if (table.qrCodeUrl.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF252525),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(4, 4),
                      blurRadius: 8,
                    ),
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.05),
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        'QR Code de la Table',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: table.qrCodeUrl,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scannez pour accéder au menu',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 32),

            // Bouton pour voir le menu
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.3),
                    offset: const Offset(4, 4),
                    blurRadius: 8,
                  ),
                  BoxShadow(
                    color: const Color(0xFF252525),
                    offset: const Offset(-2, -2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  final cart = Provider.of<Cart>(context, listen: false);
                  cart.setTable(table.id);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProductsScreen(tableId: table.id),
                    ),
                  );
                },
                icon: const Icon(Icons.restaurant_menu),
                label: const Text(
                  'Voir le Menu',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 0,
                ),
              ),
            ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  offset: const Offset(-1, -1),
                  blurRadius: 2,
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  offset: const Offset(2, 2),
                  blurRadius: 4,
                ),
              ],
            ),
            child: Icon(icon, size: 20, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Text(
            '$label: ',
            style: TextStyle(
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.white,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
