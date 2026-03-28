import 'package:flutter/material.dart';
import '../../models/table.dart' as models;
import '../../models/order.dart';
import '../../services/table_service.dart';
import '../../services/order_service.dart';
import '../../models/cart.dart';
import 'package:provider/provider.dart';
import '../../widgets/app_header.dart';
import '../home/home_screen.dart';
import '../orders/order_detail_screen.dart';
import 'qr_scan_screen.dart';

class TablesScreen extends StatefulWidget {
  const TablesScreen({super.key});

  @override
  State<TablesScreen> createState() => _TablesScreenState();
}

class _TablesScreenState extends State<TablesScreen> {
  final TableService _tableService = TableService();
  final OrderService _orderService = OrderService();
  List<models.Table> _tables = [];
  List<Order> _currentOrders = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    try {
      final results = await Future.wait([
        _tableService.getTables(),
        _orderService.getCurrentOrders(),
      ]);

      if (mounted) {
        setState(() {
          _tables = results[0] as List<models.Table>;
          _currentOrders = results[1] as List<Order>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des tables: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient
            AppHeader(
              title: 'Gestion des Tables',
              actions: [
                HeaderActionButton(
                  icon: Icons.qr_code_scanner,
                  onTap: _scanTable,
                ),
                HeaderActionButton(
                  icon: Icons.refresh,
                  onTap: _loadTables,
                ),
              ],
            ),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : _tables.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.table_restaurant,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune table configurée',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadTables,
                      color: Colors.orange,
                      backgroundColor: const Color(0xFF252525),
                      child: GridView.builder(
                        padding: const EdgeInsets.all(12),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 4,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                              childAspectRatio: 0.82,
                            ),
                        itemCount: _tables.length,
                        itemBuilder: (context, index) {
                          final table = _tables[index];
                          return _buildTableCard(table);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableCard(models.Table table) {
    final statusColor = table.statut.color;
    final statusText = table.statut.displayName;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handleTableSelection(table),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 7,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(
                      table.type == models.TableType.vip
                          ? Icons.star
                          : table.type == models.TableType.espaceJeux
                          ? Icons.sports_esports
                          : Icons.table_restaurant,
                      color: Colors.grey[400],
                      size: 14,
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1E1E1E),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.5),
                        offset: const Offset(1, 1),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    table.numero,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${table.capacite}',
                  style: TextStyle(color: Colors.grey[500], fontSize: 8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _scanTable() async {
    final result = await Navigator.push<models.Table>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(returnTableOnly: true),
      ),
    );

    if (result != null && mounted) {
      _handleTableSelection(result);
    }
  }

  void _handleTableSelection(models.Table table) {
    if (table.statut == models.TableStatus.reservee &&
        table.reservationActuelle != null) {
      _showReservationDetails(table);
    } else if (table.statut == models.TableStatus.libre) {
      // Nouvelle commande
      final cart = Provider.of<Cart>(context, listen: false);
      cart.clear();
      cart.setTable(table.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showBackButton: true),
        ),
      ).then((_) => _loadTables());
    } else if (table.statut == models.TableStatus.occupee ||
        table.statut == models.TableStatus.enPaiement) {
      // Trouver la commande active pour cette table
      final activeOrder = _currentOrders.fold<Order?>(
        null,
        (prev, order) {
          if (order.tableId == table.id &&
              order.statut != OrderStatus.terminee &&
              order.statut != OrderStatus.annulee) {
            return order;
          }
          return prev;
        },
      );

      if (activeOrder != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => OrderDetailScreen(orderId: activeOrder.id),
          ),
        ).then((_) => _loadTables());
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Aucune commande active trouvée pour cette table'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _showReservationDetails(models.Table table) {
    final reservation = table.reservationActuelle!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF252525),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.event, color: Colors.orange),
            const SizedBox(width: 10),
            Text(
              'Réservation Table ${table.numero}',
              style: const TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(Icons.person, 'Client', reservation.nomClient),
            _buildDetailRow(Icons.phone, 'Téléphone', reservation.telephone),
            _buildDetailRow(
              Icons.schedule,
              'Heure',
              reservation.heureDebut.substring(0, 5),
            ),
            _buildDetailRow(
              Icons.group,
              'Personnes',
              '${reservation.nombrePersonnes}',
            ),
            if (reservation.notes != null && reservation.notes!.isNotEmpty)
              _buildDetailRow(Icons.note, 'Notes', reservation.notes!),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 20, color: Colors.orange),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
