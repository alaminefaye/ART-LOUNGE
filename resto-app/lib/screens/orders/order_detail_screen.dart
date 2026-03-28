import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:async';
import '../../services/auth_service.dart';
import '../../services/fcm_events.dart';
import '../../config/api_config.dart';
import '../../models/order.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/order_service.dart';
import '../../services/invoice_service.dart';
import '../../services/api_service.dart';
import '../../models/invoice.dart';
import '../../utils/formatters.dart';
import 'payment_screen.dart';
import 'invoice_screen.dart';
import '../../widgets/app_header.dart';
import '../home/home_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  final InvoiceService _invoiceService = InvoiceService();
  final ApiService _apiService = ApiService();
  Order? _order;
  bool _isLoading = true;
  bool _canAddProducts = true; // Vérifier si la commande peut être modifiée
  StreamSubscription? _orderUpdateSubscription;
  bool _reviewPopupShown = false;
  final TextEditingController _reviewController = TextEditingController();
  static const Color _brandGold = Color(0xFFD0A030);

  @override
  void initState() {
    super.initState();
    _loadOrder();

    // Écouter les mises à jour des commandes
    _orderUpdateSubscription = FCMEvents.orderUpdateStream.listen((_) {
      if (mounted) {
        // Optionnel : ne recharger que si c'est la commande actuelle concernée
        // Mais pour l'instant on recharge tout car on n'a pas l'ID dans le stream
        _loadOrder();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.notifications_active, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Commande mise à jour !',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _orderUpdateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadOrder() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final order = await _orderService.getOrder(widget.orderId);

      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
          // La commande peut être modifiée tant qu'elle n'est pas terminée ou annulée
          // (On peut ajouter des produits à une commande servie)
          _canAddProducts =
              order != null &&
              order.statut != OrderStatus.terminee &&
              order.statut != OrderStatus.annulee;
        });
        await _maybeShowInvoiceAndReviewPopup();
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement de la commande: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _maybeShowInvoiceAndReviewPopup() async {
    if (!mounted || _order == null) return;
    if (_reviewPopupShown) return;
    if (_order!.statut != OrderStatus.terminee) return;
    // Facture + avis réservés au client qui a passé la commande
    final user = Provider.of<AuthService>(context, listen: false).currentUser;
    if (user == null || !user.hasRole('client')) return;

    try {
      final existing = await _apiService.get(
        ApiConfig.avisForOrder(_order!.id),
      );
      if (existing.statusCode == 200) {
        return;
      }
    } catch (_) {}

    final invoiceResult = await _invoiceService.getInvoiceByOrder(_order!.id);
    if (!mounted) return;
    if (invoiceResult['success'] != true) return;

    final invoice = invoiceResult['data'] as Invoice;
    _reviewPopupShown = true;

    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        int rating = 0;
        bool isSubmitting = false;

        return StatefulBuilder(
          builder: (context, setState) {
            Future<void> submit() async {
              if (isSubmitting) return;
              if (rating <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Veuillez choisir une note ⭐'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                isSubmitting = true;
              });

              final messenger = ScaffoldMessenger.of(this.context);
              final navigator = Navigator.of(dialogContext);

              try {
                final res = await _apiService.post(
                  ApiConfig.avis,
                  data: {
                    'commande_id': _order!.id,
                    'note': rating,
                    'commentaire': _reviewController.text.trim().isEmpty
                        ? null
                        : _reviewController.text.trim(),
                  },
                );

                if (!mounted) return;

                if (res.statusCode == 201 || res.statusCode == 200) {
                  navigator.pop();
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Merci pour votre avis !'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  final data = res.data;
                  final msg = (data is Map && data['message'] != null)
                      ? data['message'].toString()
                      : 'Erreur lors de l\'envoi de l\'avis';
                  messenger.showSnackBar(
                    SnackBar(content: Text(msg), backgroundColor: Colors.red),
                  );
                }
              } catch (e) {
                if (!mounted) return;
                messenger.showSnackBar(
                  SnackBar(
                    content: Text('Erreur: ${e.toString()}'),
                    backgroundColor: Colors.red,
                  ),
                );
              } finally {
                if (context.mounted) {
                  setState(() {
                    isSubmitting = false;
                  });
                }
              }
            }

            Widget stars() {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  final idx = i + 1;
                  final filled = idx <= rating;
                  return IconButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            setState(() {
                              rating = idx;
                            });
                          },
                    icon: Icon(
                      filled ? Icons.star : Icons.star_border,
                      color: _brandGold,
                    ),
                  );
                }),
              );
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF252525),
              title: const Text(
                'Paiement confirmé',
                style: TextStyle(color: Colors.white),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Aperçu de la facture',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Facture: ${invoice.numeroFacture}',
                            style: TextStyle(color: Colors.grey[300]),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Date: ${Formatters.formatDateTime(invoice.createdAt)}',
                            style: TextStyle(color: Colors.grey[400]),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'TOTAL',
                                style: TextStyle(color: Colors.grey[300]),
                              ),
                              Text(
                                Formatters.formatCurrency(invoice.montantTotal),
                                style: const TextStyle(
                                  color: _brandGold,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      Navigator.pop(dialogContext);
                                      _showInvoiceScreen();
                                    },
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: _brandGold),
                              ),
                              child: const Text(
                                'Voir la facture',
                                style: TextStyle(color: _brandGold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Votre avis',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    stars(),
                    TextField(
                      controller: _reviewController,
                      enabled: !isSubmitting,
                      maxLines: 3,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Commentaire (optionnel)',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Plus tard',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                ),
                ElevatedButton(
                  onPressed: isSubmitting ? null : submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brandGold,
                    foregroundColor: Colors.black,
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Text('Envoyer'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient
            AppHeader(
              title: 'Commande #${widget.orderId}',
              actions: [
                if (_order != null && _order!.statut == OrderStatus.terminee)
                  HeaderActionButton(
                    icon: Icons.receipt_long,
                    onTap: _showInvoiceScreen,
                  ),
                if (_order != null && _canAddProducts)
                  HeaderActionButton(
                    icon: Icons.add_shopping_cart,
                    onTap: _navigateToMenuToAddProducts,
                  ),
                HeaderActionButton(
                  icon: Icons.refresh,
                  onTap: _loadOrder,
                ),
              ],
            ),

            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Colors.orange),
                    )
                  : _order == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Commande non trouvée',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Impossible de charger les détails de la commande',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 24),
                          GestureDetector(
                            onTap: _loadOrder,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    offset: const Offset(0, 4),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh, color: Colors.black87),
                                  SizedBox(width: 8),
                                  Text(
                                    'Réessayer',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadOrder,
                      color: const Color(0xFFD0A030),
                      backgroundColor: Colors.white,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Statut
                            Container(
                              padding: const EdgeInsets.all(20),
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
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Statut',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        _order!.statut,
                                      ).withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: _getStatusColor(_order!.statut),
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      _order!.statut.displayName,
                                      style: TextStyle(
                                        color: _getStatusColor(_order!.statut),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Informations
                            Container(
                              padding: const EdgeInsets.all(20),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Informations',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  _buildInfoRow(
                                    Icons.table_restaurant,
                                    'Table',
                                    _order!.table != null &&
                                            _order!.table!.numero.isNotEmpty
                                        ? 'Table ${_order!.table!.numero}'
                                        : _order!.tableId > 0
                                        ? 'Table ${_order!.tableId}'
                                        : 'Table non assignée',
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 8),
                                    child: Divider(
                                      color: Colors.grey,
                                      height: 1,
                                    ),
                                  ),
                                  _buildInfoRow(
                                    Icons.calendar_today,
                                    'Date',
                                    Formatters.formatDateTime(
                                      _order!.createdAt,
                                    ),
                                  ),
                                  if (_order!.updatedAt != null) ...[
                                    const Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 8,
                                      ),
                                      child: Divider(
                                        color: Colors.grey,
                                        height: 1,
                                      ),
                                    ),
                                    _buildInfoRow(
                                      Icons.update,
                                      'Dernière mise à jour',
                                      Formatters.formatDateTime(
                                        _order!.updatedAt!,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Produits
                            Container(
                              padding: const EdgeInsets.all(20),
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Articles',
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  if (_order!.produits != null &&
                                      _order!.produits!.isNotEmpty)
                                    ..._order!.produits!.map(
                                      (item) => _buildProductItem(item),
                                    )
                                  else
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 20,
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Aucun article',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (_canAddProducts) ...[
                                    const SizedBox(height: 15),
                                    GestureDetector(
                                      onTap: _navigateToMenuToAddProducts,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: _brandGold.withValues(
                                              alpha: 0.5,
                                            ),
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.add,
                                              color: Color(0xFFD0A030),
                                              size: 20,
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Ajouter un produit',
                                              style: TextStyle(
                                                color: Color(0xFFD0A030),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Total
                            Container(
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
                              padding: const EdgeInsets.all(20),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    Formatters.formatCurrency(
                                      _order!.montantTotal,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFFD0A030),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 30),

                            // Boutons d'action
                            if ((_order!.statut == OrderStatus.attente ||
                                    _hasDraftProducts) &&
                                _order!.produits != null &&
                                _order!.produits!.isNotEmpty)
                              // Bouton "Lancer la commande" si en attente ou nouveaux produits
                              GestureDetector(
                                onTap: _launchOrder,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Colors.orange,
                                        Colors.deepOrange,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.orange.withValues(
                                          alpha: 0.4,
                                        ),
                                        offset: const Offset(4, 4),
                                        blurRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        offset: const Offset(-2, -2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.send, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Lancer la commande',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else if (_order!.statut == OrderStatus.servie ||
                                _order!.statut == OrderStatus.preparation)
                              // Bouton "Payer" si servie ou en préparation
                              GestureDetector(
                                onTap: _showPaymentScreen,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Colors.green, Color(0xFF2E7D32)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withValues(
                                          alpha: 0.4,
                                        ),
                                        offset: const Offset(4, 4),
                                        blurRadius: 8,
                                      ),
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        offset: const Offset(-2, -2),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.payment, color: Colors.white),
                                      SizedBox(width: 8),
                                      Text(
                                        'Payer',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF6EC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Icon(icon, size: 20, color: _brandGold),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductItem(OrderItem item) {
    // Couleur de bordure selon le statut
    Color borderColor = Colors.transparent;
    if (item.statut == 'brouillon') {
      borderColor = _brandGold;
    } else if (item.statut == 'envoye') {
      borderColor = Colors.green.withValues(alpha: 0.5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6EC),
        border: Border.all(
          color: borderColor,
          width: item.statut == 'brouillon' ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Stack(
        children: [
          if (item.statut == 'brouillon')
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _brandGold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Nouveau',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.image != null && item.image!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: item.image!.startsWith('http')
                            ? item.image!
                            : '${ApiConfig.serverBaseUrl}/storage/${item.image}',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFFFF0DC),
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFFD0A030),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: const Color(0xFFFFF6EC),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.restaurant_menu,
                            size: 24,
                            color: Colors.grey[600],
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: const Color(0xFFFFF6EC),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 24,
                          color: Colors.grey[600],
                        ),
                      ),
              ),
              const SizedBox(width: 15),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.produitNom,
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${Formatters.formatCurrency(item.prix)} x ${item.quantite}',
                      style: TextStyle(color: Colors.grey[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Total
              Text(
                Formatters.formatCurrency(item.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFFD0A030),
                ),
              ),
            ],
          ),
        ],
      ),
    ); // Correction: Fermeture de la Stack et du Container
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.attente:
        return Colors.orange;
      case OrderStatus.preparation:
        return Colors.blue;
      case OrderStatus.servie:
        return Colors.green;
      case OrderStatus.terminee:
        return Colors.green;
      case OrderStatus.annulee:
        return Colors.red;
    }
  }

  void _navigateToMenuToAddProducts() {
    if (_order == null) return;
    final cart = Provider.of<Cart>(context, listen: false);
    cart.clear();
    cart.setTable(_order!.tableId);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          showBackButton: true,
          targetOrderId: _order!.id,
        ),
      ),
    ).then((_) => _loadOrder());
  }

  bool get _hasDraftProducts {
    if (_order == null || _order!.produits == null) return false;
    return _order!.produits!.any((p) => p.statut == 'brouillon');
  }

  Future<void> _launchOrder() async {
    if (_order == null) return;

    // Si déjà en préparation/servie, on lance juste les nouveaux produits
    if (_order!.statut != OrderStatus.attente && !_hasDraftProducts) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun nouveau produit à lancer')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 15,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  size: 40,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Lancer la commande',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Voulez-vous lancer cette commande pour la préparation ?',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16, height: 1.5),
              ),
              const SizedBox(height: 30),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E1E1E),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.grey.shade800),
                        ),
                        child: const Center(
                          child: Text(
                            'Annuler',
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context, true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Colors.orange, Colors.deepOrange],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.withValues(alpha: 0.4),
                              offset: const Offset(0, 4),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Lancer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) =>
          const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    final result = await _orderService.launchOrder(widget.orderId);

    if (!mounted) return;
    Navigator.pop(context); // Fermer le loading

    if (result['success'] == true) {
      // Recharger la commande
      await _loadOrder();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Commande lancée avec succès !'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors du lancement'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPaymentScreen() {
    if (_order == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen(order: _order!)),
    ).then((_) {
      // Recharger la commande après paiement
      _loadOrder();
    });
  }

  void _showInvoiceScreen() {
    if (_order == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceScreen(orderId: _order!.id),
      ),
    );
  }
}

