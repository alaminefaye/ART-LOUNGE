import 'package:flutter/material.dart';
import '../models/serveur.dart';
import '../services/serveur_service.dart';
import '../theme/app_theme.dart';

class ServeurSelectionDialog extends StatefulWidget {
  const ServeurSelectionDialog({super.key});

  @override
  State<ServeurSelectionDialog> createState() => _ServeurSelectionDialogState();
}

class _ServeurSelectionDialogState extends State<ServeurSelectionDialog> {
  final ServeurService _serveurService = ServeurService();
  List<Serveur> _serveurs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadServeurs();
  }

  Future<void> _loadServeurs() async {
    final serveurs = await _serveurService.getServeurs();
    if (mounted) {
      setState(() {
        _serveurs = serveurs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AlertDialog(
        content: SizedBox(
          height: 100,
          child: Center(child: CircularProgressIndicator(color: AppTheme.brandGold)),
        ),
      );
    }

    return AlertDialog(
      title: const Text('Sélectionner le Serveur', style: TextStyle(fontWeight: FontWeight.bold)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      content: SizedBox(
        width: 400,
        height: 300,
        child: _serveurs.isEmpty
            ? const Center(child: Text('Aucun serveur configuré.'))
            : GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _serveurs.length,
                itemBuilder: (context, index) {
                  final s = _serveurs[index];
                  return InkWell(
                    onTap: () => Navigator.of(context).pop(s.id),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppTheme.brandGold.withValues(alpha: 0.1),
                        border: Border.all(color: AppTheme.brandGold),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s.prenom != null ? '${s.nom} ${s.prenom}' : s.nom,
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.brandGold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }
}
