import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/fcm_service.dart';
import '../menu/menu_screen.dart';
import '../dashboard/dashboard_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  /// Si `true`, ferme l’écran avec `true` après connexion (ex. retour au panier).
  /// Sinon, remplace la pile par le menu principal (comportement classique).
  final bool popOnSuccess;

  const LoginScreen({super.key, this.popOnSuccess = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _brandGold = Color(0xFFD0A030);
  static const Color _brandGoldDark = Color(0xFFC08A1C);
  final _formKey = GlobalKey<FormState>();
  final _emailOrPhoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailOrPhoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final authService = Provider.of<AuthService>(context, listen: false);
    final result = await authService.login(
      _emailOrPhoneController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      if (mounted) {
        if (!kIsWeb) {
          await FCMService().initialize(authService);
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connexion réussie !'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Attendre un peu pour que le message s'affiche
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          if (widget.popOnSuccess) {
            Navigator.of(context).pop(true);
          } else {
            // Redirection basée sur le rôle (même logique que dans main.dart)
            final user = authService.currentUser;
            final bool isStaff = user != null &&
                (user.hasRole('admin') ||
                    user.hasRole('manager') ||
                    user.hasRole('serveur') ||
                    user.hasRole('caissier'));

            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (_) => isStaff
                    ? const DashboardScreen()
                    : const MenuScreen(),
              ),
              (route) => false,
            );
          }
        }
      }
    } else {
      String errorMessage = result['message'] ?? 'Erreur de connexion';

      // Nettoyer le message d'erreur pour l'utilisateur
      if (errorMessage.contains('DioException')) {
        errorMessage =
            'Erreur de connexion au serveur. Vérifiez votre connexion internet.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildTextFieldContainer({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            offset: const Offset(8, 8),
            blurRadius: 20,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.95),
            offset: const Offset(-8, -8),
            blurRadius: 20,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFFFFF), Color(0xFFFFF6EC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
        Positioned(
          top: -110,
          right: -110,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              color: _brandGold.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: -140,
          left: -120,
          child: Container(
            width: 320,
            height: 320,
            decoration: BoxDecoration(
              color: Colors.deepOrange.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final logoWidth = (MediaQuery.sizeOf(context).width * 0.62).clamp(
      230.0,
      290.0,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset('assets/logo.png', width: logoWidth),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'Connexion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Connectez-vous pour continuer',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[700], fontSize: 14),
                      ),
                      const SizedBox(height: 22),
                      _buildTextFieldContainer(
                        child: TextFormField(
                          controller: _emailOrPhoneController,
                          keyboardType: TextInputType.text,
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Email ou Téléphone',
                            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                            hintText: 'exemple@email.com ou 0705316506',
                            hintStyle: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 11,
                            ),
                            prefixIcon: const Icon(
                              Icons.person,
                              color: _brandGoldDark,
                              size: 20,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre email ou téléphone';
                            }
                            if (value.contains('@')) {
                              if (!RegExp(
                                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                              ).hasMatch(value)) {
                                return 'Format email invalide';
                              }
                            }
                            if (!value.contains('@') &&
                                !RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(value)) {
                              return 'Format téléphone invalide';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 18),
                      _buildTextFieldContainer(
                        child: TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(color: Colors.black87, fontSize: 14),
                          decoration: InputDecoration(
                            labelText: 'Mot de passe',
                            labelStyle: TextStyle(color: Colors.grey[700], fontSize: 13),
                            prefixIcon: const Icon(
                              Icons.lock,
                              color: _brandGoldDark,
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.grey[600],
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 14,
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Veuillez entrer votre mot de passe';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 28),
                      GestureDetector(
                        onTap: _isLoading ? null : _login,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _isLoading
                                  ? [Colors.grey.shade400, Colors.grey.shade500]
                                  : [_brandGold, _brandGoldDark],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: _isLoading
                                ? null
                                : [
                                    BoxShadow(
                                      color: _brandGoldDark.withValues(
                                        alpha: 0.30,
                                      ),
                                      offset: const Offset(8, 8),
                                      blurRadius: 18,
                                    ),
                                  ],
                          ),
                          child: Center(
                            child: _isLoading
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
                                : const Text(
                                    'Se connecter',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Vous n\'avez pas de compte ? ',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final registered = await Navigator.push<bool>(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RegisterScreen(
                                    popOnSuccess: widget.popOnSuccess,
                                  ),
                                ),
                              );
                              if (!context.mounted) return;
                              if (registered == true && widget.popOnSuccess) {
                                Navigator.of(context).pop(true);
                              }
                            },
                            child: const Text(
                              'S\'inscrire',
                              style: TextStyle(
                                color: _brandGoldDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
