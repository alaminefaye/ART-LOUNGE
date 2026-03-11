import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../orders/cart_screen.dart';
import '../orders/orders_screen.dart';
import '../profile/profile_screen.dart';
import '../home/home_screen.dart';
import '../favorites/favorites_screen.dart';
import '../reservations/reservations_screen.dart';
import '../../models/cart.dart';
import '../../models/favorites.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex ?? 0;
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
          backgroundColor: const Color(0xFF1E1E1E),
          body: IndexedStack(
            index: _currentIndex,
            children: _buildScreens(context),
          ),
          bottomNavigationBar: Container(
            margin: const EdgeInsets.all(20),
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF252525),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(5, 5),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.05),
                  blurRadius: 5,
                  offset: const Offset(-2, -2),
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
              color: isSelected ? Colors.white : Colors.grey[600],
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
