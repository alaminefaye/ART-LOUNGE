import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/fcm_events.dart';
import '../../models/order.dart';
import '../../utils/formatters.dart';
import '../orders/orders_screen.dart';
import '../orders/order_detail_screen.dart';
import '../tables/tables_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _dailyOrderCount = 0;
  double _dailyRevenue = 0.0;
  List<Order> _recentOrders = [];
  final OrderService _orderService = OrderService();
  final NotificationService _notificationService = NotificationService();
  int _unreadNotificationCount = 0;
  late Timer _timer;
  StreamSubscription? _orderUpdateSubscription;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _startClock();

    // Écouter les mises à jour des commandes via FCM
    _orderUpdateSubscription = FCMEvents.orderUpdateStream.listen((_) {
      if (mounted) {
        _loadDashboardData();
        // Optionnel: Jouer un petit son ou vibration ici aussi si l'app est ouverte
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nouvelle commande reçue ! 🔔'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _orderUpdateSubscription?.cancel();
    super.dispose();
  }

  void _startClock() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  String _getFormattedDate() {
    return DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_currentTime);
  }

  String _getFormattedTime() {
    return DateFormat('HH:mm:ss', 'fr_FR').format(_currentTime);
  }

  Future<void> _loadDashboardData() async {
    try {
      // Badge notifications
      final count = await _notificationService.getUnreadCount();
      if (mounted) setState(() => _unreadNotificationCount = count);

      // Charger les commandes en cours et l'historique
      final currentOrders = await _orderService.getCurrentOrders();
      final historyOrders = await _orderService.getHistoryOrders();

      final now = DateTime.now();

      // Combiner et filtrer pour aujourd'hui
      final allOrders = [...currentOrders, ...historyOrders];
      final todayOrders = allOrders.where((o) {
        return o.createdAt.year == now.year &&
            o.createdAt.month == now.month &&
            o.createdAt.day == now.day;
      }).toList();

      // Calculer la recette (exclure les annulées)
      double revenue = 0;
      for (var o in todayOrders) {
        if (o.statut != OrderStatus.annulee) {
          revenue += o.montantTotal;
        }
      }

      // Filtrer les commandes récentes (non terminées)
      // On prend les commandes du jour qui sont En attente ou En préparation
      final recentOrders = currentOrders.where((o) {
        return o.statut == OrderStatus.attente ||
            o.statut == OrderStatus.preparation;
      }).toList();

      // Trier par date de mise à jour décroissante (la plus récente en haut)
      recentOrders.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt;
        final bDate = b.updatedAt ?? b.createdAt;
        return bDate.compareTo(aDate);
      });

      if (mounted) {
        setState(() {
          _dailyOrderCount = todayOrders.length;
          _dailyRevenue = revenue;
          _recentOrders = recentOrders;
        });
      }
    } catch (e) {
      debugPrint('Erreur chargement dashboard: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUser;

    // Si pas d'utilisateur, rediriger ou afficher erreur
    if (user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Déterminer le rôle principal
    final bool isAdmin = user.hasRole('admin');
    final bool isManager = user.hasRole('manager');
    final bool isServeur = user.hasRole('serveur');
    final bool isCaissier = user.hasRole('caissier');

    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // HEADER CUSTOM
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'DOLCE VITA',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bonjour, ${user.name}',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Date et Heure
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_getFormattedDate().substring(0, 1).toUpperCase()}${_getFormattedDate().substring(1)}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 1,
                                height: 12,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getFormattedTime(),
                                style: const TextStyle(
                                  color: Colors.orange,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Icône notifications
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        IconButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationsScreen(),
                              ),
                            );
                            _loadDashboardData();
                          },
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          tooltip: 'Notifications',
                        ),
                        if (_unreadNotificationCount > 0)
                          Positioned(
                            right: 4,
                            top: 4,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.orange,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 18,
                                minHeight: 18,
                              ),
                              child: Text(
                                _unreadNotificationCount > 99
                                    ? '99+'
                                    : '$_unreadNotificationCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    // Icône profil
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.orange, width: 2),
                        ),
                        child: const CircleAvatar(
                          backgroundColor: Color(0xFF252525),
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // STATS CARD (Pour Admin, Manager, Caissier)
              if (isAdmin || isManager || isCaissier)
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  padding: const EdgeInsets.all(20),
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
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              size: 14,
                              color: Colors.orange,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Statistiques du jour',
                              style: TextStyle(
                                color: Colors.orange[300],
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Commandes',
                            '$_dailyOrderCount',
                            Icons.receipt_long,
                            Colors.blue,
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.grey[800]!,
                                  Colors.grey[600]!,
                                  Colors.grey[800]!,
                                ],
                              ),
                            ),
                          ),
                          _buildStatItem(
                            'Recette',
                            Formatters.formatCurrency(
                              _dailyRevenue,
                            ).replaceAll(' FCFA', ''),
                            Icons.monetization_on,
                            Colors.green,
                            subtitle: 'FCFA',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // GRID MENU (Déplacé ici)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    // MENU & COMMANDES
                    _buildDashboardCard(
                      context,
                      'Commandes & Menu',
                      Icons.restaurant_menu,
                      Colors.orange,
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const OrdersScreen(showBackButton: true),
                        ),
                      ).then((_) => _loadDashboardData()),
                    ),

                    // CAISSE & PAIEMENTS
                    if (isCaissier || isManager || isAdmin)
                      _buildDashboardCard(
                        context,
                        'Caisse & Paiements',
                        Icons.point_of_sale,
                        Colors.green,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const OrdersScreen(showBackButton: true),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),

                    // TABLES
                    if (isServeur || isManager || isAdmin || isCaissier)
                      _buildDashboardCard(
                        context,
                        'Tables',
                        Icons.table_restaurant,
                        Colors.purple,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TablesScreen(),
                          ),
                        ),
                      ),

                    // STATISTIQUES
                    if (isAdmin || isManager)
                      _buildDashboardCard(
                        context,
                        'Statistiques',
                        Icons.bar_chart,
                        Colors.teal,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Module Statistiques en cours de développement',
                              ),
                            ),
                          );
                        },
                      ),

                    // UTILISATEURS
                    if (isAdmin)
                      _buildDashboardCard(
                        context,
                        'Utilisateurs',
                        Icons.people,
                        Colors.indigo,
                        () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Module Utilisateurs en cours de développement',
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),

              // SECTION COMMANDES RÉCENTES (Déplacé en bas)
              if (_recentOrders.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.notifications_active_outlined,
                          color: Colors.orange,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Commandes Récentes',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${_recentOrders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentOrders.length,
                  itemBuilder: (context, index) {
                    final order = _recentOrders[index];
                    return RecentOrderTile(
                      order: order,
                      onOrderUpdated: () {
                        _loadDashboardData();
                        FCMEvents.triggerOrderUpdate();
                      },
                    );
                  },
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(color: Colors.grey[500], fontSize: 10),
          ),
      ],
    );
  }

  Widget _buildDashboardCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    int badgeCount = 0,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF252525),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 40, color: color),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    badgeCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class RecentOrderTile extends StatefulWidget {
  final Order order;
  final VoidCallback onOrderUpdated;

  const RecentOrderTile({
    super.key,
    required this.order,
    required this.onOrderUpdated,
  });

  @override
  State<RecentOrderTile> createState() => _RecentOrderTileState();
}

