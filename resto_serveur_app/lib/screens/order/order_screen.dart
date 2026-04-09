import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/category.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/serveur.dart';
import '../../models/table.dart';
import '../../services/auth_service.dart';
import '../../services/menu_service.dart';
import '../../services/order_service.dart';
import '../../utils/formatters.dart';
import '../printer/printer_screen.dart';

/// Cart item: product + quantity + optional note
class _CartItem {
  final Product product;
  int quantity;
  String note;

  _CartItem({required this.product, this.quantity = 1, this.note = ''});
  // Note: quantity/note can be set after construction

  double get total => product.prix * quantity;
}

class OrderScreen extends StatefulWidget {
  final RestaurantTable table;
  final Serveur? serveur;

  const OrderScreen({super.key, required this.table, this.serveur});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen>
    with SingleTickerProviderStateMixin {
  final MenuService _menuService = MenuService();
  final OrderService _orderService = OrderService();

  List<Category> _categories = [];
  List<Product> _products = [];
  List<_CartItem> _cart = [];
  List<Order> _existingOrders = [];

  int? _selectedCategoryId;
  bool _isLoadingMenu = true;
  bool _isLoadingOrders = false;
  bool _isSendingOrder = false;
  String? _error;

  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingMenu = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        _menuService.getCategories(),
        _menuService.getProducts(),
        _orderService.getOrdersForTable(widget.table.id),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<Category>;
          _products = results[1] as List<Product>;
          _existingOrders = results[2] as List<Order>;
          _isLoadingMenu = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur de chargement: $e';
          _isLoadingMenu = false;
        });
      }
    }
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoadingOrders = true);
    final orders = await _orderService.getOrdersForTable(widget.table.id);
    if (mounted) {
      setState(() {
        _existingOrders = orders;
        _isLoadingOrders = false;
      });
    }
  }

  List<Product> get _filteredProducts {
    var filtered = _products.where((p) => p.disponible && p.actif).toList();
    if (_selectedCategoryId != null) {
      filtered =
          filtered.where((p) => p.categorieId == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      filtered = filtered
          .where((p) => p.nom.toLowerCase().contains(_searchQuery))
          .toList();
    }
    return filtered;
  }

  void _addToCart(Product product) {
    setState(() {
      final existing = _cart.where((c) => c.product.id == product.id);
      if (existing.isNotEmpty) {
        existing.first.quantity++;
      } else {
        _cart.add(_CartItem(product: product));
      }
    });
  }

  void _removeFromCart(Product product) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.product.id == product.id);
      if (idx == -1) return;
      if (_cart[idx].quantity > 1) {
        _cart[idx].quantity--;
      } else {
        _cart.removeAt(idx);
      }
    });
  }

  int _cartQuantityFor(Product product) {
    final items = _cart.where((c) => c.product.id == product.id);
    return items.isEmpty ? 0 : items.first.quantity;
  }

  double get _cartTotal => _cart.fold(0, (sum, item) => sum + item.total);

  int get _cartCount => _cart.fold(0, (sum, item) => sum + item.quantity);

  Future<void> _sendOrder() async {
    if (_cart.isEmpty) return;

    // Ask PIN confirmation before sending
    final confirmedWaiter = await _showPinConfirmDialog();
    if (confirmedWaiter == null) return;

    setState(() => _isSendingOrder = true);

    // Capture cart snapshot BEFORE clearing — used for kitchen ticket
    final newItems = _cart
        .map((item) => OrderItem(
              produitId: item.product.id,
              produitNom: item.product.nom,
              prix: item.product.prix,
              quantite: item.quantity,
              statut: 'envoye',
              servi: false,
            ))
        .toList();

    final produits = _cart
        .map(
          (item) => {
            'produit_id': item.product.id,
            'quantite': item.quantity,
            if (item.note.isNotEmpty) 'notes': item.note,
          },
        )
        .toList();

    // If there's an existing active order, add to it; otherwise create new
    Map<String, dynamic> result;
    if (_existingOrders.isNotEmpty) {
      final activeOrder = _existingOrders.first;
      result = await _orderService.addProductsToOrder(
        orderId: activeOrder.id,
        produits: produits,
      );
      // Launch the newly-added products so they reach the kitchen (brouillon → envoye)
      if (result['success'] == true) {
        await _orderService.launchOrder(activeOrder.id);
      }
    } else {
      result = await _orderService.createOrder(
        tableId: widget.table.id,
        produits: produits,
      );
      if (result['success'] == true && result['order'] != null) {
        final order = result['order'] as Order;
        await _orderService.launchOrder(order.id);
      }
    }

    if (mounted) {
      setState(() => _isSendingOrder = false);
      if (result['success'] == true) {
        setState(() => _cart = []);
        await _loadOrders();
        if (mounted) {
          _showSuccessSnack('Commande envoyée en cuisine !');
          _tabController.animateTo(1); // Switch to orders tab
          // Auto-open printer screen with ONLY the newly added items
          final sentOrder =
              _existingOrders.isNotEmpty ? _existingOrders.first : null;
          if (sentOrder != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PrinterScreen(
                  order: sentOrder,
                  serveurName: confirmedWaiter.name,
                  newItems: newItems,
                ),
              ),
            );
          }
        }
      } else {
        _showErrorSnack(result['message'] ?? 'Erreur lors de l\'envoi');
      }
    }
  }

  Future<Serveur?> _showPinConfirmDialog() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    return await showDialog<Serveur>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _PinConfirmDialog(
        authService: authService,
        cartCount: _cartCount,
        cartTotal: _cartTotal,
      ),
    );
  }

  void _showSuccessSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Table ${widget.table.numero}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.table.type.displayName,
              style: const TextStyle(fontSize: 12, color: AppTheme.brandGold),
            ),
          ],
        ),
        actions: [
          if (_existingOrders.isNotEmpty)
            IconButton(
              onPressed: () => _showReceiptOptions(),
              icon: const Icon(Icons.receipt_long_outlined),
              tooltip: 'Reçu / Facture',
            ),
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.brandGold,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.brandGold,
          tabs: [
            const Tab(
              icon: Icon(Icons.restaurant_menu, size: 20),
              text: 'Menu',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: _existingOrders.isNotEmpty,
                label: Text('${_existingOrders.length}'),
                child: const Icon(Icons.receipt_outlined, size: 20),
              ),
              text: 'Commandes',
            ),
          ],
        ),
      ),
      body: _isLoadingMenu
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.brandGold),
            )
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildMenuTab(), _buildOrdersTab()],
                ),
      bottomNavigationBar: _cart.isNotEmpty ? _buildCartBar() : null,
    );
  }

  Widget _buildMenuTab() {
    return Column(
      children: [
        // Search
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Rechercher un plat...',
              prefixIcon: const Icon(Icons.search, color: AppTheme.brandGold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
            ),
          ),
        ),

        // Category tabs
        Container(
          color: Colors.white,
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            itemCount: _categories.length + 1,
            itemBuilder: (_, i) {
              final isAll = i == 0;
              final cat = isAll ? null : _categories[i - 1];
              final isSelected = isAll
                  ? _selectedCategoryId == null
                  : _selectedCategoryId == cat!.id;
              return GestureDetector(
                onTap: () => setState(
                  () => _selectedCategoryId = isAll ? null : cat!.id,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTheme.brandGold : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isAll ? 'Tous' : cat!.nom,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const Divider(height: 1),

        // Products grid
        Expanded(
          child: _filteredProducts.isEmpty
              ? const Center(
                  child: Text(
                    'Aucun plat trouvé',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: _filteredProducts.length,
                  itemBuilder: (_, i) => _ProductCard(
                    product: _filteredProducts[i],
                    quantity: _cartQuantityFor(_filteredProducts[i]),
                    onAdd: () => _addToCart(_filteredProducts[i]),
                    onRemove: () => _removeFromCart(_filteredProducts[i]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildOrdersTab() {
    if (_isLoadingOrders) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.brandGold),
      );
    }
    if (_existingOrders.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.receipt_long, size: 60, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Aucune commande en cours',
              style: TextStyle(color: Colors.black54, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ajoutez des articles depuis le menu',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _tabController.animateTo(0),
              icon: const Icon(Icons.add),
              label: const Text('Aller au menu'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadOrders,
      color: AppTheme.brandGold,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _existingOrders.length,
        itemBuilder: (_, i) => _OrderCard(
          order: _existingOrders[i],
          onPrintReceipt: () => _showReceiptOptions(order: _existingOrders[i]),
        ),
      ),
    );
  }

  Widget _buildCartBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Cart info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$_cartCount article${_cartCount > 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 14, color: Colors.black54),
                ),
                Text(
                  Formatters.formatCurrency(_cartTotal),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),

          // View cart button
          TextButton.icon(
            onPressed: _showCart,
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: AppTheme.brandGold,
            ),
            label: const Text(
              'Voir panier',
              style: TextStyle(color: AppTheme.brandGold),
            ),
          ),
          const SizedBox(width: 8),

          // Send button
          ElevatedButton.icon(
            onPressed: _isSendingOrder ? null : _sendOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.brandGold,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            ),
            icon: _isSendingOrder
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_rounded, size: 18),
            label: Text(_isSendingOrder ? 'Envoi...' : 'Envoyer'),
          ),
        ],
      ),
    );
  }

  void _showCart() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        expand: false,
        builder: (ctx, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Mon panier',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setState(() => _cart = []);
                      Navigator.pop(ctx);
                    },
                    child: const Text(
                      'Vider',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: _cart.length,
                itemBuilder: (_, i) {
                  final item = _cart[i];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.brandGold.withValues(
                        alpha: 0.1,
                      ),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(
                          color: AppTheme.brandGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(item.product.nom),
                    subtitle: Text(
                      Formatters.formatCurrency(item.product.prix),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          Formatters.formatCurrency(item.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.brandGold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(
                              () => _cart.removeWhere(
                                (c) => c.product.id == item.product.id,
                              ),
                            );
                            if (_cart.isEmpty) Navigator.pop(ctx);
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(color: Colors.black54),
                        ),
                        Text(
                          Formatters.formatCurrency(_cartTotal),
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _sendOrder();
                    },
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Envoyer'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReceiptOptions({Order? order}) {
    final targetOrder =
        order ?? (_existingOrders.isNotEmpty ? _existingOrders.first : null);
    if (targetOrder == null) {
      _showErrorSnack('Aucune commande active pour cette table');
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrinterScreen(
          order: targetOrder,
          serveurName: widget.serveur?.name,
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            label: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── PRODUCT CARD ─────────────────────────────
class _ProductCard extends StatelessWidget {
  final Product product;
  final int quantity;
  final VoidCallback onAdd;
  final VoidCallback onRemove;

  const _ProductCard({
    required this.product,
    required this.quantity,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: quantity > 0
            ? Border.all(color: AppTheme.brandGold, width: 2)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
              child: product.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                          size: 36,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: Colors.grey.shade100,
                        child: const Icon(
                          Icons.restaurant,
                          color: Colors.grey,
                          size: 36,
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey.shade100,
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.grey,
                        size: 36,
                      ),
                    ),
            ),
          ),

          // Info
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.nom,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        Formatters.formatCurrency(product.prix),
                        style: const TextStyle(
                          color: AppTheme.brandGold,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      // Add/remove controls
                      if (quantity == 0)
                        GestureDetector(
                          onTap: onAdd,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.brandGold,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        )
                      else
                        Row(
                          children: [
                            GestureDetector(
                              onTap: onRemove,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Icon(
                                  Icons.remove,
                                  color: Colors.red.shade400,
                                  size: 14,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppTheme.brandGold,
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: onAdd,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: AppTheme.brandGold.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.brandGold.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: AppTheme.brandGold,
                                  size: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── ORDER CARD ─────────────────────────────
class _OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onPrintReceipt;

  const _OrderCard({required this.order, required this.onPrintReceipt});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.brandGold.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(14),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_outlined,
                  color: AppTheme.brandGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Commande #${order.id}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor(order.statut).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    order.statut.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: _statusColor(order.statut),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Items
          if (order.produits != null && order.produits!.isNotEmpty)
            ...order.produits!.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.brandGold.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${item.quantite}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.brandGold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.produitNom,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                    Text(
                      Formatters.formatCurrency(item.total),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const Divider(height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                    Text(
                      Formatters.formatCurrency(order.montantTotal),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.brandGold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                OutlinedButton.icon(
                  onPressed: onPrintReceipt,
                  icon: const Icon(Icons.print_outlined, size: 16),
                  label: const Text('Imprimer'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.brandGold,
                    side: const BorderSide(color: AppTheme.brandGold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.attente:
        return Colors.orange;
      case OrderStatus.preparation:
        return Colors.blue;
      case OrderStatus.servie:
        return Colors.green;
      case OrderStatus.terminee:
        return Colors.grey;
      case OrderStatus.annulee:
        return Colors.red;
    }
  }
}

// ─────────────────────────── PIN CONFIRM DIALOG ───────────────────────────
/// Two-step dialog: Step 1 — waiter selector, Step 2 — PIN keypad.
/// Returns the confirmed [Serveur] on success, null on cancel.
class _PinConfirmDialog extends StatefulWidget {
  final AuthService authService;
  final int cartCount;
  final double cartTotal;

  const _PinConfirmDialog({
    required this.authService,
    required this.cartCount,
    required this.cartTotal,
  });

  @override
  State<_PinConfirmDialog> createState() => _PinConfirmDialogState();
}

class _PinConfirmDialogState extends State<_PinConfirmDialog>
    with SingleTickerProviderStateMixin {
  // ── State
  List<Serveur>? _waiters;
  bool _loadingWaiters = true;
  Serveur? _selected;
  String _pin = '';
  bool _isLoading = false;
  bool _isError = false;

  // ── Shake animation
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    _loadWaiters();
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadWaiters() async {
    final list = await widget.authService.getWaiters();
    if (!mounted) return;
    setState(() {
      _waiters = list;
      _loadingWaiters = false;
    });
  }

  void _selectWaiter(Serveur w) {
    setState(() {
      _selected = w;
      _pin = '';
      _isError = false;
    });
  }

  void _onDigit(String d) {
    if (_pin.length >= 4 || _isLoading) return;
    setState(() { _pin += d; _isError = false; });
    if (_pin.length == 4) {
      Future.delayed(const Duration(milliseconds: 120), _verify);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty || _isLoading) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final valid = await widget.authService.checkPinOnly(_pin, userId: _selected!.id);
    if (!mounted) return;
    if (valid) {
      Navigator.pop(context, _selected);
    } else {
      setState(() { _isLoading = false; _isError = true; _pin = ''; });
      _shakeCtrl.forward(from: 0);
      Future.delayed(const Duration(seconds: 2), () { if (mounted) setState(() => _isError = false); });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: AppTheme.brandGold, size: 22),
                SizedBox(width: 8),
                Text('Confirmer la commande',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 10),
            // Order summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.brandGold.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${widget.cartCount} article${widget.cartCount > 1 ? 's' : ''} — ${Formatters.formatCurrency(widget.cartTotal)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.brandGold),
              ),
            ),
            const SizedBox(height: 16),
            // STEP 1 or STEP 2
            if (_selected == null) ..._buildWaiterSelector(),
            if (_selected != null) ..._buildPinStep(),
            const SizedBox(height: 10),
            TextButton(
              onPressed: _isLoading ? null : () => Navigator.pop(context),
              child: const Text('Annuler', style: TextStyle(color: Colors.black54)),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildWaiterSelector() {
    if (_loadingWaiters) {
      return [const SizedBox(height: 60, child: Center(child: CircularProgressIndicator(color: AppTheme.brandGold)))];
    }
    if (_waiters == null || _waiters!.isEmpty) {
      return [const Text('Aucun serveur disponible', style: TextStyle(color: Colors.red))];
    }
    return [
      const Text('Qui envoie cette commande ?',
          style: TextStyle(fontSize: 13, color: Colors.black54), textAlign: TextAlign.center),
      const SizedBox(height: 12),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        alignment: WrapAlignment.center,
        children: _waiters!.map(_waiterCard).toList(),
      ),
    ];
  }

  Widget _waiterCard(Serveur w) {
    return GestureDetector(
      onTap: () => _selectWaiter(w),
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppTheme.brandGold.withValues(alpha: 0.15),
              child: Text(w.initials,
                  style: const TextStyle(color: AppTheme.brandGold, fontWeight: FontWeight.bold, fontSize: 16)),
            ),
            const SizedBox(height: 6),
            Text(w.name.split(' ').first,
                textAlign: TextAlign.center, maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
            if (!w.hasPin)
              const Text('Pas de PIN', style: TextStyle(fontSize: 9, color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPinStep() {
    return [
      GestureDetector(
        onTap: _isLoading ? null : () => setState(() { _selected = null; _pin = ''; }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.brandGold.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_back_ios_new, size: 12, color: AppTheme.brandGold),
              const SizedBox(width: 4),
              Text(_selected!.name,
                  style: const TextStyle(color: AppTheme.brandGold, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          ),
        ),
      ),
      const SizedBox(height: 6),
      const Text('Entrez votre code PIN',
          style: TextStyle(fontSize: 13, color: Colors.black54), textAlign: TextAlign.center),
      const SizedBox(height: 16),
      // PIN dots
      AnimatedBuilder(
        animation: _shakeAnim,
        builder: (_, child) {
          final dx = _isError ? ((_shakeAnim.value * 10) % 2 - 1) * 8 : 0.0;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(4, (i) {
            final filled = i < _pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 18, height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isError ? Colors.red : filled ? AppTheme.brandGold : Colors.transparent,
                border: Border.all(
                  color: _isError ? Colors.red : filled ? AppTheme.brandGold : Colors.grey.shade400,
                  width: 2,
                ),
              ),
            );
          }),
        ),
      ),
      if (_isError)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text('Code PIN incorrect', style: TextStyle(color: Colors.red, fontSize: 12)),
        ),
      if (_isLoading)
        const Padding(
          padding: EdgeInsets.only(top: 10),
          child: SizedBox(height: 22, width: 22,
              child: CircularProgressIndicator(color: AppTheme.brandGold, strokeWidth: 2.5)),
        ),
      const SizedBox(height: 16),
      _buildKeypad(),
    ];
  }

  Widget _buildKeypad() {
    const rows = [['1','2','3'],['4','5','6'],['7','8','9']];
    return Column(
      children: [
        ...rows.map((row) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: row.map(_digitKey).toList(),
          ),
        )),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [const SizedBox(width: 80, height: 56), _digitKey('0'), _deleteKey()],
        ),
      ],
    );
  }

  Widget _digitKey(String d) => GestureDetector(
    onTap: () => _onDigit(d),
    child: Container(
      width: 64, height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
      child: Center(child: Text(d, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.black87))),
    ),
  );

  Widget _deleteKey() => GestureDetector(
    onTap: _onDelete,
    child: Container(
      width: 64, height: 56,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(14)),
      child: const Center(child: Icon(Icons.backspace_outlined, size: 20, color: Colors.black54)),
    ),
  );
}
