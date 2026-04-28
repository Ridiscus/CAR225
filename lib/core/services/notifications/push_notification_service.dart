import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🟢 NOUVEL IMPORT

// --- TES IMPORTS D'ÉCRANS ---
import '../../../features/driver/presentation/screens/driver_notification_screen.dart';
import '../../../features/home/presentation/screens/notification_screen.dart'; // Particulier
// 👇 A AJOUTER : Importe tes écrans spécifiques
// import '../../../features/driver/presentation/screens/driver_notification_screen.dart';
// import '../../../features/hostess/presentation/screens/hostess_notification_screen.dart';
// import '../../../features/agent/presentation/screens/agent_notification_screen.dart';

import '../../../main.dart'; // Contient navigatorKey

// Handler Background (Doit rester en top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Message background: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    // 1. Permissions
    await _firebaseMessaging.requestPermission(
      alert: true, badge: true, sound: true, provisional: false,
    );

    // 2. Init Local Notifications
    await _initLocalNotifications();

    // 3. Listeners Firebase
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // CAS 1 : L'app est ouverte (Foreground)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // CAS 2 : L'app est en background et l'utilisateur clique sur la notif
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification cliquée (Background) !");
      _handleMessageNavigation(message);
    });

    // CAS 3 : L'app est complètement fermée (Terminated) et l'utilisateur clique
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print("Notification cliquée (App fermée) !");
      Future.delayed(const Duration(seconds: 1), () {
        _handleMessageNavigation(initialMessage);
      });
    }
  }

  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings
    );

    await _localNotificationsPlugin.initialize(
      initSettings,
      // ✅ GESTION DU CLIC EN FOREGROUND (Local Notif)
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        Map<String, dynamic>? payloadData;
        if (response.payload != null) {
          try {
            payloadData = jsonDecode(response.payload!);
          } catch (e) {
            print("Erreur parsing payload: $e");
          }
        }
        // 🟢 On appelle la fonction de routage
        _routeBasedOnRole(payloadData);
      },
    );

    // Channel Android
    if (Platform.isAndroid) {
      await _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel',
          'Notifications Importantes',
          importance: Importance.max,
        ),
      );
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      String payload = jsonEncode(message.data);

      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'Notifications Importantes',
            icon: '@mipmap/launcher_icon',
            importance: Importance.max,
            priority: Priority.high,
          ),
        ),
        payload: payload,
      );
    }
  }

  // 🚀 INTERCEPTEUR POUR FIREBASE (Background & Terminated)
  void _handleMessageNavigation(RemoteMessage message) {
    _routeBasedOnRole(message.data);
  }

  // 🟢 LA NOUVELLE FONCTION CENTRALE DE NAVIGATION DYNAMIQUE
  Future<void> _routeBasedOnRole(Map<String, dynamic>? data) async {
    if (navigatorKey.currentState == null) return;

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');

    Widget destinationScreen;

    if (role == 'driver' || role == 'chauffeur') {
      // 👇 Remplace par ton vrai widget d'écran chauffeur
      // destinationScreen = const DriverNotificationScreen();
      destinationScreen = const DriverNotificationScreen(); // Par défaut temporaire
    } else if (role == 'hotesse' || role == 'hôtesse') {
      // 👇 Remplace par ton vrai widget d'écran hôtesse
      // destinationScreen = const HostessNotificationScreen();
      destinationScreen = const NotificationScreen(); // Par défaut temporaire
    } else if (role == 'agent') {
      // 👇 Remplace par ton vrai widget d'écran agent
      // destinationScreen = const AgentNotificationScreen();
      destinationScreen = const NotificationScreen(); // Par défaut temporaire
    } else {
      // Particulier classique
      destinationScreen = const NotificationScreen();
    }

    // On utilise le navigator global pour pousser l'écran
    navigatorKey.currentState!.push(
      MaterialPageRoute(builder: (_) => destinationScreen),
    );
  }

}