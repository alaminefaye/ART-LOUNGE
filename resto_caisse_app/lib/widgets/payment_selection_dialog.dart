import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/cart.dart';
import '../models/payment.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../services/payment_service.dart';
import '../services/printer_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../services/auth_service.dart';
import '../services/client_service.dart';
import '../models/client_fid.dart';
import 'serveur_selection_dialog.dart';

class PaymentSelectionDialog extends StatefulWidget {
  final Cart? cart;
  final Order? existingOrder;

  const PaymentSelectionDialog({
    super.key, 
    this.cart,
    this.existingOrder,
  }) : assert(cart != null || existingOrder != null, 'Must provide either cart or existingOrder');

  @override
  State<PaymentSelectionDialog> createState() => _PaymentSelectionDialogState();
}

class _PaymentSelectionDialogState extends State<PaymentSelectionDialog> {
  final OrderService _orderService = OrderService();
  final PaymentService _paymentService = PaymentService();
  final PrinterService _printerService = PrinterService();
  final ClientService _clientService = ClientService();
  
  final TextEditingController _phoneController = TextEditingController();
  ClientFid? _foundClient;
  int _pointsToUse = 0;
  bool _isSearching = false;
  
  PaymentMethod _selectedMethod = PaymentMethod.especes;
  final TextEditingController _cashReceivedController = TextEditingController();
  double _change = 0;
  bool _isLoading = false;

  double get _baseTotal => widget.existingOrder?.montantTotal ?? widget.cart!.total;
  double get _discountValue => _foundClient != null ? (_pointsToUse * _foundClient!.valeurFcfa1Point) : 0;
  double get _totalToPay => _baseTotal - _discountValue;

  void _calculateChange(String value) {
    if (_selectedMethod != PaymentMethod.especes) return;
    final received = double.tryParse(value) ?? 0;
    setState(() {
      _change = received - _totalToPay;
    });
  }

