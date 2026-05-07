import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/order_service.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _loading = true;
  List<Map<String, dynamic>> _orders = const [];
  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

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
        return RefreshIndicator(
          onRefresh: _load,
          color: AppTheme.accent,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mes commandes',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: auth.isAuthenticated ? _load : null,
                    icon: const Icon(Icons.refresh, color: AppTheme.text),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!auth.isAuthenticated)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_outline,
                        color: AppTheme.textMuted,
                        size: 34,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Connecte-toi pour voir tes commandes',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.of(context).push<bool>(
                              MaterialPageRoute(
                                builder: (_) => const LoginScreen(),
                              ),
                            );
                            if (!context.mounted) return;
                            if (context.read<AuthState>().isAuthenticated) {
                              _load();
                            }
                          },
                          child: const Text('Se connecter'),
                        ),
                      ),
                    ],
                  ),
                )
              else if (_loading)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(
                    child: CircularProgressIndicator(color: AppTheme.accent),
                  ),
                )
              else if (_orders.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        color: AppTheme.textMuted,
                        size: 34,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Aucune commande en cours',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                )
              else
                for (final o in _orders) ...[
                  _OrderCard(order: o, money: _money),
                  const SizedBox(height: 12),
                ],
              const SizedBox(height: 90),
            ],
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.money});

  final Map<String, dynamic> order;
  final NumberFormat money;

  @override
  Widget build(BuildContext context) {
    final id = order['id'];
    final statut = (order['statut_display'] ?? order['statut'] ?? '')
        .toString();
    final montant = (order['montant_total'] ?? 0) as num;
    final table = order['table'];
    final place = table is Map
        ? 'Table ${(table['numero'] ?? '').toString()}'
        : 'À emporter';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.receipt_long, color: AppTheme.text),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#$id • $place',
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  statut,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            money.format(montant),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: AppTheme.accent,
            ),
          ),
        ],
      ),
    );
  }
}
