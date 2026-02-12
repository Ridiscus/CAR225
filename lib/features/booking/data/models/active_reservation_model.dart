class ActiveReservationModel {
  final int id; // ID de la réservation
  final int programmeId; // ✅ NOUVEAU : ID du programme (trajet prévu)
  final int vehiculeId;  // ✅ NOUVEAU : ID du véhicule physique

  final String reference;
  final int seatNumber;
  final String pointDepart;
  final String pointArrive;
  final String heureDepart;
  final String heureArrive;
  final DateTime dateVoyage;
  final String compagnieName;
  final String vehiculeInfo;

  ActiveReservationModel({
    required this.id,
    required this.programmeId, // ✅
    required this.vehiculeId,  // ✅
    required this.reference,
    required this.seatNumber,
    required this.pointDepart,
    required this.pointArrive,
    required this.heureDepart,
    required this.heureArrive,
    required this.dateVoyage,
    required this.compagnieName,
    required this.vehiculeInfo,
  });

  factory ActiveReservationModel.fromJson(Map<String, dynamic> json) {
    // 1. Extraction des sous-objets
    final programme = json['programme'] ?? {};
    final compagnie = programme['compagnie'] ?? {};
    final vehicule = programme['vehicule'] ?? {};

    return ActiveReservationModel(
      id: json['id'],

      // ✅ 2. Récupération des IDs manquants
      // On met 0 par défaut pour éviter le crash si l'ID est null,
      // mais en théorie l'API doit toujours renvoyer ça.
      programmeId: programme['id'] ?? 0,
      vehiculeId: vehicule['id'] ?? 0,

      reference: json['reference'] ?? '',
      seatNumber: json['seat_number'] ?? 0,

      pointDepart: programme['point_depart'] ?? 'Inconnu',
      pointArrive: programme['point_arrive'] ?? 'Inconnu',
      heureDepart: programme['heure_depart'] ?? '--:--',
      heureArrive: programme['heure_arrive'] ?? '--:--',

      dateVoyage: DateTime.tryParse(json['date_voyage'] ?? '') ?? DateTime.now(),

      compagnieName: compagnie['name'] ?? 'Compagnie',
      vehiculeInfo: "${vehicule['modele'] ?? ''} - ${vehicule['immatriculation'] ?? ''}",
    );
  }
}