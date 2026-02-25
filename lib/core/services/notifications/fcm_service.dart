import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:developer'; // Pour les logs

class FcmService {
  // On utilise un getter pour éviter d'appeler .instance dès l'instanciation de la classe
  // surtout si Firebase n'est pas encore initialisé.
  FirebaseMessaging get _firebaseMessaging {
    try {
      return FirebaseMessaging.instance;
    } catch (e) {
      log("❌ Firebase non initialisé: $e");
      rethrow;
    }
  }

  // Méthode pour obtenir le token
  Future<String?> getToken() async {
    try {
      // Vérifie si Firebase est initialisé avant d'utiliser messaging
      // (Petit hack simple pour éviter le crash immédiat)
      final firebaseMessaging = _firebaseMessaging;

      // Demande la permission
      NotificationSettings settings = await firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? token = await firebaseMessaging.getToken();
        log("🔥 FCM TOKEN: $token");
        return token;
      } else {
        log("❌ Permission refusée pour les notifs");
        return null;
      }
    } catch (e) {
      log(
        "❌ Erreur récupération FCM Token (Firebase peut-être non initialisé): $e",
      );
      return null;
    }
  }
}
