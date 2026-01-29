import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(LoginRequestModel params);
  Future<Map<String, dynamic>> register(RegisterRequestModel params); // Ajout


  Future<UserModel> getUserProfile();
  Future<UserModel> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String adresse,
    String? photoPath, // Optionnel (fichier local)
  });


// 👇 AJOUTE CETTE LIGNE OBLIGATOIREMENT ICI 👇
  Future<void> logout();

  // ✅ AJOUTE CECI :
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio = Dio(BaseOptions(
    // ⚠️ L'URL fournie par ton dev
    //baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev',

    baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // ✅ Constructeur vide (plus besoin de passer dio)
  AuthRemoteDataSourceImpl();


  @override
  Future<Map<String, dynamic>> login(LoginRequestModel params) async {
    try {
      print("📡 ENVOI API: ${params.toJson()}");

      // On suppose que l'endpoint est /api/login ou /api/v1/auth/login
      // Demande à ton dev le chemin EXACT après l'URL de base.
      // Ici je mets '/api/login' par défaut standard Laravel/Node.
      final response = await dio.post(
        '/user/login',
        data: params.toJson(),
      );

      print("✅ REPONSE API: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        // On retourne la réponse (qui contient surement le token)
        return response.data;
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } on DioException catch (e) {
      print("❌ ERREUR API: ${e.response?.data ?? e.message}");
      // Tu peux affiner ici pour renvoyer un message d'erreur précis (ex: "Email incorrect")
      throw Exception(e.response?.data['message'] ?? "Erreur de connexion");
    }
  }




  @override
  Future<Map<String, dynamic>> register(RegisterRequestModel params) async {
    try {
      // 1. On prépare les données texte
      Map<String, dynamic> mapData = {
        "name": params.nom,
        "prenom": params.prenom,
        "email": params.email,
        "password": params.password,
        "password_confirmation": params.passwordConfirmation,
        "adresse": params.adresse,
        "contact": params.contact,
        "fcm_token": params.fcmToken,
        "nom_device": params.deviceName,
      };

      // 2. Conversion en FormData (pour l'upload)
      FormData formData = FormData.fromMap(mapData);

      // 3. Si une photo est présente, on l'ajoute au FormData
      // ATTENTION : Demande au dev si le champ s'appelle "photo", "image" ou "avatar"
      // Je mets "photo" par défaut (standard Laravel)
      if (params.photoPath != null) {
        formData.files.add(MapEntry(
          "photo_profile", // <--- NOM DU CHAMP CÔTÉ LARAVEL
          await MultipartFile.fromFile(params.photoPath!),
        ));
      }

      print("📡 INSCRIPTION (MULTIPART) ENVOI...");

      final response = await dio.post(
        '/user/register',
        data: formData, // On envoie le FormData, pas le JSON
      );

      print("✅ INSCRIPTION SUCCÈS: ${response.statusCode}");
      return response.data;

    } on DioException catch (e) {
      print("❌ ERREUR INSCRIPTION: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? "Erreur lors de l'inscription");
    }
  }




  // 👇 C'EST ICI LA CORRECTION 👇
  @override
  Future<void> logout() async {
    try {
      // 1. On récupère le TOKEN stocké
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token != null) {
        // 2. On l'injecte dans le Header "Authorization"
        dio.options.headers["Authorization"] = "Bearer $token";
      }

      print("📡 DECONNEXION SERVER (Token: ${token != null ? 'OK' : 'MANQUANT'})...");

      // 3. Appel API
      await dio.post('/user/logout');

      print("✅ LOGOUT SERVER SUCCÈS");

    } catch (e) {
      // Si le serveur refuse (ex: token expiré), ce n'est pas grave
      // on veut quand même que l'app se déconnecte localement.
      print("⚠️ Erreur Logout Serveur (non bloquant): $e");
      throw Exception("Erreur serveur logout");
    }
  }


  @override
  Future<UserModel> getUserProfile() async {
    try {
      await _addTokenHeader();
      final response = await dio.get('/user/profile');
      // On parse la partie "user" de la réponse JSON
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur chargement profil");
    }
  }

  @override
  Future<UserModel> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String adresse,
    String? photoPath,
  }) async {
    try {
      await _addTokenHeader();

      // Préparation des données
      Map<String, dynamic> mapData = {
        "name": name,
        "prenom": prenom,
        "email": email,
        "contact": contact,
        "adresse": adresse,
        // Astuce Laravel/PHP : Parfois PUT ne gère pas bien le Multipart.
        // Si ça bug, on utilise POST avec "_method": "PUT".
        "_method": "PUT",
      };

      FormData formData = FormData.fromMap(mapData);

      if (photoPath != null) {
        formData.files.add(MapEntry(
          "photo_profile", // Vérifie ce nom avec ton backend (parfois "photo", "avatar")
          await MultipartFile.fromFile(photoPath),
        ));
      }

      // On utilise POST à cause du FormData (avec _method: PUT dedans)
      // Si ton backend gère le PUT multipart natif, change en dio.put
      final response = await dio.post('/user/profile', data: formData);

      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur mise à jour");
    }
  }

  // Méthode utilitaire pour ajouter le token (comme vu précédemment)
 /* Future<void> _addTokenHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
    }
  }*/

  // Ta méthode utilitaire existante (à garder dans la classe)
  /*Future<void> _addTokenHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
      // Dio met automatiquement le Content-Type à application/json pour les Maps,
      // mais on peut le forcer si besoin :
      dio.options.headers["Accept"] = "application/json";
    }
  }*/


  // Ta méthode utilitaire pour le token
  Future<void> _addTokenHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
    }
  }




  // ✅ NOUVELLE MÉTHODE : CHANGE PASSWORD
  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _addTokenHeader(); // On ajoute le token

      // Pas besoin de baseUrl ici car il est déjà dans BaseOptions
      final response = await dio.post(
        'user/change-password', // juste le endpoint
        data: {
          "current_password": currentPassword,
          "password": newPassword,
          "password_confirmation": confirmPassword,
        },
      );

      // Succès (pas d'exception levée)
    } on DioException catch (e) {
      // Gestion erreur API
      throw Exception(e.response?.data['message'] ?? "Erreur changement mot de passe");
    }
  }


}







