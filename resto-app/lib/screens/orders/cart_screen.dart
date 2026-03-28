import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../models/cart.dart';
import '../../services/order_service.dart';
import '../../services/table_service.dart';
import '../../models/table.dart' as models;
import '../../utils/formatters.dart';
import '../tables/qr_scan_screen.dart';
import '../menu/menu_screen.dart';
import '../../widgets/app_header.dart';
import '../../utils/auth_gate.dart';

class CartScreen extends StatelessWidget {
  final int? tableId;
  final int? targetOrderId;
  final bool showBackButton;

  const CartScreen({
    super.key,
    this.tableId,
    this.targetOrderId,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<Cart>(context);
    final orderService = OrderService();

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient
            Consumer<Cart>(
              builder: (context, cart, _) => AppHeader(
                title: 'Mon Panier',
                showBackButton: showBackButton,
                actions: [
                  HeaderActionButton(
                    icon: Icons.delete_outline,
                    onTap: cart.isEmpty ? () {} : () => cart.clear(),
                  ),
                ],
              ),
            ),

            Expanded(
              child: cart.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  offset: const Offset(0, 10),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.shopping_cart_outlined,
                              size: 48,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Votre panier est vide',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Ajoutez des produits pour commencer',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: cart.items.length,
                      itemBuilder: (context, index) {
                        final item = cart.items[index];
                        return _buildCartItem(context, cart, item);
                      },
                    ),
            ),
            if (cart.isNotEmpty)
              _buildTotalSection(context, cart, orderService),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, Cart cart, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: item.product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.product.imageUrl,
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[800],
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[800],
                        child: const Icon(Icons.restaurant, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[800],
                      child: const Icon(Icons.restaurant, color: Colors.grey),
                    ),
            ),
            const SizedBox(width: 12),

            // Nom et Prix Unitaire
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.product.nom,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    Formatters.formatCurrency(item.product.prix),
                    style: const TextStyle(
                      color: Color(0xFFD0A030),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Colonne Quantité et Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Formatters.formatCurrency(item.total),
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6EC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildQtyBtn(
                        icon: Icons.remove,
                        onTap: () {
                          if (item.quantite > 1) {
                            cart.updateQuantity(
                              item.product.id,
                              item.quantite - 1,
                            );
                          } else {
                            cart.removeProduct(item.product.id);
                          }
                        },
                      ),
                      Container(
                        constraints: const BoxConstraints(minWidth: 24),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantite}',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      _buildQtyBtn(
                        icon: Icons.add,
                        color: const Color(0xFFD0A030),
                        onTap: () {
                          cart.updateQuantity(
                            item.product.id,
                            item.quantite + 1,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQtyBtn({
    required IconData icon,
    required VoidCallback onTap,
    Color color = Colors.black87,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 32,
        alignment: Alignment.center,
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }

  Widget _buildTotalSection(
    BuildContext context,
    Cart cart,
    OrderService orderService,
  ) {
    final currentTableId = cart.tableId ?? tableId;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        border: Border(
          top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          left: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
          right: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section sélection de table
            if (currentTableId == null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6EC),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFFD0A030).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.table_restaurant,
                            color: Colors.orange,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: const Text(
                            'Sélectionnez une table',
                            style: TextStyle(
                              color: Color(0xFFD0A030),
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: OutlinedButton.icon(
                          onPressed: () => _scanQrCode(context, cart),
                          icon: const Icon(Icons.qr_code_scanner, size: 18),
                          label: const Text('Scanner le QR code', style: TextStyle(fontSize: 14)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD0A030),
                            side: const BorderSide(color: Color(0xFFD0A030)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              // Afficher la table sélectionnée
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6EC),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.green.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.table_restaurant,
                        color: Colors.green,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FutureBuilder<models.Table?>(
                        future: TableService().getTable(currentTableId),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data != null) {
                            return Text(
                              'Table ${snapshot.data!.numero}',
                              style: const TextStyle(
                                color: Colors.green,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }
                          return Text(
                            'Table #$currentTableId',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    TextButton(
                      onPressed: () => _scanQrCode(context, cart),
                      child: const Text(
                        'Changer',
                        style: TextStyle(
                          color: Color(0xFFD0A030),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  Formatters.formatCurrency(cart.total),
                  style: const TextStyle(
                    color: Color(0xFFD0A030),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFD0A030).withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: currentTableId == null
                    ? () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Veuillez sélectionner une table'),
                            backgroundColor: Color(0xFFD0A030),
                          ),
                        );
                      }
                    : () => _handleCheckout(context, cart, orderService),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD0A030),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Passer la commande',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _scanQrCode(BuildContext context, Cart cart) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const QrScanScreen(returnTableOnly: true),
      ),
    );

    if (result != null && result is models.Table) {
      cart.setTable(result.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Table ${result.numero} sélectionnée'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _handleCheckout(
    BuildContext context,
    Cart cart,
    OrderService orderService,
  ) async {
    if (targetOrderId != null) {
      return _addToExistingOrder(context, cart, orderService);
    } else {
      return _createOrder(context, cart, orderService);
    }
  }

  Future<void> _addToExistingOrder(
    BuildContext context,
    Cart cart,
    OrderService orderService,
  ) async {
    final ok = await requireAuth(context);
    if (!ok || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    bool allSuccess = true;
    String? lastError;

    // Ajouter chaque produit un par un (l'API semble être par produit)
    for (var item in cart.items) {
      final res = await orderService.addProductToOrder(
        orderId: targetOrderId!,
        produitId: item.product.id,
        quantite: item.quantite,
      );
      if (res['success'] != true) {
        allSuccess = false;
        lastError = res['message'];
      }
    }

    if (!context.mounted) return;
    Navigator.pop(context); // Fermer le loading

    if (allSuccess) {
      cart.clear();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produits ajoutés à la commande !'),
            backgroundColor: Colors.green,
          ),
        );
        // Retourner à l'écran de détail de commande (OrderDetailScreen)
        // On doit depiler le Panier et le Menu
        if (showBackButton) {
          Navigator.pop(context); // Pop le CartScreen
          Navigator.pop(context); // Pop le HomeScreen (Menu)
        } else {
          Navigator.pop(context);
        }
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(lastError ?? 'Erreur lors de l\'ajout'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createOrder(
    BuildContext context,
    Cart cart,
    OrderService orderService,
  ) async {
    final targetTableId = cart.tableId ?? tableId;
    if (targetTableId == null) return;

    final ok = await requireAuth(context);
    if (!ok || !context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    final result = await orderService.createOrder(
      tableId: targetTableId,
      produits: cart.toJson(),
    );

    if (!context.mounted) return;
    Navigator.pop(context); // Fermer le loading

    if (result['success'] == true) {
      cart.clear();
      if (context.mounted) {
        // Si on est dans le flux staff (showBackButton), on revient aux tables ou dashboard
        if (showBackButton) {
          Navigator.pop(context); // Retour au Menu (HomeScreen)
          Navigator.pop(context); // Retour aux Tables
        } else {
          // Naviguer vers MenuScreen avec l'onglet Commandes (index 2)
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const MenuScreenWithOrders()),
            (route) => false,
          );
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande créée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la création'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
