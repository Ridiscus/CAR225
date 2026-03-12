/*import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🟢 IMPORTS À DÉCOMMENTER ET AJUSTER SELON TON ARBORESCENCE
// import '../data/models/hostess_profile_model.dart';
// import '../data/repositories/hostess_repository_impl.dart'; // Ou l'interface si tu l'as séparée

class HostessProfileProvider extends ChangeNotifier {
  // ==========================================
  // 1. ÉTATS (VARIABLES)
  // ==========================================

  // --- Gestion de l'image locale ---
  File? _profileImage;
  File? get profileImage => _profileImage;

  // --- Gestion des données de l'API ---
  // ⚠️ Remplace "dynamic" par "HostessProfileModel" une fois les imports décommentés
  dynamic _profileData;
  bool _isLoading = false;
  String? _errorMessage;

  // ⚠️ Remplace "dynamic" par "HostessProfileModel"
  dynamic get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==========================================
  // 2. INITIALISATION
  // ==========================================

  HostessProfileProvider() {
    loadCachedImage();
  }

  // ==========================================
  // 3. MÉTHODES POUR L'IMAGE LOCALE
  // ==========================================

  Future<void> loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString('hostess_profile_image');
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
      notifyListeners();
    }
  }

  Future<void> updateImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hostess_profile_image', path);
    _profileImage = File(path);
    notifyListeners();
  }

  // ==========================================
  // 4. MÉTHODES POUR LES DONNÉES DE L'API
  // ==========================================

  // ⚠️ Remplace "dynamic" par "HostessRepositoryImpl" (ou ton interface)
  Future<void> fetchProfile(dynamic repository) async {
    // Si on a déjà les données, on ne recharge pas inutilement
    if (_profileData != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // On notifie l'UI pour afficher le loader

    try {
      _profileData = await repository.getHostessProfile();
      _errorMessage = null; // Tout s'est bien passé
    } catch (e) {
      _errorMessage = "Impossible de charger le profil.";
      print("❌ [PROVIDER ERROR] $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // On notifie l'UI pour enlever le loader et afficher les données
    }
  }
}



*/




import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// 🟢 IMPORTS À DÉCOMMENTER ET AJUSTER SELON TON ARBORESCENCE
// import '../data/models/hostess_profile_model.dart';
// import '../data/repositories/hostess_repository_impl.dart'; // Ou l'interface si tu l'as séparée

class HostessProfileProvider extends ChangeNotifier {
  // ==========================================
  // 1. ÉTATS (VARIABLES)
  // ==========================================

  // --- Gestion de l'image locale ---
  File? _profileImage;
  File? get profileImage => _profileImage;

  // --- Gestion des données de l'API ---
  // ⚠️ Remplace "dynamic" par "HostessProfileModel" une fois les imports décommentés
  dynamic _profileData;
  bool _isLoading = false;
  String? _errorMessage;

  // ⚠️ Remplace "dynamic" par "HostessProfileModel"
  dynamic get profileData => _profileData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ==========================================
  // 2. INITIALISATION
  // ==========================================

  HostessProfileProvider() {
    loadCachedImage();
  }

  // ==========================================
  // 3. MÉTHODES POUR L'IMAGE LOCALE
  // ==========================================

  Future<void> loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString('hostess_profile_image');
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
      notifyListeners();
    }
  }

  Future<void> updateImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('hostess_profile_image', path);
    _profileImage = File(path);
    notifyListeners();
  }

  // ==========================================
  // 4. MÉTHODES POUR LES DONNÉES DE L'API
  // ==========================================

  // ⚠️ Remplace "dynamic" par "HostessRepositoryImpl" (ou ton interface)
  Future<void> fetchProfile(dynamic repository) async {
    // Si on a déjà les données, on ne recharge pas inutilement
    if (_profileData != null) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // On notifie l'UI pour afficher le loader

    try {
      _profileData = await repository.getHostessProfile();
      _errorMessage = null; // Tout s'est bien passé
    } catch (e) {
      _errorMessage = "Impossible de charger le profil.";
      print("❌ [PROVIDER ERROR] $e");
    } finally {
      _isLoading = false;
      notifyListeners(); // On notifie l'UI pour enlever le loader et afficher les données
    }
  }

  Future<void> updateProfile(dynamic repository, Map<String, dynamic> data) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. On garde en mémoire les informations précieuses avant d'envoyer la requête
      final oldCompagnie = _profileData?.nomCompagnie;
      final oldCodeId = _profileData?.codeId;

      // 2. On attend la réponse du serveur (qui n'aura peut-être pas la compagnie)
      final newProfileFromServer = await repository.updateProfile(data);

      // 3. 🟢 LA MAGIE EST ICI : On fusionne !
      // On prend le nouveau profil, mais on lui remet l'ancienne compagnie et l'ancien ID
      _profileData = newProfileFromServer.copyWith(
        nomCompagnie: oldCompagnie,
        codeId: oldCodeId,
      );

    } catch (e) {
      _errorMessage = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners(); // Met à jour l'écran avec les bonnes données fusionnées
    }
  }

}



