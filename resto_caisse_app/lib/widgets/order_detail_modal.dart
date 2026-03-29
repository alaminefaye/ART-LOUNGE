import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/printer_service.dart';
import '../services/menu_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import 'payment_selection_dialog.dart';

class OrderDetailModal extends StatefulWidget {
  final Order order;
  final VoidCallback onOrderUpdated;

  const OrderDetailModal({super.key, required this.order, required this.onOrderUpdated});

  @override
  State<OrderDetailModal> createState() => _OrderDetailModalState();
}

class _OrderDetailModalState extends State<OrderDetailModal> {
  final OrderService _orderService = OrderService();
  final PrinterService _printerService = PrinterService();
  final MenuService _menuService = MenuService();

  bool _isLoading = false;
  Order? _currentOrder;

  // Editing state: produitId -> quantite locale
  final Map<int, int> _localQuantities = {};
  // Snapshot des quantités d'ORIGINE (avant toute modification de cette session)
  final Map<int, int> _originalQuantities = {};
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _initLocalQuantities();
  }

  void _initLocalQuantities() {
    _localQuantities.clear();
    _originalQuantities.clear();
    for (final item in _currentOrder?.produits ?? []) {
      _localQuantities[item.produitId] = item.quantite;
      _originalQuantities[item.produitId] = item.quantite; // snapshot
    }
  }

  /// --- STATUS ACTIONS ---
  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _isLoading = true);
    bool success = false;

    if (newStatus == OrderStatus.preparation) {
      final res = await _orderService.launchOrder((_currentOrder ?? widget.order).id);
      success = res['success'] == true;
    } else {
      success = await _orderService.updateOrderStatus((_currentOrder ?? widget.order).id, newStatus);
    }

    setState(() => _isLoading = false);

    if (success) {
      widget.onOrderUpdated();
      if (mounted) Navigator.pop(context);
    } else {
      _showError('Erreur lors de la mise à jour du statut');
    }
  }

  /// --- QUANTITY CHANGE ---
  void _changeQty(int produitId, int delta) {
    final current = _localQuantities[produitId] ?? 1;
    final next = current + delta;
    if (next <= 0) {
      _confirmRemoveItem(produitId);
      return;
    }
    setState(() {
      _localQuantities[produitId] = next;
      _hasChanges = true;
    });
  }

  /// --- CONFIRM SAVE ALL CHANGES ---
  /// Envoie les différences à l'API, puis imprime automatiquement
  /// un bon SUPPLÉMENT avec uniquement les articles ajoutés/augmentés.
  Future<void> _saveChanges() async {
    final order = _currentOrder ?? widget.order;
    final orderId = order.id;
    final tableNum = order.table?.numero ?? 'N/A';

    setState(() => _isLoading = true);

    // Calculer le delta (nouvelles quantités > quantités d'origine)
    final List<Map<String, dynamic>> additions = [];

    for (final item in order.produits ?? []) {
      final origQty = _originalQuantities[item.produitId] ?? item.quantite;
      final newQty = _localQuantities[item.produitId] ?? item.quantite;
      final diff = newQty - origQty;

      if (diff > 0) {
        await _orderService.addProductToOrder(
          orderId: orderId,
          produitId: item.produitId,
          quantite: diff,
        );
        additions.add({'nom': item.produitNom, 'quantite': diff});
      }
    }

    setState(() {
      _isLoading = false;
      _hasChanges = false;
    });
    widget.onOrderUpdated();
    _showSuccess('Commande mise à jour avec succès');

    // Impression automatique du bon SUPPLÉMENT si des articles ont été ajoutés
    if (additions.isNotEmpty) {
      await _printerService.printSupplementKitchenTicket(
        orderId: orderId,
        tableNumero: tableNum,
        additions: additions,
      );
    }

    // Reload the order
    final refreshed = await _orderService.getOrder(orderId);
    if (mounted && refreshed != null) {
      setState(() {
        _currentOrder = refreshed;
        _initLocalQuantities(); // Reset le snapshot avec les nouvelles valeurs
      });
    }
  }

  /// --- CONFIRM REMOVE item (decrease below 1) ---
  void _confirmRemoveItem(int produitId) {
    final item = _currentOrder?.produits?.firstWhere((p) => p.produitId == produitId);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Retirer cet article ?'),
        content: Text('Supprimer "${item?.produitNom}" de la commande ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _localQuantities.remove(produitId);
                _currentOrder = Order(
                  id: _currentOrder!.id,
                  tableId: _currentOrder!.tableId,
                  userId: _currentOrder!.userId,
                  montantTotal: _currentOrder!.montantTotal,
                  statut: _currentOrder!.statut,
                  createdAt: _currentOrder!.createdAt,
                  updatedAt: _currentOrder!.updatedAt,
                  produits: _currentOrder!.produits
                      ?.where((p) => p.produitId != produitId)
                      .toList(),
                  table: _currentOrder!.table,
                  client: _currentOrder!.client,
                  reductionFidelite: _currentOrder!.reductionFidelite,
                  pointsUtilises: _currentOrder!.pointsUtilises,
                );
                _hasChanges = true;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  /// --- ADD NEW PRODUCT ---
  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (ctx) => _AddProductDialog(
        onProductAdded: (product, qty) async {
          Navigator.pop(ctx);
          setState(() => _isLoading = true);
          final res = await _orderService.addProductToOrder(
            orderId: (_currentOrder ?? widget.order).id,
            produitId: product.id,
            quantite: qty,
          );
          setState(() => _isLoading = false);
          if (res['success'] == true) {
            widget.onOrderUpdated();
            _showSuccess('${product.nom} ajouté à la commande');

            // Imprimer automatiquement un bon supplément pour cet ajout
            final order = _currentOrder ?? widget.order;
            await _printerService.printSupplementKitchenTicket(
              orderId: order.id,
              tableNumero: order.table?.numero ?? 'N/A',
              additions: [{'nom': product.nom, 'quantite': qty}],
            );

            final refreshed = await _orderService.getOrder(order.id);
            if (mounted && refreshed != null) {
              setState(() {
                _currentOrder = refreshed;
                _initLocalQuantities();
              });
            }
          } else {
            _showError(res['message'] ?? 'Erreur lors de l\'ajout');
          }
        },
        menuService: _menuService,
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  double get _computedTotal {
    double total = 0;
    for (final item in _currentOrder?.produits ?? []) {
      final qty = _localQuantities[item.produitId] ?? item.quantite;
      total += item.prix * qty;
    }
    return total;
  }

  Order get _order => _currentOrder ?? widget.order;

  @override
  Widget build(BuildContext context) {
    final isEditable = _order.statut != OrderStatus.annulee && _order.statut != OrderStatus.terminee;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 700,
        constraints: const BoxConstraints(maxHeight: 780),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──────────────────────────────────────────────
            _buildHeader(),

            // ── Info badges ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _buildInfoBadge('Table', _order.table?.numero ?? 'Aucune'),
                  const SizedBox(width: 12),
                  _buildInfoBadge('Statut', _order.statut.displayName, color: _order.statut.color),
                  const SizedBox(width: 12),
                  _buildInfoBadge(
                    'Date',
                    '${_order.createdAt.hour.toString().padLeft(2,'0')}:${_order.createdAt.minute.toString().padLeft(2,'0')}',
                  ),
                  const Spacer(),
                  if (_order.client?.nomComplet.isNotEmpty == true)
                    _buildInfoBadge('Client', _order.client!.nomComplet, color: Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),

            // ── Items list header ────────────────────────────────────
            if (isEditable)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                child: Row(
                  children: [
                    const Text('Articles', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _showAddProductDialog,
                      icon: const Icon(Icons.add_circle, color: AppTheme.brandGold),
                      label: const Text('Ajouter un produit', style: TextStyle(color: AppTheme.brandGold, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              )
            else
              const SizedBox(height: 10),

            // ── Items list ──────────────────────────────────────────
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _order.produits?.length ?? 0,
                separatorBuilder: (ctx, i) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = _order.produits![index];
                  final qty = _localQuantities[item.produitId] ?? item.quantite;
                  final itemTotal = item.prix * qty;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        // Product name + unit price
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.produitNom, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text(Formatters.formatCurrency(item.prix), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),

                        // Quantity controls (only when editable)
                        if (isEditable) ...[
                          IconButton(
                            icon: Icon(
                              qty <= 1 ? Icons.delete_outline : Icons.remove_circle_outline,
                              color: qty <= 1 ? Colors.red : Colors.grey,
                              size: 22,
                            ),
                            onPressed: () => _changeQty(item.produitId, -1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                          Container(
                            width: 36,
                            height: 36,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              border: Border.all(color: AppTheme.brandGold.withValues(alpha: 0.5)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, color: AppTheme.brandGold, size: 22),
                            onPressed: () => _changeQty(item.produitId, 1),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                          ),
                        ] else ...[
                          Text('x$qty', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ],

                        const SizedBox(width: 16),
                        // Item total
                        SizedBox(
                          width: 90,
                          child: Text(
                            Formatters.formatCurrency(itemTotal),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandGold),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Divider(height: 1),

            // ── Total + Fidelity + Net ──────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Articles', style: TextStyle(fontSize: 14, color: Colors.grey)),
                      Text(
                        Formatters.formatCurrency(_computedTotal),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textDark),
                      ),
                    ],
                  ),
                  if (_hasChanges)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _saveChanges,
                        icon: const Icon(Icons.save_alt, size: 18),
                        label: const Text('Enregistrer les modifications'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 45),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  if (_order.pointsUtilises > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Réduction Fidélité (${_order.pointsUtilises} pts)', 
                          style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600)
                        ),
                        Text(
                          '-${Formatters.formatCurrency(_order.reductionFidelite)}',
                          style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  const Divider(height: 1),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('NET À PAYER', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                      Text(
                        Formatters.formatCurrency(_computedTotal - _order.reductionFidelite),
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppTheme.brandGold),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Action buttons ───────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGold))
                  : Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      alignment: WrapAlignment.center,
                      children: [
                        // Annuler la commande
                        if (isEditable)
                          _ActionButton(
                            label: 'Annuler commande',
                            icon: Icons.cancel_outlined,
                            color: Colors.red,
                            outlined: true,
                            onPressed: () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  titlePadding: EdgeInsets.zero,
                                  title: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                                        SizedBox(width: 10),
                                        Text('Annuler la commande ?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                      ],
                                    ),
                                  ),
                                  content: Text(
                                    'Vous êtes sur le point d\'annuler la commande #${_order.id}.\n\nCette action est irréversible. Confirmez-vous ?',
                                    style: const TextStyle(fontSize: 14, height: 1.5),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx, false),
                                      child: const Text('NON, GARDER', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                    ElevatedButton.icon(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                                      icon: const Icon(Icons.delete_forever, size: 18),
                                      label: const Text('OUI, ANNULER', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                _updateStatus(OrderStatus.annulee);
                              }
                            },
                          ),

                        // Lancer en cuisine
                        if (_order.statut == OrderStatus.attente)
                          _ActionButton(
                            label: 'Lancer Cuisine',
                            icon: Icons.restaurant_menu,
                            color: AppTheme.brandGold,
                            onPressed: () async {
                              await _updateStatus(OrderStatus.preparation);
                              await _printerService.printKitchenTicket(_order);
                            },
                          ),

                        // Bon de cuisine seul
                        if (_order.statut == OrderStatus.preparation || _order.statut == OrderStatus.attente)
                          _ActionButton(
                            label: 'Bon Cuisine',
                            icon: Icons.receipt_long,
                            color: Colors.deepOrange,
                            onPressed: () => _printerService.printKitchenTicket(_order),
                          ),

                        // Marquer servi
                        if (_order.statut == OrderStatus.preparation)
                          _ActionButton(
                            label: 'Marquer Servi',
                            icon: Icons.check_circle_outline,
                            color: Colors.orange,
                            onPressed: () => _updateStatus(OrderStatus.servie),
                          ),

                        // Terminer
                        if (_order.statut == OrderStatus.servie)
                          _ActionButton(
                            label: 'Payer et Terminer',
                            icon: Icons.money_off_csred_outlined,
                            color: Colors.green,
                            onPressed: () async {
                              final success = await showDialog<bool>(
                                context: context,
                                barrierDismissible: false,
                                builder: (ctx) => PaymentSelectionDialog(existingOrder: _order),
                              );
                              if (success == true) {
                                widget.onOrderUpdated();
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                          ),

                        // Imprimer facture (always available)
                        _ActionButton(
                          label: 'Facture',
                          icon: Icons.print,
                          color: Colors.blueGrey,
                          onPressed: () {
                            final cashierName = Provider.of<AuthService>(context, listen: false).currentUser?.name;
                            _printerService.printOrderReceipt(_order, cashierName: cashierName);
                          },
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(color: AppTheme.brandGold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(
              'Commande #${_order.id}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.brandGold),
            ),
          ),
          const Spacer(),
          IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(String label, String value, {Color color = Colors.black87}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        ],
      ),
    );
  }
}

// ── Reusable action button ─────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onPressed;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    if (outlined) {
      return OutlinedButton.icon(
        icon: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return ElevatedButton.icon(
      icon: Icon(icon, size: 18, color: Colors.white),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ── Add Product Dialog ─────────────────────────────────────────────────────
class _AddProductDialog extends StatefulWidget {
  final Function(Product product, int qty) onProductAdded;
  final MenuService menuService;

  const _AddProductDialog({required this.onProductAdded, required this.menuService});

  @override
  State<_AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<_AddProductDialog> {
  List<Product> _products = [];
  List<Product> _filtered = [];
  bool _loading = true;
  final TextEditingController _searchCtrl = TextEditingController();
  final Map<int, int> _selectedQtys = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_filter);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final products = await widget.menuService.getProducts();
    if (mounted) {
      setState(() {
        _products = products.where((p) => p.disponible && p.actif).toList();
        _filtered = List.from(_products);
        _loading = false;
      });
    }
  }

  void _filter() {
    final q = _searchCtrl.text.toLowerCase();
    setState(() {
      _filtered = _products.where((p) => p.nom.toLowerCase().contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Container(
        width: 560,
        height: 560,
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                const Text('Ajouter un produit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 12),
            // Search
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Rechercher un produit...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            // Product list
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.brandGold))
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (context2, i) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = _filtered[index];
                        final qty = _selectedQtys[p.id] ?? 0;
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: p.imageUrl.isNotEmpty
                                ? Image.network(p.imageUrl, width: 48, height: 48, fit: BoxFit.cover,
                                    errorBuilder: (e, o, s) => _productIcon())
                                : _productIcon(),
                          ),
                          title: Text(p.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text(Formatters.formatCurrency(p.prix), style: const TextStyle(color: AppTheme.brandGold)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (qty > 0) ...[
                                IconButton(
                                  icon: Icon(qty <= 1 ? Icons.delete_outline : Icons.remove_circle_outline,
                                      color: qty <= 1 ? Colors.red : Colors.grey, size: 20),
                                  onPressed: () => setState(() {
                                    if (qty <= 1) {
                                      _selectedQtys.remove(p.id);
                                    } else {
                                      _selectedQtys[p.id] = qty - 1;
                                    }
                                  }),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                                ),
                                Container(
                                  width: 32,
                                  height: 32,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppTheme.brandGold.withValues(alpha: 0.5)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text('$qty', style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                              ],
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: AppTheme.brandGold, size: 20),
                                onPressed: () => setState(() => _selectedQtys[p.id] = qty + 1),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                              ),
                              if (qty > 0)
                                ElevatedButton(
                                  onPressed: () => widget.onProductAdded(p, qty),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.brandGold,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 13)),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productIcon() => Container(
        width: 48,
        height: 48,
        color: Colors.grey.shade200,
        child: const Icon(Icons.fastfood, color: Colors.grey),
      );
}
