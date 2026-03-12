import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order.dart';
import '../../models/payment.dart';
import '../../services/payment_service.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_header.dart';

class PaymentScreen extends StatefulWidget {
  final Order order;

  const PaymentScreen({super.key, required this.order});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final PaymentService _paymentService = PaymentService();
  PaymentMethod? _selectedPaymentMethod;
  final TextEditingController _transactionIdController =
      TextEditingController();
  final TextEditingController _amountReceivedController =
      TextEditingController();
  final TextEditingController _pointsToUseController = TextEditingController();
  bool _isProcessing = false;
  bool _isClient = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();
    _amountReceivedController.text = widget.order.montantTotal.toStringAsFixed(0);
    _pointsToUseController.text = '0';
    if (_isClient) _selectedPaymentMethod = PaymentMethod.especes;
  }

  String _generateTransactionId() {
    // Génère un ID unique: TX-COMMANDE_ID-TIMESTAMP
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'TX-${widget.order.id}-$timestamp';
  }

  void _checkUserRole() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      _isClient = user.roles.contains('client');
    }
  }

  @override
  void dispose() {
    _transactionIdController.dispose();
    _amountReceivedController.dispose();
    _pointsToUseController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (_selectedPaymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un mode de paiement'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    // Client : paiement en points de fidélité
    if (_isClient && _selectedPaymentMethod == PaymentMethod.pointsFidelite) {
      final user = Provider.of<AuthService>(context, listen: false).currentUser;
      if (user == null || user.pointsFidelite <= 0) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Vous n\'avez pas de points de fidélité.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final points = int.tryParse(_pointsToUseController.text.trim()) ?? 0;
      if (points <= 0) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Indiquez le nombre de points à utiliser.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (points > user.pointsFidelite) {
        setState(() => _isProcessing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Vous avez ${user.pointsFidelite} points.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      final result = await _paymentService.payWithPoints(
        commandeId: widget.order.id,
        pointsUtilises: points,
      );
      setState(() => _isProcessing = false);
      if (!mounted) return;
      if (result['success'] == true) {
        final reste = result['reste_a_payer'] as double?;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              reste != null && reste > 0
                  ? 'Points utilisés. Il reste ${Formatters.formatCurrency(reste)} à régler (espèces au serveur).'
                  : 'Paiement en points enregistré !',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Client : uniquement espèces (remettre au serveur, enregistré à la caisse)
    if (_isClient && _selectedPaymentMethod == PaymentMethod.especes) {
      setState(() {
        _isProcessing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Remettez le montant au serveur. Le paiement sera enregistré à la caisse.',
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true);
      }
      return;
    }

    // Pour espèces (personnel uniquement), utiliser payerEspeces
    if (_selectedPaymentMethod == PaymentMethod.especes && !_isClient) {
      final montantRecu =
          double.tryParse(_amountReceivedController.text) ?? 0.0;
      if (montantRecu < widget.order.montantTotal) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Le montant reçu (${Formatters.formatCurrency(montantRecu)}) est inférieur au montant total (${Formatters.formatCurrency(widget.order.montantTotal)})',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final result = await _paymentService.payCash(
        commandeId: widget.order.id,
        montantRecu: montantRecu,
      );

      setState(() {
        _isProcessing = false;
      });

      if (result['success'] == true && mounted) {
        final monnaieRendue = result['monnaie_rendue'] as double? ?? 0.0;
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paiement espèces effectué ! Monnaie rendue: ${Formatters.formatCurrency(monnaieRendue)}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors du paiement'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Pour Wave et Orange Money
    if (_selectedPaymentMethod == PaymentMethod.wave ||
        _selectedPaymentMethod == PaymentMethod.orangeMoney) {
      // Vérifier que transaction_id est fourni
      if (_transactionIdController.text.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez saisir le numéro de transaction'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Initier le paiement
      final result = await _paymentService.initiatePayment(
        commandeId: widget.order.id,
        moyenPaiement: _selectedPaymentMethod!,
        transactionId: _transactionIdController.text.trim(),
      );

      if (result['success'] == true && mounted) {
        final payment = result['data'] as Payment;

        // Si c'est le client, confirmer immédiatement
        if (_isClient) {
          final confirmResult = await _paymentService.confirmPayment(
            paymentId: payment.id,
            transactionId: _transactionIdController.text.trim(),
          );

          setState(() {
            _isProcessing = false;
          });

          if (confirmResult['success'] == true && mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Paiement confirmé ! En attente de validation par le gérant.',
                ),
                backgroundColor: Colors.green,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  confirmResult['message'] ?? 'Erreur lors de la confirmation',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        } else {
          // Gérant : valider directement
          final validateResult = await _paymentService.validatePayment(
            payment.id,
          );

          setState(() {
            _isProcessing = false;
          });

          if (validateResult['success'] == true && mounted) {
            Navigator.pop(context, true);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Paiement validé avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          } else if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  validateResult['message'] ?? 'Erreur lors de la validation',
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        setState(() {
          _isProcessing = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result['message'] ?? 'Erreur lors de l\'initiation du paiement',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      return;
    }

    setState(() {
      _isProcessing = false;
    });
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
              title: 'Paiement',
              subtitle: 'Commande #${widget.order.id}',
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Montant à payer
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFD0A030), Color(0xFFB07018)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFD0A030).withValues(alpha: 0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Montant à payer:',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            Formatters.formatCurrency(
                              widget.order.montantTotal,
                            ),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Sélection du mode de paiement
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        'Mode de paiement',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Options de paiement : client = espèces + points si dispo + Wave/OM si activés ; personnel = tous
                    if (_isClient) ...[
                      if (Provider.of<AuthService>(context).currentUser?.hasFidelity == true)
                        _buildPaymentMethodOption(
                          PaymentMethod.pointsFidelite,
                          'Points de fidélité',
                          'Utiliser vos points pour réduire ou régler la facture',
                          Icons.stars,
                        ),
                      _buildPaymentMethodOption(
                        PaymentMethod.especes,
                        'Espèces',
                        'Remettez le montant au serveur',
                        Icons.money,
                      ),
                      if (Provider.of<AuthService>(context).currentUser?.waveEnabled == true)
                        _buildPaymentMethodOption(
                          PaymentMethod.wave,
                          'Wave',
                          'Paiement mobile via Wave',
                          Icons.phone_android,
                        ),
                      if (Provider.of<AuthService>(context).currentUser?.orangeMoneyEnabled == true)
                        _buildPaymentMethodOption(
                          PaymentMethod.orangeMoney,
                          'Orange Money',
                          'Paiement mobile via Orange Money',
                          Icons.phone_android,
                        ),
                    ] else ...[
                      _buildPaymentMethodOption(
                        PaymentMethod.wave,
                        'Wave',
                        'Paiement mobile via Wave',
                        Icons.phone_android,
                      ),
                      _buildPaymentMethodOption(
                        PaymentMethod.orangeMoney,
                        'Orange Money',
                        'Paiement mobile via Orange Money',
                        Icons.phone_android,
                      ),
                      _buildPaymentMethodOption(
                        PaymentMethod.especes,
                        'Espèces',
                        'Paiement en espèces',
                        Icons.money,
                      ),
                    ],

                    // Champs pour paiement en points (client)
                    if (_isClient &&
                        _selectedPaymentMethod == PaymentMethod.pointsFidelite) ...[
                      Builder(
                        builder: (context) {
                          final user = Provider.of<AuthService>(context).currentUser;
                          if (user == null || user.pointsFidelite <= 0) return const SizedBox.shrink();
                          final valeurFcfa = user.valeurFcfa1Point ?? 100.0;
                          final pts = int.tryParse(_pointsToUseController.text.trim()) ?? 0;
                          final reduction = (pts * valeurFcfa).clamp(0.0, widget.order.montantTotal);
                          final maxPoints = (widget.order.montantTotal / valeurFcfa).ceil().clamp(0, user.pointsFidelite);
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTextField(
                                controller: _pointsToUseController,
                                label: 'Points à utiliser (max $maxPoints)',
                                hint: '0',
                                icon: Icons.stars,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD0A030).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFD0A030).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.info_outline, color: Color(0xFFD0A030), size: 20),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'Équivalent: ${Formatters.formatCurrency(reduction)} de réduction. 1 point = ${valeurFcfa.toStringAsFixed(0)} FCFA',
                                        style: const TextStyle(fontSize: 13, color: Colors.black87),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],
                          );
                        },
                      ),
                    ],

                    const SizedBox(height: 30),

                    // Champs conditionnels pour Wave/OM (personnel + client)
                    if (_selectedPaymentMethod == PaymentMethod.wave ||
                        _selectedPaymentMethod == PaymentMethod.orangeMoney) ...[
                      _buildTextField(
                        controller: _transactionIdController,
                        label: _isClient ? 'Numéro de transaction (après paiement)' : 'Numéro de transaction',
                        hint: _isClient ? 'Ex: 12345678' : 'Généré automatiquement',
                        icon: Icons.receipt,
                        readOnly: !_isClient,
                        onChanged: _isClient ? (_) => setState(() {}) : null,
                      ),
                      if (_isClient)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Après avoir payé via ${_selectedPaymentMethod == PaymentMethod.wave ? 'Wave' : 'Orange Money'}, saisissez le numéro de transaction reçu.',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      const SizedBox(height: 20),
                    ],

                    if (_selectedPaymentMethod == PaymentMethod.especes &&
                        !_isClient) ...[
                      _buildTextField(
                        controller: _amountReceivedController,
                        label: 'Montant reçu',
                        hint: 'Montant reçu du client',
                        icon: Icons.money,
                        keyboardType: TextInputType.number,
                        suffixText: 'FCFA',
                        onChanged: (value) {
                          setState(() {});
                        },
                      ),
                      const SizedBox(height: 20),
                      if (_amountReceivedController.text.isNotEmpty)
                        Builder(
                          builder: (context) {
                            final montantRecu =
                                double.tryParse(
                                  _amountReceivedController.text,
                                ) ??
                                0.0;
                            final difference =
                                montantRecu - widget.order.montantTotal;
                            final isEnough = difference >= 0;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isEnough
                                    ? Colors.green.withValues(alpha: 0.08)
                                    : Colors.red.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isEnough ? Colors.green : Colors.red,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isEnough ? Icons.check_circle : Icons.error,
                                    color: isEnough ? Colors.green : Colors.red,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      isEnough
                                          ? 'Monnaie à rendre: ${Formatters.formatCurrency(difference)}'
                                          : 'Montant insuffisant: ${Formatters.formatCurrency(-difference)}',
                                      style: TextStyle(
                                        color: isEnough
                                            ? Colors.green
                                            : Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],

                    const SizedBox(height: 40),

                    // Bouton de paiement
                    GestureDetector(
                      onTap: _isProcessing || _selectedPaymentMethod == null
                          ? null
                          : _initiatePayment,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                _isProcessing || _selectedPaymentMethod == null
                                ? [Colors.grey[300]!, Colors.grey[400]!]
                                : [const Color(0xFFD0A030), const Color(0xFFB07018)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            if (!(_isProcessing || _selectedPaymentMethod == null))
                              BoxShadow(
                                color: const Color(0xFFD0A030).withValues(alpha: 0.4),
                                offset: const Offset(0, 4),
                                blurRadius: 10,
                              ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: _isProcessing
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : Text(
                                _isClient
                                    ? 'Payer'
                                    : _selectedPaymentMethod == PaymentMethod.especes
                                        ? 'Encaisser'
                                        : 'Procéder au paiement',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption(
    PaymentMethod method,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = _selectedPaymentMethod == method;
    // Client : espèces + points de fidélité (si dispo). Personnel : toutes options.
    final isDisabled = _isClient &&
        method != PaymentMethod.especes &&
        method != PaymentMethod.pointsFidelite;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isSelected
            ? Border.all(color: const Color(0xFFD0A030), width: 2)
            : Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? const Color(0xFFD0A030).withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabled
              ? null
              : () {
                  setState(() {
                    _selectedPaymentMethod = method;
                    if (method != PaymentMethod.especes) {
                      _amountReceivedController.clear();
                      if (_transactionIdController.text.isEmpty) {
                        _transactionIdController.text =
                            _generateTransactionId();
                      }
                    } else {
                      _amountReceivedController.text = widget.order.montantTotal
                          .toStringAsFixed(0);
                      _transactionIdController.clear();
                    }
                  });
                },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFFD0A030).withValues(alpha: 0.12)
                        : const Color(0xFFFFF0DC),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? const Color(0xFFD0A030)
                        : Colors.grey[500],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDisabled
                              ? Colors.grey[400]
                              : (isSelected
                                  ? const Color(0xFFD0A030)
                                  : Colors.black87),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD0A030),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: readOnly
              ? Colors.grey[200]!
              : const Color(0xFFD0A030).withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onChanged: onChanged,
        readOnly: readOnly,
        style: TextStyle(
          color: readOnly ? Colors.grey[500] : Colors.black87,
          fontWeight: readOnly ? FontWeight.w500 : FontWeight.normal,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[600]),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: Icon(
            icon,
            color: readOnly ? Colors.grey[400] : const Color(0xFFD0A030),
          ),
          suffixText: suffixText,
          suffixStyle: const TextStyle(color: Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
