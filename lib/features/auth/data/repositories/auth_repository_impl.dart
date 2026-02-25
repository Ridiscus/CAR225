import 'package:shared_preferences/shared_preferences.dart'; // <--- N'OUBLIE PAS L'IMPORT

import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
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

      // ✅ SAUVEGARDE DU TOKEN (DÉCOMMENTÉ ET CORRIGÉ)
      final prefs = await SharedPreferences.getInstance();
      // Adapte la clé 'token' ou 'access_token' selon la réponse exacte de ton API
      if (responseData['token'] != null) {
        await prefs.setString('auth_token', responseData['token']);
        print("💾 Token sauvegardé localement");
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
    required String adresse,
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
        adresse: adresse,
        contact: contact,
        fcmToken: fcmToken,
        deviceName: deviceName,
        photoPath: photoPath,
      );

      final responseData = await remoteDataSource.register(requestBody);

      // ✅ SAUVEGARDE TOKEN INSCRIPTION AUSSI
      final prefs = await SharedPreferences.getInstance();
      if (responseData['token'] != null) {
        await prefs.setString('auth_token', responseData['token']);
        print("💾 Token inscription sauvegardé localement");
      }
    } catch (e) {
      rethrow;
    }
  }

  // 👇 C'EST ICI LA CORRECTION 👇
  @override
  Future<void> logout() async {
    try {
      // 1. Tenter de prévenir le serveur
      try {
        await remoteDataSource.logout();
      } catch (e) {
        print(
          "Info: Le serveur n'a pas répondu (peut-être token expiré), suite logique...",
        );
      }

      // 2. NETTOYAGE OBLIGATOIRE DU TELEPHONE
      final prefs = await SharedPreferences.getInstance();

      // On supprime TOUT (Token, infos user, etc.)
      await prefs.clear();

      print("🗑️ Données locales supprimées (Déconnexion réussie)");
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<UserModel> getUserProfile() async {
    // On appelle simplement le DataSource
    return await remoteDataSource.getUserProfile();
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
    // On transmet tout au DataSource
    return await remoteDataSource.updateUserProfile(
      name: name,
      prenom: prenom,
      email: email,
      contact: contact,
      adresse: adresse,
      photoPath: photoPath,
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // On délègue simplement à la datasource
    await remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }
}
