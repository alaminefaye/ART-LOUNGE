import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'models/cart.dart';
import 'models/favorites.dart';
import 'screens/menu/menu_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'firebase_options.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service.dart';
import 'utils/navigator_key.dart';
import 'config/app_brand.dart';

// Handler pour les messages en background (doit être en dehors de toute classe)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Sur Android, le plugin gère déjà l'affichage via le canal natif si "notification" est présent.
  // On évite d'initialiser Firebase inutilement si on a juste besoin d'afficher la notif.
  // Si vous avez besoin de traiter des données (data), initialisez Firebase ici.

  // Si le message contient une notification visible, on laisse le système natif gérer
  if (message.notification != null) {
    return;
  }

  // Sinon (message de données uniquement), on initialise Firebase pour traiter
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint("Handling a background data message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }
  // Sur le web : pas d'init Firebase (pas de firebase_options web configuré)

  await initializeDateFormatting('fr_FR', null);
  runApp(const RestoApp());
}

class RestoApp extends StatelessWidget {
  const RestoApp({super.key});

  @override
  Widget build(BuildContext context) {
    const brandGold = Color(0xFFD0A030);
    const brandGoldLight = Color(0xFFE0B040);
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => Cart()),
        ChangeNotifierProvider(create: (_) => Favorites()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: AppBrand.displayName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFFFF6EC),
          colorScheme: ColorScheme.fromSeed(
            seedColor: brandGold,
            brightness: Brightness.light,
            primary: brandGold,
            secondary: brandGoldLight,
            surface: Colors.white,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.black),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  late final AnimationController _splashController;
  late final Animation<double> _logoScale;
  late final Animation<double> _clocheLift;
  late final Animation<double> _clocheTilt;

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
    _clocheLift = Tween<double>(begin: 0.0, end: -10.0).animate(
      CurvedAnimation(parent: _splashController, curve: Curves.easeInOut),
    );
    _clocheTilt = Tween<double>(begin: -0.06, end: 0.06).animate(
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
      debugPrint('Startup: Checking Auth...');
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.checkAuth();
      debugPrint('Startup: Auth Checked. Authenticated: ${authService.isAuthenticated}');

      // Initialiser le service FCM uniquement sur mobile (Android/iOS)
      if (authService.isAuthenticated && 
         !kIsWeb && 
         (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
        debugPrint('Startup: Initializing FCM...');
        await FCMService().initialize(authService);
        debugPrint('Startup: FCM Initialized');
      }
    } catch (e) {
      debugPrint('Startup Error: $e');
    } finally {
      final elapsed = DateTime.now().difference(startedAt);
      const minSplash = Duration(seconds: 5);
      if (elapsed < minSplash) {
        await Future.delayed(minSplash - elapsed);
      }
      
      if (mounted) {
        debugPrint('Startup: Dismissing Splash Screen');
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      final logoWidth = (MediaQuery.sizeOf(context).width * 0.72).clamp(
        260.0,
        420.0,
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
              const SizedBox(height: 28),
              AnimatedBuilder(
                animation: _splashController,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SteamLines(
                        t: _splashController.value,
                        color: const Color(0xFFD0A030),
                      ),
                      const SizedBox(height: 6),
                      Transform.translate(
                        offset: Offset(0, _clocheLift.value),
                        child: Transform.rotate(
                          angle: _clocheTilt.value,
                          child: const Icon(
                            Icons.room_service,
                            size: 54,
                            color: Color(0xFFD0A030),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _BouncingDots(
                        t: _splashController.value,
                        color: const Color(0xFFD0A030),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthService>(
      builder: (context, authService, _) {
        if (authService.isAuthenticated) {
          final user = authService.currentUser;
          if (user != null &&
              (user.hasRole('admin') ||
                  user.hasRole('manager') ||
                  user.hasRole('serveur') ||
                  user.hasRole('caissier'))) {
            return const DashboardScreen();
          }
          return const MenuScreen();
        }
        // Invité : accès direct au menu / accueil (pas d’obligation de connexion)
        return const MenuScreen();
      },
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

    double height(int index) {
      final phase = (t + index * 0.18) % 1.0;
      final v = (1.0 - (phase - 0.5).abs() * 2.0).clamp(0.0, 1.0);
      return 10 + 12 * Curves.easeInOut.transform(v);
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (i) {
        final a = alpha(i);
        final h = height(i);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: 5,
          height: h,
          decoration: BoxDecoration(
            color: color.withValues(alpha: a),
            borderRadius: BorderRadius.circular(10),
          ),
        );
      }),
    );
  }
}
