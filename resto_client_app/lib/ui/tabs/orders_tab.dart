import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/order_service.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../login_screen.dart';
import '../order_detail_screen.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  bool _loading = false;
  List<Map<String, dynamic>> _orders = const [];
  AuthState? _auth;
  bool _autoLoadedForSession = false;
  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );
  late final DateFormat _dateFmt = DateFormat.yMMMd('fr_FR').add_Hm();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.read<AuthState>();
    if (!identical(_auth, auth)) {
      _auth?.removeListener(_onAuthChanged);
      _auth = auth;
      _auth?.addListener(_onAuthChanged);
    }
    _maybeAutoLoad();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() {
    if (!mounted) return;
    if (_auth?.isAuthenticated != true) {
      setState(() {
        _orders = const [];
        _loading = false;
        _autoLoadedForSession = false;
      });
      return;
    }
    _maybeAutoLoad();
  }

  void _maybeAutoLoad() {
    final auth = _auth;
    if (auth == null) return;
    if (!auth.isReady || !auth.isAuthenticated) return;
    if (_autoLoadedForSession) return;
    _autoLoadedForSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _load();
    });
  }

  Future<void> _load() async {
    final auth = context.read<AuthState>();
    if (!auth.isAuthenticated) {
      if (mounted) setState(() => _loading = false);
      return;
    }
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
                for (final entry in _orders.asMap().entries) ...[
                  _OrderCard(
                    order: entry.value,
                    money: _money,
                    dateFmt: _dateFmt,
                    index: entry.key,
                  ),
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
  const _OrderCard({
    required this.order,
    required this.money,
    required this.dateFmt,
    required this.index,
  });

  final Map<String, dynamic> order;
  final NumberFormat money;
  final DateFormat dateFmt;
  final int index;

  @override
  Widget build(BuildContext context) {
    final idRaw = order['id'];
    final orderId = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    final statut = (order['statut_display'] ?? order['statut'] ?? '')
        .toString();
    final montant = (order['montant_total'] ?? 0) as num;
    final table = order['table'];
    final place = table is Map
        ? 'Table ${(table['numero'] ?? '').toString()}'
        : 'À emporter';
    final createdAtRaw = order['created_at'];
    DateTime? createdAt;
    if (createdAtRaw is String) {
      createdAt = DateTime.tryParse(createdAtRaw)?.toLocal();
    }

    Color statusColor() {
      final s = statut.toLowerCase();
      if (s.contains('termin') || s.contains('pay')) {
        return Colors.lightGreenAccent.shade100;
      }
      if (s.contains('annul') || s.contains('echou') || s.contains('refus')) {
        return Colors.redAccent.shade100;
      }
      if (s.contains('en cours') ||
          s.contains('prepar') ||
          s.contains('prépar')) {
        return Colors.orangeAccent.shade100;
      }
      return AppTheme.textMuted;
    }

    Future<void> openFacture() async {
      try {
        final data = await context.read<OrderService>().fetchFactureForOrder(
          orderId,
        );
        final pdfUrl = data['pdf_url']?.toString();
        final uri = pdfUrl == null ? null : Uri.tryParse(pdfUrl);
        if (uri == null) throw Exception('Facture introuvable');
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) throw Exception('Impossible d’ouvrir la facture');
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 320 + (index * 60)),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, (1 - t) * 10),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: orderId <= 0
              ? null
              : () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute<void>(
                      builder: (_) => OrderDetailScreen(orderId: orderId),
                    ),
                  );
                },
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.10),
                  Colors.white.withValues(alpha: 0.04),
                ],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.accent.withValues(alpha: 0.30),
                        Colors.white.withValues(alpha: 0.06),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppTheme.text),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '#$orderId • $place',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.10),
                              ),
                            ),
                            child: Text(
                              statut,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor(),
                                fontWeight: FontWeight.w900,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (createdAt != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          dateFmt.format(createdAt),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              money.format(montant),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.accent,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: orderId <= 0 ? null : openFacture,
                            icon: const Icon(Icons.download_rounded),
                            color: AppTheme.text,
                            tooltip: 'Facture',
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white.withValues(alpha: 0.42),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
