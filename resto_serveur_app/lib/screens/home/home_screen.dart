import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/table.dart';
import '../../services/auth_service.dart';
import '../../services/table_service.dart';
import '../order/order_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TableService _tableService = TableService();
  List<RestaurantTable> _tables = [];
  bool _isLoading = true;
  String? _error;
  TableStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _loadTables();
  }

  Future<void> _loadTables() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final tables = await _tableService.getTables();
      if (mounted) {
        setState(() {
          _tables = tables;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error =
              'Impossible de charger les tables. Vérifiez votre connexion.';
          _isLoading = false;
        });
      }
    }
  }

  List<RestaurantTable> get _filteredTables {
    if (_filterStatus == null) return _tables;
    return _tables.where((t) => t.statut == _filterStatus).toList();
  }

  void _onTableTap(RestaurantTable table) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final serveur = authService.activeServeur ?? authService.currentUser;

    // Navigate to order screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderScreen(table: table, serveur: serveur),
      ),
    ).then((_) => _loadTables()); // Refresh on return
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final serveur = authService.activeServeur ?? authService.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBg,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              AppBrand.appName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (serveur != null)
              Text(
                'Connecté : ${serveur.name}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.brandGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _loadTables,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualiser',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'lock') {
                authService.lockServeur();
              } else if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'lock',
                child: Row(
                  children: [
                    Icon(Icons.lock_outline, size: 18),
                    SizedBox(width: 8),
                    Text('Verrouiller'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Déconnexion', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          _buildFilterChips(),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppTheme.brandGold),
                  )
                : _error != null
                ? _buildError()
                : _filteredTables.isEmpty
                ? _buildEmpty()
                : _buildTableGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Toutes',
              count: _tables.length,
              isSelected: _filterStatus == null,
              color: AppTheme.brandGold,
              onTap: () => setState(() => _filterStatus = null),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Libres',
              count: _tables.where((t) => t.statut == TableStatus.libre).length,
              isSelected: _filterStatus == TableStatus.libre,
              color: AppTheme.statusLibre,
              onTap: () => setState(() => _filterStatus = TableStatus.libre),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Occupées',
              count: _tables
                  .where((t) => t.statut == TableStatus.occupee)
                  .length,
              isSelected: _filterStatus == TableStatus.occupee,
              color: AppTheme.statusOccupee,
              onTap: () => setState(() => _filterStatus = TableStatus.occupee),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Réservées',
              count: _tables
                  .where((t) => t.statut == TableStatus.reservee)
                  .length,
              isSelected: _filterStatus == TableStatus.reservee,
              color: AppTheme.statusReservee,
              onTap: () => setState(() => _filterStatus = TableStatus.reservee),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableGrid() {
    return RefreshIndicator(
      onRefresh: _loadTables,
      color: AppTheme.brandGold,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.0,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _filteredTables.length,
        itemBuilder: (_, i) => _TableCard(
          table: _filteredTables[i],
          onTap: () => _onTableTap(_filteredTables[i]),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
              onPressed: _loadTables,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.table_restaurant, size: 60, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            _filterStatus != null
                ? 'Aucune table ${_filterStatus!.displayName.toLowerCase()}'
                : 'Aucune table disponible',
            style: const TextStyle(color: Colors.black54, fontSize: 16),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Provider.of<AuthService>(context, listen: false).logout();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── TABLE CARD ─────────────────────────────
class _TableCard extends StatelessWidget {
  final RestaurantTable table;
  final VoidCallback onTap;

  const _TableCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = table.statut.color;
    final isOccupied =
        table.statut == TableStatus.occupee ||
        table.statut == TableStatus.enPaiement;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.4),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: statusColor.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status indicator bar on top
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        Icons.table_restaurant,
                        color: statusColor,
                        size: 28,
                      ),
                      if (table.type == TableType.vip)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.brandGold.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'VIP',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.brandGold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Table ${table.numero}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(table.statut.icon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        table.statut.displayName,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.people_outline,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${table.capacite} pers.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tap overlay for occupied tables
            if (isOccupied)
              Positioned(
                bottom: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.brandGold,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Commander',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────── FILTER CHIP ─────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : color,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.3)
                    : color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
