import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../checkout_screen.dart';
import '../login_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(
      locale: 'fr_FR',
      symbol: 'FCFA',
      decimalDigits: 0,
    );

    return Consumer2<CartState, AuthState>(
      builder: (context, cart, auth, _) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Mon panier',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                ),
                IconButton(
                  onPressed: cart.items.isEmpty
                      ? null
                      : () => context.read<CartState>().clear(),
                  icon: const Icon(Icons.delete_outline, color: AppTheme.text),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (cart.items.isEmpty)
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
                      Icons.shopping_bag_outlined,
                      color: AppTheme.textMuted,
                      size: 34,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Ton panier est vide',
                      style: TextStyle(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              )
            else ...[
              for (final item in cart.items)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withValues(alpha: 0.06),
                        ),
                        child: const Icon(Icons.fastfood, color: AppTheme.text),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.product.nom,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              money.format(item.product.prix),
                              style: const TextStyle(
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            if (item.note?.trim().isNotEmpty == true) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Note : ${item.note!.trim()}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () async {
                          final result = await _editNote(
                            context,
                            initial: item.note,
                          );
                          if (result == null) return;
                          context.read<CartState>().setNote(
                            item.product.id,
                            result,
                          );
                        },
                        icon: const Icon(Icons.edit_note, color: AppTheme.text),
                      ),
                      _QtyButton(
                        icon: Icons.remove,
                        onTap: () => context.read<CartState>().removeOne(
                          item.product.id,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Text(
                          item.quantite.toString(),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      _QtyButton(
                        icon: Icons.add,
                        onTap: () =>
                            context.read<CartState>().add(item.product),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      money.format(cart.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (!auth.isAuthenticated) {
                      final ok = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                      if (ok != true) return;
                    }
                    if (!context.mounted) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                    );
                  },
                  child: Text(
                    auth.isAuthenticated
                        ? 'Valider la commande'
                        : 'Se connecter pour payer',
                  ),
                ),
              ),
              const SizedBox(height: 90),
            ],
          ],
        );
      },
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, size: 18, color: AppTheme.text),
      ),
    );
  }
}

Future<String?> _editNote(BuildContext context, {String? initial}) async {
  final ctrl = TextEditingController(text: initial ?? '');
  final result = await showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (ctx) {
      return Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0E132E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Note pour la cuisine',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ctrl,
                maxLines: 3,
                style: const TextStyle(color: AppTheme.text),
                decoration: const InputDecoration(
                  hintText: 'Ex: sans piment, sans oignon…',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(ctrl.text),
                  child: const Text('Enregistrer'),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
  ctrl.dispose();
  return result;
}
