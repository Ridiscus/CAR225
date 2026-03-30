/*import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // 1. CHARGER L'UTILISATEUR (Appelé au démarrage ou après login)
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners(); // Dit aux écrans : "Je charge, affichez un spinner si besoin"

    try {
      final user = await _authRepository.getUserProfile();
      _user = user;
    } catch (e) {
      debugPrint("Erreur Provider LoadUser: $e");
      // On garde l'ancien user ou null en cas d'erreur
    } finally {
      _isLoading = false;
      notifyListeners(); // Dit aux écrans : "C'est fini, mettez à jour l'affichage !"
    }
  }

  // 2. VIDER L'UTILISATEUR (Logout)
  void clearUser() {
    _user = null;
    notifyListeners();
  }
}*/


/*import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // 🟢 Ajout indispensable pour supprimer le token
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../services/notifications/fcm_service.dart';
import '../services/device/device_service.dart';

class UserProvider extends ChangeNotifier {
  // Le repository
  final AuthRepositoryImpl _authRepository = AuthRepositoryImpl(
    remoteDataSource: AuthRemoteDataSourceImpl(),
    fcmService: FcmService(),
    deviceService: DeviceService(),
  );

  UserModel? _user;
  bool _isLoading = false;

  // Getters
  UserModel? get user => _user;
  bool get isLoading => _isLoading;

  // 1. CHARGER L'UTILISATEUR
  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      final user = await _authRepository.getUserProfile();
      _user = user;
    } catch (e) {
      debugPrint("Erreur Provider LoadUser: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 2. VIDER L'UTILISATEUR (Ancienne méthode, au cas où tu l'utilises ailleurs sans await)
  void clearUser() {
    _user = null;
    notifyListeners();
  }

  // 3. 🟢 LA NOUVELLE MÉTHODE LOGOUT (Asynchrone)
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Étape 1 : Vider le stockage local (Supprimer le token)
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token'); // ⚠️ Vérifie que c'est bien la clé que tu utilises !

      // Optionnel : Si ton API a une route pour invalider le token côté serveur,
      // c'est ici qu'il faudrait appeler _authRepository.logout();

      // Étape 2 : Vider l'utilisateur en mémoire
      _user = null;

    } catch (e) {
      debugPrint("Erreur Provider Logout: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}*/


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