class _RecentOrderTileState extends State<RecentOrderTile> {
  bool _isLoading = false;
  final OrderService _orderService = OrderService();

  Future<void> _markOrderAsServed() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _orderService.marquerServi(widget.order.id);

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande marquée comme servie !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        widget.onOrderUpdated();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${result['message']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isPrep = widget.order.statut == OrderStatus.preparation;
    final bool isWaiting = widget.order.statut == OrderStatus.attente;

    // Status text/color
    String statusLabel = 'Nouvelle commande';
    Color statusColor = Colors.red;
    if (isPrep) {
      statusLabel = 'En préparation';
      statusColor = Colors.orange;
    } else if (isWaiting) {
      statusLabel = 'Nouvelle';
      statusColor = Colors.red;
    } else {
      statusLabel = widget.order.statut.displayName;
      statusColor = Colors.grey;
    }

    // Date formatting
    final dateStr = DateFormat('dd/MM HH:mm').format(widget.order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF252525),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: statusColor, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
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
                builder: (_) => OrderDetailScreen(orderId: widget.order.id),
              ),
            ).then((_) {
              // Trigger reload in parent via callback isn't enough if we just popped
              // But onOrderUpdated will be called if we tap served.
              // Here we want to reload dashboard if details changed something
              // But we don't have direct access to parent's _loadDashboardData here easily without passing another callback?
              // Actually, we can just call widget.onOrderUpdated()
              widget.onOrderUpdated();
            });
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Info
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.table_restaurant,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),

                // Main Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Table ${widget.order.table?.numero ?? "?"}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                      const SizedBox(height: 12),

                      // Product List — afficher seulement les produits pas encore servis (nouveaux)
                      () {
                        final all = widget.order.produits ?? [];
                        final nonServis = all.where((p) => !p.servi).toList();
                        if (nonServis.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              all.isEmpty
                                  ? 'Aucun produit'
                                  : 'Aucun nouveau produit à servir',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                                fontStyle: all.isEmpty
                                    ? FontStyle.normal
                                    : FontStyle.italic,
                              ),
                            ),
                          );
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: nonServis
                              .map(
                                (p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${p.quantite}x ',
                                        style: const TextStyle(
                                          color: Colors.orange,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          p.produitNom,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        );
                      }(),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Servi Button — actif seulement s'il reste des produits non servis
                Column(
                  children: [
                    Builder(
                      builder: (context) {
                        final nonServis = (widget.order.produits ?? [])
                            .where((p) => !p.servi)
                            .toList();
                        final hasUnserved = nonServis.isNotEmpty;
                        return ElevatedButton(
                          onPressed: _isLoading || !hasUnserved
                              ? null
                              : _markOrderAsServed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.green.withValues(
                              alpha: 0.5,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Servi',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
