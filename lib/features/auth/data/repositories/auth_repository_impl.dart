import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../booking/data/models/user_stats_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../models/auth_response.dart';
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

  // ===========================================================================
  // 🔐 LOGIN (CONNEXION) - CORRIGÉ SELON LE CONTRAT
  // ===========================================================================
  @override
  Future<AuthResponseModel> login(LoginRequestModel params) async {
    try {
      // 1. Appel API via la Data Source (qui renvoie un AuthResponseModel)
      final AuthResponseModel response = await remoteDataSource.login(params);

      // 2. 💾 SAUVEGARDE DU TOKEN (Seulement si pas d'OTP requis)
      if (response.success && !response.requiresOtp && response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.token!);
        print("✅ REPOSITORY: Token sauvegardé avec succès");
      } else if (response.requiresOtp) {
        print("🚨 REPOSITORY: OTP Requis pour ce compte");
      }

      return response;
    } catch (e) {
      print("❌ REPOSITORY ERROR LOGIN: $e");
      rethrow;
    }
  }

  // 🟢 AJOUTE EXACTEMENT CECI :
  @override
  Future<void> verifyPasswordOtp(String email, String otpCode) async {
    await remoteDataSource.verifyPasswordOtp(email, otpCode);
  }

  // ===========================================================================
  // 📝 REGISTER (INSCRIPTION) - CORRIGÉ SELON LE CONTRAT
  // ===========================================================================
  @override
  Future<AuthResponseModel> register(RegisterRequestModel params) async {
    try {
      // 1. Appel API
      final AuthResponseModel response = await remoteDataSource.register(
        params,
      );

      // 2. 💾 SAUVEGARDE TOKEN (Seulement si pas d'OTP requis)
      if (response.success && !response.requiresOtp && response.token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.token!);
        print("✅ REPOSITORY: Token Inscription sauvegardé");
      }

      return response;
    } catch (e) {
      print("❌ REPOSITORY ERROR REGISTER: $e");
      rethrow;
    }
  }

  // ===========================================================================
  // 🔵 LOGIN GOOGLE
  // ===========================================================================
  @override
  Future<void> loginWithGoogle({
    required String googleId,
    required String idToken,
    required String fcmToken,
    String? email,
    String? fullName,
    String? photoUrl,
    String? accessToken,
  }) async {
    try {
      String deviceName = await deviceService.getDeviceName();
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

      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
      }
    } catch (e) {
      rethrow;
    }
  }

  // ===========================================================================
  // 🔑 OTP & AUTRES MÉTHODES
  // ===========================================================================

  @override
  Future<void> sendOtp(String email) async =>
      await remoteDataSource.sendOtp(email);

  /*@override
  Future<void> verifyOtp(String email, String otpCode) async => await remoteDataSource.verifyOtp(email, otpCode);*/

  @override
  Future<void> verifyOtp(String email, String otpCode) async {
    try {
      // 1. On récupère la réponse (qui contient {success: true, message: ..., token: ...})
      final responseData = await remoteDataSource.verifyOtp(email, otpCode);

      // 2. On extrait le token
      final String? token = responseData['token'];

      // 3. On sauvegarde le token dans les SharedPreferences
      if (token != null && token.isNotEmpty) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', token);
        print(
          "✅ REPOSITORY [OTP] : Token sauvegardé avec succès dans le téléphone !",
        );
      } else {
        print(
          "❌ REPOSITORY [OTP] : Attention, aucun token trouvé dans la réponse !",
        );
      }
    } catch (e) {
      print("❌ REPOSITORY ERROR OTP: $e");
      rethrow;
    }
  }

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

  @override
  Future<void> logout() async {
    try {
      await remoteDataSource.logout();
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
    }
  }
}
