import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'tabs/favorites_tab.dart';
import 'tabs/menu_tab.dart';
import 'tabs/orders_tab.dart';
import 'tabs/profile_tab.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.cartNavTargetKey});

  final GlobalKey cartNavTargetKey;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = [
      MenuTab(cartButtonKey: widget.cartNavTargetKey),
      const OrdersTab(),
      const FavoritesTab(),
      const ProfileTab(),
    ];

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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 86),
                child: IndexedStack(index: _index, children: tabs),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        height: 64,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Expanded(
                              child: _NavItem(
                                icon: Icons.home_rounded,
                                label: 'Menu',
                                active: _index == 0,
                                onTap: () => setState(() => _index = 0),
                              ),
                            ),
                            Expanded(
                              child: _NavItem(
                                icon: Icons.receipt_long,
                                label: 'Commandes',
                                active: _index == 1,
                                onTap: () => setState(() => _index = 1),
                              ),
                            ),
                            Expanded(
                              child: _NavItem(
                                icon: Icons.favorite_border_rounded,
                                label: 'Favoris',
                                active: _index == 2,
                                onTap: () => setState(() => _index = 2),
                              ),
                            ),
                            Expanded(
                              child: _NavItem(
                                icon: Icons.person_outline,
                                label: 'Profil',
                                active: _index == 3,
                                onTap: () => setState(() => _index = 3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppTheme.accent : AppTheme.textMuted;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
