import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:async';
import 'auth_service.dart';
import '../config/api_config.dart';
import 'api_service.dart';
import 'fcm_events.dart';
import '../utils/navigator_key.dart';
import '../screens/orders/orders_screen.dart';
import '../screens/orders/order_detail_screen.dart';

class FCMService {
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final ApiService _apiService = ApiService();
  AuthService? _authService;

  // Canal de notification pour Android
  late AndroidNotificationChannel channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  Future<void> initialize(AuthService authService) async {
    _authService = authService;

    if (_isInitialized) {
      // Même si déjà initialisé, on met à jour le token si l'utilisateur change
      await _saveTokenToDatabase();
      return;
    }

    // 1. Demander la permission
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Utilisateur a accepté les notifications');
    } else {
      debugPrint('Utilisateur a refusé ou n\'a pas accepté les notifications');
      return;
    }

    // 2. Configuration pour Android (High Importance Channel)
    if (!kIsWeb) {
      channel = const AndroidNotificationChannel(
        'dolcevita_order_channel', // id
        'Commandes Dolce Vita', // title
        description: 'Notifications de nouvelles commandes et mises à jour',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('notification_sound'),
        playSound: true,
      );

      flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.createNotificationChannel(channel);

      // Initialisation pour iOS
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      final InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await flutterLocalNotificationsPlugin.initialize(initializationSettings);

      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }

    // 3. Gestionnaire de messages en premier plan
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;

      // Déclencher un événement global pour rafraîchir l'UI
      if (message.data['type'] == 'commande_update' ||
          message.data['type'] == 'new_order' ||
          message.data['type'] == 'payment_validated') {
        FCMEvents.triggerOrderUpdate();
      }

      // Si l'application est au premier plan, on affiche une notification locale
      if (notification != null && !kIsWeb) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              sound: const RawResourceAndroidNotificationSound(
                'notification_sound',
              ),
              playSound: true,
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound:
                  'notification_sound.mp3', // Le fichier doit être dans le bundle
            ),
          ),
        );
      }
    });

    // 4. Gestionnaire d'ouverture de notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notification ouverte: ${message.data}');
      // Déclencher aussi l'update au cas où
      if (message.data['type'] == 'commande_update' ||
          message.data['type'] == 'new_order' ||
          message.data['type'] == 'payment_validated') {
        FCMEvents.triggerOrderUpdate();
      }

      // Naviguer vers l'écran approprié
      final rawId = message.data['order_id'] ?? message.data['commande_id'];
      if (rawId != null) {
        final orderId = int.tryParse(rawId.toString());
        if (orderId != null) {
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => OrderDetailScreen(orderId: orderId),
            ),
          );
        } else {
          navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => const OrdersScreen()),
          );
        }
      } else {
        navigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => const OrdersScreen()),
        );
      }
    });

    // 5. Récupérer et envoyer le token
    await _saveTokenToDatabase();

    // 6. Écouter les changements de token
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _saveTokenToDatabase(token: newToken);
    });

    _isInitialized = true;
  }

  Future<void> _saveTokenToDatabase({String? token}) async {
    // On ne sauvegarde que si l'utilisateur est connecté
    if (_authService == null || !_authService!.isAuthenticated) return;

    // Récupérer le token actuel
    String? fcmToken;

    // Sur iOS, il faut attendre que le token APNS soit disponible avant de demander le token FCM
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken = await _firebaseMessaging.getAPNSToken();
      if (apnsToken == null) {
        debugPrint('⚠️ Token APNS non disponible. Attente de 3 secondes...');
        await Future.delayed(const Duration(seconds: 3));
        apnsToken = await _firebaseMessaging.getAPNSToken();
        if (apnsToken == null) {
          debugPrint('❌ Erreur: Token APNS toujours null sur le simulateur.');
          // Mode Simulation : On génère un faux token pour tester le flux backend
          fcmToken =
              "SIMULATOR_TEST_TOKEN_${DateTime.now().millisecondsSinceEpoch}";
          debugPrint(
            '🔧 MODE SIMULATEUR: Utilisation d\'un token fictif pour tester l\'API.',
          );
        }
      }
    }

    if (fcmToken == null) {
      try {
        fcmToken = token ?? await _firebaseMessaging.getToken();
      } catch (e) {
        debugPrint('❌ Erreur récupération getToken: $e');
        return;
      }
    }

    debugPrint('--- FCM TOKEN DEBUG ---');
    debugPrint('Token récupéré : $fcmToken');

    if (fcmToken != null) {
      try {
        // Envoi au backend
        debugPrint('Envoi du token au serveur...');
        await _apiService.post(
          ApiConfig.updateFcmToken,
          data: {'fcm_token': fcmToken},
        );
        debugPrint('✅ Token FCM mis à jour sur le serveur avec succès');
      } catch (e) {
        debugPrint('❌ Erreur lors de la mise à jour du token FCM: $e');
      }
    } else {
      debugPrint('⚠️ Impossible de récupérer le token FCM (null)');
    }
    debugPrint('-----------------------');
  }

  // Appelé manuellement après le login
  Future<void> updateTokenAfterLogin(AuthService authService) async {
    debugPrint('🔄 Mise à jour du token après connexion...');
    _authService = authService;
    await _saveTokenToDatabase();
  }
}
