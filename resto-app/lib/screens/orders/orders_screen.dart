import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../services/fcm_events.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart'; // Import AuthService
import '../../utils/formatters.dart';
import '../menu/menu_screen.dart';
import 'order_detail_screen.dart';
import '../../widgets/app_header.dart';

class OrdersScreen extends StatefulWidget {
  final bool showBackButton;

  const OrdersScreen({super.key, this.showBackButton = true});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final OrderService _orderService = OrderService();
  List<Order> _orders = [];
  bool _isLoading = true;
  StreamSubscription? _orderUpdateSubscription;

  @override
  void initState() {
    super.initState();
    _loadOrders();

    // Écouter les mises à jour des commandes
    _orderUpdateSubscription = FCMEvents.orderUpdateStream.listen((_) {
      if (mounted) {
        _loadOrders();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Liste des commandes mise à jour 🔔'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _orderUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Charger uniquement les commandes du jour non terminées
      final orders = await _orderService.getCurrentOrders();

      if (mounted) {
        setState(() {
          _orders = orders;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des commandes: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final isStaff =
        user != null &&
        (user.hasRole('admin') ||
            user.hasRole('manager') ||
            user.hasRole('serveur') ||
            user.hasRole('caissier'));
    final String title = isStaff ? 'Toutes les Commandes' : 'Mes Commandes';

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      floatingActionButton: isStaff
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MenuScreen()),
                );
              },
              backgroundColor: Colors.orange,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Nouvelle Commande',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient
            AppHeader(
              title: title,
              showBackButton: widget.showBackButton,
              onBack: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => const MenuScreen(),
                    ),
                  );
                }
              },
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : _orders.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  offset: const Offset(0, 10),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.receipt_long_outlined,
                              size: 60,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Aucune commande en cours',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vos commandes du jour en cours\napparaîtront ici',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrders,
                      color: const Color(0xFFD0A030),
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        itemCount: _orders.length,
                        itemBuilder: (context, index) {
                          final order = _orders[index];
                          return _buildOrderCard(context, order);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: order.id),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.receipt_long,
                            color: Color(0xFFD0A030),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Commande #${order.id}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          order.statut,
                        ).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: _getStatusColor(
                            order.statut,
                          ).withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        order.statut.displayName,
                        style: TextStyle(
                          color: _getStatusColor(order.statut),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (order.table != null) ...[
                          Icon(
                            Icons.table_restaurant,
                            size: 14,
                            color: Colors.grey[500],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Table ${order.table!.numero}',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.shopping_bag,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${order.produits?.length ?? 0} article(s)',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      Formatters.formatCurrency(order.montantTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFD0A030),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  Formatters.formatRelativeDate(order.createdAt),
                  style: TextStyle(color: Colors.grey[700], fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.attente:
        return Colors.orange;
      case OrderStatus.preparation:
        return Colors.blue;
      case OrderStatus.servie:
        return Colors.green;
      case OrderStatus.terminee:
        return Colors.green;
      case OrderStatus.annulee:
        return Colors.red;
    }
  }
}
