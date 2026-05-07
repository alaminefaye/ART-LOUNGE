import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/order_service.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _orders = const [];
  final _money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final service = context.read<OrderService>();
      final orders = await service.fetchMyOrders(current: true);
      if (!mounted) return;
      setState(() => _orders = orders);
    } catch (_) {
      if (mounted) {
        setState(() => _orders = const []);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, auth, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mes commandes'),
            actions: [
              IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
            ],
          ),
          body: auth.isAuthenticated
              ? (_loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_orders.isEmpty
                      ? const Center(child: Text('Aucune commande en cours'))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemBuilder: (context, index) {
                            final o = _orders[index];
                            final id = o['id'];
                            final statut = (o['statut_display'] ?? o['statut'] ?? '').toString();
                            final montant = (o['montant_total'] ?? 0) as num;
                            final table = o['table'];
                            final place = table is Map ? 'Table ${(table['numero'] ?? '').toString()}' : 'À emporter';
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.black12),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppTheme.backgroundColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(Icons.receipt_long, color: AppTheme.brandGold),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('#$id • $place', style: const TextStyle(fontWeight: FontWeight.w800)),
                                        const SizedBox(height: 4),
                                        Text(statut, style: const TextStyle(color: Colors.black54)),
                                      ],
                                    ),
                                  ),
                                  Text(_money.format(montant), style: const TextStyle(fontWeight: FontWeight.w900)),
                                ],
                              ),
                            );
                          },
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemCount: _orders.length,
                        )))
              : const Center(child: Text('Connecte-toi pour voir tes commandes')),
        );
      },
    );
  }
}

