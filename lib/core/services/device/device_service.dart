import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Récupère l'ID unique de l'appareil (utilisé pour le login)
  Future<String> getDeviceId() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return androidInfo.id; // ID unique Android
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? 'unknown_ios_id'; // ID unique iOS
    }
    return 'unknown_device_id';
  }

  /// Récupère le nom du modèle (ex: "Samsung S21" ou "iPhone 13")
  Future<String> getDeviceName() async {
    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfo.androidInfo;
      return "${androidInfo.brand} ${androidInfo.model}";
    } else if (Platform.isIOS) {
      final iosInfo = await _deviceInfo.iosInfo;
      return iosInfo.name; // Nom donné au téléphone par l'utilisateur
    }
    return 'Appareil Inconnu';
  }

  // --- C'EST CETTE MÉTHODE QUI MANQUAIT ---
  // Elle retourne une Map avec le modèle, l'ID et la plateforme
  Future<Map<String, String>> getDeviceInfo() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        return {
          'model': "${androidInfo.brand.toUpperCase()} ${androidInfo.model}",
          'id': androidInfo.id,
          'platform': 'Android'
        };
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        return {
          'model': iosInfo.name, // Ex: "iPhone de Jean"
          'id': iosInfo.identifierForVendor ?? '',
          'platform': 'iOS'
        };
      }
    } catch (e) {
      // En cas d'erreur (ex: Web ou autre)
    }

    return {
      'model': 'Appareil Inconnu',
      'id': '',
      'platform': 'Autre'
    };
  }
}