import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car225/features/auth/presentation/screens/login_screen.dart';

// Key globale pour la navigation sans context
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class DioClient {
  static Dio? _dio;
  static bool _isLoggingOut =
      false; // Flag pour éviter les boucles de déconnexion

  static Dio get instance {
    if (_dio == null) {
      _dio = Dio(
        BaseOptions(
          //baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
          baseUrl: 'https://car225.com/api/',
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

      // Ajout des intercepteurs
      _dio!.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            // Ajouter le token automatiquement à chaque requête
            final prefs = await SharedPreferences.getInstance();
            final token = prefs.getString('auth_token');
            if (token != null) {
              options.headers["Authorization"] = "Bearer $token";
            }
            return handler.next(options);
          },
          onError: (DioException e, handler) async {
            // Gérer l'erreur 401 (Token expiré ou invalide)
            if (e.response?.statusCode == 401) {
              await _handleLogout();
              // On rejette la requête pour ne pas continuer le flux avec des données erronées
              return handler.reject(e);
            }
            return handler.next(e);
          },
        ),
      );
    }
    return _dio!;
  }

  /// Méthode de déconnexion centralisée avec protection contre les appels multiples
  static Future<void> _handleLogout() async {
    // Si une déconnexion est déjà en cours, on ne fait rien
    if (_isLoggingOut) return;

    _isLoggingOut = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token'); // On vide le token localement

      debugPrint(
        "🚨 Session expirée (401) : Redirection vers Login via Navigator...",
      );

      // ✅ Utilisation du Navigator classique (via GlobalKey) pour la déconnexion
      navigatorKey.currentState!.pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      debugPrint("❌ Erreur lors de la déconnexion automatique : $e");
    } finally {
      // On laisse un petit délai avant de reset le flag pour laisser la navigation se stabiliser
      Future.delayed(const Duration(seconds: 2), () {
        _isLoggingOut = false;
      });
    }
  }
}
