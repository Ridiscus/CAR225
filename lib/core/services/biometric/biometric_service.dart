import 'package:local_auth/local_auth.dart';
import 'package:local_auth/error_codes.dart' as auth_error;
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  static const String _prefKey = 'is_biometric_enabled';

  /// Vérifie si l'appareil a le matériel nécessaire
  Future<bool> isDeviceSupported() async {
    final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
    final bool isDeviceSupported = await _auth.isDeviceSupported();
    return canAuthenticateWithBiometrics || isDeviceSupported;
  }

  /// Tente d'authentifier l'utilisateur (Pop-up Empreinte/FaceID)
  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour continuer',
        options: const AuthenticationOptions(
          stickyAuth: true, // Garde le pop-up si l'app passe en arrière-plan
          biometricOnly: true, // Ne pas autoriser le code PIN, seulement bio
        ),
      );
    } catch (e) {
      print("Erreur biométrie: $e");
      return false;
    }
  }

  /// Sauvegarde la préférence de l'utilisateur
  Future<void> setBiometricEnabled(bool isEnabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, isEnabled);
  }

  /// Récupère la préférence actuelle
  Future<bool> getBiometricStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }
}