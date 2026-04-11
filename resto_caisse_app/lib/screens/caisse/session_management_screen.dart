import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../models/caisse_session.dart';
import '../../services/caisse_service.dart';
import '../../services/auth_service.dart';
import '../../services/printer_service.dart';
import '../../utils/formatters.dart';

class SessionManagementScreen extends StatefulWidget {
  final VoidCallback? onSessionOpened;
  const SessionManagementScreen({super.key, this.onSessionOpened});

  @override
  State<SessionManagementScreen> createState() => _SessionManagementScreenState();
}

class _SessionManagementScreenState extends State<SessionManagementScreen> {
  final CaisseService _caisseService = CaisseService();
  bool _isLoading = true;
  CaisseSession? _currentSession;
  Map<String, dynamic>? _bilan;

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _transactionFilter = 'toutes';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final session = await _caisseService.getCurrentSession();
    if (session != null) {
      final bilanRes = await _caisseService.getBilan();
      if (bilanRes['success']) {
        _bilan = bilanRes['data'];
      }
    }
    setState(() {
      _currentSession = session;
      _isLoading = false;
    });
  }

  Future<void> _handleOpenSession() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le solde d\'ouverture')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Montant invalide')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final res = await _caisseService.openSession(amount);
    if (res['success']) {
      _amountController.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session ouverte avec succès')),
      );
      // Rafraîchir les données pour passer à la vue active et désactiver le loading
      await _loadData();
      if (widget.onSessionOpened != null) {
        widget.onSessionOpened!();
      }
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Erreur lors de l\'ouverture')),
      );
    }
  }

  Future<void> _handleCloseSession() async {
    final amountText = _amountController.text.trim();
    if (amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez entrer le montant réel en caisse')),
      );
      return;
    }

    final amount = double.tryParse(amountText);
    if (amount == null) return;

    setState(() => _isLoading = true);
    final res = await _caisseService.closeSession(
      amount,
      notes: _notesController.text.trim(),
    );

    if (res['success']) {
      _amountController.clear();
      _notesController.clear();
      if (!mounted) return;

      // Récupérer le bilan le plus récent (avant deconnexion)
      final bilanRes = await _caisseService.getBilan();
      final bilan = bilanRes['success'] ? (bilanRes['data'] as Map<String, dynamic>? ?? {}) : (_bilan ?? {});

      // Récupérer le nom du caissier
      final authService = Provider.of<AuthService>(context, listen: false);
      final cashierName = authService.currentUser?.name ?? 'Caissier';
      final openedAt = _currentSession?.openedAt ?? DateTime.now();

      // Imprimer le rapport de clôture (ne pas bloquer si erreur)
      try {
        await PrinterService().printClosingReport(
          bilan: bilan,
          cashierName: cashierName,
          openedAt: openedAt,
        );
      } catch (_) {}

      // Déconnexion immédiate → retour écran login
      if (mounted) {
        await authService.logout();
      }
    } else {
      setState(() => _isLoading = false);
      if (!mounted) return;

      // Si des commandes actives bloquent la fermeture → dialog explicite
      final int commandesActives = res['commandes_actives'] ?? 0;
      if (commandesActives > 0) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: EdgeInsets.zero,
            title: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.redAccent,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Fermeture impossible',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  '$commandesActives commande(s) ne sont pas encore payée(s).',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Réglez toutes les commandes en cours avant de fermer la caisse.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('COMPRIS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message'] ?? 'Erreur lors de la fermeture'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      appBar: AppBar(
        title: const Text(
          'GESTION DE CAISSE',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: 1.2),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: _currentSession == null ? _buildOpenView() : _buildActiveView(),
              ),
            ),
    );
  }

  Widget _buildOpenView() {
    return Column(
      children: [
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.no_accounts_outlined, size: 48, color: Colors.orange),
              ),
              const SizedBox(height: 24),
              const Text(
                'AUCUNE SESSION OUVERTE',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: 0.5),
              ),
              const SizedBox(height: 8),
              Text(
                'Vous devez ouvrir une session de caisse pour commencer à encaisser des paiements.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], height: 1.5),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Solde d\'ouverture (fond de caisse)',
                  hintText: 'Ex: 10000',
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  suffixText: 'FCFA',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _handleOpenSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('OUVRIR LA SESSION', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () async {
                  await Provider.of<AuthService>(context, listen: false).logout();
                  if (mounted && Navigator.canPop(context)) {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  }
                },
                icon: const Icon(Icons.logout, color: Colors.grey),
                label: const Text(
                  'SE DÉCONNECTER',
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveView() {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final double soldeOuverture = _currentSession?.soldeOuverture ?? 0.0;
    final double totalVentes = parseDouble(_bilan?['total_ventes']);
    final double totalAttendu = parseDouble(_bilan?['total_attendu_caisse']);
    final List repartition = _bilan?['repartition'] ?? [];
    final List transactions = _bilan?['transactions'] ?? [];
    
    final filteredTransactions = _transactionFilter == 'toutes' 
        ? transactions 
        : transactions.where((t) => t['moyen_paiement'].toString().toLowerCase() == _transactionFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Badge Statut
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text(
                'SESSION ACTIVE',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Ouverte le ${DateFormat('dd/MM à HH:mm').format(_currentSession!.openedAt)}',
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        const SizedBox(height: 24),

        // Résumé financier
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2D2D2D),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: Column(
            children: [
              const Text(
                'TOTAL LIQUIDITÉS ATTENDU',
                style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
              const SizedBox(height: 12),
              Text(
                Formatters.formatCurrency(totalAttendu),
                style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
              const SizedBox(height: 20),
              Container(height: 1, color: Colors.white10),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMiniStat('Ouverture', Formatters.formatCurrency(soldeOuverture)),
                  Container(width: 1, height: 30, color: Colors.white10),
                  _buildMiniStat('Recettes Shift', Formatters.formatCurrency(parseDouble(_bilan?['total_liquide']))),
                  Container(width: 1, height: 30, color: Colors.white10),
                  _buildMiniStat('Paiement Points', Formatters.formatCurrency(parseDouble(_bilan?['total_points_fidelite_montant']))),
                  Container(width: 1, height: 30, color: Colors.white10),
                  _buildMiniStat('Total Ventes', Formatters.formatCurrency(totalVentes)),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),
        const Text(
          'DÉTAIL PAR MODE DE PAIEMENT',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),

        // Liste des moyens de paiement
        ...repartition.map((item) {
          final String label = item['moyen_paiement'];
          final double total = parseDouble(item['total']);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getIconForMethod(label), color: Colors.grey[700], size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label.toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ),
                Text(
                  Formatters.formatCurrency(total),
                  style: const TextStyle(fontWeight: FontWeight.w800, color: Colors.orange),
                ),
              ],
            ),
          );
        }),

        if (transactions.isNotEmpty) ...[
          const SizedBox(height: 32),
          const Text(
            'HISTORIQUE DES TRANSACTIONS',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('Toutes', 'toutes'),
                ...repartition.map((item) => _buildFilterChip(item['moyen_paiement'].toString().toUpperCase(), item['moyen_paiement'].toString().toLowerCase())),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (filteredTransactions.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Text("Aucune transaction pour ce moyen de paiement.", style: TextStyle(color: Colors.grey)),
            ))
          else ...[
            ...filteredTransactions.take(5).map((t) => _buildTransactionItem(t)),
            if (filteredTransactions.length > 5)
               Center(
                 child: TextButton(
                   onPressed: () => _showTransactionsDialog(filteredTransactions),
                   child: Text(
                     '+ ${filteredTransactions.length - 5} autres transactions',
                     style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                   ),
                 ),
               ),
          ]
        ],

        const SizedBox(height: 40),
        const Text(
          'CLÔTURER LE SHIFT',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, letterSpacing: 0.5),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Montant réel en caisse',
                  hintText: 'Comptez l\'argent physiquement',
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes / Écarts constatés',
                  hintText: 'Facultatif...',
                  prefixIcon: const Icon(Icons.note_alt_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _showConfirmCloseDialog,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: const Text('FERMER LA CAISSE', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ],
    );
  }

  Widget _buildFilterChip(String label, String code) {
    final isSelected = _transactionFilter == code;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) setState(() => _transactionFilter = code);
        },
        selectedColor: Colors.orange.withValues(alpha: 0.2),
        showCheckmark: false,
        labelStyle: TextStyle(
          color: isSelected ? Colors.orange : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> p) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    final client = p['client'] ?? {};
    final String clientName = '${client['nom'] ?? ''} ${client['prenom'] ?? ''}'.trim();
    final double amount = parseDouble(p['montant']);
    final String tableName = p['commande']?['table']?['numero'] != null 
        ? 'Table ${p['commande']?['table']?['numero']}' 
        : 'Table';
    final String method = p['moyen_paiement']?.toString() ?? 'inconnu';
    final isFidelity = method.toLowerCase() == 'points_fidelite';
    final int points = p['points_utilises'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(_getIconForMethod(method), color: Colors.grey[700], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  clientName.isEmpty ? 'Client inconnu' : clientName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                Text(
                  '$tableName • Commande #${p['commande_id']}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
          if (isFidelity) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$points pts',
                style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 11),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            Formatters.formatCurrency(amount),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  void _showTransactionsDialog(List transactions) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.orange,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(28), topRight: Radius.circular(28)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOUTES LES TRANSACTIONS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: Colors.white)),
            ],
          ),
        ),
        content: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: transactions.map((t) => _buildTransactionItem(t)).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
    );
  }

  IconData _getIconForMethod(String method) {
    switch (method.toLowerCase()) {
      case 'especes': return Icons.money;
      case 'wave': return Icons.waves;
      case 'orange_money': return Icons.phone_android;
      case 'points_fidelite': return Icons.star;
      default: return Icons.payment;
    }
  }

  void _showConfirmCloseDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmer la clôture ?'),
        content: const Text('Cette action va verrouiller vos transactions pour ce shift. Assurez-vous d\'avoir bien compté votre caisse.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('ANNULER')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleCloseSession();
            },
            child: const Text('FERMER DÉFINITIVEMENT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
