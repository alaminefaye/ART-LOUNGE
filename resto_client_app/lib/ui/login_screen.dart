import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/auth_state.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _introCtrl;
  late final AnimationController _loopCtrl;
  late final Animation<double> _introFade;
  late final Animation<Offset> _introSlide;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _introFade = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);
    _introSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic));

    _introCtrl.forward();
    _loopCtrl.repeat();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _loopCtrl.dispose();
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
          child: Stack(
            children: [
              Positioned(
                top: -40,
                left: -50,
                child: _GlowBlob(
                  size: 220,
                  color: AppTheme.accent.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -40,
                child: _GlowBlob(
                  size: 260,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: FadeTransition(
                  opacity: _introFade,
                  child: SlideTransition(
                    position: _introSlide,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _GlassIconButton(
                              onTap: () => Navigator.of(context).pop(false),
                              icon: Icons.arrow_back_ios_new,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: const Text(
                                'ART Moments',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        AnimatedBuilder(
                          animation: _loopCtrl,
                          builder: (context, _) {
                            final t = _loopCtrl.value;
                            final floatY = math.sin(t * math.pi * 2) * 6;
                            final shimmer = (t * 2) % 1.0;
                            return Column(
                              children: [
                                Transform.translate(
                                  offset: Offset(0, floatY),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Container(
                                        width: 98,
                                        height: 98,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: AppTheme.accent.withValues(
                                              alpha: 0.55,
                                            ),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                              blurRadius: 24,
                                              offset: const Offset(0, 12),
                                            ),
                                            BoxShadow(
                                              color: AppTheme.accent.withValues(
                                                alpha: 0.12,
                                              ),
                                              blurRadius: 36,
                                              offset: const Offset(0, 18),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        child: Image.asset(
                                          'logo.jpeg',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.restaurant_rounded,
                                                color: AppTheme.bgTop,
                                                size: 44,
                                              ),
                                        ),
                                      ),
                                      _OrbitIcon(
                                        icon: Icons.restaurant_menu_rounded,
                                        t: t + 0.10,
                                        radius: 74,
                                        color: AppTheme.accent,
                                      ),
                                      _OrbitIcon(
                                        icon: Icons.local_bar_rounded,
                                        t: t + 0.46,
                                        radius: 70,
                                        color: Colors.white,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ShaderMask(
                                  shaderCallback: (rect) {
                                    final dx =
                                        rect.width * (shimmer * 1.6 - 0.3);
                                    return LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: const [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFF2BC91),
                                        Color(0xFFFFFFFF),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                      transform: _SlideGradient(dx: dx),
                                    ).createShader(rect);
                                  },
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    'ART Moments',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                        ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Connexion',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w900,
                                color: AppTheme.text,
                              ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'Tu peux naviguer sans compte.\nConnecte-toi seulement pour payer.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontWeight: FontWeight.w700,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _identifierCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                    cursorColor: AppTheme.accent,
                                    decoration: InputDecoration(
                                      labelText: 'Téléphone ou email',
                                      prefixIcon: const Icon(
                                        Icons.person_outline,
                                        color: AppTheme.textMuted,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: AppTheme.accent,
                                          width: 2,
                                        ),
                                      ),
                                      labelStyle: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      floatingLabelStyle: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black.withValues(
                                        alpha: 0.22,
                                      ),
                                      suffixIcon:
                                          _identifierCtrl.text.trim().isEmpty
                                          ? null
                                          : IconButton(
                                              onPressed: () {
                                                _identifierCtrl.clear();
                                                setState(() {});
                                              },
                                              icon: const Icon(
                                                Icons.close_rounded,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _passwordCtrl,
                                    obscureText: _obscure,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                    cursorColor: AppTheme.accent,
                                    decoration: InputDecoration(
                                      labelText: 'Mot de passe',
                                      prefixIcon: const Icon(
                                        Icons.lock_outline,
                                        color: AppTheme.textMuted,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.14,
                                          ),
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(16),
                                        borderSide: const BorderSide(
                                          color: AppTheme.accent,
                                          width: 2,
                                        ),
                                      ),
                                      labelStyle: const TextStyle(
                                        color: AppTheme.textMuted,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      floatingLabelStyle: const TextStyle(
                                        color: AppTheme.accent,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      filled: true,
                                      fillColor: Colors.black.withValues(
                                        alpha: 0.22,
                                      ),
                                      suffixIcon: IconButton(
                                        onPressed: () => setState(
                                          () => _obscure = !_obscure,
                                        ),
                                        icon: Icon(
                                          _obscure
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      icon: _loading
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.login_rounded,
                                              color: Colors.white,
                                            ),
                                      label: Text(
                                        _loading
                                            ? 'Connexion...'
                                            : 'Se connecter',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'Astuce: utilise ton numéro (ex: 770000000) ou ton email.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () async {
                                            final ok =
                                                await Navigator.of(
                                                  context,
                                                ).push<bool>(
                                                  MaterialPageRoute(
                                                    builder: (_) =>
                                                        const RegisterScreen(),
                                                  ),
                                                );
                                            if (!mounted) return;
                                            if (ok == true) {
                                              Navigator.of(context).pop(true);
                                            }
                                          },
                                    child: Text(
                                      'Créer un compte',
                                      style: TextStyle(
                                        color: AppTheme.accent.withValues(
                                          alpha: _loading ? 0.55 : 1.0,
                                        ),
                                        fontWeight: FontWeight.w900,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassIconButton extends StatelessWidget {
  const _GlassIconButton({required this.onTap, required this.icon});

  final VoidCallback onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Icon(icon, color: AppTheme.text, size: 18),
      ),
    );
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
          stops: const [0.0, 1.0],
        ),
      ),
    );
  }
}

class _OrbitIcon extends StatelessWidget {
  const _OrbitIcon({
    required this.icon,
    required this.t,
    required this.radius,
    required this.color,
  });

  final IconData icon;
  final double t;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final angle = t * math.pi * 2;
    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius * 0.65;
    final opacity = (0.70 + (math.sin(angle + 1.1) * 0.22)).clamp(0.35, 0.95);
    return Transform.translate(
      offset: Offset(x, y),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Center(
          child: Icon(
            icon,
            size: 20,
            color: color.withValues(alpha: opacity.toDouble()),
          ),
        ),
      ),
    );
  }
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient({required this.dx});

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with TickerProviderStateMixin {
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _pass2Ctrl = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  late final AnimationController _introCtrl;
  late final AnimationController _loopCtrl;
  late final Animation<double> _introFade;
  late final Animation<Offset> _introSlide;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _introFade = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);
    _introSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _introCtrl, curve: Curves.easeOutCubic));
    _introCtrl.forward();
    _loopCtrl.repeat();
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _loopCtrl.dispose();
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _telCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _pass2Ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final nom = _nomCtrl.text.trim();
    final prenom = _prenomCtrl.text.trim();
    final telephone = _telCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final pass2 = _pass2Ctrl.text;

    if (nom.isEmpty || prenom.isEmpty || telephone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplis nom, prénom et téléphone')),
      );
      return;
    }
    if (pass.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le mot de passe doit faire 6 caractères'),
        ),
      );
      return;
    }
    if (pass != pass2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Les mots de passe ne correspondent pas')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await context.read<AuthState>().register(
        nom: nom,
        prenom: prenom,
        telephone: telephone,
        email: email.isEmpty ? null : email,
        password: pass,
        passwordConfirmation: pass2,
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

  InputDecoration _dec(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppTheme.textMuted),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppTheme.accent, width: 2),
      ),
      labelStyle: const TextStyle(
        color: AppTheme.textMuted,
        fontWeight: FontWeight.w700,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppTheme.accent,
        fontWeight: FontWeight.w800,
      ),
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.22),
    );
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
          child: Stack(
            children: [
              Positioned(
                top: -40,
                left: -50,
                child: _GlowBlob(
                  size: 220,
                  color: AppTheme.accent.withValues(alpha: 0.18),
                ),
              ),
              Positioned(
                bottom: -60,
                right: -40,
                child: _GlowBlob(
                  size: 260,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
                child: FadeTransition(
                  opacity: _introFade,
                  child: SlideTransition(
                    position: _introSlide,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _GlassIconButton(
                              onTap: () => Navigator.of(context).pop(false),
                              icon: Icons.arrow_back_ios_new,
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: const Text(
                                'ART Moments',
                                style: TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        AnimatedBuilder(
                          animation: _loopCtrl,
                          builder: (context, _) {
                            final t = _loopCtrl.value;
                            final floatY = math.sin(t * math.pi * 2) * 6;
                            final shimmer = (t * 2) % 1.0;
                            return Column(
                              children: [
                                Transform.translate(
                                  offset: Offset(0, floatY),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      _OrbitIcon(
                                        icon: Icons.restaurant_menu_rounded,
                                        t: t + 0.10,
                                        radius: 76,
                                        color: AppTheme.accent,
                                      ),
                                      _OrbitIcon(
                                        icon: Icons.local_bar_rounded,
                                        t: t + 0.46,
                                        radius: 72,
                                        color: Colors.white,
                                      ),
                                      Container(
                                        width: 90,
                                        height: 90,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white,
                                          border: Border.all(
                                            color: AppTheme.accent.withValues(
                                              alpha: 0.55,
                                            ),
                                            width: 2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(
                                                alpha: 0.22,
                                              ),
                                              blurRadius: 24,
                                              offset: const Offset(0, 12),
                                            ),
                                            BoxShadow(
                                              color: AppTheme.accent.withValues(
                                                alpha: 0.12,
                                              ),
                                              blurRadius: 36,
                                              offset: const Offset(0, 18),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(14),
                                        child: Image.asset(
                                          'logo.jpeg',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                                Icons.restaurant_rounded,
                                                color: AppTheme.bgTop,
                                                size: 40,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 14),
                                ShaderMask(
                                  shaderCallback: (rect) {
                                    final dx =
                                        rect.width * (shimmer * 1.6 - 0.3);
                                    return LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: const [
                                        Color(0xFFFFFFFF),
                                        Color(0xFFF2BC91),
                                        Color(0xFFFFFFFF),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                      transform: _SlideGradient(dx: dx),
                                    ).createShader(rect);
                                  },
                                  blendMode: BlendMode.srcIn,
                                  child: Text(
                                    'Inscription',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.6,
                                        ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(22),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _prenomCtrl,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                    cursorColor: AppTheme.accent,
                                    decoration: _dec(
                                      'Prénom',
                                      Icons.badge_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _nomCtrl,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                    cursorColor: AppTheme.accent,
                                    decoration: _dec(
                                      'Nom',
                                      Icons.person_outline,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _telCtrl,
                                    keyboardType: TextInputType.phone,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                    cursorColor: AppTheme.accent,
                                    decoration: _dec(
                                      'Téléphone',
                                      Icons.phone_outlined,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                    cursorColor: AppTheme.accent,
                                    decoration: _dec(
                                      'Email (optionnel)',
                                      Icons.alternate_email_rounded,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _passCtrl,
                                    obscureText: _obscure1,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                    cursorColor: AppTheme.accent,
                                    decoration:
                                        _dec(
                                          'Mot de passe',
                                          Icons.lock_outline,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                              () => _obscure1 = !_obscure1,
                                            ),
                                            icon: Icon(
                                              _obscure1
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextField(
                                    controller: _pass2Ctrl,
                                    obscureText: _obscure2,
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                    ),
                                    cursorColor: AppTheme.accent,
                                    decoration:
                                        _dec(
                                          'Confirmer le mot de passe',
                                          Icons.lock_outline,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            onPressed: () => setState(
                                              () => _obscure2 = !_obscure2,
                                            ),
                                            icon: Icon(
                                              _obscure2
                                                  ? Icons
                                                        .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 18),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      onPressed: _loading ? null : _submit,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppTheme.accent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                      ),
                                      icon: _loading
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.person_add_alt_1_rounded,
                                              color: Colors.white,
                                            ),
                                      label: const Text(
                                        'Créer mon compte',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () =>
                                              Navigator.of(context).pop(false),
                                    child: Text(
                                      'Déjà un compte ? Se connecter',
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: _loading ? 0.55 : 0.85,
                                        ),
                                        fontWeight: FontWeight.w800,
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
