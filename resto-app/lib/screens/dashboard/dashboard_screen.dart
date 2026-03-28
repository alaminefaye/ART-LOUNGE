import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/order_service.dart';
import '../../services/printer_service.dart';
import '../../services/fcm_events.dart';
import '../../models/order.dart';
import '../../utils/formatters.dart';
import '../orders/orders_screen.dart';
import '../orders/order_detail_screen.dart';
import '../orders/invoice_screen.dart';
import '../tables/tables_screen.dart';
import '../profile/profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../../services/notification_service.dart';
import '../tables/qr_scan_screen.dart';
import '../../models/table.dart' as models;
import '../../models/cart.dart';
import '../home/home_screen.dart';
import '../caisse/session_management_screen.dart';
import 'staff_order_history_screen.dart';

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
  StreamSubscription? _paymentValidatedSubscription;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Barre de statut en sombre pour être lisible sur fond clair
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFFFFF6EC),
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    _loadDashboardData();
    _startClock();

    // Écouter les mises à jour des commandes via FCM
    _orderUpdateSubscription = FCMEvents.orderUpdateStream.listen((_) {
      if (mounted) {
        _loadDashboardData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Nouvelle commande reçue !',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });

    // Popup "Paiement reçu" (facture + avis) réservé au client uniquement
    _paymentValidatedSubscription =
        FCMEvents.paymentValidatedStream.listen((orderId) {
      if (!mounted) return;
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user != null && user.hasRole('client')) {
        _showPaymentReceivedDialog(orderId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paiement validé pour la commande #$orderId'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _orderUpdateSubscription?.cancel();
    _paymentValidatedSubscription?.cancel();
    super.dispose();
  }

  Future<void> _showPaymentReceivedDialog(int orderId) async {
    if (!mounted) return;
    Order? order;
    try {
      order = await _orderService.getOrder(orderId);
    } catch (_) {}
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Paiement reçu !', style: TextStyle(fontSize: 20)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Commande #$orderId',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (order != null) ...[
                const SizedBox(height: 8),
                if (order.table != null)
                  Text(
                    'Table ${order.table!.numero}',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                const SizedBox(height: 4),
                Text(
                  'Total: ${Formatters.formatCurrency(order.montantTotal)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFD0A030),
                  ),
                ),
                if (order.produits != null && order.produits!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Aperçu de la commande',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...order.produits!.take(5).map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          '• ${p.quantite}x ${p.produitNom}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[800]),
                        ),
                      )),
                  if (order.produits!.length > 5)
                    Text(
                      '... et ${order.produits!.length - 5} autre(s)',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Fermer'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderDetailScreen(orderId: orderId),
                ),
              );
            },
            icon: const Icon(Icons.star_outline, size: 20),
            label: const Text('Noter la satisfaction'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD0A030),
            ),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => InvoiceScreen(orderId: orderId),
                ),
              );
            },
            icon: const Icon(Icons.receipt_long, size: 20),
            label: const Text('Voir le reçu'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
            ),
          ),
        ],
      ),
    );
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
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          color: Colors.orange,
          backgroundColor: Colors.white,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
            children: [
              // HEADER CUSTOM
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'DOLCE VITA',
                          style: TextStyle(
                            color: Color(0xFFB07018),
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Bonjour, ${user.name}',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 10),
                        // Date et Heure
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.06),
                                offset: const Offset(0, 3),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 16,
                                  color: Colors.grey[800],
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${_getFormattedDate().substring(0, 1).toUpperCase()}${_getFormattedDate().substring(1)}',
                                  style: TextStyle(
                                    color: Colors.grey[900],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  width: 1,
                                  height: 14,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(width: 12),
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 16,
                                  color: const Color(0xFFB07018),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _getFormattedTime(),
                                  style: const TextStyle(
                                    color: Color(0xFFB07018),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    ),
                    // Bouton Actualiser
                    IconButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _loadDashboardData();
                      },
                      icon: Icon(
                        Icons.refresh,
                        color: Colors.grey[900],
                        size: 26,
                      ),
                      tooltip: 'Actualiser',
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
                          icon: Icon(
                            Icons.notifications_outlined,
                            color: Colors.grey[900],
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
                          backgroundColor: Color(0xFFFFF0DC),
                          child: Icon(Icons.person, color: Colors.black87),
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
                                color: Colors.orange[800],
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.4,
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
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
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
                    if (isServeur || isManager || isAdmin || isCaissier) ...[
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
                        ).then((_) => _loadDashboardData()),
                      ),
                      _buildDashboardCard(
                        context,
                        'Scanner Table',
                        Icons.qr_code_scanner,
                        const Color(0xFFD0A030),
                        () => _scanTable(context),
                      ),
                      _buildDashboardCard(
                        context,
                        'Historique commandes',
                        Icons.history,
                        Colors.brown,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const StaffOrderHistoryScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
                      ),
                    ],

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
                    
                    // SESSION DE CAISSE
                    if (isCaissier || isManager || isAdmin)
                      _buildDashboardCard(
                        context,
                        'Session de Caisse',
                        Icons.account_balance_wallet,
                        Colors.blueGrey,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SessionManagementScreen(),
                          ),
                        ).then((_) => _loadDashboardData()),
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
                      Text(
                        'Commandes Récentes',
                        style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD0A030),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFD0A030).withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '${_recentOrders.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      for (final order in _recentOrders)
                        RecentOrderTile(
                          order: order,
                          onOrderUpdated: () {
                            _loadDashboardData();
                            FCMEvents.triggerOrderUpdate();
                          },
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ],
          ),
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
              style: TextStyle(
                color: Colors.grey[800],
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.grey[900],
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.3,
          ),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
      ),
      color: Colors.white,
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, size: 24, color: color),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                      letterSpacing: 0.1,
                      height: 1.1,
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

  void _scanTable(BuildContext context) async {
    final result = await Navigator.push<models.Table>(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(returnTableOnly: true),
      ),
    );

    if (result != null && context.mounted) {
      _handleTableSelection(context, result);
    }
  }

  void _handleTableSelection(BuildContext context, models.Table table) async {
    if (table.statut == models.TableStatus.reservee &&
        table.reservationActuelle != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TablesScreen()),
      );
    } else if (table.statut == models.TableStatus.libre) {
      final cart = Provider.of<Cart>(context, listen: false);
      cart.clear();
      cart.setTable(table.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const HomeScreen(showBackButton: true),
        ),
      ).then((_) => _loadDashboardData());
    } else if (table.statut == models.TableStatus.occupee ||
        table.statut == models.TableStatus.enPaiement) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Colors.orange),
        ),
      );

      try {
        final currentOrders = await _orderService.getCurrentOrders();
        if (context.mounted) Navigator.pop(context);

        final activeOrder = currentOrders.fold<Order?>(
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

        if (activeOrder != null && context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: activeOrder.id),
            ),
          ).then((_) => _loadDashboardData());
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aucune commande active trouvée pour cette table'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      } catch (e) {
        if (context.mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
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
  bool _printKitchenLoading = false;
  final OrderService _orderService = OrderService();
  final PrinterService _printerService = PrinterService();

  Future<void> _printKitchenTicket() async {
    if (_printKitchenLoading) return;
    setState(() {
      _printKitchenLoading = true;
    });
    try {
      final order = await _orderService.getOrder(widget.order.id);
      if (!mounted) return;
      if (order == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible de charger la commande pour l’impression'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await _printerService.printKitchenOrder(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bon cuisine envoyé à l’imprimante'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Impression cuisine impossible : $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _printKitchenLoading = false;
        });
      }
    }
  }

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
    final currentUser =
        Provider.of<AuthService>(context, listen: false).currentUser;
    final showKitchenPrint =
        currentUser != null && !currentUser.hasRole('client');

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
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          children: [
            Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: 5,
            child: Container(color: statusColor),
          ),
            Material(
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
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Table Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6EC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFD0A030).withValues(alpha: 0.4)),
                  ),
                  child: Icon(
                    Icons.table_restaurant_rounded,
                    color: Colors.grey[900],
                    size: 24,
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
                              color: Color(0xFF1A1A1A),
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                              letterSpacing: 0.2,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.25),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              statusLabel,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        dateStr,
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
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
                                color: Colors.grey[800],
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
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
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${p.quantite}x ',
                                        style: const TextStyle(
                                          color: Color(0xFFD0A030),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          p.produitNom,
                                          style: const TextStyle(
                                            color: Color(0xFF1A1A1A),
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
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

                // Impression cuisine (staff) + Servi
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showKitchenPrint)
                      IconButton(
                        tooltip: 'Imprimer cuisine',
                        onPressed: _printKitchenLoading ? null : _printKitchenTicket,
                        icon: _printKitchenLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFD0A030),
                                ),
                              )
                            : const Icon(
                                Icons.restaurant_menu,
                                color: Color(0xFFD0A030),
                                size: 26,
                              ),
                      ),
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
        ],
      ),
    ),
    );
  }
}
