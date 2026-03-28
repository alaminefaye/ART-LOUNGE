import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_brand.dart';
import '../../models/user.dart';
import '../../services/auth_service.dart';
import 'orders_history_screen.dart';
import '../../widgets/app_header.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  static const Color _brandGold = Color(0xFFD0A030);
  static const Color _brandGoldDark = Color(0xFFB08010);

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        try {
          final user = authService.currentUser;

          if (user == null) {
            return Scaffold(
              backgroundColor: const Color(0xFFFFF6EC),
              body: SafeArea(
                top: false,
                child: Column(
                  children: [
                    const AppHeader(
                      title: 'Mon Profil',
                      titleFontSize: 18,
                      showBackButton: false,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.person_outline,
                              size: 64,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Connectez-vous',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey[800],
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'Accédez à votre profil, historique et avantages.',
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
                                  backgroundColor: _brandGold,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
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
                              child: Text(
                                'Créer un compte',
                                style: TextStyle(
                                  color: _brandGoldDark,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
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
            body: SafeArea(
              top: false,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Header gradient
                    AppHeader(
                      title: 'Mon Profil',
                      titleFontSize: 18,
                      showBackButton: false,
                    ),

                    // Photo de profil et informations
                    Column(
                      children: [
                        // Photo de profil avec badge
                        Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _brandGold,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _brandGold.withValues(alpha: 0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 40,
                                backgroundColor: _brandGold,
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : user.email.isNotEmpty
                                      ? user.email[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                            // Badge Admin si rôle admin
                            if (user.roles.isNotEmpty &&
                                user.roles.any(
                                  (role) =>
                                      role.toLowerCase().contains('admin'),
                                ))
                              Positioned(
                                bottom: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_brandGoldDark, _brandGold],
                                    ),
                                    borderRadius: BorderRadius.circular(15),
                                    boxShadow: [
                                      BoxShadow(
                                        color: _brandGold.withValues(
                                          alpha: 0.5,
                                        ),
                                        blurRadius: 6,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Text(
                                    'ADMIN',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Nom
                        Text(
                          user.name.isNotEmpty ? user.name : 'Utilisateur',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Bouton Edit Profile
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_brandGold, _brandGoldDark],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: _brandGold.withValues(alpha: 0.3),
                                  offset: const Offset(4, 4),
                                  blurRadius: 10,
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  offset: const Offset(-2, -2),
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.edit, size: 14, color: Colors.white),
                                SizedBox(width: 6),
                                Text(
                                  'Éditer le profil',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 40),

                    // Section Points de fidélité
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'POINTS DE FIDÉLITÉ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildPointsCard(user),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Section Informations
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'INFORMATIONS',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildInfoCard(
                            icon: Icons.email_outlined,
                            title: 'Email',
                            value: user.email,
                          ),
                          if (user.phone != null) ...[
                            const SizedBox(height: 15),
                            _buildInfoCard(
                              icon: Icons.phone_outlined,
                              title: 'Téléphone',
                              value: user.phone!,
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),

                    // Section Actions
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTIONS',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 15),
                          _buildActionCard(
                            icon: Icons.receipt_long,
                            title: 'Historique des commandes',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const OrdersHistoryScreen(),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 15),
                          _buildActionCard(
                            icon: Icons.info_outline_rounded,
                            title: 'À propos',
                            onTap: () {
                              showAboutDialog(
                                context: context,
                                applicationName: AppBrand.displayName,
                                applicationVersion: '1.0.0',
                                applicationIcon: const Icon(
                                  Icons.restaurant_menu,
                                ),
                              );
                            },
                          ),
                          if (user.hasRole('client') &&
                              !user.hasRole('admin') &&
                              !user.hasRole('manager') &&
                              !user.hasRole('serveur') &&
                              !user.hasRole('caissier')) ...[
                            _buildActionCard(
                              icon: Icons.delete_forever_outlined,
                              title: 'Supprimer mon compte',
                              color: Colors.redAccent,
                              onTap: () {
                                showDialog<void>(
                                  context: context,
                                  builder: (_) => const _DeleteAccountDialog(),
                                );
                              },
                            ),
                            const SizedBox(height: 15),
                          ],
                          _buildActionCard(
                            icon: Icons.logout,
                            title: 'Déconnexion',
                            color: Colors.red,
                            onTap: () async {
                              await authService.logout();
                              if (!context.mounted) return;
                              // Ferme les écrans empilés (profil depuis le dashboard, login, etc.)
                              // pour éviter Retour → ancienne route (ex. connexion).
                              Navigator.of(context).popUntil(
                                (route) => route.isFirst,
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        } catch (e) {
          debugPrint('Erreur ProfileScreen: $e');
          return Scaffold(
            backgroundColor: const Color(0xFFFFF6EC),
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              title: const Text(
                'Mon Profil',
                style: TextStyle(color: Colors.black),
              ),
              iconTheme: const IconThemeData(color: Colors.black87),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Erreur lors du chargement du profil',
                    style: TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    e.toString(),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Retour'),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildPointsCard(User user) {
    final points = user.pointsFidelite;
    final valeurFcfa = user.valeurFcfa1Point;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFD0A030).withValues(alpha: 0.15),
            const Color(0xFFB08010).withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFD0A030).withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, 6),
            blurRadius: 16,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFD0A030).withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.stars, color: Color(0xFFD0A030), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Votre solde',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$points point${points != 1 ? 's' : ''}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (valeurFcfa != null && valeurFcfa > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '1 point = ${valeurFcfa.toStringAsFixed(0)} FCFA de réduction',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            offset: const Offset(0, 10),
            blurRadius: 22,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6EC),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: Icon(icon, color: _brandGold, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? color,
  }) {
    final themeColor = color ?? _brandGold;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              offset: const Offset(0, 10),
              blurRadius: 22,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: themeColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: themeColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: color ?? Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF6EC),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Icon(
                Icons.chevron_right,
                color: Colors.grey[700],
                size: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialogue de suppression de compte (mot de passe + texte légal / stats).
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _pwd = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _pwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 28),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Supprimer mon compte',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cette action est définitive : vous ne pourrez plus vous connecter avec ce compte.',
              style: TextStyle(height: 1.35),
            ),
            const SizedBox(height: 12),
            Text(
              'Vos commandes passées et les montants associés restent conservés de façon anonyme dans notre système (statistiques et obligations comptables). Vos données personnelles sur ce profil seront effacées ou anonymisées.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[800],
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _pwd,
              obscureText: _obscure,
              enabled: !_loading,
              decoration: InputDecoration(
                labelText: 'Mot de passe actuel',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscure ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _loading
              ? null
              : () async {
                  if (_pwd.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Saisissez votre mot de passe pour confirmer.'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  setState(() => _loading = true);
                  final r = await auth.deleteAccount(_pwd.text);
                  if (!context.mounted) return;
                  setState(() => _loading = false);
                  if (r['success'] == true) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          r['message'] as String? ?? 'Compte supprimé.',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );
                    if (!context.mounted) return;
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  } else {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          r['message'] as String? ?? 'Erreur',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
          child: _loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Supprimer définitivement'),
        ),
      ],
    );
  }
}
