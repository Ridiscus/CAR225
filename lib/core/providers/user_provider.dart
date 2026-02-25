import 'package:flutter/material.dart';
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
  
}