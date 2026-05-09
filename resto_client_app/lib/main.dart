import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'core/api_client.dart';
import 'services/menu_service.dart';
import 'services/order_service.dart';
import 'state/auth_state.dart';
import 'state/cart_state.dart';
import 'state/favorites_state.dart';
import 'theme/app_theme.dart';
import 'ui/home_screen.dart';
import 'widgets/cart_add_feedback.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final apiClient = ApiClient();
  runApp(ArtRestoClientApp(apiClient: apiClient));
}

class ArtRestoClientApp extends StatefulWidget {
  const ArtRestoClientApp({super.key, required this.apiClient});

  final ApiClient apiClient;

  @override
  State<ArtRestoClientApp> createState() => _ArtRestoClientAppState();
}

class _ArtRestoClientAppState extends State<ArtRestoClientApp> {
  /// Cible l’entrée Panier pour l’animation « vol depuis le plat » sur toutes les routes.
  final GlobalKey _cartNavTargetKey = GlobalKey(debugLabel: 'cartNavTarget');

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider.value(value: widget.apiClient),
        ChangeNotifierProvider(
          create: (_) => AuthState(widget.apiClient)..init(),
        ),
        ChangeNotifierProvider(create: (_) => CartState()),
        ChangeNotifierProvider(create: (_) => FavoritesState()..init()),
        Provider(create: (_) => MenuService(widget.apiClient)),
        Provider(create: (_) => OrderService(widget.apiClient)),
      ],
      child: MaterialApp(
        title: 'ART MOMENT',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) => CartFlightTargetScope(
          cartTargetKey: _cartNavTargetKey,
          child: child ?? const SizedBox.shrink(),
        ),
        home: SplashScreen(cartNavTargetKey: _cartNavTargetKey),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key, required this.cartNavTargetKey});

  final GlobalKey cartNavTargetKey;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _introCtrl;
  late final AnimationController _loopCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _fadeIn;
  late final Animation<double> _logoGlow;

  @override
  void initState() {
    super.initState();
    _introCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loopCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );

    _logoScale = CurvedAnimation(parent: _introCtrl, curve: Curves.elasticOut);
    _fadeIn = CurvedAnimation(parent: _introCtrl, curve: Curves.easeOut);
    _logoGlow = CurvedAnimation(parent: _loopCtrl, curve: Curves.easeInOut);

    _introCtrl.forward();
    _loopCtrl.repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 5000), () {
        if (!mounted) return;
        Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (_) =>
                HomeScreen(cartNavTargetKey: widget.cartNavTargetKey),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _introCtrl.dispose();
    _loopCtrl.dispose();
    super.dispose();
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
          child: Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([_introCtrl, _loopCtrl]),
              builder: (context, _) {
                final t = _loopCtrl.value;
                final floatY = math.sin(t * math.pi * 2) * 10;
                final rotate = math.sin(t * math.pi * 2) * 0.06;
                final blob1 = math.sin(t * math.pi * 2) * 18;
                final blob2 = math.cos(t * math.pi * 2) * 14;
                final shimmer = (t * 2) % 1.0;
                final orbit = t * math.pi * 2;
                return Opacity(
                  opacity: _fadeIn.value,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Positioned(
                        top: 90 + blob1,
                        left: 40 + blob2,
                        child: _GlowBlob(
                          size: 180,
                          color: AppTheme.accent.withValues(alpha: 0.22),
                        ),
                      ),
                      Positioned(
                        bottom: 120 + blob2,
                        right: 36 + blob1,
                        child: _GlowBlob(
                          size: 220,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              _OrbitingIcon(
                                icon: Icons.restaurant_menu_rounded,
                                angle: orbit + 0.2,
                                radius: 98,
                                color: AppTheme.accent,
                              ),
                              _OrbitingIcon(
                                icon: Icons.local_bar_rounded,
                                angle: orbit + 2.2,
                                radius: 92,
                                color: Colors.white,
                              ),
                              _OrbitingIcon(
                                icon: Icons.local_cafe_rounded,
                                angle: orbit + 4.1,
                                radius: 96,
                                color: Colors.white,
                              ),
                              Transform.translate(
                                offset: Offset(0, floatY),
                                child: Transform.rotate(
                                  angle: rotate,
                                  child: CustomPaint(
                                    size: const Size(170, 170),
                                    painter: _SteamPainter(t: t),
                                  ),
                                ),
                              ),
                              ScaleTransition(
                                scale: _logoScale,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 136,
                                      height: 136,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withValues(
                                          alpha: 0.08,
                                        ),
                                        border: Border.all(
                                          color: AppTheme.accent.withValues(
                                            alpha:
                                                0.30 + (_logoGlow.value * 0.25),
                                          ),
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppTheme.accent.withValues(
                                              alpha:
                                                  0.16 + _logoGlow.value * 0.18,
                                            ),
                                            blurRadius:
                                                36 + (_logoGlow.value * 26),
                                            spreadRadius:
                                                2 + (_logoGlow.value * 2),
                                            offset: const Offset(0, 14),
                                          ),
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.24,
                                            ),
                                            blurRadius: 26,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      width: 110,
                                      height: 110,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: ClipOval(
                                        child: Image.asset(
                                          'logo.jpeg',
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, _, _) =>
                                              Image.asset(
                                                'assets/logo.png',
                                                fit: BoxFit.contain,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          ShaderMask(
                            shaderCallback: (rect) {
                              final dx = rect.width * (shimmer * 1.6 - 0.3);
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
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.0,
                                  ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Restaurant • Commande • Fidélité',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: AppTheme.textMuted,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: 46,
                            height: 46,
                            child: CircularProgressIndicator(
                              color: AppTheme.accent,
                              strokeWidth: 3,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
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

class _OrbitingIcon extends StatelessWidget {
  const _OrbitingIcon({
    required this.icon,
    required this.angle,
    required this.radius,
    required this.color,
  });

  final IconData icon;
  final double angle;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final x = math.cos(angle) * radius;
    final y = math.sin(angle) * radius * 0.65;
    final pulse = (math.sin(angle * 2) * 0.08) + 1.0;
    final opacity = (0.70 + (math.sin(angle + 1.1) * 0.22)).clamp(0.35, 0.95);
    return Transform.translate(
      offset: Offset(x, y),
      child: Transform.scale(
        scale: pulse,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: color.withValues(alpha: opacity.toDouble()),
            ),
          ),
        ),
      ),
    );
  }
}

class _SteamPainter extends CustomPainter {
  const _SteamPainter({required this.t});

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseY = center.dy - 10;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;

    for (var i = 0; i < 3; i++) {
      final phase = t * math.pi * 2 + i * 1.6;
      final x = center.dx + (i - 1) * 18;
      final rise = (math.sin(phase) * 8) - 18;
      final alpha = (0.35 + 0.35 * math.sin(phase + 0.8))
          .clamp(0.08, 0.55)
          .toDouble();

      paint.color = Colors.white.withValues(alpha: alpha);
      final path = Path()
        ..moveTo(x, baseY + 34)
        ..cubicTo(
          x - 10,
          baseY + 20 + rise,
          x + 10,
          baseY + 6 + rise,
          x,
          baseY - 12 + rise,
        );
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SteamPainter oldDelegate) => oldDelegate.t != t;
}

class _SlideGradient extends GradientTransform {
  const _SlideGradient({required this.dx});

  final double dx;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}
