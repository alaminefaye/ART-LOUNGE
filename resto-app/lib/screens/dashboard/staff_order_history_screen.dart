import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_header.dart';
import '../orders/order_detail_screen.dart';

/// Liste complète des commandes (toutes dates) avec recherche et tri par date.
class StaffOrderHistoryScreen extends StatefulWidget {
  const StaffOrderHistoryScreen({super.key});

  @override
  State<StaffOrderHistoryScreen> createState() =>
      _StaffOrderHistoryScreenState();
}

class _StaffOrderHistoryScreenState extends State<StaffOrderHistoryScreen> {
  final OrderService _orderService = OrderService();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<Order> _orders = [];
  bool _isLoading = true;
  bool _newestFirst = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final list = await _orderService.getStaffOrderHistory(
        search: _searchController.text,
        newestFirst: _newestFirst,
      );
      if (mounted) {
        setState(() {
          _orders = list;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    }
  }

  void _onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            AppHeader(
              title: 'Historique des commandes',
              showBackButton: true,
              onBack: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText:
                      'N° commande, table, téléphone ou nom client…',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                            _load();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
                onChanged: (v) {
                  setState(() {});
                  _onSearchChanged(v);
                },
                onSubmitted: (_) => _load(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Tri par date :'),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment<bool>(
                          value: true,
                          label: Text('Récent'),
                          icon: Icon(Icons.arrow_downward, size: 18),
                        ),
                        ButtonSegment<bool>(
                          value: false,
                          label: Text('Ancien'),
                          icon: Icon(Icons.arrow_upward, size: 18),
                        ),
                      ],
                      selected: {_newestFirst},
                      onSelectionChanged: (Set<bool> s) {
                        setState(() {
                          _newestFirst = s.first;
                        });
                        _load();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                color: Colors.orange,
                backgroundColor: Colors.white,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Text(
              'Aucune commande trouvée.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _orders.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final o = _orders[index];
        final tableLabel = o.table?.numero ?? '—';
        String? clientLine;
        if (o.client != null) {
          final c = o.client!;
          final parts = <String>[];
          if (c.nomComplet.isNotEmpty) parts.add(c.nomComplet);
          if (c.telephone != null && c.telephone!.isNotEmpty) {
            parts.add(c.telephone!);
          }
          clientLine = parts.isEmpty ? null : parts.join(' · ');
        }
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(vertical: 4),
          title: Text(
            'Commande #${o.id} · Table $tableLabel',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Formatters.formatDateTime(o.createdAt),
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 13,
                ),
              ),
              if (clientLine != null)
                Text(
                  clientLine,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              Text(
                '${o.statut.displayName} · ${Formatters.formatCurrency(o.montantTotal)}',
                style: const TextStyle(fontSize: 13),
              ),
            ],
          ),
          isThreeLine: clientLine != null,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => OrderDetailScreen(orderId: o.id),
              ),
            ).then((_) => _load());
          },
        );
      },
    );
  }
}
