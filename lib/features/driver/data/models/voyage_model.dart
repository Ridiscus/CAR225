class VoyageModel {
  final int id;
  final String dateVoyage;
  final String statut;
  final int occupancy;
  final String? tempsRestant;
  final VoyageProgrammeModel? programme;
  final VoyageVehiculeModel? vehicule;
  final String? estimatedArrivalAt;

  VoyageModel({
    required this.id,
    required this.dateVoyage,
    required this.statut,
    required this.occupancy,
    this.tempsRestant,
    this.programme,
    this.vehicule,
    this.estimatedArrivalAt,
  });

  String get status => statut;
  bool get hasArrived => (statut == 'terminé' || statut == 'arrivé') && (estimatedArrivalAt != null && estimatedArrivalAt != "NULL");

  factory VoyageModel.fromJson(Map<String, dynamic> json) {
    return VoyageModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      dateVoyage: json['date_voyage']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      occupancy: json['occupancy'] != null ? int.tryParse(json['occupancy'].toString()) ?? 0 : 0,
      tempsRestant: json['temps_restant']?.toString(),
      programme: json['programme'] != null ? VoyageProgrammeModel.fromJson(json['programme']) : null,
      vehicule: json['vehicule'] != null ? VoyageVehiculeModel.fromJson(json['vehicule']) : null,
      estimatedArrivalAt: json['estimated_arrival_at']?.toString(),
    );
  }
}

class VoyageProgrammeModel {
  final int id;
  final String pointDepart;
  final String pointArrive;
  final String heureDepart;
  final String heureArrive;
  final String gareDepart;
  final String gareArrivee;
  final double tarif;
  final int capacity;
  // Coordonnées GPS des gares (pour le tracking)
  final double? gareDepartLat;
  final double? gareDepartLng;
  final double? gareArriveeLat;
  final double? gareArriveeLng;

  VoyageProgrammeModel({
    required this.id,
    required this.pointDepart,
    required this.pointArrive,
    required this.heureDepart,
    required this.heureArrive,
    required this.gareDepart,
    required this.gareArrivee,
    required this.tarif,
    required this.capacity,
    this.gareDepartLat,
    this.gareDepartLng,
    this.gareArriveeLat,
    this.gareArriveeLng,
  });

  factory VoyageProgrammeModel.fromJson(Map<String, dynamic> json) {
    return VoyageProgrammeModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      pointDepart: json['point_depart']?.toString() ?? '',
      pointArrive: json['point_arrive']?.toString() ?? '',
      heureDepart: json['heure_depart']?.toString() ?? '',
      heureArrive: json['heure_arrive']?.toString() ?? '',
      gareDepart: _gareName(json, 'gare_depart'),
      gareArrivee: _gareName(json, 'gare_arrivee'),
      tarif: json['montant_billet'] != null ? double.tryParse(json['montant_billet'].toString()) ?? 0.0 : 0.0,
      capacity: json['capacity'] != null ? int.tryParse(json['capacity'].toString()) ?? 0 : 0,
      gareDepartLat: _gareCoord(json, 'gare_depart', 'lat'),
      gareDepartLng: _gareCoord(json, 'gare_depart', 'lng'),
      gareArriveeLat: _gareCoord(json, 'gare_arrivee', 'lat'),
      gareArriveeLng: _gareCoord(json, 'gare_arrivee', 'lng'),
    );
  }

  /// Extract gare name: tries nested object first, falls back to string field.
  static String _gareName(Map<String, dynamic> json, String key) {
    final val = json[key];
    if (val is Map) {
      return val['nom']?.toString() ??
          val['name']?.toString() ??
          val['libelle']?.toString() ??
          '';
    }
    return val?.toString() ?? '';
  }

  /// Extract coordinate from multiple possible field naming conventions.
  static double? _gareCoord(Map<String, dynamic> json, String prefix, String axis) {
    // 1. Try flat fields: gare_depart_lat / gare_depart_lng
    final flat = json['${prefix}_$axis'];
    if (flat != null) {
      final v = double.tryParse(flat.toString());
      if (v != null) return v;
    }
    // 2. Try flat latitude/longitude variants
    final altKey = axis == 'lat' ? 'latitude' : 'longitude';
    final flat2 = json['${prefix}_$altKey'];
    if (flat2 != null) {
      final v = double.tryParse(flat2.toString());
      if (v != null) return v;
    }
    // 3. Try nested gare object: json['gare_depart'] is a Map
    final nested = json[prefix];
    if (nested is Map) {
      final keys = axis == 'lat'
          ? ['lat', 'latitude', 'gps_lat', 'coordonnee_lat']
          : ['lng', 'lon', 'longitude', 'gps_lng', 'coordonnee_lng'];
      for (final k in keys) {
        final v = double.tryParse(nested[k]?.toString() ?? '');
        if (v != null) return v;
      }
    }
    return null;
  }
}

class VoyageVehiculeModel {
  final int id;
  final String marque;
  final String? modele;
  final String immatriculation;
  final int places;

  VoyageVehiculeModel({
    required this.id,
    required this.marque,
    this.modele,
    required this.immatriculation,
    required this.places,
  });

  factory VoyageVehiculeModel.fromJson(Map<String, dynamic> json) {
    return VoyageVehiculeModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      marque: json['marque']?.toString() ?? '',
      modele: json['modele']?.toString(),
      immatriculation: json['immatriculation']?.toString() ?? '',
      places: json['nombre_place'] != null ? int.tryParse(json['nombre_place'].toString()) ?? 0 : 0,
    );
  }
}

extension VoyageModelUI on VoyageModel {
  String get departureStation => programme?.gareDepart ?? '';
  String get arrivalStation => programme?.gareArrivee ?? '';
  String get carRegistration => vehicule?.immatriculation ?? '';
  
  DateTime get scheduledDepartureTime {
    try {
      final hDepart = programme?.heureDepart;
      if (hDepart != null && hDepart.contains(':')) {
        final parts = hDepart.split(':');
        if (parts.length >= 2) {
          final now = DateTime.now();
          final hour = int.tryParse(parts[0]) ?? 0;
          final minute = int.tryParse(parts[1]) ?? 0;
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }
      return dateVoyage.isNotEmpty ? DateTime.tryParse(dateVoyage) ?? DateTime.now() : DateTime.now();
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime get scheduledArrivalTime {
    try {
      final hArrive = programme?.heureArrive;
      if (hArrive != null && hArrive.contains(':')) {
        final timeParts = hArrive.split(':');
        if (timeParts.length >= 2) {
          final now = DateTime.now();
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          return DateTime(now.year, now.month, now.day, hour, minute);
        }
      }
      return scheduledDepartureTime.add(const Duration(hours: 3));
    } catch (_) {
      return scheduledDepartureTime.add(const Duration(hours: 3));
    }
  }

  Duration get timeRemaining {
    final now = DateTime.now();
    if (scheduledArrivalTime.isBefore(now)) return Duration.zero;
    return scheduledArrivalTime.difference(now);
  }

  double get price => programme?.tarif ?? 0.0;
  int get passengersCount => occupancy;
  
  int get totalSeats {
    final prog = programme;
    if (prog != null && prog.capacity > 0) {
      return prog.capacity;
    }
    final v = vehicule;
    if (v != null) {
      return v.places;
    }
    return 70;
  }
}
