import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationPrefs {
  static const String _key = 'user_wants_notifications';

  /// Vérifie si l'utilisateur a activé l'option ET si le système l'autorise
  Future<bool> getNotificationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    // 1. On regarde si l'utilisateur a dit OUI dans l'app
    bool userPref = prefs.getBool(_key) ?? true; // Par défaut true

    // 2. On regarde si le SYSTÈME (Android/iOS) est d'accord
    var status = await Permission.notification.status;

    // Si l'utilisateur veut les notifs MAIS que le système bloque, on considère c'est false
    if (userPref && (status.isDenied || status.isPermanentlyDenied)) {
      return false;
    }

    return userPref;
  }

  /// Tente d'activer ou désactiver
  Future<bool> setNotificationStatus(bool enable) async {
    final prefs = await SharedPreferences.getInstance();

    if (enable) {
      // CAS : L'utilisateur veut ACTIVER
      var status = await Permission.notification.request();

      if (status.isGranted) {
        // Le système a dit OUI, on sauvegarde la préférence
        await prefs.setBool(_key, true);
        return true;
      } else if (status.isPermanentlyDenied) {
        // Le système a dit NON définitif -> On doit ouvrir les paramètres
        await openAppSettings();
        return false; // On reste à false en attendant qu'il revienne
      }
      return false;
    } else {
      // CAS : L'utilisateur veut DÉSACTIVER
      // On ne peut pas retirer la permission système via code,
      // mais on enregistre que l'utilisateur ne veut plus rien recevoir.
      await prefs.setBool(_key, false);
      return false;
    }
  }
}