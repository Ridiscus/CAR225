/*class ActiveReservationModel {
  final int id; // ID de la réservation
  final int programmeId; // ID du programme (trajet prévu)
  final int? vehiculeId;  // ID du véhicule physique

  final String reference;
  final int seatNumber;
  final String pointDepart;
  final String pointArrive;
  final String heureDepart;
  final String heureArrive;
  final DateTime dateVoyage;
  final String compagnieName;
  final String vehiculeInfo;

  // ✅ NOUVEL AJOUT : Le statut pour le filtrage
  final String displayStatut;

  ActiveReservationModel({
    required this.id,
    required this.programmeId,
    required this.vehiculeId,
    required this.reference,
    required this.seatNumber,
    required this.pointDepart,
    required this.pointArrive,
    required this.heureDepart,
    required this.heureArrive,
    required this.dateVoyage,
    required this.compagnieName,
    required this.vehiculeInfo,
    required this.displayStatut, // ✅ On l'exige ici
  });

  factory ActiveReservationModel.fromJson(Map<String, dynamic> json) {
    // 1. Extraction des sous-objets
    final programme = json['programme'] ?? {};
    final compagnie = programme['compagnie'] ?? {};
    final vehicule = programme['vehicule'] ?? {};

    return ActiveReservationModel(
      id: json['id'],
      programmeId: programme['id'] ?? 0,
      vehiculeId: vehicule['id'],

      reference: json['reference'] ?? '',
      seatNumber: json['seat_number'] ?? 0,

      pointDepart: programme['point_depart'] ?? 'Inconnu',
      pointArrive: programme['point_arrive'] ?? 'Inconnu',
      heureDepart: programme['heure_depart'] ?? '--:--',
      heureArrive: programme['heure_arrive'] ?? '--:--',

      dateVoyage: DateTime.tryParse(json['date_voyage'] ?? '') ?? DateTime.now(),

      compagnieName: compagnie['name'] ?? 'Compagnie',
      vehiculeInfo: "${vehicule['modele'] ?? ''} - ${vehicule['immatriculation'] ?? ''}",

      // ✅ 2. RECUPERATION DU STATUT
      // On cherche d'abord 'display_statut', si c'est null on cherche 'statut',
      // et si les deux sont null on met une chaîne vide "".
      displayStatut: json['display_statut'] ?? json['statut'] ?? "",
    );
  }
}*/








class ActiveReservationModel {
  final int id; // ID de la réservation
  final int programmeId; // ID du programme (trajet prévu)
  final int? vehiculeId;  // ID du véhicule physique, nullable

  final String reference;
  final int seatNumber;
  final String pointDepart;
  final String pointArrive;
  final String heureDepart;
  final String heureArrive;
  final DateTime dateVoyage;
  final String compagnieName;
  final String vehiculeInfo;

  // Statut pour le filtrage
  final String displayStatut;

  ActiveReservationModel({
    required this.id,
    required this.programmeId,
    required this.vehiculeId,
    required this.reference,
    required this.seatNumber,
    required this.pointDepart,
    required this.pointArrive,
    required this.heureDepart,
    required this.heureArrive,
    required this.dateVoyage,
    required this.compagnieName,
    required this.vehiculeInfo,
    required this.displayStatut,
  });

  /*factory ActiveReservationModel.fromJson(Map<String, dynamic> json) {
    // Extraire les sous-objets de manière sécurisée
    final programme = json['programme'] as Map<String, dynamic>? ?? {};
    final compagnie = programme['compagnie'] as Map<String, dynamic>? ?? {};
    final vehicule = programme['vehicule'] as Map<String, dynamic>? ?? {};

    return ActiveReservationModel(
      id: json['id'] ?? 0,
      programmeId: programme['id'] ?? 0,

      // ⚠️ Cast explicite vers int? pour éviter les crashs
      vehiculeId: vehicule['id'] != null ? vehicule['id'] as int : null,

      reference: json['reference'] ?? '',
      seatNumber: json['seat_number'] ?? 0,

      pointDepart: programme['point_depart'] ?? 'Inconnu',
      pointArrive: programme['point_arrive'] ?? 'Inconnu',
      heureDepart: programme['heure_depart'] ?? '--:--',
      heureArrive: programme['heure_arrive'] ?? '--:--',

      dateVoyage: DateTime.tryParse(json['date_voyage'] ?? '') ?? DateTime.now(),

      compagnieName: compagnie['name'] ?? 'Compagnie',
      vehiculeInfo: "${vehicule['modele'] ?? ''} - ${vehicule['immatriculation'] ?? ''}",

      displayStatut: json['display_statut'] ?? json['statut'] ?? "",
    );
  }*/


  factory ActiveReservationModel.fromJson(Map<String, dynamic> json) {
    final programme = json['programme'] ?? {};
    final compagnie = programme['compagnie'] ?? {};

    // On cherche le vehicule dans le premier voyage du programme
    int? vehiculeId;
    String vehiculeInfo = "";

    final List<dynamic>? voyages = programme['voyages'];
    if (voyages != null && voyages.isNotEmpty) {
      final voyage = voyages[0];
      vehiculeId = voyage['vehicule_id'];
      final modele = voyage['vehicule']?['modele'] ?? '';
      final immat = voyage['vehicule']?['immatriculation'] ?? '';
      vehiculeInfo = "$modele - $immat";
    }

    return ActiveReservationModel(
      id: json['id'],
      programmeId: programme['id'] ?? 0,
      vehiculeId: vehiculeId, // ✅ prend maintenant la bonne valeur

      reference: json['reference'] ?? '',
      seatNumber: json['seat_number'] ?? 0,

      pointDepart: programme['point_depart'] ?? 'Inconnu',
      pointArrive: programme['point_arrive'] ?? 'Inconnu',
      heureDepart: programme['heure_depart'] ?? '--:--',
      heureArrive: programme['heure_arrive'] ?? '--:--',

      dateVoyage: DateTime.tryParse(json['date_voyage'] ?? '') ?? DateTime.now(),

      compagnieName: compagnie['name'] ?? 'Compagnie',
      vehiculeInfo: vehiculeInfo,

      displayStatut: json['display_statut'] ?? json['statut'] ?? "",
    );
  }

}