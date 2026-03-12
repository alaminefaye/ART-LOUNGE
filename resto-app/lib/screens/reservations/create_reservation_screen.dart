import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../models/reservation.dart';
import '../../models/table.dart' as models;
import '../../services/reservation_service.dart';
import '../../services/table_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_header.dart';

class CreateReservationScreen extends StatefulWidget {
  const CreateReservationScreen({super.key});

  @override
  State<CreateReservationScreen> createState() =>
      _CreateReservationScreenState();
}

class _CreateReservationScreenState extends State<CreateReservationScreen> {
  static const Color _brandGold = Color(0xFFD0A030);
  final ReservationService _reservationService = ReservationService();
  final TableService _tableService = TableService();
  final _formKey = GlobalKey<FormState>();

  List<models.Table> _tables = [];
  models.Table? _selectedTable;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _duree = 1;
  int _nombrePersonnes = 1;
  double? _prixTotal;
  bool _isCheckingAvailability = false;
  bool _isCreating = false;
  bool _isGameRoom = false;
  List<Reservation> _dailyReservations = [];

  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _telephoneController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTables();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserInfo();
    });
  }

  void _loadUserInfo() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user != null) {
      setState(() {
        _nomController.text = user.name;
        if (user.phone != null) {
          _telephoneController.text = user.phone!;
        }
      });
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _telephoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadTables() async {
    try {
      debugPrint('Chargement des tables...');
      final tables = await _tableService.getTables();
      debugPrint('Tables chargées: ${tables.length}');
      if (mounted) {
        setState(() {
          _tables = tables.where((t) => t.actif).toList();
        });

        if (_tables.isEmpty) {
          debugPrint('Aucune table active trouvée');
        } else {
          debugPrint('Tables actives: ${_tables.length}');
          // Debug: afficher les types de tables
          for (var t in _tables) {
            debugPrint('Table ${t.numero}: ${t.type}, Cap: ${t.capacite}');
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des tables: $e');
    }
  }

  Future<void> _checkAvailability() async {
    // Essayer de recharger les tables si la liste est vide
    if (_tables.isEmpty) {
      await _loadTables();
      if (_tables.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Impossible de charger la liste des tables. Vérifiez votre connexion.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isCheckingAvailability = true;
      _dailyReservations = [];
      _selectedTable = null;
    });

    try {
      models.Table? bestTable;
      Map<String, dynamic> successResult = {};
      Map<String, dynamic>? failureResult;
      bool found = false;

      if (_isGameRoom) {
        // Trouver la salle de jeu (unique)
        try {
          bestTable = _tables.firstWhere(
            (t) => t.type == models.TableType.espaceJeux,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aucune salle de jeu disponible'),
                backgroundColor: _brandGold,
              ),
            );
          }
          setState(() {
            _isCheckingAvailability = false;
          });
          return;
        }

        // Vérifier disponibilité
        final result = await _reservationService.verifierDisponibilite(
          tableId: bestTable.id,
          dateReservation: _selectedDate,
          heureDebut:
              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
          duree: _duree,
        );

        if (result['success'] == true && result['disponible'] == true) {
          successResult = result;
          found = true;
          _selectedTable = bestTable;
        } else {
          failureResult = result;
        }
      } else {
        // Mode Table : Chercher une table appropriée
        // Filtrer les tables (non-jeu) et capacité suffisante
        final suitableTables = _tables
            .where(
              (t) =>
                  t.type != models.TableType.espaceJeux &&
                  t.capacite >= _nombrePersonnes,
            )
            .toList();

        // Trier par capacité croissante (pour optimiser l'espace)
        suitableTables.sort((a, b) => a.capacite.compareTo(b.capacite));

        if (suitableTables.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Aucune table trouvée pour ce nombre de personnes. Essayez de réduire le nombre.',
                ),
                backgroundColor: _brandGold,
              ),
            );
          }
          setState(() {
            _isCheckingAvailability = false;
          });
          return;
        }

        // Boucler pour trouver la première table disponible
        for (final table in suitableTables) {
          final result = await _reservationService.verifierDisponibilite(
            tableId: table.id,
            dateReservation: _selectedDate,
            heureDebut:
                '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
            duree: _duree,
          );

          if (result['success'] == true && result['disponible'] == true) {
            successResult = result;
            found = true;
            _selectedTable = table;
            break; // On a trouvé une table, on arrête
          }
        }
      }

      setState(() {
        _isCheckingAvailability = false;
      });

      if (mounted) {
        if (found) {
          setState(() {
            _prixTotal = successResult['prix_total'] as double?;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Disponible ! Prix: ${Formatters.formatCurrency(_prixTotal ?? 0)}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Non disponible
          if (_isGameRoom && bestTable != null) {
            // Charger le programme pour la salle de jeu
            final reservations = await _reservationService.getReservations(
              date: DateFormat('yyyy-MM-dd').format(_selectedDate),
              tableId: bestTable.id,
              statut: 'confirmee,en_cours,attente',
            );

            // Trier les réservations
            reservations.sort((a, b) => a.heureDebut.compareTo(b.heureDebut));

            setState(() {
              _dailyReservations = reservations;
              _selectedTable =
                  bestTable; // On garde la table pour afficher le programme
              _prixTotal = null;
            });

            if (mounted) {
              String message = 'Occupé à cette heure.';
              if (failureResult != null &&
                  failureResult.containsKey('prochaine_disponibilite') &&
                  failureResult['prochaine_disponibilite'] != null) {
                message +=
                    ' Disponible à partir de ${failureResult['prochaine_disponibilite']}';
              }
              message += ' Voir le programme ci-dessous.';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(message),
                  backgroundColor: _brandGold,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Aucune table disponible à cette heure.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint('Erreur checkAvailability: $e');
      setState(() {
        _isCheckingAvailability = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de la vérification'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createReservation() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Le contrôle de _selectedTable est fait via _prixTotal qui est set lors du check
    if (_prixTotal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez vérifier la disponibilité d\'abord'),
          backgroundColor: _brandGold,
        ),
      );
      return;
    }

    if (_selectedTable == null) {
      // Should not happen if _prixTotal is set, but just in case
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur interne: Aucune table sélectionnée'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    final result = await _reservationService.createReservation(
      tableId: _selectedTable!.id,
      nomClient: _nomController.text.trim(),
      telephone: _telephoneController.text.trim(),
      dateReservation: _selectedDate,
      heureDebut:
          '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
      duree: _duree,
      nombrePersonnes: _nombrePersonnes,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    setState(() {
      _isCreating = false;
    });

    if (mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Réservation créée avec succès'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Erreur lors de la création'),
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
      body: SafeArea(top: false,
        child: Column(
          children: [
            // Header gradient
            const AppHeader(title: 'Nouvelle réservation'),

            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type de réservation (Table / Salle de jeu)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.05),
                              offset: const Offset(-1, -1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (_isGameRoom) {
                                    setState(() {
                                      _isGameRoom = false;
                                      _selectedTable = null;
                                      _prixTotal = null;
                                      _dailyReservations = [];
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: !_isGameRoom
                                        ? _brandGold
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Table',
                                    style: TextStyle(
                                      color: !_isGameRoom
                                          ? Colors.white
                                          : Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (!_isGameRoom) {
                                    setState(() {
                                      _isGameRoom = true;
                                      _selectedTable = null;
                                      _prixTotal = null;
                                      _dailyReservations = [];
                                      _nombrePersonnes =
                                          1; // Reset to 1 for Game Room
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _isGameRoom
                                        ? _brandGold
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    'Salle de jeu',
                                    style: TextStyle(
                                      color: _isGameRoom
                                          ? Colors.white
                                          : Colors.grey[800],
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Date et heure
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    offset: const Offset(4, 4),
                                    blurRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    offset: const Offset(-2, -2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Date',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final date = await showDatePicker(
                                        context: context,
                                        initialDate: _selectedDate,
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime.now().add(
                                          const Duration(days: 365),
                                        ),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.dark(
                                                    primary: _brandGold,
                                                    onPrimary: Colors.white,
                                                    surface: Colors.white,
                                                    onSurface: Colors.white,
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (date != null) {
                                        setState(() {
                                          _selectedDate = date;
                                          _prixTotal = null;
                                          _dailyReservations = [];
                                        });
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat(
                                            'dd/MM/yyyy',
                                          ).format(_selectedDate),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.calendar_today,
                                          color: _brandGold,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    offset: const Offset(4, 4),
                                    blurRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    offset: const Offset(-2, -2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Heure',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  InkWell(
                                    onTap: () async {
                                      final time = await showTimePicker(
                                        context: context,
                                        initialTime: _selectedTime,
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme:
                                                  const ColorScheme.dark(
                                                    primary: _brandGold,
                                                    onPrimary: Colors.white,
                                                    surface: Colors.white,
                                                    onSurface: Colors.white,
                                                  ),
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (time != null) {
                                        setState(() {
                                          _selectedTime = time;
                                          _prixTotal = null;
                                        });
                                      }
                                    },
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _selectedTime.format(context),
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const Icon(
                                          Icons.access_time,
                                          color: _brandGold,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Durée et nombre de personnes
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.05),
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            if (_isGameRoom)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Durée (heures)',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildCounterButton(
                                        icon: Icons.remove,
                                        onPressed: _duree > 1
                                            ? () {
                                                setState(() {
                                                  _duree--;
                                                  _prixTotal = null;
                                                });
                                              }
                                            : null,
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '$_duree',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      _buildCounterButton(
                                        icon: Icons.add,
                                        onPressed: _duree < 12
                                            ? () {
                                                setState(() {
                                                  _duree++;
                                                  _prixTotal = null;
                                                });
                                              }
                                            : null,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            if (!_isGameRoom)
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Personnes',
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 16,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      _buildCounterButton(
                                        icon: Icons.remove,
                                        onPressed: _nombrePersonnes > 1
                                            ? () {
                                                setState(() {
                                                  _nombrePersonnes--;
                                                  _prixTotal = null;
                                                });
                                              }
                                            : null,
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: Text(
                                          '$_nombrePersonnes',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                      _buildCounterButton(
                                        icon: Icons.add,
                                        onPressed: () {
                                          setState(() {
                                            _nombrePersonnes++;
                                            _prixTotal = null;
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bouton vérifier disponibilité
                      GestureDetector(
                        onTap: _isCheckingAvailability
                            ? null
                            : _checkAvailability,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_brandGold, Color(0xFFB08010)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: _brandGold.withValues(alpha: 0.4),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.2),
                                offset: const Offset(-2, -2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isCheckingAvailability)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _isCheckingAvailability
                                    ? 'Vérification...'
                                    : 'Vérifier disponibilité',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (_prixTotal != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Prix total:',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                Formatters.formatCurrency(_prixTotal!),
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),

                      // Affichage du programme si salle de jeu occupée
                      if (_isGameRoom && _dailyReservations.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.4),
                                offset: const Offset(4, 4),
                                blurRadius: 8,
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.05),
                                offset: const Offset(-2, -2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.event_note, color: _brandGold),
                                  SizedBox(width: 8),
                                  Text(
                                    'Programme du jour',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: _dailyReservations.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(color: Colors.grey),
                                itemBuilder: (context, index) {
                                  final res = _dailyReservations[index];
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${res.heureDebut} - ${res.heureFin ?? '...'}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _brandGold.withValues(
                                              alpha: 0.1,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'Occupé',
                                            style: TextStyle(
                                              color: _brandGold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),

                      // Informations client
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              offset: const Offset(4, 4),
                              blurRadius: 8,
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.05),
                              offset: const Offset(-2, -2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Informations client',
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _nomController,
                              'Nom complet *',
                              Icons.person,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _telephoneController,
                              'Téléphone *',
                              Icons.phone,
                              keyboardType: TextInputType.phone,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              _notesController,
                              'Notes (optionnel)',
                              Icons.note,
                              maxLines: 3,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Bouton créer réservation
                      GestureDetector(
                        onTap: _isCreating || _prixTotal == null
                            ? null
                            : _createReservation,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: _isCreating || _prixTotal == null
                                ? LinearGradient(
                                    colors: [
                                      Colors.grey.shade700,
                                      Colors.grey.shade800,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : const LinearGradient(
                                    colors: [_brandGold, Color(0xFFB08010)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: _isCreating || _prixTotal == null
                                ? null
                                : [
                                    BoxShadow(
                                      color: _brandGold.withValues(
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isCreating)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              else
                                const Icon(Icons.event, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                _isCreating
                                    ? 'Création...'
                                    : 'Créer la réservation',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 40),
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

  Widget _buildCounterButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    final isEnabled = onPressed != null;
    return Container(
      decoration: BoxDecoration(
        color: isEnabled ? const Color(0xFFD0A030) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: _brandGold.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(4, 4),
                ),
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(-2, -2),
                ),
              ]
            : null,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white, size: 20),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(2, 2),
            blurRadius: 4,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            offset: const Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[700]),
          prefixIcon: Icon(icon, color: _brandGold),
          filled: true,
          fillColor: Colors.transparent,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _brandGold, width: 1),
          ),
        ),
        style: const TextStyle(color: Colors.black87, fontSize: 16),
        keyboardType: keyboardType,
        maxLines: maxLines,
        validator: (value) {
          if (label.contains('*') && (value == null || value.trim().isEmpty)) {
            return 'Ce champ est requis';
          }
          return null;
        },
      ),
    );
  }
}
