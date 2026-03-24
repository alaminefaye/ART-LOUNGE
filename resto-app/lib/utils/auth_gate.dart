import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../screens/auth/login_screen.dart';

/// Retourne `true` si l’utilisateur est connecté, sinon ouvre la connexion
/// et retourne `true` après succès, ou `false` si annulé.
Future<bool> requireAuth(BuildContext context) async {
  final auth = Provider.of<AuthService>(context, listen: false);
  if (auth.isAuthenticated) {
    return true;
  }
  final result = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const LoginScreen(popOnSuccess: true),
    ),
  );
  return result == true;
}
