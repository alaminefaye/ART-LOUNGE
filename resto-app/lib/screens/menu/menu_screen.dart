import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../orders/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../orders/order_detail_screen.dart';
import '../orders/invoice_screen.dart';
import '../profile/profile_screen.dart';
import '../home/home_screen.dart';
import '../favorites/favorites_screen.dart';
import '../reservations/reservations_screen.dart';
import '../../models/cart.dart';
import '../../models/favorites.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_events.dart';
import '../../utils/formatters.dart';

class MenuScreen extends StatefulWidget {
  final int? initialIndex;

  const MenuScreen({super.key, this.initialIndex});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

// Widget pour naviguer directement vers les commandes
class MenuScreenWithOrders extends MenuScreen {
  const MenuScreenWithOrders({super.key}) : super(initialIndex: 2);
}

// Widget pour naviguer directement vers les réservations
class MenuScreenWithReservations extends MenuScreen {
  const MenuScreenWithReservations({super.key}) : super(initialIndex: 3);
}

class _MenuScreenState extends State<MenuScreen> {
  static const Color _brandGold = Color(0xFFD0A030);
  late int _currentIndex;
  final OrderService _orderService = OrderService();
  StreamSubscription? _paymentValidatedSubscription;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
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

  List<Widget> _buildScreens(BuildContext context) {
    final favorites = Provider.of<Favorites>(context, listen: false);
    return [
      const HomeScreen(), // Index 0 - Accueil
      FavoritesScreen(
        key: ValueKey('favorites_${favorites.count}'),
      ), // Index 1 - Favoris avec clé unique
      const OrdersScreen(showBackButton: false), // Index 2 - Commandes
      const ReservationsScreen(), // Index 3 - Réservations
      const CartScreen(
        tableId: null,
        showBackButton: false,
      ), // Index 4 - Panier
      const ProfileScreen(), // Index 5 - Profil
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<Favorites>(
      builder: (context, favorites, _) {
        return Scaffold(
          body: IndexedStack(
            index: _currentIndex,
            children: _buildScreens(context),
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.all(20),
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(Icons.home_rounded, _currentIndex == 0, () {
                  setState(() => _currentIndex = 0);
                }, isHome: true),
                _buildNavItem(Icons.favorite_rounded, _currentIndex == 1, () {
                  setState(() => _currentIndex = 1);
                }),
                _buildNavItem(
                  Icons.receipt_long_rounded,
                  _currentIndex == 2,
                  () {
                    setState(() => _currentIndex = 2);
                  },
                ),
                _buildNavItem(
                  Icons.calendar_month_rounded,
                  _currentIndex == 3,
                  () {
                    setState(() => _currentIndex = 3);
                  },
                ),
                _buildNavItem(
                  Icons.shopping_cart_rounded,
                  _currentIndex == 4,
                  () {
                    setState(() => _currentIndex = 4);
                  },
                  isCart: true,
                ),
                _buildNavItem(Icons.person_rounded, _currentIndex == 5, () {
                  setState(() => _currentIndex = 5);
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
    IconData icon,
    bool isSelected,
    VoidCallback onTap, {
    bool isCart = false,
    bool isHome = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? _brandGold : Colors.transparent,
              borderRadius: BorderRadius.circular(15),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _brandGold.withValues(alpha: 0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey[700],
              size: 24,
            ),
          ),
          if (isCart)
            Consumer<Cart>(
              builder: (context, cart, _) {
                if (cart.itemCount > 0) {
                  return Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 10,
                        minHeight: 10,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
        ],
      ),
    );
  }
}
