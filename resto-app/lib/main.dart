import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/auth_service.dart';
import 'models/cart.dart';
import 'models/favorites.dart';
import 'screens/auth/login_screen.dart';
import 'screens/menu/menu_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'firebase_options.dart';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'services/fcm_service.dart';
import 'utils/navigator_key.dart';

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
  // Initialiser Firebase avec les options explicites
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enregistrer le handler de background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialiser les données de locale pour le formatage de date
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
        title: 'Resto App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF1E1E1E),
          colorScheme: const ColorScheme.dark(
            primary: brandGold,
            secondary: brandGoldLight,
            surface: Color(0xFF252525),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            iconTheme: IconThemeData(color: Colors.white),
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

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.checkAuth();

    // Initialiser le service FCM une fois l'auth vérifiée
    if (authService.isAuthenticated) {
      await FCMService().initialize(authService);
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
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
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
