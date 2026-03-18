class VoyageModel {
  final int id;
  final String dateVoyage;
  final String statut;
  final int occupancy;
  final VoyageProgrammeModel? programme;
  final VoyageVehiculeModel? vehicule;

  VoyageModel({
    required this.id,
    required this.dateVoyage,
    required this.statut,
    required this.occupancy,
    this.programme,
    this.vehicule,
  });

  factory VoyageModel.fromJson(Map<String, dynamic> json) {
    return VoyageModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      dateVoyage: json['date_voyage']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      occupancy: json['occupancy'] != null ? int.tryParse(json['occupancy'].toString()) ?? 0 : 0,
      programme: json['programme'] != null ? VoyageProgrammeModel.fromJson(json['programme']) : null,
      vehicule: json['vehicule'] != null ? VoyageVehiculeModel.fromJson(json['vehicule']) : null,
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

  VoyageProgrammeModel({
    required this.id,
    required this.pointDepart,
    required this.pointArrive,
    required this.heureDepart,
    required this.heureArrive,
    required this.gareDepart,
    required this.gareArrivee,
    required this.tarif,
  });

  factory VoyageProgrammeModel.fromJson(Map<String, dynamic> json) {
    return VoyageProgrammeModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      pointDepart: json['point_depart']?.toString() ?? '',
      pointArrive: json['point_arrive']?.toString() ?? '',
      heureDepart: json['heure_depart']?.toString() ?? '',
      heureArrive: json['heure_arrive']?.toString() ?? '',
      gareDepart: json['gare_depart']?.toString() ?? '',
      gareArrivee: json['gare_arrivee']?.toString() ?? '',
      tarif: json['tarif'] != null ? double.tryParse(json['tarif'].toString()) ?? 0.0 : 0.0,
    );
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
      places: json['places'] != null ? int.tryParse(json['places'].toString()) ?? 70 : 70,
    );
  }
}

extension VoyageModelUI on VoyageModel {
  String get departureStation => programme?.gareDepart ?? '';
  String get arrivalStation => programme?.gareArrivee ?? '';
  String get carRegistration => vehicule?.immatriculation ?? '';
  
  DateTime get scheduledDepartureTime {
    try {
      if (programme?.heureDepart != null) {
        // Mock parsing if heureDepart is not a full dateTime but 'HH:mm'
        final parts = programme!.heureDepart.split(':');
        final now = DateTime.now();
        return DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
      }
      return DateTime.parse(dateVoyage);
    } catch (_) {
      return DateTime.now();
    }
  }

  DateTime get scheduledArrivalTime {
    try {
      if (programme?.heureArrive != null && programme!.heureArrive.isNotEmpty) {
        final timeParts = programme!.heureArrive.split(':');
        final arrival = DateTime.parse(dateVoyage);
        return DateTime(
          arrival.year,
          arrival.month,
          arrival.day,
          int.parse(timeParts[0]),
          int.parse(timeParts[1]),
        );
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

  // legacy fields
  DateTime? get actualDepartureTime => null;
  DateTime? get actualArrivalTime => null;
  double get price => programme?.tarif ?? 0.0;
  int get passengersCount => occupancy;
  int get totalSeats => (vehicule != null) ? vehicule!.places : 70;
  String get status => statut;
}
