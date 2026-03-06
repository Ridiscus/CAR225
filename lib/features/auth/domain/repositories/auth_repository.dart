import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../booking/data/models/user_stats_model.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/user_model.dart';

// ===========================================================================
// 1️⃣ L'INTERFACE (LE CONTRAT)
// ===========================================================================
abstract class AuthRepository {
  // Authentification de base avec le nouveau modèle de réponse
  //Future<AuthResponseModel> login(String email, String password);
  //Future<AuthResponseModel> register(RegisterRequestModel params);
  Future<void> verifyPasswordOtp(String email, String otpCode);
  // ✅ MODIFIE CETTE LIGNE : elle doit prendre LoginRequestModel
  Future<AuthResponseModel> login(LoginRequestModel params);

  // ✅ MODIFIE AUSSI CELLE-CI pour être cohérent
  Future<AuthResponseModel> register(RegisterRequestModel params);

  // Google Login
  Future<void> loginWithGoogle({
    required String googleId,
    required String idToken,
    required String fcmToken,
    String? email,
    String? fullName,
    String? photoUrl,
  });

  // OTP et Sécurité
  Future<void> verifyOtp(String email, String otpCode);
  Future<void> sendOtp(String email);
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String password,
    required String passwordConfirmation,
  });

  // Profil et Stats
  Future<UserModel> getUserProfile();
  Future<UserModel> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String nomUrgence,
    required String lienParenteUrgence,
    required String contactUrgence,
    String? photoPath,
  });
  Future<void> deactivateAccount(String password);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<void> logout();

  // Statistiques
  Future<UserStatsModel> getUserStats();
  Future<TripDetailsModel> getTripDetails();
}


// ===========================================================================
// 2️⃣ L'IMPLÉMENTATION
// ===========================================================================

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FcmService fcmService;
  final DeviceService deviceService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.fcmService,
    required this.deviceService,
  });


  // 🔐 LOGIN : Corrigé pour accepter l'objet LoginRequestModel
  @override
  Future<AuthResponseModel> login(LoginRequestModel params) async { // <-- Signature corrigée ici
    try {
      // Plus besoin de créer 'request' ici car on reçoit déjà 'params' (le modèle)

      // On appelle directement la data source avec les params reçus
      final AuthResponseModel response = await remoteDataSource.login(params);

      // 💡 LOGIQUE DE SAUVEGARDE DU TOKEN
      if (response.success && !response.requiresOtp && response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.token!);
        print("✅ [REPO] Token sauvegardé : ${response.token}");
      } else if (response.requiresOtp) {
        print("🚨 [REPO] OTP Requis pour : ${response.contact}");
      }

      return response;
    } catch (e) {
      print("❌ [REPO] Erreur Login : $e");
      rethrow;
    }
  }


  // 🟢 NOUVEAU : Implémentation pour le reset de mot de passe
  @override
  Future<void> verifyPasswordOtp(String email, String otpCode) async {
    await remoteDataSource.verifyPasswordOtp(email, otpCode);
  }

  // 🟢 REGISTER : Gère maintenant le flux OTP
  @override
  Future<AuthResponseModel> register(RegisterRequestModel params) async {
    try {
      final AuthResponseModel response = await remoteDataSource.register(params);

      if (response.success && !response.requiresOtp && response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.token!);
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // 🟡 VERIFICATION OTP
  @override
  Future<void> verifyOtp(String contact, String otpCode) async {
    // Note : Si ton API renvoie un token après la vérification OTP,
    // il faudra modifier cette méthode pour le sauvegarder ici aussi.
    await remoteDataSource.verifyOtp(contact, otpCode);
  }

  // 🔵 LOGIN GOOGLE
  @override
  Future<void> loginWithGoogle({
    required String googleId,
    required String idToken,
    required String fcmToken,
    String? email,
    String? fullName,
    String? photoUrl,
  }) async {
    try {
      String deviceName = await deviceService.getDeviceName();

      // Découpage du nom pour matcher le backend
      String prenom = "";
      String nomFamille = "";
      if (fullName != null && fullName.isNotEmpty) {
        List<String> parts = fullName.split(' ');
        prenom = parts.first;
        if (parts.length > 1) nomFamille = parts.sublist(1).join(' ');
      }

      final Map<String, dynamic> body = {
        "email": email ?? "",
        "google_id": googleId,
        "name": nomFamille,
        "prenom": prenom,
        "contact": "",
        "avatar_url": photoUrl ?? "",
        "google_token": idToken,
        "fcm_token": fcmToken,
        "nom_device": deviceName
      };

      final responseData = await remoteDataSource.loginSocial(body);
      final String? token = responseData['token'] ?? responseData['access_token'];

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- MÉTHODES DE PROFIL & STATS ---

  @override
  Future<UserModel> getUserProfile() async => await remoteDataSource.getUserProfile();

  @override
  Future<UserStatsModel> getUserStats() async => await remoteDataSource.getUserStats();

  @override
  Future<TripDetailsModel> getTripDetails() async => await remoteDataSource.getTripDetails();

  @override
  Future<UserModel> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String nomUrgence,
    required String lienParenteUrgence,
    required String contactUrgence,
    String? photoPath,
  }) async {
    return await remoteDataSource.updateUserProfile(
      name: name, prenom: prenom, email: email, contact: contact,
      nomUrgence: nomUrgence, lienParenteUrgence: lienParenteUrgence,
      contactUrgence: contactUrgence, photoPath: photoPath,
    );
  }

  // --- SÉCURITÉ & SESSION ---
  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }

  @override
  Future<void> deactivateAccount(String password) async {
    await remoteDataSource.deactivateAccount(password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  @override
  Future<void> sendOtp(String email) async => await remoteDataSource.sendOtp(email);

  @override
  Future<void> resetPassword({
    required String email, required String otpCode,
    required String password, required String passwordConfirmation,
  }) async {
    await remoteDataSource.resetPassword(email, otpCode, password, passwordConfirmation);
  }

  @override
  Future<void> changePassword({
    required String currentPassword, required String newPassword, required String confirmPassword,
  }) async {
    await remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}