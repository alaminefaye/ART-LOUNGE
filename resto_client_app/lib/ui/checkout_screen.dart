import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

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
      final headerNote = _notesCtrl.text.trim();
      final itemNotes = cart.items
          .where((it) => (it.note?.trim().isNotEmpty ?? false))
          .map((it) => '- ${it.product.nom} : ${it.note!.trim()}')
          .toList(growable: false);
      final combinedNotes = [
        if (headerNote.isNotEmpty) headerNote,
        if (itemNotes.isNotEmpty) 'Détails:\n${itemNotes.join('\n')}',
      ].join('\n\n');
      final created = await orderService.createEmporter(
        notes: combinedNotes,
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

        final paymentUrl = await orderService.createWaveCheckoutSession(
          paiementId: paiementId,
        );
        final uri = Uri.tryParse(paymentUrl);
        if (uri == null) {
          throw Exception('URL Wave invalide');
        }
        final opened = await launchUrl(
          uri,
          mode: LaunchMode.externalApplication,
        );
        if (!opened) {
          throw Exception('Impossible d’ouvrir Wave');
        }
        cart.clear();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Wave ouvert. Après paiement, ça se valide automatiquement. (#$commandeId)',
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

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final auth = context.watch<AuthState>();

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppTheme.bgTop, AppTheme.bgBottom],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: AppTheme.text,
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Paiement',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
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
                        color: AppTheme.accent,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notesCtrl,
                maxLines: 2,
                style: const TextStyle(color: AppTheme.text),
                decoration: const InputDecoration(
                  labelText: 'Note (optionnel)',
                  prefixIcon: Icon(Icons.edit_note, color: AppTheme.textMuted),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Moyen de paiement',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
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
                    ? 'Payer via Wave (validation automatique).'
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
                  style: const TextStyle(color: AppTheme.text),
                  decoration: const InputDecoration(
                    labelText: 'Nombre de points à utiliser',
                    prefixIcon: Icon(
                      Icons.card_giftcard,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Valider la commande',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                ),
              ),
            ],
          ),
        ),
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
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppTheme.accent
              : Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: RadioListTile<PaymentChoice>(
        value: value,
        groupValue: groupValue,
        onChanged: enabled ? onChanged : null,
        activeColor: AppTheme.accent,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
