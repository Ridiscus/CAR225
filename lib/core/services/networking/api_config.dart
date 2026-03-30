import 'package:flutter/foundation.dart'; // Obligatoire pour utiliser kDebugMode

class ApiConfig {
  // 🔘 L'INTERRUPTEUR MAGIQUE
  // true = Tu utilises Ngrok (Tests en cours)
  // false = Tu utilises la Prod (car225.com)
  static const bool useLocalInDebug = false;

  // ==============================================================================
  // ⚙️ CONFIGURATION DES URLS
  // ==============================================================================

  // 🔴 PRODUCTION (La vraie application)
  static const String _prodUrl = 'https://car225.com/api/';
  static const String _prodSocketUrl = 'https://car225.com'; // Au cas où tu utilises des WebSockets (Pusher, etc.)

  // 🟢 LOCAL / NGROK (Pour tes tests)
  static const String _localUrl = 'https://jingly-lindy-unminding.ngrok-free.dev/api/';
  static const String _localSocketUrl = 'https://jingly-lindy-unminding.ngrok-free.dev';

  // ==============================================================================
  // 🧠 LOGIQUE INTELLIGENTE
  // ==============================================================================

  static String get baseUrl {
    // Si on est en mode Debug (lancé depuis l'IDE) ET que l'interrupteur est sur true
    if (kDebugMode && useLocalInDebug) {
      return _localUrl;
    } else {
      // Sinon (App compilée en Release OU interrupteur sur false), on prend la Prod
      return _prodUrl;
    }
  }

  static String get socketUrl {
    if (kDebugMode && useLocalInDebug) {
      return _localSocketUrl;
    } else {
      return _prodSocketUrl;
    }
  }
}