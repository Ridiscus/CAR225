// models/live_trip_location.dart
class LiveTripLocation {
  final double latitude;
  final double longitude;
  final String? speed;
  final String? heading;
  final String lastUpdate;
  final String chauffeur;
  final String vehicule;
  final String depart;
  final String arrivee;
  final String heureDepart;
  final String heureArrivee;
  final String dateVoyage;
  final String tempsRestant;

  LiveTripLocation({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    required this.lastUpdate,
    required this.chauffeur,
    required this.vehicule,
    required this.depart,
    required this.arrivee,
    required this.heureDepart,
    required this.heureArrivee,
    required this.dateVoyage,
    required this.tempsRestant,
  });

  factory LiveTripLocation.fromJson(Map<String, dynamic> json) {
    final loc = json['location'] ?? {};
    return LiveTripLocation(
      latitude: loc['latitude']?.toDouble() ?? 0.0,
      longitude: loc['longitude']?.toDouble() ?? 0.0,
      speed: loc['speed']?.toString(),
      heading: loc['heading']?.toString(),
      lastUpdate: loc['last_update'] ?? '',
      chauffeur: loc['chauffeur'] ?? '',
      vehicule: loc['vehicule'] ?? '',
      depart: loc['depart'] ?? '',
      arrivee: loc['arrivee'] ?? '',
      heureDepart: loc['heure_depart'] ?? '',
      heureArrivee: loc['heure_arrivee'] ?? '',
      dateVoyage: loc['date_voyage'] ?? '',
      tempsRestant: loc['temps_restant'] ?? '',
    );
  }
}