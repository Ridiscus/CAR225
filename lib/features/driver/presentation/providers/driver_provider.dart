import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/trip_model.dart';

class DriverProvider extends ChangeNotifier {
  File? _profileImage;
  File? get profileImage => _profileImage;

  TripModel? _currentTrip;
  TripModel? get currentTrip => _currentTrip;

  List<TripModel> _allTrips = [];
  List<TripModel> get allTrips => _allTrips;

  // Filtres
  List<TripModel> get todayTrips => _allTrips
      .where(
        (t) =>
            t.scheduledDepartureTime.day == DateTime.now().day &&
            t.scheduledDepartureTime.month == DateTime.now().month &&
            t.scheduledDepartureTime.year == DateTime.now().year &&
            t.status != 'completed' &&
            t.status != 'cancelled',
      )
      .toList();

  List<TripModel> get upcomingTrips => _allTrips
      .where(
        (t) =>
            t.scheduledDepartureTime.isAfter(DateTime.now()) &&
            t.scheduledDepartureTime.day != DateTime.now().day &&
            t.status != 'completed' &&
            t.status != 'cancelled',
      )
      .toList();

  List<TripModel> get historyTrips => _allTrips
      .where((t) => t.status == 'completed' || t.status == 'cancelled')
      .toList();

  List<TripModel> get activeTrips => _allTrips
      .where((t) => t.status == 'started' || t.status == 'pending')
      .toList();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  int _currentIndex = 0;
  int get currentIndex => _currentIndex;

  void setIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  DriverProvider() {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    await loadCachedImage();
    await fetchAllTrips();

    _isLoading = false;
    notifyListeners();
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

  Future<void> fetchAllTrips() async {
    await Future.delayed(const Duration(seconds: 1));

    _allTrips = [
      TripModel(
        id: "TRIP-001",
        departureStation: "Gare Nord (Adjamé)",
        arrivalStation: "Gare Sud (Treichville)",
        carRegistration: "AB-123-CD",
        scheduledDepartureTime: DateTime.now().add(const Duration(hours: 1)),
        scheduledArrivalTime: DateTime.now().add(const Duration(hours: 3)),
        status: 'started',
        price: 5000,
        passengersCount: 42,
        totalSeats: 70,
      ),
      TripModel(
        id: "TRIP-002",
        departureStation: "Gare Bassam",
        arrivalStation: "Gare Nord",
        carRegistration: "EF-456-GH",
        scheduledDepartureTime: DateTime.now().add(
          const Duration(days: 1, hours: 2),
        ),
        scheduledArrivalTime: DateTime.now().add(
          const Duration(days: 1, hours: 5),
        ),
        status: 'pending',
        price: 2500,
        passengersCount: 15,
        totalSeats: 32,
      ),
      TripModel(
        id: "TRIP-003",
        departureStation: "Gare Yamoussoukro",
        arrivalStation: "Gare Bouaké",
        carRegistration: "IJ-789-KL",
        scheduledDepartureTime: DateTime.now().subtract(
          const Duration(days: 1),
        ),
        scheduledArrivalTime: DateTime.now().subtract(
          const Duration(days: 1, hours: -3),
        ),
        status: 'completed',
        actualDepartureTime: DateTime.now().subtract(const Duration(days: 1)),
        actualArrivalTime: DateTime.now().subtract(
          const Duration(days: 1, hours: -3),
        ),
        price: 7000,
        passengersCount: 65,
        totalSeats: 70,
      ),
      TripModel(
        id: "TRIP-004",
        departureStation: "Gare Korhogo",
        arrivalStation: "Gare Ferké",
        carRegistration: "MN-012-OP",
        scheduledDepartureTime: DateTime.now().subtract(
          const Duration(days: 2),
        ),
        scheduledArrivalTime: DateTime.now().subtract(
          const Duration(days: 2, hours: -2),
        ),
        status: 'cancelled',
        price: 3000,
        passengersCount: 0,
        totalSeats: 32,
      ),
    ];

    // On définit le premier trajet du jour comme "current" s'il existe
    if (todayTrips.isNotEmpty) {
      _currentTrip = todayTrips.first;
    }

    notifyListeners();
  }

  Future<void> markDeparture() async {
    if (_currentTrip != null) {
      final index = _allTrips.indexWhere((t) => t.id == _currentTrip!.id);
      if (index != -1) {
        _allTrips[index] = _allTrips[index].copyWith(
          status: 'started',
          actualDepartureTime: DateTime.now(),
        );
        _currentTrip = _allTrips[index];
        notifyListeners();
      }
    }
  }

  Future<void> markArrival() async {
    if (_currentTrip != null) {
      final index = _allTrips.indexWhere((t) => t.id == _currentTrip!.id);
      if (index != -1) {
        _allTrips[index] = _allTrips[index].copyWith(
          status: 'completed',
          actualArrivalTime: DateTime.now(),
        );
        _currentTrip = null; // Une fois terminé, on décharge le trajet courant
        notifyListeners();
      }
    }
  }

  Future<void> submitReport({
    required String type,
    required String description,
    required String tripId,
  }) async {
    // Simulation d'envoi de rapport
    await Future.delayed(const Duration(seconds: 1));
    print("Rapport envoyé: $type - $description pour le trajet $tripId");
  }
}
