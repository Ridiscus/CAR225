import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/datasources/driver_remote_data_source.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../data/models/driver_profile_model.dart';
import '../../data/models/voyage_model.dart';
import '../../data/models/driver_message_model.dart';
import '../../data/models/driver_scan_info_model.dart';
import '../../data/models/signalement_model.dart';

class DriverProvider extends ChangeNotifier {
  final DriverRepositoryImpl _repo = DriverRepositoryImpl(remoteDataSource: DriverRemoteDataSourceImpl());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DriverProfileModel? _profile;
  DriverProfileModel? get profile => _profile;

  File? _profileImage;
  File? get profileImage => _profileImage;

  DriverProvider() {
    loadCachedImage();
    loadProfile();
    loadDashboard().then((_) => _checkOngoingTracking());
  }

  Timer? _locationTimer;

  void _checkOngoingTracking() {
    final ongoing = currentTrip;
    if (ongoing != null && ongoing.statut == 'en_cours') {
      _startLocationTracking(ongoing.id);
    } else {
      _stopLocationTracking();
    }
  }

  void _startLocationTracking(int voyageId) {
    _locationTimer?.cancel();
    
    // Premier envoi immédiat
    _sendLocation(voyageId);

    _locationTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      _sendLocation(voyageId);
    });
  }

  Future<void> _sendLocation(int voyageId) async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      await updateLocation(
        voyageId,
        position.latitude,
        position.longitude,
        speed: position.speed,
        heading: position.heading,
      );
    } catch (e) {
      debugPrint("Location tracking error: $e");
    }
  }

  void _stopLocationTracking() {
    _locationTimer?.cancel();
    _locationTimer = null;
  }

  Future<void> loadCachedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? imagePath = prefs.getString('driver_profile_image');
    if (imagePath != null && File(imagePath).existsSync()) {
      _profileImage = File(imagePath);
      notifyListeners();
    }
  }

  Future<void> updateProfileImage(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('driver_profile_image', path);
    _profileImage = File(path);
    notifyListeners();
  }

  // Trips lists (Vocabulaire UI adapté pour Minimiser les casses, type VoyageModel)
  List<VoyageModel> _todayTrips = [];
  List<VoyageModel> get todayTrips => _todayTrips;

  List<VoyageModel> _upcomingTrips = [];
  List<VoyageModel> get upcomingTrips => _upcomingTrips;

  List<VoyageModel> _historyTrips = [];
  List<VoyageModel> get historyTrips => _historyTrips;

  VoyageModel? _selectedTripForReport;
  VoyageModel? get selectedTripForReport => _selectedTripForReport;

  void setSelectedTripForReport(VoyageModel? trip) {
    _selectedTripForReport = trip;
    notifyListeners();
  }

  List<DriverMessageModel> _messages = [];
  List<DriverMessageModel> get messages => _messages;

  DriverScanInfoModel? _scanInfo;
  DriverScanInfoModel? get scanInfo => _scanInfo;

  List<SignalementModel> _signalements = [];
  List<SignalementModel> get signalements => _signalements;

  Map<String, dynamic>? _stats;
  Map<String, dynamic>? get stats => _stats;

  VoyageModel? get currentTrip {
    try {
      return _todayTrips.firstWhere((t) => t.statut == 'en_cours' || t.statut == 'confirmé');
    } catch (e) {
      if (_todayTrips.isNotEmpty) {
        return _todayTrips.firstWhere((t) => t.statut != 'terminé' && t.statut != 'annulé', orElse: () => _todayTrips.first);
      }
      return null;
    }
  }

  List<VoyageModel> get activeTrips => _todayTrips.where((t) => t.statut == 'en_cours' || t.statut == 'confirmé').toList();

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  // Loader state modifier
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() => _setError(null);

  Future<void> loadProfile() async {
    _setLoading(true);
    _setError(null);
    try {
      final res = await _repo.getProfile();
      _profile = res;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadDashboard() async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _repo.getDashboardData();
      if (data['success'] == true) {
        _todayTrips = (data['today_voyages'] as List).map((v) => VoyageModel.fromJson(v)).toList();
        _upcomingTrips = (data['upcoming_voyages'] as List).map((v) => VoyageModel.fromJson(v)).toList();
        _stats = data['stats'];
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchAllTrips() async {
    await loadDashboard();
  }

  Future<void> loadVoyagesHistory({int page = 1}) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _repo.getVoyageHistory(page: page);
      print("HISTORY DATA RECEIVED: ${data['voyages'] != null ? (data['voyages'] as List).length : 0} items");
      if (data['success'] == true) {
        _historyTrips = (data['voyages'] as List).map((v) => VoyageModel.fromJson(v)).toList();
      }
    } catch (e) {
      print("HISTORY ERROR: $e");
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmVoyage(int voyageId) async {
    _setLoading(true);
    try {
      await _repo.confirmVoyage(voyageId);
      await loadDashboard(); // refresh
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markDeparture(int voyageId) async {
    _setLoading(true);
    try {
      await _repo.startVoyage(voyageId);
      await loadDashboard(); // refresh
      _startLocationTracking(voyageId);
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> markArrival(int voyageId) async {
    _setLoading(true);
    try {
      await _repo.completeVoyage(voyageId);
      await loadDashboard(); // refresh
      _stopLocationTracking();
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSignalements({int page = 1}) async {
    _setLoading(true);
    try {
      final data = await _repo.getSignalements(page: page);
      if (data['success'] == true) {
        _signalements = (data['signalements']['data'] ?? data['signalements'] as List)
            .map<SignalementModel>((v) => SignalementModel.fromJson(v))
            .toList();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> submitReport({
    required String type,
    required String description,
    required String tripId,
    File? image,
    double? latitude,
    double? longitude,
  }) async {
    _setLoading(true);
    try {
      Map<String, dynamic> data = {
        'voyage_id': tripId,
        'type': type.toLowerCase(),
        'description': description,
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
      };
      // La gestion de fichier multipart est traitée par fromMap(FormData) dans le data source
      // Mais pour simplifier ici : on omet la photo ou on utilise MultipartFile si c'est implémenté correctement avec dio.
      // Il faudrait adapter selon le package `dio` si 'photo': await MultipartFile.fromFile(image.path)
      
      await _repo.createSignalement(data);
      await loadSignalements(); // refresh
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateLocation(int voyageId, double lat, double lng, {double? speed, double? heading}) async {
    try {
      await _repo.updateLocation(voyageId, lat, lng, speed: speed, heading: heading);
    } catch (e) {
      print("Erreur update location gps: $e");
    }
  }

  // Scanner & Messages
  Future<void> loadMessages({int page = 1}) async {
    _setLoading(true);
    try {
      final res = await _repo.getMessages(page: page);
      if (res['success'] == true) {
        // Le serveur renvoie directement la liste dans 'messages'
        final List msgList = res['messages'] is List 
            ? res['messages'] 
            : (res['messages']['data'] ?? []);
            
        _messages = msgList
            .map((m) => DriverMessageModel.fromJson(m))
            .toList();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadScanInfo() async {
    _setLoading(true);
    try {
      _scanInfo = await _repo.getScanInfo();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<Map<String, dynamic>> validateTicket(String reference) async {
    _setLoading(true);
    try {
      // 1. Rechercher la réservation
      final searchRes = await _repo.searchReservation(reference);
      if (searchRes['success'] != true) {
        return searchRes;
      }
      
      // 2. Confirmer l'embarquement
      final confirmRes = await _repo.confirmEmbarquement(reference);
      await loadScanInfo(); // refresh list
      return confirmRes;
    } catch (e) {
      _setError(e.toString());
      return {'success': false, 'message': e.toString()};
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendMessage(String subject, String message) async {
    _setLoading(true);
    try {
      await _repo.sendMessageToGare(subject, message);
      await loadMessages(); // Refresh
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markMessageAsRead(DriverMessageModel message) async {
    try {
      // L'appel aux détails marque automatiquement comme LU côté serveur
      await _repo.getMessageDetails(message.id, message.source);
      // Rafraîchir la liste locale pour mettre à jour le statut "isRead" et le badge
      await loadMessages();
      await loadDashboard(); // Pour décrémenter le badge sur l'accueil
    } catch (e) {
      debugPrint("Error marking message as read: $e");
    }
  }
}

