class DriverReservationModel {
  final int id;
  final String reference;
  final String? passagerNomComplet;
  final String? passagerTelephone;
  final String seatNumber;
  final String? trajet;
  final String? heureDepart;
  final String? gareDepart;
  final String? gareArrivee;
  final String? montant;
  final bool? isAllerRetour;
  final String? typeScan;
  final String? statut;
  final int? vehiculeId;
  final String? scannedAt;
  final String? statutAller;
  final String? statutRetour;

  DriverReservationModel({
    required this.id,
    required this.reference,
    this.passagerNomComplet,
    this.passagerTelephone,
    required this.seatNumber,
    this.trajet,
    this.heureDepart,
    this.gareDepart,
    this.gareArrivee,
    this.montant,
    this.isAllerRetour,
    this.typeScan,
    this.statut,
    this.vehiculeId,
    this.scannedAt,
    this.statutAller,
    this.statutRetour,
  });

  factory DriverReservationModel.fromJson(Map<String, dynamic> json) {
    return DriverReservationModel(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      passagerNomComplet: json['passager_nom_complet'] ?? json['passager_nom'],
      passagerTelephone: json['passager_telephone'],
      seatNumber: json['seat_number'] ?? json['seat_number']?.toString() ?? '',
      trajet: json['trajet'],
      heureDepart: json['heure_depart'],
      gareDepart: json['gare_depart'],
      gareArrivee: json['gare_arrivee'],
      montant: json['montant']?.toString(),
      isAllerRetour: json['is_aller_retour'] == 1 || json['is_aller_retour'] == true,
      typeScan: json['type_scan'],
      statut: json['statut'],
      vehiculeId: json['vehicule_id'],
      scannedAt: json['scanned_at'],
      statutAller: json['statut_aller'],
      statutRetour: json['statut_retour'],
    );
  }
}
