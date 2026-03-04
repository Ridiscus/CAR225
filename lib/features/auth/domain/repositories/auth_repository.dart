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
/*abstract class AuthRepository {

  //Future<void> login(String email, String password);

  Future<AuthResponseModel> login(LoginRequestModel params);
  Future<AuthResponseModel> register(RegisterRequestModel params);
  Future<void> verifyOtp(String email, String otpCode); // Méthode pour valider le code


  // Dans abstract class AuthRepository
  Future<void> loginWithGoogle({
    required String googleId,   // <--- AJOUTE ÇA
    required String idToken,
    required String fcmToken,
    String? email,
    String? fullName,           // On renome 'name' en 'fullName' pour éviter la confusion avec le 'name' (nom de famille) du backend
    String? photoUrl,
  });

  // ✅ AJOUTE CECI :
  Future<void> deactivateAccount(String password);



  Future<void> logout();
  Future<UserModel> getUserProfile();


  // ✅ REGISTER : On retire 'adresse'
  /*Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String contact,
    String? photoPath,
  });*/

  // ✅ UPDATE PROFIL : On retire 'adresse' et on ajoute les contacts d'urgence
  Future<UserModel> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String nomUrgence,     // Nouveau
    required String lienParenteUrgence, // <-- Remplacé
    required String contactUrgence, // Nouveau
    String? photoPath,
  });


  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  // --- PARTIE MOT DE PASSE OUBLIÉ ---
  Future<void> sendOtp(String email);

  // 👇 C'EST CETTE LIGNE QUI MANQUAIT 👇
  Future<void> verifyOtp(String email, String otpCode);

  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String password,
    required String passwordConfirmation,
  });

  // 🟢 AJOUTE CES DEUX LIGNES ICI :
  Future<UserStatsModel> getUserStats();
  Future<TripDetailsModel> getTripDetails();

}*/



