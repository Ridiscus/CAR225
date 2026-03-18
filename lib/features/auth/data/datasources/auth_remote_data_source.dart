import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../booking/data/models/user_stats_model.dart';
import '../../../hostess/models/hostess_profile_model.dart';
import '../../../hostess/models/sale_model.dart';
import '../models/auth_response.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/unified_login_request_model.dart';
import '../models/user_model.dart';



abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> loginSocial(Map<String, dynamic> body);


  Future<AuthResponseModel> unifiedLogin(UnifiedLoginRequestModel params);
  Future<void> logoutHotesse();
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
  Future<Map<String, dynamic>> getHostessDashboard();

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
    dio = Dio(
      BaseOptions(
        //baseUrl: 'https://car225.com/api/',
        baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
        //baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

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
  Future<AuthResponseModel> unifiedLogin(UnifiedLoginRequestModel params) async {
    try {
      print("⏳ [UNIFIED LOGIN] Tentative avec Code ID: ${params.codeId}");

      final response = await dio.post('/unified-login', data: params.toJson());

      print("✅ [UNIFIED LOGIN] Succès : ${response.data}");

      // On utilise le même modèle de réponse que le login normal
      return AuthResponseModel.fromJson(response.data);

    } on DioException catch (e) {
      // 🟢 ON AJOUTE CES LOGS POUR COMPRENDRE LE VRAI PROBLÈME
      print("❌ [UNIFIED LOGIN DIO ERROR] Type: ${e.type}");
      print("❌ [UNIFIED LOGIN DIO ERROR] Message: ${e.message}");
      print("❌ [UNIFIED LOGIN DIO ERROR] Status: ${e.response?.statusCode}, Data: ${e.response?.data}");

      if (e.response == null) {
        // Le serveur n'a pas répondu (crash, mauvaise URL, ou pas de réseau)
        throw Exception("Impossible de joindre le serveur. Erreur réseau ou mauvaise URL.");
      }

      throw Exception(e.response?.data['message'] ?? "Identifiants invalides");
    } catch (e) {
      print("🚨 [UNIFIED LOGIN ERROR] Erreur : $e");
      rethrow;
    }
  }

  @override
  Future<void> logoutHotesse() async {
    try {
      print("⏳ [LOGOUT] Déconnexion de l'hôtesse en cours...");

      // Appel à l'API. Si tu utilises une méthode DELETE ou POST, adapte le `.post`
      await dio.post('/hotesse/logout');

      print("✅ [LOGOUT] Succès : Hôtesse déconnectée du serveur.");
    } on DioException catch (e) {
      print("❌ [LOGOUT DIO ERROR] Status: ${e.response?.statusCode}");
      // Même si le serveur renvoie une erreur (ex: token déjà expiré),
      // on veut généralement quand même déconnecter l'utilisateur localement.
      // On log l'erreur mais on ne throw pas forcément d'exception bloquante.
    } catch (e) {
      print("🚨 [LOGOUT ERROR] Erreur : $e");
    }
  }


  @override
  Future<HostessProfileModel> getHostessProfile() async {
    try {
      print("⏳ [GET HOSTESS PROFILE] Appel API...");
      final response = await dio.get('/hotesse/profile');
      print("✅ [GET HOSTESS PROFILE] Succès : ${response.data}");

      // 🟢 CHANGEMENT ICI : On pointe sur 'hotesse' selon ton JSON
      final data = response.data['hotesse'];

      if (data == null) {
        throw Exception("Clé 'hotesse' manquante dans le JSON.");
      }

      return HostessProfileModel.fromJson(data);

    } catch (e) {
      print("🚨 [GET HOSTESS PROFILE ERROR] $e");
      rethrow;
    }
  }

  @override
  Future<HostessProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      print("⏳ [UPDATE HOSTESS PROFILE] Appel API avec les données : $data");

      // Utilisation de dio.put (ou dio.post selon ce qu'attend ton backend Laravel)
      final response = await dio.post('/hotesse/profile', data: data);

      print("✅ [UPDATE HOSTESS PROFILE] Succès : ${response.data}");

      // 🟢 On adapte selon la réponse de ton backend.
      // S'il renvoie les données mises à jour dans la clé 'hotesse' comme pour le GET :
      final responseData = response.data['hotesse'] ?? response.data;

      if (responseData == null) {
        throw Exception("Données manquantes dans la réponse de mise à jour.");
      }

      return HostessProfileModel.fromJson(responseData);

    } catch (e) {
      print("🚨 [UPDATE HOSTESS PROFILE ERROR] $e");
      rethrow;
    }
  }

  @override
  Future<void> changePasswordHotesse(Map<String, dynamic> data) async {
    try {
      print("⏳ [CHANGE PASSWORD] Appel API...");

      final response = await dio.post('/hotesse/change-password', data: data);

      print("✅ [CHANGE PASSWORD] Succès : ${response.data}");

    } on DioException catch (e) {
      // 1. On regarde si on a reçu une réponse du serveur (comme l'erreur 422)
      if (e.response != null && e.response?.data != null) {
        final responseData = e.response!.data;
        print("🛑 [DETAILS ERREUR BACKEND] $responseData");

        // 2. On extrait le message d'erreur renvoyé par Laravel
        if (responseData is Map<String, dynamic>) {
          String errorMessage = responseData['message'] ?? 'Erreur lors de la modification.';

          // Si Laravel renvoie ses fameuses erreurs de validation détaillées
          if (responseData.containsKey('errors')) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            // On récupère le tout premier message d'erreur de la liste pour l'afficher
            if (errors.isNotEmpty) {
              errorMessage = errors.values.first[0].toString();
            }
          }

          // 3. On renvoie uniquement le message clair !
          throw Exception(errorMessage);
        }
      }

      // Si c'est un problème de réseau pur (pas de connexion, timeout...)
      throw Exception("Problème de connexion au serveur. Veuillez réessayer.");

    } catch (e) {
      // Pour toute autre erreur inattendue
      throw Exception("Une erreur inattendue s'est produite.");
    }
  }


  Future<List<HostessSaleModel>> getSalesHistory(DateTime? startDate, DateTime? endDate) async {
    try {
      // 1. Formatage des dates au format attendu par Laravel (YYYY-MM-DD)
      final fmt = DateFormat('yyyy-MM-dd');
      String queryParams = '';

      if (startDate != null) {
        queryParams += '?date_debut=${fmt.format(startDate)}';
      }
      // Si tu as aussi un paramètre date_fin côté backend :
      if (endDate != null) {
        final prefix = queryParams.isEmpty ? '?' : '&';
        queryParams += '${prefix}date_fin=${fmt.format(endDate)}';
      }

      // 2. Appel API
      final response = await dio.get('/hotesse/ventes$queryParams');

      // 3. Parsing
      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['ventes']['data'];
        return data.map((json) => HostessSaleModel.fromJson(json)).toList();

        // Note: Tu peux aussi extraire les stats ici si tu veux les afficher en haut de l'écran !
      } else {
        throw Exception("Erreur lors de la récupération des ventes.");
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> searchTickets({
    required String dateDepart,
    required String pointDepart,
    required String pointArrive,
  }) async {
    try {
      print("🌍 [GET REQUÊTE] Vers: /hotesse/vendre-ticket");
      print("🔍 [GET PARAMS] date: $dateDepart, depart: $pointDepart, arrivee: $pointArrive");

      final response = await dio.get(
        '/hotesse/vendre-ticket',
        queryParameters: {
          'date_depart': dateDepart,
          'point_depart': pointDepart,
          'point_arrive': pointArrive,
        },
      );

      print("✅ [GET SUCCÈS] Code: ${response.statusCode}");
      print("📦 [GET RÉPONSE] ${response.data}");

      return response.data;
    } catch (e) {
      print("❌ [GET ERREUR] $e");
      if (e is DioException) {
        print("🚨 [GET DÉTAILS BACKEND] ${e.response?.data}");
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> bookTicket(Map<String, dynamic> payload) async {
    try {
      print("🚀 [POST REQUÊTE] Vers: /hotesse/vendre-ticket");
      print("📤 [POST PAYLOAD] $payload");

      final response = await dio.post(
        '/hotesse/vendre-ticket',
        data: payload,
      );

      print("✅ [POST SUCCÈS] Code: ${response.statusCode}");
      print("📥 [POST RÉPONSE] ${response.data}");

      return response.data;
    } catch (e) {
      print("❌ [POST ERREUR] $e");
      // Souvent, quand un POST échoue (ex: erreur 400 ou 422),
      // le backend envoie la vraie raison dans e.response.data
      if (e is DioException) {
        print("🚨 [POST DÉTAILS BACKEND] ${e.response?.statusCode} - ${e.response?.data}");
      }
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getHostessDashboard() async {
    try {
      print("🚀 [GET REQUÊTE] Vers: /hotesse/dashboard");

      // C'est un GET, donc pas de payload (data)
      final response = await dio.get('/hotesse/dashboard');

      print("✅ [GET SUCCÈS] Code: ${response.statusCode}");
      print("📥 [GET RÉPONSE] ${response.data}");

      return response.data;
    } catch (e) {
      print("❌ [GET ERREUR] $e");
      // On intercepte l'erreur du backend pour voir ce qui cloche
      if (e is DioException) {
        print("🚨 [GET DÉTAILS BACKEND] ${e.response?.statusCode} - ${e.response?.data}");
      }
      rethrow;
    }
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