import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../booking/data/models/user_stats_model.dart';
import '../../../hostess/models/hostess_profile_model.dart';
import '../../../hostess/models/sale_model.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/unified_login_request_model.dart';
import '../../data/models/user_model.dart';

// ===========================================================================
// 1️⃣ L'INTERFACE (LE CONTRAT)
// ===========================================================================
abstract class AuthRepository {
  Future<void> verifyPasswordOtp(String email, String otpCode);
  // ✅ MODIFIE CETTE LIGNE : elle doit prendre LoginRequestModel
  Future<AuthResponseModel> login(LoginRequestModel params);

  Future<AuthResponseModel> unifiedLogin(UnifiedLoginRequestModel params);
  Future<void> logout();
  Future<HostessProfileModel> getHostessProfile();
  Future<HostessProfileModel> updateProfile(Map<String, dynamic> data);
  Future<void> changePasswordHotesse(Map<String, dynamic> data);
  Future<List<HostessSaleModel>> getSalesHistory(DateTime? startDate, DateTime? endDate);
  Future<Map<String, dynamic>> searchTickets({
    required String dateDepart,
    required String pointDepart,
    required String pointArrive,
  });
  // 🟢 NOUVELLE MÉTHODE
  Future<Map<String, dynamic>> bookTicket(Map<String, dynamic> payload);
  // À ajouter dans abstract class AuthRepository
  Future<Map<String, dynamic>> getHostessDashboard();

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
  Future<void> logouut();

  // Statistiques
  Future<UserStatsModel> getUserStats();
  Future<TripDetailsModel> getTripDetails();

  // Nouvelles méthodes pour les convois
  Future<List<dynamic>> getConvoiCompagnies();
  Future<List<dynamic>> getConvoiGares(int compagnieId);
  Future<List<dynamic>> getConvoiItineraires(int compagnieId);

  Future<Map<String, dynamic>> getMyConvois({String? statut, int page = 1});
  Future<Map<String, dynamic>> getConvoiDetails(int convoiId);

  Future<Map<String, dynamic>> accepterMontantConvoi(int convoiId);
  Future<Map<String, dynamic>> refuserMontantConvoi(int convoiId);
  Future<Map<String, dynamic>> enregistrerPassagers(int convoiId, Map<String, dynamic> data);

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


  @override
  Future<List<dynamic>> getConvoiCompagnies() async {
    return await remoteDataSource.getConvoiCompagnies();
  }

  @override
  Future<List<dynamic>> getConvoiGares(int compagnieId) async {
    return await remoteDataSource.getConvoiGares(compagnieId);
  }

  @override
  Future<List<dynamic>> getConvoiItineraires(int compagnieId) async {
    return await remoteDataSource.getConvoiItineraires(compagnieId);
  }


  @override
  Future<AuthResponseModel> unifiedLogin(UnifiedLoginRequestModel params) async {
    try {
      final AuthResponseModel response = await remoteDataSource.unifiedLogin(params);

      if (response.success && response.token != null) {
        final prefs = await SharedPreferences.getInstance();

        await prefs.setString('auth_token', response.token!);

        // 🟢 ON SAUVEGARDE LE VRAI RÔLE DE L'API
        // Si response.role existe, on le prend, sinon on met 'user' par défaut
        await prefs.setString('user_type', response.role ?? 'user');

        print("✅ [REPO] Token et Rôle (${response.role}) sauvegardés !");
      }

      return response;
    } catch (e) {
      print("❌ [REPO] Erreur Unified Login : $e");
      rethrow;
    }
  }


  @override
  Future<void> logouut() async {
    try {
      // 1. Appeler l'API pour invalider le token côté serveur
      await remoteDataSource.logoutHotesse();

      // 2. Nettoyer les données locales
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_type');

      // Optionnel : Si tu stockes d'autres infos (profil, etc.), supprime-les ici
      // await prefs.remove('user_profile');

      print("✅ [REPO] Token et rôle supprimés localement.");

    } catch (e) {
      print("❌ [REPO] Erreur lors de la déconnexion : $e");
      rethrow;
    }
  }

  @override
  Future<HostessProfileModel> getHostessProfile() async {
    try {
      // On délègue simplement le travail au RemoteDataSource
      return await remoteDataSource.getHostessProfile();
    } catch (e) {
      print("❌ [REPO ERROR] Erreur dans AuthRepositoryImpl.getHostessProfile : $e");
      rethrow;
    }
  }