abstract class AuthRepository {
  // Authentification de base avec le nouveau modèle de réponse
  //Future<AuthResponseModel> login(String email, String password);
  //Future<AuthResponseModel> register(RegisterRequestModel params);

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
/*class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final FcmService fcmService;
  final DeviceService deviceService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.fcmService,
    required this.deviceService,
  });




  // ===========================================================================
  // 🔵 LOGIN GOOGLE (ADAPTÉ AU JSON BACKEND)
  // ===========================================================================
  @override
  Future<void> loginWithGoogle({
    required String googleId,    // L'ID unique Google (ex: 108560...)
    required String idToken,     // Le token d'accès (ex: ya29...)
    required String fcmToken,    // Le token de notif
    String? email,
    String? fullName,            // Le nom complet (ex: Jean Dupont)
    String? photoUrl,
  }) async {
    try {
      print("🔵 [REPO] Préparation des données Google pour le Backend...");

      // 1. Récupération infos appareil
      String deviceName = await deviceService.getDeviceName();

      // 2. DÉCOUPAGE DU NOM (Le backend veut 'prenom' et 'name' séparés)
      String prenom = "";
      String nomFamille = "";

      if (fullName != null && fullName.isNotEmpty) {
        List<String> parts = fullName.split(' ');
        if (parts.isNotEmpty) {
          prenom = parts.first; // Premier mot = Prénom
          if (parts.length > 1) {
            // Le reste = Nom de famille
            nomFamille = parts.sublist(1).join(' ');
          }
        }
      }

      // 3. CONSTRUCTION EXACTE DU JSON BACKEND
      final Map<String, dynamic> body = {
        "email": email ?? "",
        "google_id": googleId,           // <--- Important
        "name": nomFamille,              // Backend: 'name' = Nom de famille
        "prenom": prenom,                // Backend: 'prenom' = Prénom
        "contact": "",                   // Google ne donne pas le téléphone, on envoie vide
        "avatar_url": photoUrl ?? "",
        "google_token": idToken,         // Backend: 'google_token'
        "fcm_token": fcmToken,
        "nom_device": deviceName
      };

      print("🚀 [REPO] ENVOI JSON AU BACKEND : $body");

      // 4. Appel API (Attention: vérifie l'URL dans remoteDataSource)
      final responseData = await remoteDataSource.loginSocial(body);

      print("✅ [REPO] Réponse Backend reçue : $responseData");

      // 5. Sauvegarde du Token
      final String? token = responseData['token'] ?? responseData['access_token'];

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        print("💾 [REPO] Token sauvegardé avec succès.");
      } else {
        print("⚠️ [REPO] Pas de token dans la réponse (Vérifier le return du backend).");
      }

    } catch (e) {
      print("❌ [REPO] ERREUR LOGIN GOOGLE : $e");
      rethrow;
    }
  }


  // ✅ AJOUTE CECI :
  @override
  Future<void> deactivateAccount(String password) async {
    // Appel à la source de données
    await remoteDataSource.deactivateAccount(password);

    // Optionnel : Supprimer le token localement tout de suite
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }



  @override
  Future<void> sendOtp(String email) async {
    await remoteDataSource.sendOtp(email);
  }

  @override
  Future<void> verifyOtp(String email, String otpCode) async {
    await remoteDataSource.verifyOtp(email, otpCode);
  }

  @override
  Future<UserStatsModel> getUserStats() async {
    return await remoteDataSource.getUserStats();
  }

  @override
  Future<TripDetailsModel> getTripDetails() async {
    return await remoteDataSource.getTripDetails();
  }



  @override
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String password,
    required String passwordConfirmation,
  }) async {
    await remoteDataSource.resetPassword(email, otpCode, password, passwordConfirmation);
  }

  // --- AUTRES MÉTHODES (Login, Register, etc.) ---

  @override
  Future<void> login(String email, String password) async {
    try {
      String fcmToken = await fcmService.getToken() ?? "dummy_token";
      String deviceName = await deviceService.getDeviceName();

      final requestBody = LoginRequestModel(
        email: email,
        password: password,
        fcmToken: fcmToken,
        deviceName: deviceName,
      );

      final responseData = await remoteDataSource.login(requestBody);
      final prefs = await SharedPreferences.getInstance();
      final String? token = responseData['token'] ?? responseData['access_token'];

      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        print("✅ TOKEN SAUVEGARDÉ DANS LE TÉLÉPHONE : $token");
      } else {
        print("⚠️ ATTENTION : L'API a répondu OK mais sans token !");
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    //required String adresse,
    required String contact,
    String? photoPath,
  }) async {
    try {
      String fcmToken = await fcmService.getToken() ?? "dummy_token";
      String deviceName = await deviceService.getDeviceName();

      final requestBody = RegisterRequestModel(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
        passwordConfirmation: password,
        //adresse: adresse,
        contact: contact,
        fcmToken: fcmToken,
        deviceName: deviceName,
        photoPath: photoPath,
      );

      final responseData = await remoteDataSource.register(requestBody);
      final prefs = await SharedPreferences.getInstance();
      final String? token = responseData['token'] ?? responseData['access_token'];

      if (token != null && token.isNotEmpty) {
        await prefs.setString('auth_token', token);
        print("✅ TOKEN INSCRIPTION SAUVEGARDÉ");
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> logout() async {
    try {
      try {
        await remoteDataSource.logout();
      } catch (e) {
        print("Info: Le serveur n'a pas répondu au logout, on continue...");
      }
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print("🗑️ TOKEN SUPPRIMÉ LOCALEMENT");
    }
  }

  @override
  Future<UserModel> getUserProfile() async {
    return await remoteDataSource.getUserProfile();
  }




  @override
  Future<UserModel> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String nomUrgence,
    required String lienParenteUrgence, // <-- Remplacé
    required String contactUrgence,
    String? photoPath,
  }) async {
    // On passe tout à la source de données
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
}*/



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