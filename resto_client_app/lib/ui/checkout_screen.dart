import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/order_service.dart';
import '../state/auth_state.dart';
import '../state/cart_state.dart';
import '../theme/app_theme.dart';

enum PaymentChoice { later, wave, points }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _notesCtrl = TextEditingController();
  final _pointsCtrl = TextEditingController();
  PaymentChoice _choice = PaymentChoice.later;
  bool _loading = false;

  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _notesCtrl.dispose();
    _pointsCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final cart = context.read<CartState>();
    if (cart.items.isEmpty) {
      Navigator.of(context).pop();
      return;
    }

    setState(() => _loading = true);
    try {
      final orderService = context.read<OrderService>();
      final created = await orderService.createEmporter(
        notes: _notesCtrl.text,
        produits: cart.toCommandeProduitsPayload(),
      );
      final commandeId = (created['id'] as num?)?.toInt();
      if (commandeId == null) {
        throw Exception('Commande non créée');
      }

      if (_choice == PaymentChoice.later) {
        cart.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Commande #$commandeId créée. Tu paies à la récupération.',
            ),
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      if (_choice == PaymentChoice.points) {
        final points = int.tryParse(_pointsCtrl.text.trim()) ?? 0;
        final paiement = await orderService.initPaiement(
          commandeId: commandeId,
          moyenPaiement: 'points_fidelite',
          pointsUtilises: points,
        );
        cart.clear();
        await context.read<AuthState>().refreshMe();
        if (!mounted) return;
        final message = (paiement['message'] ?? '').toString();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message.isNotEmpty ? message : 'Paiement en points enregistré',
            ),
          ),
        );
        Navigator.of(context).pop();
        return;
      }

      if (_choice == PaymentChoice.wave) {
        final paiement = await orderService.initPaiement(
          commandeId: commandeId,
          moyenPaiement: 'wave',
        );
        final paiementId = (paiement['id'] as num?)?.toInt();
        if (paiementId == null) {
          throw Exception('Paiement non initialisé');
        }

        final transactionId = await _askTransactionId(context);
        if (transactionId == null || transactionId.trim().isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction ID requis pour confirmer Wave'),
            ),
          );
          return;
        }

        await orderService.confirmerPaiementWave(
          paiementId: paiementId,
          transactionId: transactionId.trim(),
        );
        cart.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Paiement Wave confirmé. En attente de validation. (#$commandeId)',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<String?> _askTransactionId(BuildContext context) async {
    final ctrl = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Transaction ID Wave'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(labelText: 'ID de transaction'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(ctrl.text),
              child: const Text('Confirmer'),
            ),
          ],
        );
      },
    );
    ctrl.dispose();
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final auth = context.watch<AuthState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Paiement')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                Text(
                  _money.format(cart.total),
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.brandGold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optionnel)',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Moyen de paiement',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          _ChoiceTile(
            title: 'Payer à la récupération',
            subtitle:
                'Tu commandes maintenant, tu paies quand tu viens récupérer.',
            value: PaymentChoice.later,
            groupValue: _choice,
            onChanged: _loading
                ? null
                : (v) {
                    if (v != null) setState(() => _choice = v);
                  },
          ),
          _ChoiceTile(
            title: 'Wave',
            subtitle: auth.waveEnabled
                ? 'Payer via Wave (validation par le gérant).'
                : 'Wave est désactivé.',
            value: PaymentChoice.wave,
            groupValue: _choice,
            enabled: auth.waveEnabled,
            onChanged: _loading || !auth.waveEnabled
                ? null
                : (v) {
                    if (v != null) setState(() => _choice = v);
                  },
          ),
          _ChoiceTile(
            title: 'Points fidélité',
            subtitle: auth.fidelityEnabled
                ? 'Solde: ${auth.pointsFidelite} points (1 point = ${auth.valeurFcfa1Point.toStringAsFixed(0)} FCFA)'
                : 'Fidélité désactivée.',
            value: PaymentChoice.points,
            groupValue: _choice,
            enabled: auth.fidelityEnabled,
            onChanged: _loading || !auth.fidelityEnabled
                ? null
                : (v) {
                    if (v != null) setState(() => _choice = v);
                  },
          ),
          if (_choice == PaymentChoice.points) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _pointsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nombre de points à utiliser',
                prefixIcon: Icon(Icons.card_giftcard),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Valider la commande'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    this.enabled = true,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final PaymentChoice value;
  final PaymentChoice groupValue;
  final bool enabled;
  final ValueChanged<PaymentChoice?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? AppTheme.brandGold : Colors.black12,
        ),
      ),
      child: RadioListTile<PaymentChoice>(
        value: value,
        groupValue: groupValue,
        onChanged: enabled ? onChanged : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
      ),
    );
  }
}