  @override
  Future<HostessProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      // Tu peux ajouter des vérifications réseau ici (InternetConnectionChecker) si tu en as
      final updatedProfile = await remoteDataSource.updateProfile(data);
      return updatedProfile;
    } catch (e) {
      // Gère tes exceptions personnalisées ici si nécessaire
      rethrow;
    }
  }

  @override
  Future<void> changePasswordHotesse(Map<String, dynamic> data) async {
    try {
      await remoteDataSource.changePasswordHotesse(data);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<HostessSaleModel>> getSalesHistory(DateTime? startDate, DateTime? endDate) async {
    try {
      // On délègue simplement l'appel au Remote Data Source
      return await remoteDataSource.getSalesHistory(startDate, endDate);
    } catch (e) {
      rethrow;
    }
  }

  // 👇 L'IMPLÉMENTATION MANQUANTE À AJOUTER ICI :
  @override
  Future<Map<String, dynamic>> searchTickets({
    required String dateDepart,
    required String pointDepart,
    required String pointArrive,
  }) async {
    return await remoteDataSource.searchTickets(
      dateDepart: dateDepart,
      pointDepart: pointDepart,
      pointArrive: pointArrive,
    );
  }

  @override
  Future<Map<String, dynamic>> bookTicket(Map<String, dynamic> payload) async {
    // Tu peux ajouter de la logique ici plus tard si besoin (sauvegarde locale, etc.)
    return await remoteDataSource.bookTicket(payload);
  }

  @override
  Future<Map<String, dynamic>> getHostessDashboard() async {
    try {
      // On délègue simplement l'appel à la source de données (RemoteDataSource)
      return await remoteDataSource.getHostessDashboard();
    } catch (e) {
      // On fait remonter l'erreur pour que l'UI (le HomeScreen) puisse l'attraper
      rethrow;
    }
  }




  // 🔐 LOGIN : Corrigé pour accepter l'objet LoginRequestModel
  @override
  Future<AuthResponseModel> login(LoginRequestModel params) async {
    // <-- Signature corrigée ici
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
      final AuthResponseModel response = await remoteDataSource.register(
        params,
      );

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
        "nom_device": deviceName,
      };

      final responseData = await remoteDataSource.loginSocial(body);
      final String? token =
          responseData['token'] ?? responseData['access_token'];

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
  Future<UserModel> getUserProfile() async =>
      await remoteDataSource.getUserProfile();

  @override
  Future<UserStatsModel> getUserStats() async =>
      await remoteDataSource.getUserStats();

  @override
  Future<TripDetailsModel> getTripDetails() async =>
      await remoteDataSource.getTripDetails();

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
      name: name,
      prenom: prenom,
      email: email,
      contact: contact,
      nomUrgence: nomUrgence,
      lienParenteUrgence: lienParenteUrgence,
      contactUrgence: contactUrgence,
      photoPath: photoPath,
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
  Future<void> sendOtp(String email) async =>
      await remoteDataSource.sendOtp(email);

  @override
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String password,
    required String passwordConfirmation,
  }) async {
    await remoteDataSource.resetPassword(
      email,
      otpCode,
      password,
      passwordConfirmation,
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Future<Map<String, dynamic>> getMyConvois({String? statut, int page = 1}) async {
    try {
      return await remoteDataSource.getMyConvois(statut: statut, page: page);
    } catch (e) {
      print("❌ REPOSITORY ERROR getMyConvois: $e");
      rethrow;
    }
  }

  // Dans AuthRepositoryImpl (tout en bas)
  @override
  Future<Map<String, dynamic>> getConvoiDetails(int convoiId) async {
    return await remoteDataSource.getConvoiDetails(convoiId);
  }

  @override
  Future<Map<String, dynamic>> accepterMontantConvoi(int convoiId) async {
    try {
      return await remoteDataSource.accepterMontantConvoi(convoiId);
    } catch (e) {
      print("❌ REPOSITORY ERROR accepterMontantConvoi: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> refuserMontantConvoi(int convoiId) async {
    try {
      return await remoteDataSource.refuserMontantConvoi(convoiId);
    } catch (e) {
      print("❌ REPOSITORY ERROR refuserMontantConvoi: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> enregistrerPassagers(int convoiId, Map<String, dynamic> data) async {
    try {
      return await remoteDataSource.enregistrerPassagers(convoiId, data);
    } catch (e) {
      print("❌ REPOSITORY ERROR enregistrerPassagers: $e");
      rethrow;
    }
  }



}
