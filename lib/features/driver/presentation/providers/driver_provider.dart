import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/driver_remote_data_source.dart';
import '../../data/models/driver_profile_model.dart';
import '../../data/models/voyage_model.dart';
import '../../data/models/convoi_model.dart';
import '../../data/models/driver_message_model.dart';

class DriverNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final String type;
  bool isRead;

  DriverNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.type,
    this.isRead = false,
  });
}

class DriverProvider extends ChangeNotifier {
  final DriverRemoteDataSourceImpl _ds = DriverRemoteDataSourceImpl();

  // ─── Profil ───────────────────────────────────────────────────────────────
  DriverProfileModel? _profile;
  DriverProfileModel? get profile => _profile;

  // Cache rapide du nom affiché dans la navbar (chargé avant l'API)
  String? _cachedPrenom;
  String? _cachedName;
  String? _cachedCodeId;
  String? get cachedPrenom => _cachedPrenom;
  String? get cachedName => _cachedName;
  String? get cachedCodeId => _cachedCodeId;

  /// Vrai tant que le profil n'est pas encore disponible (ni cache ni API)
  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  File? _profileImageFile;
  File? get profileImage => _profileImageFile;

  // ─── Dashboard ────────────────────────────────────────────────────────────
  List<VoyageModel> _todayVoyages = [];
  List<VoyageModel> get todayVoyages => _todayVoyages;

  List<VoyageModel> _upcomingVoyages = [];
  List<VoyageModel> get upcomingVoyages => _upcomingVoyages;

  // Convois affichés sur le dashboard
  List<ConvoiModel> _todayConvois = [];
  List<ConvoiModel> get todayConvois => _todayConvois;

  List<ConvoiModel> _upcomingConvois = [];
  List<ConvoiModel> get upcomingConvois => _upcomingConvois;

  // Convois bloqués : en_cours dont la date est passée (oubli de Terminer)
  List<ConvoiModel> _blockedConvois = [];
  List<ConvoiModel> get blockedConvois => _blockedConvois;

  Map<String, dynamic> _stats = {};
  Map<String, dynamic> get stats => _stats;

  // ─── Voyages (onglet Voyages) ─────────────────────────────────────────────
  List<VoyageModel> _voyages = [];
  List<VoyageModel> get voyages => _voyages;

  // Voyages bloqués : en_cours depuis une date passée
  List<VoyageModel> _blockedVoyages = [];
  List<VoyageModel> get blockedVoyages => _blockedVoyages;

  // ─── Convois (missions de convoyage) ──────────────────────────────────────
  List<ConvoiModel> _convois = [];
  List<ConvoiModel> get convois => _convois;

  bool _isLoadingConvois = false;
  bool get isLoadingConvois => _isLoadingConvois;

  String? _convoisTab = 'active';
  String? get convoisTab => _convoisTab;

  String? _convoisDate;
  String? get convoisDate => _convoisDate;

  // ─── Historique ───────────────────────────────────────────────────────────
  List<VoyageModel> _historyVoyages = [];
  List<VoyageModel> get historyVoyages => _historyVoyages;

  // ─── Messages ─────────────────────────────────────────────────────────────
  List<DriverMessageModel> _messages = [];
  List<DriverMessageModel> get messages => _messages;

  int _unreadMessagesCount = 0;
  int get unreadMessagesCount => _unreadMessagesCount;

  // ─── Notifications locales ────────────────────────────────────────────────
  List<DriverNotification> _notifications = [];
  List<DriverNotification> get notifications => _notifications;
  int get unreadNotificationsCount =>
      _notifications.where((n) => !n.isRead).length;

  // ─── Stream de refresh déclenché par notification push ───────────────────
  final StreamController<String> _notifRefreshController =
  StreamController.broadcast();
  Stream<String> get notifRefreshStream => _notifRefreshController.stream;

  /// Appelé par PushNotificationService quand une notification pertinente arrive.
  /// Rafraîchit le dashboard ET diffuse un message pour l'UI (ex: SnackBar).
  void triggerNotificationRefresh(String message) {
    loadDashboard();
    _notifRefreshController.add(message);
  }

  // ─── États de chargement ──────────────────────────────────────────────────
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingVoyages = false;
  bool get isLoadingVoyages => _isLoadingVoyages;

  bool _isLoadingHistory = false;
  bool get isLoadingHistory => _isLoadingHistory;

  bool _isLoadingMessages = false;
  bool get isLoadingMessages => _isLoadingMessages;

  String? _error;
  String? get error => _error;

