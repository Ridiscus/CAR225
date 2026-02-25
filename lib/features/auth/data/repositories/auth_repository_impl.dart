import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../booking/data/models/user_stats_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

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
  Future<void> sendOtp(String email) async {
    await remoteDataSource.sendOtp(email);
  }

  @override
  Future<void> verifyOtp(String email, String otpCode) async {
    await remoteDataSource.verifyOtp(email, otpCode);
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

  // ===========================================================================
  // 🔐 LOGIN (CONNEXION) - CORRIGÉ
  // ===========================================================================
  @override
  Future<void> login(String email, String password) async {
    try {
      // 1. Récupération des infos techniques
      String fcmToken = await fcmService.getToken() ?? "";
      String deviceName = await deviceService.getDeviceName();

      // 2. Création de la requête
      final requestBody = LoginRequestModel(
        email: email,
        password: password,
        fcmToken: fcmToken,
        deviceName: deviceName,
      );

      // 3. Appel API
      final responseData = await remoteDataSource.login(requestBody);

      // 4. 💾 SAUVEGARDE DU TOKEN
      // On vérifie les clés possibles renvoyées par Laravel (token ou access_token)
      final String? token = responseData['token'] ?? responseData['access_token'];

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        print("✅ REPOSITORY: Token sauvegardé avec succès ($token)");
      } else {
        print("⚠️ REPOSITORY: Connexion OK mais aucun token trouvé dans la réponse : $responseData");
      }

    } catch (e) {
      rethrow;
    }
  }

  // 🟢 AJOUTE LE @override POUR ÊTRE PROPRE
  @override
  Future<UserStatsModel> getUserStats() async {
    return await remoteDataSource.getUserStats();
  }

  @override
  Future<TripDetailsModel> getTripDetails() async {
    return await remoteDataSource.getTripDetails();
  }




  // ===========================================================================
  // 🔵 LOGIN GOOGLE (IMPLEMENTATION MANQUANTE)
  // ===========================================================================
  // ===========================================================================
  // 🔵 LOGIN GOOGLE (ADAPTÉ AU JSON BACKEND)
  // ===========================================================================
  @override
  Future<void> loginWithGoogle({
    required String googleId,    // <--- AJOUTÉ
    required String idToken,
    required String fcmToken,
    String? email,
    String? fullName,            // Renommé pour clarté
    String? photoUrl,
    String? accessToken,         // Gardé si besoin, mais le backend demande 'google_token' (idToken)
  }) async {
    try {
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
        "google_id": googleId,           // Backend: 'google_id'
        "name": nomFamille,              // Backend: 'name' = Nom de famille
        "prenom": prenom,                // Backend: 'prenom' = Prénom
        "contact": "",                   // Google ne donne pas le téléphone
        "avatar_url": photoUrl ?? "",    // Backend: 'avatar_url'
        "google_token": idToken,         // Backend: 'google_token' (C'est souvent l'ID Token qu'on envoie ici)
        "fcm_token": fcmToken,
        "nom_device": deviceName
      };

      print("🚀 [REPO] ENVOI JSON AU BACKEND : $body");

      // 4. Appel API
      final responseData = await remoteDataSource.loginSocial(body);

      // 5. Sauvegarde du Token
      final String? token = responseData['token'] ?? responseData['access_token'];

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        print("✅ REPOSITORY: Token Google sauvegardé ($token)");
      } else {
        print("⚠️ REPOSITORY: Login Google OK mais pas de token reçu.");
      }
    } catch (e) {
      rethrow;
    }
  }



  // ===========================================================================
  // 📝 REGISTER (INSCRIPTION)
  // ===========================================================================
  @override
  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String contact,
    String? photoPath,
  }) async {
    try {
      String fcmToken = await fcmService.getToken() ?? "";
      String deviceName = await deviceService.getDeviceName();

      final requestBody = RegisterRequestModel(
        nom: nom,
        prenom: prenom,
        email: email,
        password: password,
        passwordConfirmation: password,
        contact: contact,
        fcmToken: fcmToken,
        deviceName: deviceName,
        photoPath: photoPath,
      );

      final responseData = await remoteDataSource.register(requestBody);

      // 💾 SAUVEGARDE TOKEN INSCRIPTION
      final String? token = responseData['token'] ?? responseData['access_token'];
      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        print("✅ REPOSITORY: Token Inscription sauvegardé");
      }

    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // 🚪 LOGOUT
  // ===========================================================================
  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } catch (e) {
      print("Info: Le serveur n'a pas répondu au logout, force cleaning local.");
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      print("🗑️ REPOSITORY: Token supprimé (Déconnexion)");
    }
  }

  // ===========================================================================
  // 👤 AUTRES MÉTHODES
  // ===========================================================================
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

  @override
  Future<void> deactivateAccount(String password) async {
    await remoteDataSource.deactivateAccount(password);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
}