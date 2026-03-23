import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../services/notifications/fcm_service.dart';
import '../services/device/device_service.dart';

class UserProvider extends ChangeNotifier {
  // Le repository (On l'instancie ici pour faire simple)
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
    fcmService: FcmService(),
    deviceService: DeviceService(),
  );

  UserModel? _user;
  String? _token;
  bool _isLoading = false;

  // Getters
  UserModel? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;

  // 1. CHARGER L'UTILISATEUR (Appelé au démarrage ou après login)
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      final user = await _authRepository.getUserProfile();
      _user = user;
    } catch (e) {
      debugPrint("Erreur Provider LoadUser: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. LOGOUT (Déconnexion complète)
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    try {
      await _authRepository.logout();
    } catch (e) {
      debugPrint("Erreur logout Provider: $e");
    } finally {
      _user = null;
      _token = null;
      _isLoading = false;
      notifyListeners();
    }
  }

  // 3. VIDER L'UTILISATEUR (Local uniquement)
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}