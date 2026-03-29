import 'package:flutter/material.dart';
import '../../services/caisse_service.dart';
import '../../theme/app_theme.dart';
import '../pos_screen.dart';
import 'session_management_screen.dart';
import '../kitchen/kitchen_screen.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

class SessionWrapper extends StatefulWidget {
  const SessionWrapper({super.key});

  @override
  State<SessionWrapper> createState() => _SessionWrapperState();
}

class _SessionWrapperState extends State<SessionWrapper> {
  final CaisseService _caisseService = CaisseService();
  bool _isLoading = true;
  bool _hasSession = false;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    setState(() => _isLoading = true);
    final session = await _caisseService.getCurrentSession();
    if (mounted) {
      setState(() {
        _hasSession = session != null && session.isOuverte;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthService>(context, listen: false).currentUser;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(child: CircularProgressIndicator(color: AppTheme.brandGold)),
      );
    }

    // Role check: If Cuisinier, go to Kitchen screen directly
    if (user != null && user.hasRole('cuisinier')) {
      return const KitchenScreen();
    }

    if (_hasSession) {
      return PosScreen(
        onRequireSessionCheck: _checkSession,
      );
    }

    // Wrap in a WillPopScope or just return the view
    return SessionManagementScreen(
      onSessionOpened: _checkSession,
    );
  }
}
