import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer'; // Pour les logs

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Méthode pour obtenir le token
  Future<String?> getToken() async {
    try {
      // Demande la permission (Surtout pour iOS, mais bonne pratique Android 13+)
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        // Récupération du token
        String? token = await _firebaseMessaging.getToken();
        log("🔥 FCM TOKEN: $token");
        return token;
      } else {
        log("❌ Permission refusée pour les notifs");
        return null;
      }
    } catch (e) {
      log("❌ Erreur récupération FCM Token: $e");
      return null;
    }
  }
}