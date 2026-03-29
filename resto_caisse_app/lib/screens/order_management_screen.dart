import 'package:flutter/material.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../widgets/order_detail_modal.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
  List<Order> _ordersCurrent = [];
  List<Order> _ordersHistory = [];
  bool _isLoading = true;
  String _currentFilter = 'en_attente'; // en_attente, preparation, pret, toutes
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final ordersCurrent = await _orderService.getCurrentOrders();
      final ordersHistory = await _orderService.getHistoryOrders();
      if (mounted) {
        setState(() {
          _ordersCurrent = ordersCurrent;
          _ordersHistory = ordersHistory;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  bool _matchesSearch(Order order) {
    if (_searchQuery.isEmpty) return true;
    final query = _searchQuery.toLowerCase();
    final orderId = order.id.toString().toLowerCase();
    final clientName = (order.client?.nomComplet ?? 'Anonyme').toLowerCase();
    final tableNum = (order.table?.numero ?? 'Aucune').toLowerCase();
    
    return orderId.contains(query) || 
           clientName.contains(query) || 
           tableNum.contains(query);
  }

  List<Order> get _filteredOrders {
    List<Order> filtered = _ordersCurrent;
    if (_currentFilter == 'en_attente') {
      filtered = _ordersCurrent.where((o) => o.statut == OrderStatus.attente).toList();
    } else if (_currentFilter == 'preparation') {
      filtered = _ordersCurrent.where((o) => o.statut == OrderStatus.preparation).toList();
    } else if (_currentFilter == 'pret') {
      filtered = _ordersCurrent.where((o) => o.statut == OrderStatus.servie).toList();
    }
    
    return filtered.where(_matchesSearch).toList();
  }

  List<Order> get _filteredHistory {
    return _ordersHistory.where(_matchesSearch).toList();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: AppBar(
          title: const Text('Gestion des commandes'),
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadOrders),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'EN COURS'),
              Tab(text: 'HISTORIQUE'),
            ],
            labelColor: AppTheme.brandGold,
            unselectedLabelColor: Colors.black54,
            indicatorColor: AppTheme.brandGold,
          ),
        ),
        body: Column(
          children: [
            // Search Bar
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Rechercher par #ID, Client ou Table...',
                  prefixIcon: const Icon(Icons.search, color: AppTheme.brandGold),
                  suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.clear), 
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ) 
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.brandGold),
                  ),
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildEnCoursTab(),
                  _buildHistoriqueTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnCoursTab() {
    return Column(
      children: [
        // Filtres
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            alignment: WrapAlignment.center,
            children: [
              _buildFilterChip('En attente', 'en_attente'),
              _buildFilterChip('En cuisine', 'preparation'),
              _buildFilterChip('Prêt', 'pret'),
              _buildFilterChip('Toutes', 'toutes'),
            ],
          ),
        ),

        // Liste
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGold))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = _filteredOrders[index];
                    return _buildOrderCard(order);
                  },
                ),
        )
      ],
    );
  }

  Widget _buildHistoriqueTab() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGold))
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _filteredHistory.length,
            itemBuilder: (context, index) {
              final order = _filteredHistory[index];
              return _buildOrderCard(order);
            },
          );
  }

  Widget _buildOrderCard(Order order) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (ctx) => OrderDetailModal(
              order: order,
              onOrderUpdated: _loadOrders,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text('Commande #${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              'Client: ${order.client?.nomComplet ?? 'Anonyme'} - Table: ${order.table?.numero ?? 'Aucune'}\n${Formatters.formatCurrency(order.montantTotal)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: order.statut.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(order.statut.displayName, style: TextStyle(color: order.statut.color, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _currentFilter = value);
      },
      selectedColor: AppTheme.brandGold.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.brandGold : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
