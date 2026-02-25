import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Pour récupérer le fcm_token frais

import '../../../booking/data/models/notification_model.dart';

class NotificationRepository {
  final Dio dio;

  NotificationRepository({required this.dio});

  // Helper pour récupérer le token Auth
  Future<String> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token') ??
        prefs.getString('access_token') ??
        prefs.getString('token');
    if (token == null) throw Exception("Non connecté");
    return token;
  }

  // Helper pour récupérer le FCM Token (nécessaire pour tes API POST)
  Future<String?> _getFcmToken() async {
    // Idéalement, Firebase est déjà init. Sinon, gère le cas null.
    return await FirebaseMessaging.instance.getToken();
  }

  Future<List<NotificationModel>> getNotifications() async {
    final token = await _getAuthToken();
    dio.options.headers["Authorization"] = "Bearer $token";

    final response = await dio.get('user/notifications');

    if (response.statusCode == 200 && response.data['success'] == true) {
      final List<dynamic> list = response.data['data']['data'];
      return list.map((e) => NotificationModel.fromJson(e)).toList();
    }
    throw Exception("Erreur chargement notifications");
  }

  Future<void> markAsRead(String id) async {
    final token = await _getAuthToken();
    final fcmToken = await _getFcmToken();

    dio.options.headers["Authorization"] = "Bearer $token";
    await dio.post('user/notifications/$id/mark-as-read', data: {
      "fcm_token": fcmToken
    });
  }

  Future<void> markAllAsRead() async {
    final token = await _getAuthToken();
    final fcmToken = await _getFcmToken();

    dio.options.headers["Authorization"] = "Bearer $token";
    await dio.post('user/notifications/mark-all-as-read', data: {
      "fcm_token": fcmToken
    });
  }

  Future<void> deleteNotification(String id) async {
    final token = await _getAuthToken();
    final fcmToken = await _getFcmToken();

    dio.options.headers["Authorization"] = "Bearer $token";
    // Attention: DELETE accepte parfois des body, mais c'est moins standard.
    // Dio le gère via 'data'.
    await dio.delete('user/notifications/$id', data: {
      "fcm_token": fcmToken
    });
  }



  // Dans NotificationRepository
  Future<int> getUnreadCount() async {
    final token = await _getAuthToken(); // Ta méthode existante
    dio.options.headers["Authorization"] = "Bearer $token";

    try {
      final response = await dio.get('user/notifications/unread-count');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // On s'assure que c'est bien un int
        return response.data['unread_count'] as int;
      }
      return 0;
    } catch (e) {
      print("Erreur unread count: $e");
      return 0; // En cas d'erreur, on affiche 0 par sécurité
    }
  }



}