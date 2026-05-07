import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../checkout_screen.dart';

class CartTab extends StatelessWidget {
  const CartTab({super.key});

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(locale: 'fr_FR', symbol: 'FCFA', decimalDigits: 0);

    return Scaffold(
      appBar: AppBar(title: const Text('Panier')),
      body: Consumer<CartState>(
        builder: (context, cart, _) {
          if (cart.items.isEmpty) {
            return const Center(child: Text('Ton panier est vide'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              for (final item in cart.items)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.product.nom, style: const TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text('${money.format(item.product.prix)} • ${item.quantite}'),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: () => context.read<CartState>().removeOne(item.product.id),
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(item.quantite.toString(), style: const TextStyle(fontWeight: FontWeight.w700)),
                        IconButton(
                          onPressed: () => context.read<CartState>().add(item.product),
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 10),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                      Text(money.format(cart.total), style: const TextStyle(fontWeight: FontWeight.w900)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Consumer<AuthState>(
                builder: (context, auth, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.isAuthenticated
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                              );
                            }
                          : null,
                      child: Text(auth.isAuthenticated ? 'Commander' : 'Connecte-toi pour commander'),
                    ),
                  );
                },
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => context.read<CartState>().clear(),
                child: const Text('Vider le panier'),
              ),
            ],
          );
        },
      ),
    );
  }
}

