import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/login_request_model.dart';
import '../models/register_request_model.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<Map<String, dynamic>> login(LoginRequestModel params);
  Future<Map<String, dynamic>> register(RegisterRequestModel params);
  Future<UserModel> getUserProfile();
  Future<UserModel> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String adresse,
    String? photoPath,
  });
  Future<void> logout();
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<void> sendOtp(String contact);
  Future<void> verifyOtp(String contact, String code);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final Dio dio = Dio(
    BaseOptions(
      baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );

  AuthRemoteDataSourceImpl();

  @override
  Future<Map<String, dynamic>> login(LoginRequestModel params) async {
    try {
      final response = await dio.post('/user/login', data: params.toJson());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data;
      } else {
        throw Exception("Erreur serveur: ${response.statusCode}");
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur de connexion");
    }
  }

  @override
  Future<Map<String, dynamic>> register(RegisterRequestModel params) async {
    try {
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

      FormData formData = FormData.fromMap(mapData);
      if (params.photoPath != null) {
        formData.files.add(
          MapEntry(
            "photo_profile",
            await MultipartFile.fromFile(params.photoPath!),
          ),
        );
      }

      final response = await dio.post('/user/register', data: formData);
      return response.data;
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? "Erreur lors de l'inscription",
      );
    }
  }

  @override
  Future<void> logout() async {
    try {
      await _addTokenHeader();
      await dio.post('/user/logout');
    } catch (e) {
      throw Exception("Erreur serveur logout");
    }
  }

  @override
  Future<UserModel> getUserProfile() async {
    try {
      await _addTokenHeader();
      final response = await dio.get('/user/profile');
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? "Erreur chargement profil",
      );
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
      Map<String, dynamic> mapData = {
        "name": name,
        "prenom": prenom,
        "email": email,
        "contact": contact,
        "adresse": adresse,
        "_method": "PUT",
      };

      FormData formData = FormData.fromMap(mapData);
      if (photoPath != null) {
        formData.files.add(
          MapEntry("photo_profile", await MultipartFile.fromFile(photoPath)),
        );
      }

      final response = await dio.post('/user/profile', data: formData);
      return UserModel.fromJson(response.data['user']);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Erreur mise à jour");
    }
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      await _addTokenHeader();
      await dio.post(
        'user/change-password',
        data: {
          "current_password": currentPassword,
          "password": newPassword,
          "password_confirmation": confirmPassword,
        },
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? "Erreur changement mot de passe",
      );
    }
  }

  @override
  Future<void> sendOtp(String contact) async {
    try {
      await dio.post('/user/send-otp', data: {"contact": contact});
    } on DioException catch (e) {
      throw Exception(
        e.response?.data['message'] ?? "Erreur lors de l'envoi du code",
      );
    }
  }

  @override
  Future<void> verifyOtp(String contact, String code) async {
    try {
      final response = await dio.post(
        '/user/verify-otp',
        data: {"contact": contact, "code": code},
      );
      if (response.data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', response.data['token']);
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Code invalide");
    }
  }

  Future<void> _addTokenHeader() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null) {
      dio.options.headers["Authorization"] = "Bearer $token";
      dio.options.headers["Accept"] = "application/json";
    }
  }
}
