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

  double get total => product.prix * quantity;
}

class OrderScreen extends StatefulWidget {
  final RestaurantTable table;
  final Serveur? serveur;

  const OrderScreen({super.key, required this.table, this.serveur});

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final MenuService _menuService = MenuService();
  final OrderService _orderService = OrderService();

  List<Category> _categories = [];
  List<Product> _products = [];
  List<_CartItem> _cart = [];
  List<Order> _activeOrders = []; // only attente / preparation

  int? _selectedCategoryId;
  bool _isLoadingMenu = true;
  bool _isSendingOrder = false;
  String? _error;
  String _searchQuery = '';

  final _searchController = TextEditingController();

  // Mobile: show ticket panel on top
  bool _showTicketOnMobile = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(
      () => setState(() => _searchQuery = _searchController.text.toLowerCase()),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────

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
        final allOrders = results[2] as List<Order>;
        setState(() {
          _categories = results[0] as List<Category>;
          _products = results[1] as List<Product>;
          // Only keep active (non-finished) orders
          _activeOrders =
              allOrders
                  .where(
                    (o) =>
                        o.statut == OrderStatus.attente ||
                        o.statut == OrderStatus.preparation,
                  )
                  .toList();
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

  // ── Cart helpers ──────────────────────────────────────────────────────

  void _addToCart(Product product) {
    setState(() {
      final idx = _cart.indexWhere((c) => c.product.id == product.id);
      if (idx >= 0) {
        _cart[idx].quantity++;
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

  void _removeLineFromCart(int idx) {
    setState(() => _cart.removeAt(idx));
  }

  int _cartQtyFor(Product p) {
    final items = _cart.where((c) => c.product.id == p.id);
    return items.isEmpty ? 0 : items.first.quantity;
  }

  double get _cartTotal => _cart.fold(0, (s, i) => s + i.total);
  int get _cartCount => _cart.fold(0, (s, i) => s + i.quantity);

  List<Product> get _filteredProducts {
    var list = _products.where((p) => p.disponible && p.actif).toList();
    if (_selectedCategoryId != null) {
      list = list.where((p) => p.categorieId == _selectedCategoryId).toList();
    }
    if (_searchQuery.isNotEmpty) {
      list =
          list
              .where((p) => p.nom.toLowerCase().contains(_searchQuery))
              .toList();
    }
    return list;
  }

  // ── Send order ────────────────────────────────────────────────────────

  Future<void> _sendOrder() async {
    if (_cart.isEmpty) return;

    final confirmedWaiter = await _showPinConfirmDialog();
    if (confirmedWaiter == null) return;

    setState(() => _isSendingOrder = true);

    final newItems =
        _cart
            .map(
              (item) => OrderItem(
                produitId: item.product.id,
                produitNom: item.product.nom,
                prix: item.product.prix,
                quantite: item.quantity,
                statut: 'envoye',
                servi: false,
              ),
            )
            .toList();

    final produits =
        _cart
            .map(
              (item) => {
                'produit_id': item.product.id,
                'quantite': item.quantity,
                if (item.note.isNotEmpty) 'notes': item.note,
              },
            )
            .toList();

    Map<String, dynamic> result;
    if (_activeOrders.isNotEmpty) {
      final activeOrder = _activeOrders.first;
      result = await _orderService.addProductsToOrder(
        orderId: activeOrder.id,
        produits: produits,
      );
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
        await _loadData();
        if (mounted) {
          _showSuccessSnack('Commande envoyée en cuisine !');
          final sentOrder =
              _activeOrders.isNotEmpty ? _activeOrders.first : null;
          if (sentOrder != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => PrinterScreen(
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

  // ── Print receipt ─────────────────────────────────────────────────────

  void _printReceipt() {
    if (_activeOrders.isEmpty) return;
    final activeOrder = _activeOrders.first;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => PrinterScreen(
              order: activeOrder,
              serveurName: widget.serveur?.name ?? '',
            ),
      ),
    );
  }

  // ── Admin Actions (Cancel / Remove) ───────────────────────────────────

  Future<void> _requireAdminPinAndExecute({
    required Future<void> Function() action,
    required String actionName,
  }) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await showDialog<Serveur>(
      context: context,
      builder:
          (context) => _AdminPinDialog(
            authService: authService,
            actionName: actionName,
          ),
    );
    if (result != null) {
      if (result.hasRole('admin') || 
          result.hasRole('gerant') || 
          result.hasRole('manager') || 
          result.hasRole('super-admin')) {
        await action();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accès refusé. Droits gérant ou admin requis.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelOrder() async {
    if (_activeOrders.isEmpty) return;
    
    await _requireAdminPinAndExecute(
      actionName: 'Annuler la commande #${_activeOrders.first.id}',
      action: () async {
        setState(() => _isSendingOrder = true);
        final res = await _orderService.cancelOrder(_activeOrders.first.id);
        setState(() => _isSendingOrder = false);
        if (res['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Commande annulée avec succès'), backgroundColor: Colors.green),
          );
          Navigator.pop(context, true); // Go back, order is cancelled
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Erreur'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  Future<void> _removeProduct(OrderItem item) async {
    if (_activeOrders.isEmpty) return;

    await _requireAdminPinAndExecute(
      actionName: 'Supprimer: ${item.quantite}x ${item.produitNom}',
      action: () async {
        setState(() => _isSendingOrder = true);
        final res = await _orderService.removeProductFromOrder(_activeOrders.first.id, item.produitId);
        if (res['success'] == true) {
          await _loadData();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produit supprimé'), backgroundColor: Colors.green),
          );
        } else {
          setState(() => _isSendingOrder = false);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(res['message'] ?? 'Erreur'), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  // ── PIN dialog ────────────────────────────────────────────────────────

  Future<Serveur?> _showPinConfirmDialog() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    return await showDialog<Serveur>(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => _PinConfirmDialog(
            authService: authService,
            cartCount: _cartCount,
            cartTotal: _cartTotal,
          ),
    );
  }

  // ── Snack helpers ─────────────────────────────────────────────────────

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

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoadingMenu) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.brandGold),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppTheme.scaffoldBg,
        appBar: AppBar(title: Text('Table ${widget.table.numero}')),
        body: _buildError(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return Scaffold(
          backgroundColor: AppTheme.scaffoldBg,
          appBar: _buildAppBar(),
          floatingActionButton:
              isMobile && (_cart.isNotEmpty || _activeOrders.isNotEmpty)
                  ? FloatingActionButton.extended(
                    onPressed: () => setState(() => _showTicketOnMobile = true),
                    backgroundColor: AppTheme.brandGold,
                    icon: const Icon(Icons.receipt_long, color: Colors.white),
                    label: Text(
                      _cart.isNotEmpty
                          ? '${Formatters.formatCurrency(_cartTotal)} ($_cartCount)'
                          : 'Voir la commande',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  : null,
          body: Stack(
            children: [
              Row(
                children: [
                  // ── Left: menu ──────────────────────────────────────
                  Expanded(child: _buildMenuPanel()),

                  // ── Right: ticket (desktop only) ────────────────────
                  if (!isMobile)
                    SizedBox(
                      width: 360,
                      child: _buildTicketPanel(),
                    ),
                ],
              ),

              // ── Mobile ticket overlay ───────────────────────────────
              if (isMobile && _showTicketOnMobile)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: () => setState(() => _showTicketOnMobile = false),
                    child: Container(
                      color: Colors.black54,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap:
                                () => setState(
                                  () => _showTicketOnMobile = false,
                                ),
                            child: Container(
                              width: 56,
                              color: Colors.transparent,
                              child: const Icon(
                                Icons.chevron_left,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {},
                              child: _buildTicketPanel(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.brandGold.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.table_restaurant,
                  color: AppTheme.brandGold,
                  size: 16,
                ),
                const SizedBox(width: 5),
                Text(
                  'Table ${widget.table.numero}',
                  style: const TextStyle(
                    color: AppTheme.brandGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_activeOrders.isNotEmpty) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border:
                      Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bolt, color: Colors.orange.shade700, size: 13),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        'En cours',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
      actions: [
        if (_activeOrders.isNotEmpty) ...[
          IconButton(
            onPressed: _printReceipt,
            icon: const Icon(Icons.print_outlined, color: AppTheme.brandGold),
            tooltip: 'Imprimer le reçu',
          ),
          IconButton(
            onPressed: _cancelOrder,
            icon: const Icon(Icons.cancel_outlined, color: Colors.red),
            tooltip: 'Annuler la commande',
          ),
        ],
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh, color: Colors.black54),
          tooltip: 'Actualiser',
        ),
      ],
    );
  }

  // ── Menu panel (left) ─────────────────────────────────────────────────

  Widget _buildMenuPanel() {
    return Column(
      children: [
        // Active order summary banner
        if (_activeOrders.isNotEmpty) _buildActiveOrderBanner(),

        // Search bar
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
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => _searchController.clear(),
                      )
                      : null,
            ),
          ),
        ),

        // Category pills
        Container(
          color: Colors.white,
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: _categories.length + 1,
            itemBuilder: (_, i) {
              final isAll = i == 0;
              final cat = isAll ? null : _categories[i - 1];
              final isSelected =
                  isAll
                      ? _selectedCategoryId == null
                      : _selectedCategoryId == cat!.id;
              return GestureDetector(
                onTap:
                    () => setState(
                      () => _selectedCategoryId = isAll ? null : cat!.id,
                    ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  margin: const EdgeInsets.only(right: 8),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppTheme.brandGold : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow:
                        isSelected
                            ? [
                              BoxShadow(
                                color: AppTheme.brandGold.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                            : [],
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
          child:
              _filteredProducts.isEmpty
                  ? const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restaurant_menu, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text(
                          'Aucun plat trouvé',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                  : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 200,
                          childAspectRatio: 0.78,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: _filteredProducts.length,
                    itemBuilder:
                        (_, i) => _ProductCard(
                          product: _filteredProducts[i],
                          quantity: _cartQtyFor(_filteredProducts[i]),
                          onAdd: () => _addToCart(_filteredProducts[i]),
                          onRemove: () => _removeFromCart(_filteredProducts[i]),
                        ),
                  ),
        ),
      ],
    );
  }

  Widget _buildActiveOrderBanner() {
    final order = _activeOrders.first;
    final itemCount = order.produits?.length ?? 0;
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Commande #${order.id} en cours · $itemCount article${itemCount > 1 ? 's' : ''} · Ajouter des articles ci-dessous',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Ticket panel (right) ──────────────────────────────────────────────

  Widget _buildTicketPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Color(0x14000000), blurRadius: 20, offset: Offset(-4, 0)),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            decoration: BoxDecoration(
              color: AppTheme.brandGold.withValues(alpha: 0.05),
              border: Border(
                bottom: BorderSide(
                  color: AppTheme.brandGold.withValues(alpha: 0.15),
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.receipt_long,
                  color: AppTheme.brandGold,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Nouvelle commande',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      'Table ${widget.table.numero}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.brandGold,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_cart.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _cart = []),
                    child: const Text(
                      'Vider',
                      style: TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),

          // Cart items or empty state
          Expanded(
            child:
                _cart.isEmpty
                    ? _buildEmptyCart()
                    : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _cart.length,
                      itemBuilder: (_, i) => _CartLineItem(
                        item: _cart[i],
                        onAdd: () => _addToCart(_cart[i].product),
                        onRemove: () => _removeFromCart(_cart[i].product),
                        onDelete: () => _removeLineFromCart(i),
                      ),
                    ),
          ),

          // Existing order summary (if any)
          if (_activeOrders.isNotEmpty && _activeOrders.first.produits != null)
            _buildExistingOrderSummary(),

          // Total + send button
          _buildTicketFooter(),
        ],
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.add_shopping_cart,
            size: 56,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Panier vide',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Sélectionnez des articles dans le menu',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildExistingOrderSummary() {
    final order = _activeOrders.first;
    final items = order.produits ?? [];
    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
        title: Text(
          'Déjà commandé (${items.length} article${items.length > 1 ? 's' : ''})',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.black54,
          ),
        ),
        trailing: Text(
          Formatters.formatCurrency(order.montantTotal),
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.black45,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: Column(
              children:
                  items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${item.quantite}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  item.produitNom,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black54,
                                  ),
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(item.total),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black45,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => _removeProduct(item),
                                child: const Padding(
                                  padding: EdgeInsets.all(4.0),
                                  child: Icon(Icons.close, color: Colors.red, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketFooter() {
    final hasActiveOrder = _activeOrders.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        children: [
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$_cartCount article${_cartCount > 1 ? 's' : ''} à envoyer',
                style: const TextStyle(color: Colors.black54, fontSize: 13),
              ),
              Text(
                Formatters.formatCurrency(_cartTotal),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Send button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_cart.isEmpty || _isSendingOrder) ? null : _sendOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.brandGold,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade200,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: _cart.isEmpty ? 0 : 2,
              ),
              icon:
                  _isSendingOrder
                      ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                      : const Icon(Icons.send_rounded, size: 20),
              label: Text(
                _isSendingOrder
                    ? 'Envoi en cuisine...'
                    : hasActiveOrder
                    ? 'Ajouter à la commande'
                    : 'Envoyer en cuisine',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          if (hasActiveOrder) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _printReceipt,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.brandGold,
                  side: const BorderSide(color: AppTheme.brandGold),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.print_outlined, size: 18),
                label: const Text(
                  'Imprimer le reçu',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.black54, fontSize: 15),
          ),
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

// ─────────────────────────── PRODUCT CARD ─────────────────────────────────────

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
    final inCart = quantity > 0;
    return GestureDetector(
      onTap: onAdd,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: inCart ? AppTheme.brandGold : Colors.grey.shade200,
            width: inCart ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  inCart
                      ? AppTheme.brandGold.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.04),
              blurRadius: inCart ? 12 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    child:
                        product.imageUrl.isNotEmpty
                            ? CachedNetworkImage(
                              imageUrl: product.imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              placeholder:
                                  (_, __) => Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                      opacity: const AlwaysStoppedAnimation(0.4),
                                    ),
                                  ),
                              errorWidget:
                                  (_, __, ___) => Container(
                                    color: Colors.white,
                                    padding: const EdgeInsets.all(12),
                                    child: Image.asset(
                                      'assets/logo.png',
                                      fit: BoxFit.contain,
                                      opacity: const AlwaysStoppedAnimation(0.4),
                                    ),
                                  ),
                            )
                            : Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/logo.png',
                                fit: BoxFit.contain,
                                opacity: const AlwaysStoppedAnimation(0.4),
                              ),
                            ),
                  ),
                  if (inCart)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.brandGold,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '×$quantity',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Info + controls
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.nom,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        height: 1.2,
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
                        if (quantity == 0)
                          GestureDetector(
                            onTap: onAdd,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppTheme.brandGold,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 15,
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
                                    size: 13,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
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
                                    color: AppTheme.brandGold.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppTheme.brandGold.withValues(alpha: 0.4),
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    color: AppTheme.brandGold,
                                    size: 13,
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
      ),
    );
  }
}

// ─────────────────────────── CART LINE ITEM ───────────────────────────────────

class _CartLineItem extends StatelessWidget {
  final _CartItem item;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const _CartLineItem({
    required this.item,
    required this.onAdd,
    required this.onRemove,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Quantity controls
          GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Icon(Icons.remove, color: Colors.red.shade400, size: 14),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppTheme.brandGold,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppTheme.brandGold.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.brandGold.withValues(alpha: 0.4)),
              ),
              child: const Icon(Icons.add, color: AppTheme.brandGold, size: 14),
            ),
          ),

          const SizedBox(width: 10),

          // Name
          Expanded(
            child: Text(
              item.product.nom,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          const SizedBox(width: 8),

          // Price
          Text(
            Formatters.formatCurrency(item.total),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),

          // Delete
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.close, color: Colors.red, size: 18),
            padding: const EdgeInsets.only(left: 6),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── PIN CONFIRM DIALOG ───────────────────────────────

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

class _PinConfirmDialogState extends State<_PinConfirmDialog> {
  final _pinController = TextEditingController();
  String? _error;
  bool _isVerifying = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final result = await widget.authService.checkPinOnly(_pinController.text.trim());
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, result);
    } else {
      setState(() {
        _error = 'PIN incorrect';
        _isVerifying = false;
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(
        children: [
          Icon(Icons.pin_outlined, color: AppTheme.brandGold),
          SizedBox(width: 8),
          Text(
            'Confirmer votre PIN',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.brandGold.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${widget.cartCount} article${widget.cartCount > 1 ? 's' : ''}',
                  style: const TextStyle(color: Colors.black54),
                ),
                Text(
                  Formatters.formatCurrency(widget.cartTotal),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.brandGold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            onSubmitted: (_) => _verify(),
            style: const TextStyle(fontSize: 20, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '• • • •',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.brandGold),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.brandGold),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppTheme.brandGold, width: 2),
              ),
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.brandGold,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child:
              _isVerifying
                  ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                  : const Text('Envoyer', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class _AdminPinDialog extends StatefulWidget {
  final AuthService authService;
  final String actionName;

  const _AdminPinDialog({required this.authService, required this.actionName});

  @override
  State<_AdminPinDialog> createState() => _AdminPinDialogState();
}

class _AdminPinDialogState extends State<_AdminPinDialog> {
  final _pinController = TextEditingController();
  String? _error;
  bool _isVerifying = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (_pinController.text.trim().isEmpty) return;
    setState(() {
      _isVerifying = true;
      _error = null;
    });
    final result = await widget.authService.checkPinOnly(_pinController.text.trim());
    if (!mounted) return;
    if (result != null) {
      Navigator.pop(context, result);
    } else {
      setState(() {
        _error = 'PIN incorrect';
        _isVerifying = false;
        _pinController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: const [
          Icon(Icons.security, color: Colors.red),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Autorisation requise',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.actionName,
            style: const TextStyle(color: Colors.black54, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofocus: true,
            onSubmitted: (_) => _verify(),
            style: const TextStyle(fontSize: 20, letterSpacing: 8),
            decoration: InputDecoration(
              hintText: '• • • •',
              hintStyle: TextStyle(color: Colors.grey.shade400),
              prefixIcon: const Icon(Icons.lock_outline, color: Colors.red),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isVerifying ? null : _verify,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: _isVerifying
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
              : const Text('Valider'),
        ),
      ],
    );
  }
}
