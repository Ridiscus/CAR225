import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/networking/api_config.dart';
import '../../../booking/data/models/user_stats_model.dart';
import '../models/auth_response.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';



abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> loginSocial(Map<String, dynamic> body);

  // Ajoute ceci dans la classe abstraite AuthRemoteDataSource :
  Future<Map<String, dynamic>> verifyPasswordOtp(String email, String otpCode);
  // ✅ CHANGEMENT ICI : On utilise AuthResponseModel au lieu de Map
  Future<AuthResponseModel> login(LoginRequestModel params);
  Future<AuthResponseModel> register(RegisterRequestModel params);

  Future<void> deactivateAccount(String password);
  Future<void> sendOtp(String email);
  // DANS L'INTERFACE (AuthRemoteDataSource)
  Future<Map<String, dynamic>> verifyOtp(String contact, String otpCode);
  Future<void> resetPassword(String email, String otpCode, String password, String passwordConfirmation);
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
  Future<void> logout();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<UserStatsModel> getUserStats();
  Future<TripDetailsModel> getTripDetails();
}


class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  late final Dio dio;

  AuthRemoteDataSourceImpl() {
    dio = Dio(BaseOptions(
      baseUrl: 'https://car225.com/api/',
      //baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
      //baseUrl: ApiConfig.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // INTERCEPTOR : Injecte le token automatiquement
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print("🔑 [Interceptor] Token injecté");
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print("⛔ [Interceptor] Erreur 401: Non autorisé");
        }
        return handler.next(e);
      },
    ));
  }

  @override
  Future<Map<String, dynamic>> loginSocial(Map<String, dynamic> body) async {
    try {
      // 1. On utilise 'dio' au lieu de 'client'
      // 2. Pas besoin de Uri.parse, juste le chemin (le baseUrl est déjà configuré plus haut)
      // 3. Pas besoin de jsonEncode, on passe la Map 'body' directement dans 'data'

      // ATTENTION : Vérifie avec ton dev backend si l'URL est '/auth/social_login' ou '/user/social_login'
      final response = await dio.post(
        '/user/google-auth',
        data: body,
      );

      // Dio renvoie déjà du JSON décodé dans response.data
      return response.data;

    } on DioException catch (e) {
      // Gestion d'erreur propre à Dio
      print("❌ Erreur API Google: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? "Erreur lors de la connexion Google");
    }
  }


  @override
  Future<AuthResponseModel> login(LoginRequestModel params) async {
    try {
      final Map<String, dynamic> body = {
        "login": params.email,
        "password": params.password,
        "fcm_token": params.fcmToken,
        "nom_device": params.deviceName,
      };

      final response = await dio.post('/user/login', data: body);
      return AuthResponseModel.fromJson(response.data); // 🆕 Retourne le modèle complet
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur de connexion");
    }
  }


  @override
  Future<void> logout() async {
    await dio.post('/user/logout');
  }

  @override
  Future<UserModel> getUserProfile() async {
    try {
      final response = await dio.get('/user/profile');

      // Gestion robuste de la réponse JSON
      if (response.data is Map<String, dynamic> && response.data.containsKey('user')) {
        return UserModel.fromJson(response.data['user']);
      } else {
        return UserModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur profil");
    }
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
    try {
      Map<String, dynamic> mapData = {
        "name": name,
        "prenom": prenom,
        "email": email,
        "contact": contact,
        "nom_urgence": nomUrgence,
        "lien_parente_urgence": lienParenteUrgence, // <-- La clé exacte attendue par Laravel
        "contact_urgence": contactUrgence,
        "_method": "PUT",
      };

      FormData formData = FormData.fromMap(mapData);

      if (photoPath != null) {
        formData.files.add(MapEntry(
          "photo_profile",
          await MultipartFile.fromFile(photoPath),
        ));
      }

      final response = await dio.post('/user/profile', data: formData);

      if (response.data is Map<String, dynamic> && response.data.containsKey('user')) {
        return UserModel.fromJson(response.data['user']);
      } else {
        return UserModel.fromJson(response.data);
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur mise à jour");
    }
  }


  @override
  Future<void> deactivateAccount(String password) async {
    try {
      await dio.post('/user/deactivate', data: {"password": password});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur suppression");
    }
  }

  @override
  Future<void> changePassword({required String currentPassword, required String newPassword, required String confirmPassword}) async {
    try {
      await dio.post('/user/change-password', data: {
        "current_password": currentPassword,
        "password": newPassword,
        "password_confirmation": confirmPassword,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur password");
    }
  }

  @override
  Future<void> sendOtp(String email) async {
    try {
      await dio.post('/user/password/send-otp', data: {'email': email});
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur envoi OTP");
    }
  }


  @override
  Future<void> resetPassword(String email, String otpCode, String password, String passwordConfirmation) async {
    try {
      await dio.post('/user/password/reset', data: {
        'email': email,
        'otp': otpCode,
        'password': password,
        'password_confirmation': passwordConfirmation,
      });
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur reset");
    }
  }


  // 🟢 1. Récupérer les stats globales
  Future<UserStatsModel> getUserStats() async {
    try {
      final response = await dio.get('/user/stats'); // ⚠️ Vérifie que ton token est bien passé dans tes intercepteurs Dio !
      return UserStatsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur lors du chargement des statistiques");
    }
  }

  // 🟢 2. Récupérer les détails des voyages
  Future<TripDetailsModel> getTripDetails() async {
    try {
      final response = await dio.get('/user/stats/trips');
      return TripDetailsModel.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur lors du chargement des détails");
    }
  }


  @override
  Future<AuthResponseModel> register(RegisterRequestModel params) async {
    try {
      print("⏳ [REGISTER] Préparation des données pour : ${params.email}...");

      FormData formData = FormData.fromMap({
        "name": params.nom,
        "prenom": params.prenom,
        "email": params.email,
        "password": params.password,
        "password_confirmation": params.passwordConfirmation,
        "contact": params.contact,
        "fcm_token": params.fcmToken,
        "nom_device": params.deviceName,
      });

      if (params.photoPath != null) {
        print("📸 [REGISTER] Ajout de la photo de profil depuis : ${params.photoPath}");
        formData.files.add(MapEntry("photo_profile", await MultipartFile.fromFile(params.photoPath!)));
      }

      print("🚀 [REGISTER] Envoi de la requête à /user/register...");
      final response = await dio.post('/user/register', data: formData);

      // --- NOUVEAUX LOGS DE DÉBOGAGE ---
      print("✅ [REGISTER] Statut de la réponse : ${response.statusCode}");
      print("📦 [REGISTER] Données brutes reçues (response.data) : ${response.data}");
      print("🔍 [REGISTER] Type des données reçues : ${response.data.runtimeType}");
      // ---------------------------------

      return AuthResponseModel.fromJson(response.data);

    } on DioException catch (e) {
      print("❌ [REGISTER DIO ERROR] Status: ${e.response?.statusCode}, Data: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? "Erreur inscription");
    } catch (e, stacktrace) {
      // Capture l'erreur de parsing JSON (celle du 'String' is not subtype of 'int')
      print("🚨 [REGISTER PARSING ERROR] Erreur inattendue : $e");
      print("📜 [REGISTER STACKTRACE] $stacktrace");
      rethrow;
    }
  }


  @override
  Future<Map<String, dynamic>> verifyOtp(String contact, String otpCode) async {
    try {
      print("⏳ [OTP] Début de la vérification pour le contact: $contact, Code: $otpCode...");

      final response = await dio.post('/user/verify-phone-otp', data: {
        'contact': contact,
        'otp': otpCode,
      });

      // --- NOUVEAUX LOGS DE DÉBOGAGE ---
      print("✅ [OTP] Statut de la réponse : ${response.statusCode}");
      print("📦 [OTP] Données brutes reçues (response.data) : ${response.data}");
      print("🔍 [OTP] Type des données reçues : ${response.data.runtimeType}");
      // ---------------------------------

      return response.data;

    } on DioException catch (e) {
      print("❌ [OTP DIO ERROR] Status: ${e.response?.statusCode}, Data: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? "Code invalide");
    } catch (e, stacktrace) {
      print("🚨 [OTP PARSING ERROR] Erreur inattendue : $e");
      print("📜 [OTP STACKTRACE] $stacktrace");
      rethrow;
    }
  }


// Et ceci dans l'implémentation AuthRemoteDataSourceImpl :
  @override
  Future<Map<String, dynamic>> verifyPasswordOtp(String email, String otpCode) async {
    try {
      print("⏳ [PASSWORD OTP] Vérification pour l'email: $email, Code: $otpCode...");

      final response = await dio.post('/user/password/verify-otp', data: {
        'email': email,
        'otp': otpCode,
      });

      print("✅ [PASSWORD OTP] Succès : ${response.data}");
      return response.data;

    } on DioException catch (e) {
      print("❌ [PASSWORD OTP DIO ERROR] Status: ${e.response?.statusCode}, Data: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? "Code OTP invalide pour la réinitialisation");
    } catch (e) {
      print("🚨 [PASSWORD OTP ERROR] Erreur : $e");
      rethrow;
    }
  }


}