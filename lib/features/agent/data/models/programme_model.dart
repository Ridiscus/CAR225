// lib/data/models/programme_model.dart

/*class ProgrammeModel {
  final int id;
  final String pointDepart;
  final String pointArrive;
  final String heureDepart;
  final String gareDepart;
  final String gareArrivee;
  final int vehiculeId;
  final String immatriculation;

  ProgrammeModel({
    required this.id,
    required this.pointDepart,
    required this.pointArrive,
    required this.heureDepart,
    required this.gareDepart,
    required this.gareArrivee,
    required this.vehiculeId,
    required this.immatriculation,
  });

  factory ProgrammeModel.fromJson(Map<String, dynamic> json) {
    return ProgrammeModel(
      id: json['id'] ?? 0,
      pointDepart: json['point_depart'] ?? '',
      pointArrive: json['point_arrive'] ?? '',
      heureDepart: json['heure_depart'] ?? '',
      gareDepart: json['gare_depart'] ?? '',
      gareArrivee: json['gare_arrivee'] ?? '',
      vehiculeId: json['vehicule_id'] ?? 0,
      immatriculation: json['immatriculation'] ?? 'Inconnu',
    );
  }
}*/


class ProgrammeModel {
  final int id;
  final String pointDepart;
  final String pointArrive;
  final String? duree;

  // 🟢 NOUVEAUX CHAMPS BASÉS SUR LE JSON
  final String? heureDepart;
  final String? heureArrivee;
  final String? gareDepart;
  final String? gareArrivee;
  final int? vehiculeId;
  final String? immatriculation;
  final String? chauffeurNom;

  // Champs conservés pour la compatibilité
  final int montantBillet;
  final int placesDisponibles;

  ProgrammeModel({
    required this.id,
    required this.pointDepart,
    required this.pointArrive,
    this.duree,
    this.heureDepart,
    this.heureArrivee,
    this.gareDepart,
    this.gareArrivee,
    this.vehiculeId,
    this.immatriculation,
    this.chauffeurNom,
    this.montantBillet = 0,
    this.placesDisponibles = 0,
  });

  factory ProgrammeModel.fromJson(Map<String, dynamic> json) {
    return ProgrammeModel(
      id: json['id'] ?? 0,
      pointDepart: json['point_depart'] ?? "Inconnu",
      pointArrive: json['point_arrive'] ?? "Inconnu",
      duree: json['durer_parcours'],
      // 🟢 MAPPING DES NOUVEAUX CHAMPS
      heureDepart: json['heure_depart'],
      heureArrivee: json['heure_arrivee'], // S'il n'existe pas dans l'API, ce sera null
      gareDepart: json['gare_depart'],
      gareArrivee: json['gare_arrivee'],
      vehiculeId: json['vehicule_id'],
      immatriculation: json['immatriculation'],
      chauffeurNom: json['chauffeur_nom'], // S'il n'existe pas, ce sera null

      montantBillet: json['montant_billet'] ?? 0,
      placesDisponibles: json['places_disponibles'] ?? 0,
    );
  }

  // --- HELPER POUR L'UI ---
  String get depart {
    return pointDepart.split(',')[0].trim();
  }

  String get arrivee {
    return pointArrive.split(',')[0].trim();
  }

  String get trajet => "$depart → $arrivee";
}