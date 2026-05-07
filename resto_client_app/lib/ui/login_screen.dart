import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final identifier = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (identifier.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Remplis ton téléphone/email et ton mot de passe'),
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthState>().login(
        identifier: identifier,
        password: password,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color: AppTheme.text,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: const Text(
                        'Connexion',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  'Connexion',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tu peux naviguer sans compte. Connecte-toi seulement pour payer.',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: _identifierCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppTheme.text),
                        decoration: const InputDecoration(
                          labelText: 'Téléphone ou Email',
                          prefixIcon: Icon(
                            Icons.person_outline,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordCtrl,
                        obscureText: true,
                        style: const TextStyle(color: AppTheme.text),
                        decoration: const InputDecoration(
                          labelText: 'Mot de passe',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ),
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
                                  'Se connecter',
                                  style: TextStyle(fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Astuce: tu peux te connecter avec ton numéro (ex: 770000000) ou ton email.',
                        style: TextStyle(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
