import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../models/order.dart';
import '../../theme/app_theme.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class KitchenScreen extends StatefulWidget {
  const KitchenScreen({super.key});

  @override
  State<KitchenScreen> createState() => _KitchenScreenState();
}

class _KitchenScreenState extends State<KitchenScreen> {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  List<Order> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
    // Auto-refresh every 30 seconds
    Future.delayed(Duration.zero, _startAutoRefresh);
  }

  void _startAutoRefresh() {
    if (!mounted) return;
    _loadOrders(silent: true);
    Future.delayed(const Duration(seconds: 30), _startAutoRefresh);
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final orders = await _orderService.getOrders();
      if (mounted) {
        setState(() {
          // Uniquement les commandes en attente ou en préparation
          _orders = orders.where((o) => 
            o.statut == OrderStatus.attente || 
            o.statut == OrderStatus.preparation
          ).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(Order order, OrderStatus newStatus) async {
    setState(() => _isLoading = true);
    bool success = false;
    
    if (newStatus == OrderStatus.preparation) {
      final res = await _orderService.launchOrder(order.id);
      success = res['success'] == true;
    } else {
      success = await _orderService.updateOrderStatus(order.id, newStatus);
    }

    if (success) {
      _loadOrders();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: Colors.red),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.restaurant, color: AppTheme.brandGold),
            const SizedBox(width: 12),
            const Text('MODE CUISINE (KDS)', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textDark)),
            const Spacer(),
            Text('${_orders.length} Commandes en cours', style: const TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppTheme.brandGold),
            onPressed: () => _loadOrders(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await Provider.of<AuthService>(context, listen: false).logout();
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: _isLoading && _orders.isEmpty
        ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGold))
        : _orders.isEmpty 
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text('Tout est prêt ! Pas de commandes en attente.', 
                    style: TextStyle(fontSize: 20, color: Colors.grey, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 450,
                childAspectRatio: 0.75,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
              ),
              itemCount: _orders.length,
              itemBuilder: (context, index) => _buildOrderCard(_orders[index]),
            ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isPrep = order.statut == OrderStatus.preparation;
    final accentColor = isPrep ? Colors.blue : Colors.orange;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
        border: Border.all(color: accentColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TABLE ${order.table?.numero ?? "Caisse"}',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: accentColor),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('#${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '${DateTime.now().difference(order.createdAt).inMinutes} min depuis commande',
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Items List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: order.produits?.length ?? 0,
              separatorBuilder: (context, i) => Divider(color: Colors.grey.withValues(alpha: 0.1)),
              itemBuilder: (context, i) {
                final item = order.produits![i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${item.quantite}',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          item.produitNom,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Action Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {
                if (!isPrep) {
                  _updateStatus(order, OrderStatus.preparation);
                } else {
                  _updateStatus(order, OrderStatus.servie);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isPrep ? Colors.green : Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isPrep ? Icons.check_circle : Icons.play_arrow),
                  const SizedBox(width: 12),
                  Text(
                    isPrep ? 'MARQUER PRÊT' : 'COMMENCER',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
