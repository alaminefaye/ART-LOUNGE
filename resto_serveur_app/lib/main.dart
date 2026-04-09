import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'services/auth_service.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  runApp(const ServeurApp());
}

class ServeurApp extends StatelessWidget {
  const ServeurApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthService())],
      child: MaterialApp(
        title: AppBrand.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AppWrapper(),
      ),
    );
  }
}

class _AppWrapper extends StatefulWidget {
  const _AppWrapper();

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late AnimationController _splashController;
  late Animation<double> _logoScale;
  late Animation<double> _iconLift;

  @override
  void initState() {
    super.initState();
    _splashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeInOut),
    );
    _iconLift = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeInOut),
    );
    _splashController.repeat(reverse: true);
    _checkAuth();
  }

  @override
  void dispose() {
    _splashController.dispose();
    super.dispose();
  }

  Future<void> _checkAuth() async {
    final startedAt = DateTime.now();
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.checkAuth();
    } catch (_) {}

    final elapsed = DateTime.now().difference(startedAt);
    const minSplash = Duration(seconds: 3);
    if (elapsed < minSplash) {
      await Future.delayed(minSplash - elapsed);
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildSplash();
    }

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        // Not authenticated → Login screen
        if (!authService.isAuthenticated) {
          return const LoginScreen();
        }

        // Authenticated → Home (shared tablet, no PIN lock screen)
        return const HomeScreen();
      },
    );
  }

  Widget _buildSplash() {
    final logoWidth = (MediaQuery.sizeOf(context).width * 0.72).clamp(
      220.0,
      360.0,
    );
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: _logoScale,
              child: Image.asset('assets/logo.png', width: logoWidth),
            ),
            const SizedBox(height: 32),
            AnimatedBuilder(
              animation: _splashController,
              builder: (_, __) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SteamLines(
                    t: _splashController.value,
                    color: AppTheme.brandGold,
                  ),
                  const SizedBox(height: 6),
                  Transform.translate(
                    offset: Offset(0, _iconLift.value),
                    child: const Icon(
                      Icons.room_service,
                      size: 50,
                      color: AppTheme.brandGold,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _BouncingDots(
                    t: _splashController.value,
                    color: AppTheme.brandGold,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    AppBrand.appName,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppTheme.brandGold,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BouncingDots extends StatelessWidget {
  final double t;
  final Color color;
  const _BouncingDots({required this.t, required this.color});

  @override
  Widget build(BuildContext context) {
    double dotScale(int index) {
      final phase = (t + index * 0.18) % 1.0;
      final v = (1.0 - (phase - 0.5).abs() * 2.0).clamp(0.0, 1.0);
      return 0.7 + 0.5 * Curves.easeInOut.transform(v);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final s = dotScale(i);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          transform: Matrix4.diagonal3Values(s, s, 1.0),
        );
      }),
    );
  }
}

class _SteamLines extends StatelessWidget {
  final double t;
  final Color color;
  const _SteamLines({required this.t, required this.color});

  @override
  Widget build(BuildContext context) {
    double alpha(int index) {
      final phase = (t + index * 0.22) % 1.0;
      final v = (1.0 - (phase - 0.5).abs() * 2.0).clamp(0.0, 1.0);
      return 0.15 + 0.55 * Curves.easeInOut.transform(v);
    }

    double lineHeight(int index) {
      final phase = (t + index * 0.18) % 1.0;
      final v = (1.0 - (phase - 0.5).abs() * 2.0).clamp(0.0, 1.0);
      return 10 + 12 * Curves.easeInOut.transform(v);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 5,
          height: lineHeight(i),
          decoration: BoxDecoration(
            color: color.withValues(alpha: alpha(i)),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
