class TicketReservationModel {
  final int id;
  final String reference;
  final String passengerName;
  final String passengerPhone;
  final int seatNumber;
  final String travelDate;
  final String route;
  final String departureTime;
  final String arrivalTime;
  final String departureStation;
  final String arrivalStation;
  final String amount;
  final String status;

  // 🟢 NOUVEAUX CHAMPS AJOUTÉS ICI
  final int vehiculeId;
  final int programmeId;

  TicketReservationModel({
    required this.id,
    required this.reference,
    required this.passengerName,
    required this.passengerPhone,
    required this.seatNumber,
    required this.travelDate,
    required this.route,
    required this.departureTime,
    required this.arrivalTime,
    required this.departureStation,
    required this.arrivalStation,
    required this.amount,
    required this.status,

    // 🟢 REQUIS DANS LE CONSTRUCTEUR
    required this.vehiculeId,
    required this.programmeId,
  });

  factory TicketReservationModel.fromJson(Map<String, dynamic> json) {
    // On récupère nom et prénom
    final nom = json['passager_nom'] ?? '';
    final prenom = json['passager_prenom'] ?? '';

    // On les combine proprement
    final nomComplet = '$nom $prenom'.trim();

    return TicketReservationModel(
      id: json['id'] ?? 0,
      reference: json['reference'] ?? '',
      // 🟢 Utilisation du nom combiné ou 'Inconnu' si vide
      passengerName: nomComplet.isNotEmpty ? nomComplet : 'Inconnu',
      passengerPhone: json['passager_telephone'] ?? '',
      seatNumber: json['seat_number'] ?? 0,
      travelDate: json['date_voyage'] ?? '',
      route: json['trajet'] ?? '',
      departureTime: json['heure_depart'] ?? '',
      arrivalTime: json['heure_arrivee'] ?? '',
      departureStation: json['gare_depart'] ?? '',
      arrivalStation: json['gare_arrivee'] ?? '',
      amount: json['montant'] ?? '',
      status: json['statut'] ?? '',
      vehiculeId: json['vehicule_id'] ?? 0,
      programmeId: json['programme_id'] ?? 0,
    );
  }
}