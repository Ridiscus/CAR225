/*import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:io';

// ⚠️ Fonction Top-Level (en dehors de la classe) pour gérer les notifs quand l'app est tuée
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print("Message reçu en background: ${message.messageId}");
}

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  // Initialisation complète
  Future<void> init() async {
    // 1. Demander la permission à l'utilisateur (C'est ICI que la pop-up système apparaît)
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permission accordée');

      // 2. Récupérer le Token FCM (Utile pour tester depuis la console Firebase)
      String? token = await _firebaseMessaging.getToken();
      print("🔥 FCM TOKEN: $token"); // COPIE CE TOKEN POUR TESTER

      // 3. Initialiser les notifications locales (pour l'affichage flottant)
      await _initLocalNotifications();

      // 4. Écouter les messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // En premier plan (App ouverte)
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print("Message reçu en premier plan: ${message.notification?.title}");
        if (message.notification != null) {
          _showLocalNotification(message);
        }
      });

    } else {
      print('❌ Permission refusée');
    }
  }

  // Configuration des notifications locales (Android & iOS)
  Future<void> _initLocalNotifications() async {
    // Android config
    //const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // On pointe vers le fichier qu'on vient de mettre dans le dossier drawable (sans l'extension .png)
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/launcher_icon');

    // iOS config
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings();

    const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings
    );

    // Création du canal Android (Indispensable pour le "Heads-up" / Flottant)
    if (Platform.isAndroid) {
      await _localNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(
        const AndroidNotificationChannel(
          'high_importance_channel', // Id doit matcher celui du Manifest
          'Notifications Importantes', // Nom visible dans les paramètres
          description: 'Ce canal est utilisé pour les alertes importantes.',
          importance: Importance.max, // ✅ C'est ça qui fait flotter la notif !
        ),
      );
    }

    await _localNotificationsPlugin.initialize(initSettings);
  }

  // Fonction pour afficher la notification flottante manuellement
  Future<void> _showLocalNotification(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null) {
      await _localNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // ID du canal
            'Notifications Importantes',
            channelDescription: 'Canal pour les notifications urgentes',
            icon: 'ic_notification',
            importance: Importance.max, // ✅ Priorité MAX pour l'affichage flottant
            priority: Priority.high,
            playSound: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    }
  }
}*/






import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../features/driver/presentation/providers/driver_provider.dart';

// Importe ta GlobalKey définie dans main.dart
import '../../../features/home/presentation/screens/notification_screen.dart';
import '../../../main.dart';


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
        
        // Rafraîchir les données si c'est un nouveau voyage (Chauffeur)
        if (message.data['type'] == 'voyage_assigned') {
          final context = navigatorKey.currentContext;
          if (context != null) {
            try {
              final driverProvider = Provider.of<DriverProvider>(context, listen: false);
              driverProvider.loadDashboard();
            } catch (e) {
              print("Erreur refresh driver provider: $e");
            }
          }
        }
      }
    });

    // CAS 2 : L'app est en background et l'utilisateur clique sur la notif
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print("Notification cliquée (Background) !");
      _handleMessageNavigation(message);
    });

    // CAS 3 : L'app est complètement fermée (Terminated) et l'utilisateur clique
    // On vérifie s'il y a un message initial au démarrage
    final RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print("Notification cliquée (App fermée) !");
      // On attend un peu que l'app se construise
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
      // ✅ C'EST ICI QUE SE GÈRE LE CLIC EN FOREGROUND (Local Notif)
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          // On reconstruit un objet "similaire" à RemoteMessage pour centraliser la logique
          // Note : Le payload doit être une string JSON envoyée lors de la création de la notif locale
          try {
            final data = jsonDecode(response.payload!);
            // On navigue
            navigatorKey.currentState?.push(
              MaterialPageRoute(builder: (_) => const NotificationScreen()),
            );
          } catch (e) {
            print("Erreur payload: $e");
          }
        }
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
      // On encode les données (data) en JSON pour les passer au payload du clic local
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
        payload: payload, // 👈 IMPORTANT : On passe les données ici
      );
    }
  }

  // 🚀 FONCTION CENTRALE DE NAVIGATION
  void _handleMessageNavigation(RemoteMessage message) {
    // Si tu veux aller vers un détail précis, tu peux utiliser message.data['id']
    // Pour l'instant, on redirige vers la liste des notifications
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.push(
        MaterialPageRoute(builder: (_) => const NotificationScreen()),
      );
    }
  }
}