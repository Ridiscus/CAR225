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
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      reference: json['reference']?.toString() ?? '',
      passagerNomComplet: json['passager_nom_complet']?.toString() ?? json['passager_nom']?.toString(),
      passagerTelephone: json['passager_telephone']?.toString(),
      seatNumber: json['seat_number']?.toString() ?? '',
      trajet: json['trajet']?.toString(),
      heureDepart: json['heure_depart']?.toString(),
      gareDepart: json['gare_depart']?.toString(),
      gareArrivee: json['gare_arrivee']?.toString(),
      montant: json['montant']?.toString(),
      isAllerRetour: json['is_aller_retour'] == 1 || json['is_aller_retour'] == true || json['is_aller_retour'].toString() == '1',
      typeScan: json['type_scan']?.toString(),
      statut: json['statut']?.toString(),
      vehiculeId: json['vehicule_id'] != null ? int.tryParse(json['vehicule_id'].toString()) : null,
      scannedAt: json['scanned_at']?.toString(),
      statutAller: json['statut_aller']?.toString(),
      statutRetour: json['statut_retour']?.toString(),
    );
  }
}
