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
  final _seatCtrl = TextEditingController();
  PaymentChoice _choice = PaymentChoice.later;
  bool _loading = false;
  bool _isPassager = false;
  bool _trajetsLoading = false;
  List<Map<String, dynamic>> _trajets = const [];
  int? _trajetId;

  final _money = NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'FCFA',
    decimalDigits: 0,
  );

  @override
  void dispose() {
    _notesCtrl.dispose();
    _pointsCtrl.dispose();
    _seatCtrl.dispose();
    super.dispose();
  }

  String _trajetLabel(Map<String, dynamic> t) {
    final depart = (t['depart'] ?? '').toString();
    final destination = (t['destination'] ?? '').toString();
    final heure = (t['heure_depart'] ?? '').toString();
    final hhmm = heure.length >= 5 ? heure.substring(0, 5) : heure;
    final a = depart.trim().isEmpty ? 'Départ' : depart.trim();
    final b = destination.trim().isEmpty ? 'Destination' : destination.trim();
    return '$a → $b • $hhmm';
  }

  Future<void> _loadTrajets() async {
    if (_trajetsLoading) return;
    setState(() => _trajetsLoading = true);
    try {
      final service = context.read<OrderService>();
      final list = await service.fetchTrajets();
      if (!mounted) return;
      setState(() {
        _trajets = list;
        if (_trajetId != null &&
            !_trajets.any((t) => (t['id'] as num?)?.toInt() == _trajetId)) {
          _trajetId = null;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _trajets = const []);
    } finally {
      if (mounted) setState(() => _trajetsLoading = false);
    }
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

      if (_isPassager) {
        final seat = _seatCtrl.text.trim();
        if (_trajetId == null) {
          throw Exception('Choisis ton trajet');
        }
        if (seat.isEmpty) {
          throw Exception('Indique ton numéro de siège');
        }
      }

      final created = await orderService.createEmporter(
        notes: combinedNotes,
        produits: cart.toCommandeProduitsPayload(),
        isPassager: _isPassager,
        trajetId: _isPassager ? _trajetId : null,
        numeroSiege: _isPassager ? _seatCtrl.text.trim() : null,
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.10),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Êtes-vous passager ?',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Si oui, indique ton trajet pour anticiper la commande.',
                                style: TextStyle(
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isPassager,
                          onChanged: _loading
                              ? null
                              : (v) {
                                  setState(() => _isPassager = v);
                                  if (v) _loadTrajets();
                                },
                          activeColor: AppTheme.accent,
                        ),
                      ],
                    ),
                    if (_isPassager) ...[
                      const SizedBox(height: 10),
                      DropdownButtonFormField<int>(
                        value: _trajetId,
                        items: _trajets
                            .map(
                              (t) => DropdownMenuItem<int>(
                                value: (t['id'] as num?)?.toInt(),
                                child: Text(_trajetLabel(t)),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: _loading
                            ? null
                            : (v) => setState(() => _trajetId = v),
                        decoration: InputDecoration(
                          labelText: 'Trajet',
                          prefixIcon: _trajetsLoading
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppTheme.accent,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.route_rounded,
                                  color: AppTheme.textMuted,
                                ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _seatCtrl,
                        enabled: !_loading,
                        keyboardType: TextInputType.text,
                        style: const TextStyle(color: AppTheme.text),
                        decoration: const InputDecoration(
                          labelText: 'Numéro de siège',
                          prefixIcon: Icon(
                            Icons.event_seat_rounded,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
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
                title: '',
                subtitle: auth.waveEnabled
                    ? 'Payer via Wave (validation automatique).'
                    : 'Wave est désactivé.',
                value: PaymentChoice.wave,
                groupValue: _choice,
                leading: Image.asset('logowave.png', fit: BoxFit.contain),
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
    this.leading,
    this.enabled = true,
    required this.onChanged,
  });

  static const double _leadingSize = 56;

  final String title;
  final String subtitle;
  final PaymentChoice value;
  final PaymentChoice groupValue;
  final Widget? leading;
  final bool enabled;
  final ValueChanged<PaymentChoice?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    final hasTitle = title.trim().isNotEmpty;
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
        title: Row(
          children: [
            if (leading != null) ...[
              SizedBox.square(dimension: _leadingSize, child: leading),
              if (hasTitle) const SizedBox(width: 10),
            ],
            if (hasTitle)
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
          ],
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppTheme.textMuted),
        ),
      ),
    );
  }
}
