import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Tes imports pour la data
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/repositories/agent_repository_impl.dart';

class AgentProfileProvider extends ChangeNotifier {
  File? _profileImage;
  File? get profileImage => _profileImage;

  // Variables pour le profil
  Map<String, dynamic>? _profileData;
  Map<String, dynamic>? get profileData => _profileData;

  bool _isLoadingProfile = false;
  bool get isLoadingProfile => _isLoadingProfile;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  AgentProfileProvider() {
    loadCachedImage();
  }

  // 🔵 1. LES MÉTHODES POUR GÉRER L'IMAGE (Qui manquaient à l'appel)
  Future<void> loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString('agent_profile_image');
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
      notifyListeners();
    }
  }

  Future<void> updateImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('agent_profile_image', path);
    _profileImage = File(path);
    notifyListeners();
  }

  // 🟢 NOUVELLE MÉTHODE POUR CHARGER L'API DU PROFIL
  Future<void> fetchProfile() async {
    _isLoadingProfile = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final repo = AgentRepositoryImpl(
        remoteDataSource: AgentRemoteDataSourceImpl(),
      );

      final responseData = await repo.getProfile();

      // 🐛 DEBUG: On affiche la réponse brute dans la console pour être sûr !
      print('====== JSON BRUT DU PROFIL ======');
      print(responseData);
      print('=================================');

      // 🛡️ EXTRACTION BLINDÉE : On cherche l'objet agent peu importe où il est caché
      if (responseData.containsKey('agent')) {
        _profileData = responseData['agent'];
      } else if (responseData.containsKey('data') && responseData['data'] is Map && responseData['data'].containsKey('agent')) {
        _profileData = responseData['data']['agent'];
      } else if (responseData.containsKey('data')) {
        _profileData = responseData['data'];
      } else {
        _profileData = responseData;
      }

    } catch (e) {
      _errorMessage = "Impossible de charger le profil : $e";
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // 1. On instancie le repo (comme dans fetchProfile)
    final repo = AgentRepositoryImpl(
      remoteDataSource: AgentRemoteDataSourceImpl(),
    );

    // 2. On utilise 'repo' au lieu de 'repository'
    return await repo.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }


}