  Future<void> _searchClient() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) return;
    
    setState(() => _isSearching = true);
    final res = await _clientService.searchByPhone(phone);
    setState(() {
      _isSearching = false;
        if (res['success']) {
          _foundClient = res['client'] as ClientFid;
          // NE PAS auto-appliquer, laisser à 0 par défaut pour éviter le "gratuit" par erreur
          _pointsToUse = 0;
          _calculateChange(_cashReceivedController.text);
        } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'])));
        _foundClient = null;
      }
    });
  }

  Future<void> _processPayment() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    // Avertissement si un numéro est saisi mais pas recherché
    if (_foundClient == null && _phoneController.text.isNotEmpty) {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Client non identifié'),
          content: const Text('Vous avez saisi un numéro mais n\'avez pas cliqué sur l\'icône de recherche. Voulez-vous continuer sans points de fidélité ?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Continuer sans points')),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isLoading = true);
    
    try {
      Order? order;
      
      // 1. Get or Create the order
      if (widget.existingOrder != null) {
        order = widget.existingOrder;
      } else {
        int? serveurSelection = widget.cart!.serveurId;
        if (serveurSelection == null) {
           setState(() => _isLoading = false);
           if (!mounted) return;
           serveurSelection = await showDialog<int>(
             context: context,
             barrierDismissible: true,
             builder: (ctx) => const ServeurSelectionDialog(),
           );
           if (serveurSelection == null) {
             return; // L'utilisateur a annulé
           }
           setState(() => _isLoading = true);
        }

        final orderRes = await _orderService.createOrder(
          tableId: widget.cart!.tableId ?? 0,
          serveurId: serveurSelection,
          produits: widget.cart!.toJson(),
        );
        if (orderRes['success'] && orderRes['order'] != null) {
          order = orderRes['order'];
        } else {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(orderRes['message'] ?? 'Erreur lors de la création de commande'), backgroundColor: Colors.red),
            );
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      if (order != null) {
        // 2. Process Payment
        bool paymentSuccess = false;
        String? errorMsg;

        if (_selectedMethod == PaymentMethod.especes) {
          final res = await _paymentService.payCash(
            commandeId: order.id,
            montantRecu: double.tryParse(_cashReceivedController.text) ?? _totalToPay,
            clientId: _foundClient?.id,
            pointsUtilises: _pointsToUse > 0 ? _pointsToUse : null,
          );
          paymentSuccess = res['success'];
          errorMsg = res['message'];
        } else if (_selectedMethod == PaymentMethod.pointsFidelite) {
           final user = authService.currentUser;
           if (user != null && user.hasFidelity) {
             final pointsNeeded = (_baseTotal / (user.valeurFcfa1Point ?? 1)).ceil();
             final res = await _paymentService.payWithPoints(
               commandeId: order.id,
               pointsUtilises: pointsNeeded,
             );
             paymentSuccess = res['success'];
             errorMsg = res['message'];
           } else {
             errorMsg = "Le client n'a pas assez de points.";
           }
        } else {
          final res = await _paymentService.initiatePayment(
            commandeId: order.id,
            moyenPaiement: _selectedMethod,
            pointsUtilises: _pointsToUse > 0 ? _pointsToUse : null,
            clientId: _foundClient?.id,
          );
          paymentSuccess = res['success'];
          errorMsg = res['message'];
        }

        if (paymentSuccess) {
          // Capture le nom du caissier avant tout appel async
          final cashierName = mounted ? Provider.of<AuthService>(context, listen: false).currentUser?.name : null;
          // 3. Print the receipt (invoice)
          await _printerService.printOrderReceipt(order, cashierName: cashierName);
          // 4. Print the kitchen ticket (only if new order, usually)
          if (widget.cart != null) {
            await _printerService.printKitchenTicket(order);
          }
          
          if (mounted) Navigator.pop(context, true);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(errorMsg ?? 'Erreur lors du paiement'), backgroundColor: Colors.red),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur inattendue: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500),
              padding: EdgeInsets.all(isNarrow ? 16 : 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.existingOrder != null ? 'Encaisser Commande #${widget.existingOrder!.id}' : 'Finaliser le paiement',
                    style: TextStyle(fontSize: isNarrow ? 20 : 24, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    Formatters.formatCurrency(_totalToPay),
                    style: TextStyle(fontSize: isNarrow ? 28 : 36, fontWeight: FontWeight.w900, color: AppTheme.brandGold),
                    textAlign: TextAlign.center,
                  ),
                  if (_discountValue > 0)
                    Text(
                      'Réduction fidélité: -${Formatters.formatCurrency(_discountValue)}',
                      style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 16),

                  // Section Identification Client / Fidélité
                  _buildLoyaltySection(),
                  
                  const SizedBox(height: 24),
                  
                  const Text('Mode de paiement', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 16),
                  
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: isNarrow ? 2.0 : 2.5,
                    children: PaymentMethod.values
                        .where((m) => m != PaymentMethod.pointsFidelite)
                        .map((method) {
                      final isSelected = _selectedMethod == method;
                      return InkWell(
                        onTap: () => setState(() => _selectedMethod = method),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.brandGold : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSelected ? AppTheme.brandGold : Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(method.emoji, style: const TextStyle(fontSize: 20)),
                              const SizedBox(width: 8),
                              Text(
                                method.displayName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : Colors.black87,
                                  fontSize: isNarrow ? 12 : 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  
                  if (_selectedMethod == PaymentMethod.especes) ...[
                    const SizedBox(height: 24),
                    TextField(
                      controller: _cashReceivedController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: _calculateChange,
                      decoration: InputDecoration(
                        labelText: 'Montant reçu',
                        hintText: 'Ex: 10000',
                        prefixIcon: const Icon(Icons.money),
                        suffixText: 'FCFA',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _change >= 0 ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Monnaie à rendre :', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(
                            Formatters.formatCurrency(_change > 0 ? _change : 0),
                            style: TextStyle(
                              fontSize: 20, 
                              fontWeight: FontWeight.bold,
                              color: _change >= 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  
                  ElevatedButton(
                    onPressed: _isLoading ? null : _processPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.brandGold,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CONFIRMER ET IMPRIMER', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoyaltySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.card_membership, color: AppTheme.brandGold, size: 20),
              SizedBox(width: 8),
              Text('Client & Fidélité', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          if (_foundClient == null)
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: 'Téléphone (ex: 77... )',
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isSearching ? null : _searchClient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 36),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSearching 
                    ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search, color: Colors.white, size: 20),
                ),
              ],
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_foundClient!.nomComplet, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandGold)),
                    Text(
                      '1 pt = ${Formatters.formatCurrency(_foundClient!.valeurFcfa1Point)}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                    ),
                    InkWell(
                      onTap: () => setState(() { _foundClient = null; _pointsToUse = 0; _calculateChange(_cashReceivedController.text); }),
                      child: const Icon(Icons.close, size: 18, color: Colors.red),
                    ),
                  ],
                ),
                Text('Points disponibles : ${_foundClient!.pointsFidelite}', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                const SizedBox(height: 8),
                if (_foundClient!.pointsFidelite > 0) ...[
                  Row(
                    children: [
                      const Text('Utiliser : ', style: TextStyle(fontSize: 13)),
                      const Spacer(),
                      IconButton(
                        onPressed: _pointsToUse > 0 ? () => setState(() { _pointsToUse -= 10; if (_pointsToUse < 0) _pointsToUse = 0; _calculateChange(_cashReceivedController.text); }) : null,
                        icon: const Icon(Icons.remove_circle_outline, size: 18),
                      ),
                      Text('$_pointsToUse', style: const TextStyle(fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: _pointsToUse < _foundClient!.pointsFidelite ? () {
                          setState(() {
                            // Ne pas dépasser le montant total
                            final potentialTotal = (_pointsToUse + 10) * _foundClient!.valeurFcfa1Point;
                            if (potentialTotal <= _baseTotal) {
                              _pointsToUse += 10;
                            } else {
                              _pointsToUse = (_baseTotal / _foundClient!.valeurFcfa1Point).floor();
                            }
                            if (_pointsToUse > _foundClient!.pointsFidelite) _pointsToUse = _foundClient!.pointsFidelite;
                            _calculateChange(_cashReceivedController.text);
                          });
                        } : null,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _pointsToUse = (_baseTotal / _foundClient!.valeurFcfa1Point).floor();
                            if (_pointsToUse > _foundClient!.pointsFidelite) _pointsToUse = _foundClient!.pointsFidelite;
                            _calculateChange(_cashReceivedController.text);
                          });
                        },
                        child: const Text('MAX', style: TextStyle(fontSize: 12, color: AppTheme.brandGold)),
                      ),
                    ],
                  ),
                ] else
                  const Text('Aucun point à utiliser.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
              ],
            ),
        ],
      ),
    );
  }
}
