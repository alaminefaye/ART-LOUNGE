import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reservation.dart';
import '../../services/reservation_service.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import 'create_reservation_screen.dart';
import 'reservation_detail_screen.dart';
import '../../widgets/app_header.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final ReservationService _reservationService = ReservationService();
  List<Reservation> _reservations = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, a_venir, attente, confirmee
  bool? _wasAuthenticated;

  void _syncReservationsForAuth(AuthService auth) {
    final isAuth = auth.isAuthenticated;
    final wasAuth = _wasAuthenticated;
    _wasAuthenticated = isAuth;

    if (wasAuth == true && !isAuth) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _reservations = [];
          _isLoading = false;
        });
      });
      return;
    }

    if (isAuth && wasAuth != true) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final a = Provider.of<AuthService>(context, listen: false);
        if (!a.isAuthenticated) return;
        _loadReservations();
      });
    }
  }

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadReservations() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      bool? aVenir;
      String? statut;

      if (_filter == 'a_venir') {
        aVenir = true;
      } else if (_filter != 'all') {
        statut = _filter;
      }

      final reservations = await _reservationService.getReservations(
        statut: statut,
        aVenir: aVenir,
      );

      if (mounted) {
        setState(() {
          _reservations = reservations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des réservations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    _syncReservationsForAuth(authService);

    if (!authService.isAuthenticated) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFF6EC),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              AppHeader(
                title: 'Réservations',
                titleFontSize: 18,
                showBackButton: false,
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.event_outlined,
                          size: 64,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Connectez-vous pour vos réservations',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Réservez une table et retrouvez vos réservations ici.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFD0A030),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Se connecter',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Créer un compte',
                            style: TextStyle(
                              color: Color(0xFFC08A1C),
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6EC),
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient
            AppHeader(
              title: 'Réservations',
              titleFontSize: 18,
              showBackButton: false,
              actions: [
                HeaderActionButton(
                  icon: Icons.add,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CreateReservationScreen(),
                      ),
                    );
                    if (result == true) {
                      _loadReservations();
                    }
                  },
                ),
                HeaderActionButton(
                  icon: Icons.refresh,
                  onTap: _loadReservations,
                ),
              ],
            ),
            // Filter chips
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _build3DFilterChip('all', 'Toutes'),
                    const SizedBox(width: 12),
                    _build3DFilterChip('a_venir', 'À venir'),
                    const SizedBox(width: 12),
                    _build3DFilterChip('attente', 'En attente'),
                    const SizedBox(width: 12),
                    _build3DFilterChip('confirmee', 'Confirmées'),
                  ],
                ),
              ),
            ),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFD0A030),
                      ),
                    )
                  : _reservations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.12),
                                  offset: const Offset(0, 10),
                                  blurRadius: 22,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.event_busy,
                              size: 60,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 32),
                          Text(
                            'Aucune réservation',
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Vos réservations apparaîtront ici',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadReservations,
                      color: const Color(0xFFD0A030),
                      backgroundColor: Colors.white,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _reservations.length,
                        itemBuilder: (context, index) {
                          final reservation = _reservations[index];
                          return _buildReservationCard(context, reservation);
                        },
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _build3DFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _filter = value;
        });
        _loadReservations();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFD0A030) : Colors.white,
          border: Border.all(
            color: isSelected
                ? const Color(0xFFD0A030)
                : Colors.black.withValues(alpha: 0.06),
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFD0A030).withValues(alpha: 0.3),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, 4),
                    blurRadius: 12,
                  ),
                ],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
            fontSize: 12,
            shadows: isSelected
                ? [
                    const Shadow(
                      color: Colors.black26,
                      offset: Offset(1, 1),
                      blurRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildReservationCard(BuildContext context, Reservation reservation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ReservationDetailScreen(reservationId: reservation.id),
              ),
            ).then((_) => _loadReservations());
          },
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF6EC),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                offset: const Offset(0, 4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.table_restaurant,
                            color: Color(0xFFD0A030),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.table != null
                                  ? 'Table ${reservation.table!.numero}'
                                  : 'Réservation #${reservation.id}',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 3),
                            if (reservation.table != null)
                              Text(
                                reservation.table!.type.displayName,
                                style: TextStyle(
                                  color: Colors.grey[700],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor(
                          reservation.statut,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _getStatusColor(
                            reservation.statut,
                          ).withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        reservation.statut.displayName,
                        style: TextStyle(
                          color: _getStatusColor(reservation.statut),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF6EC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.black.withValues(alpha: 0.06),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoItem(
                        Icons.calendar_today,
                        Formatters.formatDate(reservation.dateReservation),
                      ),
                      _buildVerticalDivider(),
                      _buildInfoItem(
                        Icons.access_time,
                        '${reservation.heureDebut} - ${reservation.heureFin ?? 'N/A'}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF6EC),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      child: Icon(
                        Icons.people,
                        size: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${reservation.nombrePersonnes} personne(s)',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      Formatters.formatCurrency(reservation.prixTotal),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Color(0xFFD0A030),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            color: Colors.grey[700],
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(height: 20, width: 1, color: Colors.grey[400]);
  }

  Color _getStatusColor(ReservationStatus status) {
    switch (status) {
      case ReservationStatus.attente:
        return Colors.orangeAccent;
      case ReservationStatus.confirmee:
        return Colors.greenAccent;
      case ReservationStatus.enCours:
        return Colors.lightBlueAccent;
      case ReservationStatus.terminee:
        return Colors.grey;
      case ReservationStatus.annulee:
        return Colors.redAccent;
    }
  }
}
