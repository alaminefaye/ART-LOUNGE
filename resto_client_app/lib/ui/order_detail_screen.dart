import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/order_service.dart';
import '../theme/app_theme.dart';

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _detail;

  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  late final DateFormat _dateFmt = DateFormat.yMMMd('fr_FR').add_Hm();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await context.read<OrderService>().fetchOrderById(widget.orderId);
      if (!mounted) return;
      setState(() {
        _detail = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> _products() {
    final raw = _detail?['produits'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Map<String, dynamic>.from(m))
        .toList();
  }

  String _lieu(Map<String, dynamic> d) {
    final table = d['table'];
    if (table is Map && (table['numero'] ?? '').toString().isNotEmpty) {
      return 'Table ${table['numero']}';
    }
    return 'À emporter';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded),
                      color: AppTheme.text,
                    ),
                    Expanded(
                      child: Text(
                        'Commande #${widget.orderId}',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: _loading ? null : _load,
                      icon: const Icon(Icons.refresh_rounded),
                      color: AppTheme.text,
                    ),
                  ],
                ),
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.accent),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: AppTheme.textMuted, size: 48),
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.textMuted, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 18),
              ElevatedButton(onPressed: _load, child: const Text('Réessayer')),
            ],
          ),
        ),
      );
    }

    final d = _detail!;
    final montant = (d['montant_total'] ?? 0) as num;
    final statut = (d['statut_display'] ?? d['statut'] ?? '').toString();
    final notes = (d['notes'] as String?)?.trim();
    final reduc = (d['reduction_fidelite'] ?? 0) as num;

    DateTime? created;
    try {
      final cs = d['created_at'];
      if (cs is String) created = DateTime.tryParse(cs);
    } catch (_) {}

    final produits = _products();

    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _lieu(d),
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    ),
                    child: Text(
                      statut,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    ),
                  ),
                ],
              ),
              if (created != null) ...[
                const SizedBox(height: 8),
                Text(
                  _dateFmt.format(created.toLocal()),
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'Articles',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
        ),
        const SizedBox(height: 10),
        if (produits.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Aucune ligne disponible.',
                style: TextStyle(color: AppTheme.textMuted.withValues(alpha: 0.9)),
              ),
            ),
          )
        else
          ...produits.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${p['nom'] ?? ''}',
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${p['quantite'] ?? 0} × ${_money.format((p['prix_unitaire'] ?? 0) as num)}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                          if ((((p['notes'] as String?) ?? '').trim().isNotEmpty))
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Note : ${((p['notes'] as String?) ?? '').trim()}',
                                style: TextStyle(
                                  color: AppTheme.accent.withValues(alpha: 0.95),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      _money.format((p['sous_total'] ?? 0) as num),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (notes != null && notes.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.brandGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppTheme.brandGoldLight.withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Note pour le restaurant',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Text(notes, style: const TextStyle(fontWeight: FontWeight.w600, height: 1.35)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            children: [
              if (reduc > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Réduction fidélité',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textMuted,
                        ),
                      ),
                      Text(
                        '- ${_money.format(reduc)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Colors.lightGreenAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                  Text(
                    _money.format(montant),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppTheme.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
