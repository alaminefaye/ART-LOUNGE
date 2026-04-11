import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../services/table_service.dart';
import '../services/order_service.dart';
import '../models/order.dart';
import '../services/printer_service.dart'; // Import PrinterService
import '../models/table.dart' as model;
import 'payment_selection_dialog.dart';
import 'serveur_selection_dialog.dart';
import 'pin_verification_dialog.dart';

class CartTicket extends StatelessWidget {
  const CartTicket({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(-2, 0),
          ),
        ],
      ),
      child: Consumer<Cart>(
        builder: (context, cart, child) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.backgroundColor,
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cart.activeOrder != null
                              ? 'Commande #${cart.activeOrder!.id}'
                              : 'Commande en cours',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        if (cart.activeOrder != null)
                          const Text(
                            'Modification en cours',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.brandGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    Row(
                      children: [
                        if (cart.isNotEmpty)
                          IconButton(
                            onPressed: () => cart.clear(),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            tooltip: 'Vider le chariot',
                          ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.brandGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${cart.itemCount} articles',
                            style: const TextStyle(
                              color: AppTheme.brandGold,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Table Selection Widget
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: InkWell(
                  onTap: () => _showTableSelectionDialog(context, cart),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(
                        color: cart.tableId == null
                            ? Colors.red.shade200
                            : AppTheme.brandGold.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.table_restaurant,
                          color: cart.tableId == null
                              ? Colors.red
                              : AppTheme.brandGold,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            cart.tableId == null
                                ? 'Veuillez sélectionner une table'
                                : 'Table ${cart.tableNumero}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: cart.tableId == null
                                  ? Colors.red
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(Icons.chevron_right, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
              ),

              // Items List
              Expanded(
                child: cart.items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.shopping_bag_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Le ticket est vide',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 16),
                        itemBuilder: (context, index) {
                          final cartItem = cart.items[index];
                          final productId = cartItem.product.id;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity controls
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Colors.grey.shade300,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.add,
                                        size: 14,
                                        color: cartItem.isNew
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                      onPressed: cartItem.isNew
                                          ? () => cart.addProduct(
                                              cartItem.product,
                                            )
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                    ),
                                    Text(
                                      '${cartItem.quantite}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: cartItem.isNew
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.remove,
                                        size: 14,
                                        color: cartItem.isNew
                                            ? Colors.black
                                            : Colors.grey,
                                      ),
                                      onPressed: cartItem.isNew
                                          ? () => cart.updateQuantity(
                                              productId,
                                              cartItem.quantite - 1,
                                            )
                                          : null,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(
                                        minWidth: 28,
                                        minHeight: 28,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Product Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (cartItem.isNew)
                                          Container(
                                            width: 8,
                                            height: 8,
                                            margin: const EdgeInsets.only(
                                              right: 8,
                                            ),
                                            decoration: const BoxDecoration(
                                              color: Colors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            cartItem.product.nom,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      Formatters.formatCurrency(
                                        cartItem.product.prix,
                                      ),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Total per item
                              Text(
                                Formatters.formatCurrency(cartItem.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.brandGold,
                                ),
                              ),

                              // Delete button
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () async {
                                  if (cartItem.isNew) {
                                    cart.removeProduct(productId);
                                  } else if (cart.activeOrder != null) {
                                    // Demander PIN Admin pour suppression sur le serveur
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => PinVerificationDialog(
                                        title:
                                            'Autorisation requise pour annuler "${cartItem.product.nom}"',
                                        requireAdmin: true,
                                        serveurNom: cart.serveurNom,
                                      ),
                                    );

                                    if (confirmed == true && context.mounted) {
                                      final res = await OrderService()
                                          .removeProductFromOrder(
                                            cart.activeOrder!.id,
                                            productId,
                                          );
                                      if (res['success'] == true) {
                                        // Re-sync l'ordre complet
                                        final updated = await OrderService()
                                            .getOrder(cart.activeOrder!.id);
                                        if (updated != null)
                                          cart.syncWithOrder(updated);
                                      } else {
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Erreur: ${res['message']}',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  }
                                },
                              ),
                            ],
                          );
                        },
                      ),
              ),

              // Footer Totals & Actions
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey.shade200)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Net',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        Text(
                          Formatters.formatCurrency(cart.total),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // Annuler Commande
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: (cart.activeOrder == null)
                                ? null
                                : () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => PinVerificationDialog(
                                        title:
                                            'Autorisation requise pour annuler la commande #${cart.activeOrder!.id}',
                                        requireAdmin: true,
                                        serveurNom: cart.serveurNom,
                                      ),
                                    );

                                    if (confirm == true && context.mounted) {
                                      showDialog(
                                        context: context,
                                        barrierDismissible: false,
                                        builder: (ctx) => const Center(
                                          child: CircularProgressIndicator(
                                            color: AppTheme.brandGold,
                                          ),
                                        ),
                                      );

                                      try {
                                        await OrderService().updateOrderStatus(
                                          cart.activeOrder!.id,
                                          OrderStatus.annulee,
                                        );
                                        cart.clear(); // Vider l'écran après
                                      } finally {
                                        if (context.mounted)
                                          Navigator.pop(
                                            context,
                                          ); // Fermer le loader
                                      }
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade50,
                              foregroundColor: Colors.red,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ANNULER',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Imprimer Facture
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: cart.activeOrder == null
                                ? null
                                : () {
                                    PrinterService().printOrderReceipt(
                                      cart.activeOrder!,
                                    );
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade50,
                              foregroundColor: Colors.blue,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'FACTURE',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Lancer Cuisine / Mettre à jour
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed:
                                (cart.isEmpty ||
                                    cart.tableId == null ||
                                    !cart.hasNewItems)
                                ? null
                                : () => _lancerCuisine(context, cart),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'ENVOYER',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Payer / Encaisser
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: (cart.isEmpty || cart.tableId == null)
                                ? null
                                : () => _showPaymentDialog(context, cart),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              backgroundColor: AppTheme.brandGold,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'PAYER',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _lancerCuisine(BuildContext context, Cart cart) async {
    final orderService = OrderService();
    final printerService = PrinterService(); // Instance du service d'impression

    try {
      // 1. Si pas de commande active -> Créer
      if (cart.activeOrder == null) {
        // Demander le serveur avant de créer la commande
        final serveurId = await showDialog<int>(
          context: context,
          barrierDismissible: true,
          builder: (ctx) => const ServeurSelectionDialog(),
        );

        if (serveurId == null) {
          // L'utilisateur a annulé la sélection du serveur
          return;
        }

        // On a le serveur, on crée la commande
        final res = await orderService.createOrder(
          tableId: cart.tableId!,
          serveurId: serveurId,
          produits: cart.toJson(),
        );
        if (res['success']) {
          final order = res['order'] as Order;
          await orderService.launchOrder(order.id);

          // Impression du bon de cuisine complet
          try {
            await printerService.printKitchenTicket(order);
          } catch (_) {}

          cart.syncWithOrder(order);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Commande envoyée en cuisine et ticket imprimé !',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
      // 2. Si déjà une commande -> Ajouter les nouveaux produits
      else {
        final newItems = cart.items.where((i) => i.isNew).toList();
        List<Map<String, dynamic>> printedAdditions = [];

        for (var item in newItems) {
          final res = await orderService.addProductToOrder(
            orderId: cart.activeOrder!.id,
            produitId: item.product.id,
            quantite: item.quantite,
          );
          if (res['success']) {
            printedAdditions.add({
              'nom': item.product.nom,
              'quantite': item.quantite,
            });
          }
        }

        // Impression du bon de cuisine "Supplément" (uniquement ce qui vient d'être ajouté)
        if (printedAdditions.isNotEmpty) {
          try {
            await printerService.printSupplementKitchenTicket(
              orderId: cart.activeOrder!.id,
              tableNumero: cart.tableNumero ?? '?',
              additions: printedAdditions,
            );
          } catch (_) {}
        }

        // Re-sync pour tout avoir au propre (optionnel mais recommandé)
        final updatedOrder = await orderService.getOrder(cart.activeOrder!.id);
        if (updatedOrder != null) {
          cart.syncWithOrder(updatedOrder);
        }
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Table mise à jour en cuisine et ticket imprimé !'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showPaymentDialog(BuildContext context, Cart cart) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PaymentSelectionDialog(
        cart: cart.activeOrder == null ? cart : null,
        existingOrder: cart.activeOrder,
      ),
    ).then((success) {
      if (success == true) {
        cart.clear();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Paiement enregistré et commande validée !'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }

  void _showTableSelectionDialog(BuildContext context, Cart cart) {
    String searchQuery = '';
    String filterMode = 'all'; // 'all', 'libres', 'occupees'
    final Future<List<model.Table>> tablesFuture = TableService().getTables();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (stateCtx, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: FutureBuilder<List<model.Table>>(
                future: tablesFuture,
                builder: (futureCtx, snapshot) {
                  final tables = snapshot.data ?? [];
                  final libres = tables
                      .where((t) => t.statut != model.TableStatus.occupee)
                      .length;
                  final occupees = tables
                      .where((t) => t.statut == model.TableStatus.occupee)
                      .length;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Sélectionner une table',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (snapshot.hasData) ...[
                            InkWell(
                              onTap: () => setDialogState(
                                () => filterMode = filterMode == 'libres'
                                    ? 'all'
                                    : 'libres',
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: _TableBadge(
                                count: libres,
                                label: 'Libres',
                                color: filterMode == 'libres'
                                    ? Colors.green
                                    : Colors.grey,
                                isSelected: filterMode == 'libres',
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () => setDialogState(
                                () => filterMode = filterMode == 'occupees'
                                    ? 'all'
                                    : 'occupees',
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: _TableBadge(
                                count: occupees,
                                label: 'Occupées',
                                color: filterMode == 'occupees'
                                    ? Colors.red
                                    : Colors.grey,
                                isSelected: filterMode == 'occupees',
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher une table...',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() {
                            searchQuery = val.toLowerCase();
                          });
                        },
                      ),
                    ],
                  );
                },
              ),
              content: SizedBox(
                width: 500,
                height: 400,
                child: FutureBuilder<List<model.Table>>(
                  future: tablesFuture,
                  builder: (futureCtx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.brandGold,
                        ),
                      );
                    }
                    if (snapshot.hasError) {
                      return const Center(
                        child: Text('Erreur de chargement des tables'),
                      );
                    }

                    List<model.Table> displayTables = snapshot.data ?? [];

                    // Appliquer le filtre de statut
                    if (filterMode == 'libres') {
                      displayTables = displayTables
                          .where((t) => t.statut != model.TableStatus.occupee)
                          .toList();
                    } else if (filterMode == 'occupees') {
                      displayTables = displayTables
                          .where((t) => t.statut == model.TableStatus.occupee)
                          .toList();
                    }

                    // Appliquer la recherche
                    if (searchQuery.isNotEmpty) {
                      displayTables = displayTables
                          .where(
                            (t) => t.numero.toLowerCase().contains(searchQuery),
                          )
                          .toList();
                    }

                    if (displayTables.isEmpty) {
                      return const Center(child: Text('Aucune table trouvée'));
                    }

                    return GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 1.5,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                      itemCount: displayTables.length,
                      itemBuilder: (ctx, index) {
                        final t = displayTables[index];
                        final isOccupied =
                            t.statut == model.TableStatus.occupee;

                        return InkWell(
                          onTap: () async {
                            if (isOccupied) {
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (loaderCtx) => const Center(
                                  child: CircularProgressIndicator(
                                    color: AppTheme.brandGold,
                                  ),
                                ),
                              );

                              try {
                                final activeOrder = await OrderService()
                                    .getActiveOrderByTable(t.id);
                                if (activeOrder != null) {
                                  cart.syncWithOrder(activeOrder);
                                } else {
                                  cart.setTable(t.id, tableNumero: t.numero);
                                }
                              } finally {
                                if (context.mounted)
                                  Navigator.of(
                                    context,
                                    rootNavigator: true,
                                  ).pop();
                              }
                            } else {
                              cart.setTable(t.id, tableNumero: t.numero);
                            }

                            if (context.mounted) Navigator.of(dialogCtx).pop();
                          },
                          onLongPress: isOccupied
                              ? () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => PinVerificationDialog(
                                      title:
                                          'Autorisation requise pour libérer la table ${t.numero}',
                                      requireAdmin: true,
                                    ),
                                  );

                                  if (confirm == true && context.mounted) {
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (ctx) => const Center(
                                        child: CircularProgressIndicator(
                                          color: AppTheme.brandGold,
                                        ),
                                      ),
                                    );

                                    try {
                                      final activeOrder = await OrderService()
                                          .getActiveOrderByTable(t.id);
                                      if (activeOrder != null) {
                                        await OrderService().updateOrderStatus(
                                          activeOrder.id,
                                          OrderStatus.annulee,
                                        );
                                      }
                                      setDialogState(() {});
                                    } finally {
                                      if (context.mounted)
                                        Navigator.pop(
                                          context,
                                        ); // Fermer le loader
                                    }
                                  }
                                }
                              : null,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isOccupied
                                  ? Colors.grey.shade200
                                  : AppTheme.brandGold.withValues(alpha: 0.1),
                              border: Border.all(
                                color: isOccupied
                                    ? Colors.grey.shade400
                                    : AppTheme.brandGold,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  t.numero,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: isOccupied
                                        ? Colors.grey
                                        : AppTheme.brandGold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isOccupied ? 'Occupée' : 'Libre',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isOccupied
                                        ? Colors.red
                                        : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TableBadge extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final bool isSelected;

  const _TableBadge({
    required this.count,
    required this.label,
    required this.color,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: isSelected ? 1.0 : 0.4),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$count $label',
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