  // ─── Navigation ───────────────────────────────────────────────────────────
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int i) {
    _currentIndex = i;
    notifyListeners();
  }

  // ─── Cible de signalement pré-sélectionnée ───────────────────────────────
  // Utilisé par les écrans Voyages/Convois pour pré-remplir le formulaire
  // de signalement quand l'utilisateur clique « Faire un signalement ».
  ConvoiModel? _signalementConvoi;
  ConvoiModel? get signalementConvoi => _signalementConvoi;

  VoyageModel? _signalementVoyage;
  VoyageModel? get signalementVoyage => _signalementVoyage;

  /// Définit la cible (convoi OU voyage, mutuellement exclusifs) à pré-sélectionner
  /// sur l'écran Signalements. Passer `null` aux deux pour effacer.
  void setSignalementTarget({ConvoiModel? convoi, VoyageModel? voyage}) {
    _signalementConvoi = convoi;
    _signalementVoyage = voyage;
    notifyListeners();
  }

  /// Remet à zéro la cible de signalement (à appeler après consommation
  /// par l'écran Signalements).
  void clearSignalementTarget() {
    if (_signalementConvoi == null && _signalementVoyage == null) return;
    _signalementConvoi = null;
    _signalementVoyage = null;
    notifyListeners();
  }

  // ─── Voyage actif (pour le dashboard) ────────────────────────────────────
  VoyageModel? get currentVoyage {
    final enCours =
        _todayVoyages.where((v) => v.statut == 'en_cours').firstOrNull;
    if (enCours != null) return enCours;
    final confirme =
        _todayVoyages.where((v) => v.statut == 'confirme').firstOrNull;
    if (confirme != null) return confirme;
    return _todayVoyages.where((v) => v.statut == 'en_attente').firstOrNull;
  }

  // ─── Init ─────────────────────────────────────────────────────────────────
  DriverProvider() {
    _init();
  }

  Future<void> _init() async {
    await Future.wait([
      loadCachedProfileImage(),
      _loadCachedProfile(),      // ← charge nom/prénom depuis prefs AVANT l'API
    ]);
    _isInitializing = false;
    notifyListeners();
    await loadDashboard();        // ← ensuite on appelle le réseau
  }

  /// Charge le nom/prénom/codeId depuis le cache SharedPreferences.
  Future<void> _loadCachedProfile() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedPrenom = prefs.getString('driver_cached_prenom');
    _cachedName   = prefs.getString('driver_cached_name');
    _cachedCodeId = prefs.getString('driver_cached_code_id');
  }

  /// Persiste le profil en cache local après un appel API réussi.
  Future<void> _saveCachedProfile(DriverProfileModel p) async {
    final prefs = await SharedPreferences.getInstance();
    if (p.prenom != null) await prefs.setString('driver_cached_prenom', p.prenom!);
    if (p.name   != null) await prefs.setString('driver_cached_name',   p.name!);
    if (p.codeId != null) await prefs.setString('driver_cached_code_id', p.codeId!);
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────
  Future<void> loadDashboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([_loadProfile(), _loadDashboardData()]);
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadProfile() async {
    try {
      _profile = await _ds.getProfile();
      if (_profile != null) {
        // Met à jour le cache rapide et les valeurs locales
        _cachedPrenom = _profile!.prenom ?? _cachedPrenom;
        _cachedName   = _profile!.name   ?? _cachedName;
        _cachedCodeId = _profile!.codeId ?? _cachedCodeId;
        await _saveCachedProfile(_profile!);
      }
    } catch (_) {}
  }

  Future<void> _loadDashboardData() async {
    final data = await _ds.getDashboardData();
    if (data['success'] == true) {
      _todayVoyages = ((data['today_voyages'] ?? []) as List)
          .map((v) => VoyageModel.fromJson(v as Map<String, dynamic>))
          .toList();
      _upcomingVoyages = ((data['upcoming_voyages'] ?? []) as List)
          .map((v) => VoyageModel.fromJson(v as Map<String, dynamic>))
          .toList();
      // Voyages bloqués (en_cours d'un jour passé : oubli de "Terminer")
      _blockedVoyages = ((data['blocked_voyages'] ?? []) as List)
          .map((v) => VoyageModel.fromJson(v as Map<String, dynamic>))
          .toList();
      // Convois
      _todayConvois = ((data['today_convois'] ?? []) as List)
          .map((c) => ConvoiModel.fromJson(c as Map<String, dynamic>))
          .toList();
      _upcomingConvois = ((data['upcoming_convois'] ?? []) as List)
          .map((c) => ConvoiModel.fromJson(c as Map<String, dynamic>))
          .toList();
      _blockedConvois = ((data['blocked_convois'] ?? []) as List)
          .map((c) => ConvoiModel.fromJson(c as Map<String, dynamic>))
          .toList();
      _stats = Map<String, dynamic>.from(data['stats'] ?? {});
    }
  }

  // ─── Voyages (liste complète) ─────────────────────────────────────────────
  Future<void> loadVoyages() async {
    _isLoadingVoyages = true;
    notifyListeners();
    try {
      final data = await _ds.getVoyages();
      if (data['success'] == true) {
        _voyages = ((data['voyages'] ?? []) as List)
            .map((v) => VoyageModel.fromJson(v as Map<String, dynamic>))
            .toList();
        // Charger aussi les voyages bloqués retournés par l'API
        _blockedVoyages = ((data['blocked_voyages'] ?? []) as List)
            .map((v) => VoyageModel.fromJson(v as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {} finally {
      _isLoadingVoyages = false;
      notifyListeners();
    }
  }

  // ─── Historique ───────────────────────────────────────────────────────────
  Future<void> loadHistory() async {
    _isLoadingHistory = true;
    notifyListeners();
    try {
      final data = await _ds.getVoyageHistory();
      if (data['success'] == true) {
        _historyVoyages = ((data['voyages'] ?? []) as List)
            .map((v) => VoyageModel.fromJson(v as Map<String, dynamic>))
            .toList();
      }
    } catch (_) {} finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  // ─── Messages ─────────────────────────────────────────────────────────────
  Future<void> loadMessages() async {
    _isLoadingMessages = true;
    notifyListeners();
    try {
      final data = await _ds.getMessages();
      if (data['success'] == true) {
        _messages = ((data['messages'] ?? []) as List)
            .map((m) => DriverMessageModel.fromJson(m as Map<String, dynamic>))
            .toList();
        _unreadMessagesCount =
            int.tryParse(data['unread_count']?.toString() ?? '0') ?? 0;
      }
    } catch (_) {} finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  void markMessageAsRead(DriverMessageModel msg) {
    if (_unreadMessagesCount > 0) _unreadMessagesCount--;
    notifyListeners();
    // Marque comme lu côté serveur (fire and forget)
    _ds.getMessageDetails(msg.id, msg.source);
  }

  Future<bool> sendMessage(String subject, String message) async {
    try {
      final r = await _ds.sendMessageToGare(subject, message);
      return r['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── Cycle de vie d'un voyage ─────────────────────────────────────────────
  Future<void> confirmVoyage(int id) async {
    final updated = await _ds.confirmVoyage(id);
    _patchTodayVoyage(updated);
  }

  Future<void> startVoyage(int id) async {
    final updated = await _ds.startVoyage(id);
    _patchTodayVoyage(updated);
  }

  /// Confirm (if en_attente) then start in one tap — used from dashboard.
  Future<void> confirmAndStartVoyage(int id) async {
    final voyage = currentVoyage;
    if (voyage != null && voyage.statut == 'en_attente') {
      try {
        final confirmed = await _ds.confirmVoyage(id);
        _patchTodayVoyage(confirmed);
      } catch (_) {
        // If confirmation fails, still attempt to start
      }
    }
    final started = await _ds.startVoyage(id);
    _patchTodayVoyage(started);
  }

  Future<void> cancelVoyage(int id, {String? reason}) async {
    await _ds.cancelVoyage(id, reason: reason);
    await loadDashboard();
  }

  Future<void> completeVoyage(int id) async {
    await _ds.completeVoyage(id);
    await loadDashboard();
  }

  // ─── Convois : cycle de vie ───────────────────────────────────────────────

  /// Charge la liste des convois assignés au chauffeur.
  /// [tab] = 'active' (défaut) | 'effectues' | 'non_effectues'
  /// [date] : YYYY-MM-DD, utilisé pour filtrer l'onglet "active"
  Future<void> loadConvois({String? tab, String? date}) async {
    _isLoadingConvois = true;
    _convoisTab = tab ?? _convoisTab;
    _convoisDate = date ?? _convoisDate;
    notifyListeners();
    try {
      _convois = await _ds.getConvois(
        date: _convoisDate,
        tab: _convoisTab,
      );
    } catch (e) {
      _error = e.toString().replaceAll('Exception:', '').trim();
    } finally {
      _isLoadingConvois = false;
      notifyListeners();
    }
  }

  Future<ConvoiModel> getConvoiDetails(int id) async {
    return await _ds.getConvoiDetails(id);
  }

  Future<ConvoiModel> startConvoi(int id) async {
    final updated = await _ds.startConvoi(id);
    _patchConvoi(updated);
    return updated;
  }

  /// Termine un convoi. Retourne le message renvoyé par le serveur
  /// (utile pour afficher "Aller terminé, retour prévu le ...").
  Future<Map<String, dynamic>> completeConvoi(int id) async {
    final r = await _ds.completeConvoi(id);
    // Si c'était juste la fin de l'aller, le convoi reste dans la liste mais
    // passe à aller_done=true ; sinon il sort des "actifs"
    await loadConvois();
    return r;
  }

  Future<void> cancelConvoi(int id, String motif) async {
    await _ds.cancelConvoi(id, motif);
    await loadConvois();
  }

  void _patchConvoi(ConvoiModel updated) {
    final i = _convois.indexWhere((c) => c.id == updated.id);
    if (i != -1) {
      _convois[i] = updated;
    } else {
      _convois.insert(0, updated);
    }
    notifyListeners();
  }

  void _patchTodayVoyage(VoyageModel updated) {
    final i = _todayVoyages.indexWhere((v) => v.id == updated.id);
    if (i != -1) {
      _todayVoyages[i] = updated;
    } else {
      _todayVoyages.add(updated);
    }
    notifyListeners();
  }

  // ─── Scanner de billets ───────────────────────────────────────────────────

  /// Step 1: Search reservation by reference — returns data without confirming.
  Future<Map<String, dynamic>> searchReservation(String reference) async {
    try {
      return await _ds.searchReservation(reference);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception:', '').trim(),
      };
    }
  }

  /// Step 2: Confirm boarding after driver validation.
  Future<Map<String, dynamic>> confirmEmbarquement(String reference) async {
    try {
      return await _ds.confirmEmbarquement(reference);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception:', '').trim(),
      };
    }
  }

  /// Legacy one-shot validate (search + confirm) — kept for compatibility.
  Future<Map<String, dynamic>> validateTicket(String reference) async {
    try {
      final search = await _ds.searchReservation(reference);
      if (search['success'] != true) {
        return {
          'success': false,
          'message': search['message'] ?? 'Billet introuvable',
        };
      }
      return await _ds.confirmEmbarquement(reference);
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception:', '').trim(),
      };
    }
  }

  // ─── Signalements ─────────────────────────────────────────────────────────
  Future<void> submitReport({
    required String type,
    required String description,
    int? voyageId,
    int? convoiId,
    double? latitude,
    double? longitude,
    File? photo,
  }) async {
    final data = <String, dynamic>{
      'type': _typeToApi(type),
      'description': description,
      if (voyageId != null) 'voyage_id': voyageId,
      if (convoiId != null) 'convoi_id': convoiId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
    };
    if (photo != null) {
      data['photo'] = await MultipartFile.fromFile(
        photo.path,
        filename: photo.path.split('/').last,
      );
    }
    await _ds.createSignalement(data);
  }

  String _typeToApi(String display) {
    if (display.contains('Panne')) return 'panne';
    if (display.contains('Accident')) return 'accident';
    if (display.contains('Incident') || display.contains('passager')) {
      return 'comportement';
    }
    if (display.contains('route') || display.contains('Route')) return 'retard';
    return 'autre';
  }

  // ─── Image de profil (locale) ─────────────────────────────────────────────
  Future<void> loadCachedProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString('driver_profile_image');
    if (path != null && File(path).existsSync()) {
      _profileImageFile = File(path);
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String path) async {
    // Show locally immediately
    _profileImageFile = File(path);
    notifyListeners();

    // Upload to server
    try {
      final multipart = await MultipartFile.fromFile(
        path,
        filename: path.split('/').last,
      );
      final updated = await _ds.updateProfile({'profile_picture': multipart});
      _profile = updated;
      // Server now holds the photo — no need to cache local path
      _profileImageFile = null;
      notifyListeners();
    } catch (_) {
      // Upload failed — keep local file as fallback and cache path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('driver_profile_image', path);
    }
  }

  /// Save editable profile fields to server.
  Future<void> updateProfileFields(Map<String, dynamic> fields) async {
    final updated = await _ds.updateProfile(fields);
    _profile = updated;
    notifyListeners();
  }

  // ─── Notifications locales ────────────────────────────────────────────────
  void markNotificationAsRead(String id) {
    final i = _notifications.indexWhere((n) => n.id == id);
    if (i != -1) {
      _notifications[i].isRead = true;
      notifyListeners();
    }
  }

  void addNotification(DriverNotification n) {
    _notifications.insert(0, n);
    notifyListeners();
  }

  // ─── Mot de passe ─────────────────────────────────────────────────────────
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    await _ds.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  // ─── Déconnexion ──────────────────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _ds.logout();
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _profile = null;
    _cachedPrenom = null;
    _cachedName = null;
    _cachedCodeId = null;
    _isInitializing = true;
    _todayVoyages = [];
    _upcomingVoyages = [];
    _historyVoyages = [];
    _voyages = [];
    _blockedVoyages = [];
    _convois = [];
    _todayConvois = [];
    _upcomingConvois = [];
    _blockedConvois = [];
    _messages = [];
    _notifications = [];
    _profileImageFile = null;
    _signalementConvoi = null;
    _signalementVoyage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _notifRefreshController.close();
    super.dispose();
  }
}
