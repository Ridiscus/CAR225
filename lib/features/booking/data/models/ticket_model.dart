import 'package:intl/intl.dart';

class TicketModel {
  // 🟢 1. CHANGEMENT : L'ID devient un int (ID base de données)
  final int id;
  // 🟢 2. AJOUT : On garde la référence de transaction à part
  final String transactionId;

  final String ticketNumber;
  final String passengerName;

  // Sièges
  final String seatNumber;        // Siège Aller
  final String? returnSeatNumber; // Siège Retour

  final String departureCity;
  final String arrivalCity;

  // Dates
  final DateTime date;        // Date Aller
  final DateTime? returnDate; // Date Retour

  // Heures (Format HH:mm)
  final String departureTimeRaw; // Heure Aller
  final String? returnTimeRaw;   // Heure Retour

  final String companyName;
  final String price;
  final String status;
  final String? qrCodeUrl;
  final String? pdfBase64;
  final bool isAllerRetour;

  // 🟢 AJOUT : Ce booléen dira "Je suis le ticket RETOUR"
  final bool isReturnLeg;



  TicketModel({
    required this.id, // ID numérique
    required this.transactionId, // TX-WAL...
    required this.ticketNumber,
    required this.passengerName,
    required this.seatNumber,
    this.returnSeatNumber,
    required this.departureCity,
    required this.arrivalCity,
    required this.date,
    this.returnDate,
    required this.companyName,
    required this.price,
    required this.status,
    required this.departureTimeRaw,
    this.returnTimeRaw,
    this.qrCodeUrl,
    this.pdfBase64,
    this.isAllerRetour = false,
    this.isReturnLeg = false,
  });

  // 1. FACTORY STANDARD (Liste simple)
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    bool isAR = json['is_aller_retour'] == true || json['is_aller_retour'] == 1;
    String seat = "??";
    String? returnSeat;
    String name = "Passager";

    // Gestion passagers
    if (json['passagers'] != null && (json['passagers'] as List).isNotEmpty) {
      final firstPassenger = json['passagers'][0];
      seat = firstPassenger['seat_number']?.toString() ?? "??";
      returnSeat = firstPassenger['return_seat_number']?.toString();
      name = "${firstPassenger['prenom']} ${firstPassenger['nom']}";
    } else {
      seat = json['seat_number']?.toString() ?? "??";
      name = "${json['passager_prenom']} ${json['passager_nom']}";
    }

    return TicketModel(
      // 🟢 On force la conversion en INT
      id: int.tryParse(json['id'].toString()) ?? 0,
      // 🟢 On récupère la transaction si dispo
      transactionId: json['payment_transaction_id'] ?? json['transaction_id'] ?? "",

      ticketNumber: json['reference'] ?? "",
      passengerName: name,
      seatNumber: seat,
      returnSeatNumber: returnSeat,
      departureCity: json['point_depart'] ?? "Départ",
      arrivalCity: json['point_arrive'] ?? "Arrivée",
      companyName: json['company_name'] ?? "Compagnie",
      departureTimeRaw: "00:00",
      date: DateTime.tryParse(json['date_voyage'] ?? "") ?? DateTime.now(),
      status: json['statut'] ?? "En attente",
      price: json['montant']?.toString() ?? "0",
      isAllerRetour: isAR,
      qrCodeUrl: json['qr_code'],
    );
  }

  // 2. FACTORY DÉTAILLÉE (Celle utilisée pour le détail/modif)
  /*factory TicketModel.fromRoundTripJson(Map<String, dynamic> json) {
    final aller = json['aller'] ?? {};
    final retour = json['retour'] ?? {};
    final programme = aller['programme'] ?? {};
    final compagnie = programme['compagnie'] ?? {};

    String heureAller = aller['heure_depart'] ?? "00:00";
    if (heureAller.length > 5) heureAller = heureAller.substring(0, 5);
    DateTime dateAller = DateTime.tryParse(aller['date_voyage'] ?? "") ?? DateTime.now();

    DateTime? dateRetour;
    String? heureRetour;

    if ((json['is_aller_retour'] == true || json['is_aller_retour'] == 1) && retour.isNotEmpty) {
      if (retour['date_voyage'] != null) {
        dateRetour = DateTime.tryParse(retour['date_voyage']);
      }
      if (retour['heure_depart'] != null) {
        heureRetour = retour['heure_depart'].toString();
        if (heureRetour.length > 5) heureRetour = heureRetour.substring(0, 5);
      }
    }

    String siegeAller = aller['seat_number'].toString();
    String? siegeRetour = retour['seat_number']?.toString();

    String rawStatus = (aller['statut'] ?? "Inconnu").toString().toLowerCase();
    String displayStatus = "En attente";
    if (rawStatus.contains("confirm") || rawStatus.contains("pay")) displayStatus = "Confirmé";
    else if (rawStatus.contains("annul")) displayStatus = "Annulé";
    else if (rawStatus.contains("util") || rawStatus.contains("scan")) displayStatus = "Terminé";

    String depart = programme['point_depart'] ?? aller['point_depart'] ?? "Départ";
    String arrivee = programme['point_arrive'] ?? aller['point_arrive'] ?? "Arrivée";

    return TicketModel(
      // 🟢 CORRECTION CRITIQUE ICI :
      // On prend l'ID numérique de la réservation 'aller', c'est ça que l'API veut
      id: int.tryParse(aller['id'].toString()) ?? 0,

      // On stocke le TX... dans transactionId pour l'affichage
      transactionId: json['payment_transaction_id'] ?? aller['reference'] ?? "",

      ticketNumber: aller['reference'] ?? "REF",
      passengerName: "${aller['passager_prenom']} ${aller['passager_nom']}",
      seatNumber: siegeAller,
      returnSeatNumber: siegeRetour,
      departureCity: depart,
      arrivalCity: arrivee,
      companyName: compagnie['name'] ?? "Compagnie",
      departureTimeRaw: heureAller,
      returnTimeRaw: heureRetour,
      date: dateAller,
      status: displayStatus,
      qrCodeUrl: aller['qr_code'],
      pdfBase64: null,
      price: aller['montant']?.toString() ?? "0",
      isAllerRetour: true,
      returnDate: dateRetour,
    );
  }*/

  // 2. FACTORY DÉTAILLÉE (Celle utilisée pour le détail/modif)
  factory TicketModel.fromRoundTripJson(Map<String, dynamic> json, {int? targetId}) {
    final aller = json['aller'] ?? {};
    final retour = json['retour'] ?? {};

    // 🟢 1. Par défaut, on pointe sur l'aller
    Map<String, dynamic> targetLeg = aller;
    bool isRetour = false;

    // 🟢 2. MAGIE : Si on a un targetId et qu'il correspond à l'ID du retour, on bascule !
    if (targetId != null && retour.isNotEmpty) {
      if (retour['id'].toString() == targetId.toString()) {
        targetLeg = retour;
        isRetour = true;
      }
    }

    // 🟢 AJOUT : On stocke "l'autre" trajet pour ne pas perdre ses dates !
    Map<String, dynamic> otherLeg = isRetour ? aller : retour;

    final programme = targetLeg['programme'] ?? {};
    final compagnie = programme['compagnie'] ?? (aller['programme']?['compagnie'] ?? {});

    String heureDepart = targetLeg['heure_depart'] ?? "00:00";
    if (heureDepart.length > 5) heureDepart = heureDepart.substring(0, 5);

    /*DateTime? dateRetour;
    if ((json['is_aller_retour'] == true || json['is_aller_retour'] == 1) && retour.isNotEmpty) {
      if (retour['date_voyage'] != null) dateRetour = DateTime.tryParse(retour['date_voyage']);
    }*/

    // 🟢 MODIFICATION : On prend les infos de l'autre trajet (otherLeg)
    DateTime? dateComplementaire;
    String? heureComplementaire;

    if ((json['is_aller_retour'] == true || json['is_aller_retour'] == 1) && otherLeg.isNotEmpty) {
      if (otherLeg['date_voyage'] != null) {
        dateComplementaire = DateTime.tryParse(otherLeg['date_voyage']);
      }
      if (otherLeg['heure_depart'] != null) {
        heureComplementaire = otherLeg['heure_depart'].toString();
        if (heureComplementaire.length > 5) heureComplementaire = heureComplementaire.substring(0, 5);
      }
    }

    String siege = targetLeg['seat_number']?.toString() ?? "??";

    String rawStatus = (targetLeg['statut'] ?? "Inconnu").toString().toLowerCase();
    String displayStatus = "En attente";
    if (rawStatus.contains("confirm") || rawStatus.contains("pay")) displayStatus = "Confirmé";
    else if (rawStatus.contains("annul")) displayStatus = "Annulé";
    else if (rawStatus.contains("util") || rawStatus.contains("scan")) displayStatus = "Terminé";

    String depart = programme['point_depart'] ?? targetLeg['point_depart'] ?? "Départ";
    String arrivee = programme['point_arrive'] ?? targetLeg['point_arrive'] ?? "Arrivée";

    return TicketModel(
      id: int.tryParse(targetLeg['id'].toString()) ?? 0,
      transactionId: json['payment_transaction_id'] ?? targetLeg['reference'] ?? "",
      ticketNumber: targetLeg['reference'] ?? "REF",
      passengerName: "${targetLeg['passager_prenom']} ${targetLeg['passager_nom']}",
      seatNumber: siege,
      returnSeatNumber: retour['seat_number']?.toString(),
      departureCity: depart,
      arrivalCity: arrivee,
      companyName: compagnie['name'] ?? "Compagnie",
      departureTimeRaw: heureDepart,
      //returnTimeRaw: retour['heure_depart']?.toString(),
      date: DateTime.tryParse(targetLeg['date_voyage'] ?? "") ?? DateTime.now(),
      status: displayStatus,
      qrCodeUrl: targetLeg['qr_code'],
      pdfBase64: null,
      price: targetLeg['montant']?.toString() ?? "0",
      isAllerRetour: json['is_aller_retour'] == true || json['is_aller_retour'] == 1,
      //returnDate: dateRetour,
      returnDate: dateComplementaire,
      returnTimeRaw: heureComplementaire,
      isReturnLeg: isRetour, // ✅ Le modèle sait enfin qui il est !
    );

  }

  // ✅ METHODE COPYWITH MISE A JOUR
  TicketModel copyWith({
    int? id,
    String? transactionId,
    String? ticketNumber,
    String? passengerName,
    String? seatNumber,
    String? returnSeatNumber,
    String? departureCity,
    String? arrivalCity,
    DateTime? date,
    DateTime? returnDate,
    String? departureTimeRaw,
    String? returnTimeRaw,
    String? companyName,
    String? price,
    String? status,
    String? qrCodeUrl,
    String? pdfBase64,
    bool? isAllerRetour,
  }) {
    return TicketModel(
      id: id ?? this.id,
      transactionId: transactionId ?? this.transactionId,
      ticketNumber: ticketNumber ?? this.ticketNumber,
      passengerName: passengerName ?? this.passengerName,
      seatNumber: seatNumber ?? this.seatNumber,
      returnSeatNumber: returnSeatNumber ?? this.returnSeatNumber,
      departureCity: departureCity ?? this.departureCity,
      arrivalCity: arrivalCity ?? this.arrivalCity,
      date: date ?? this.date,
      returnDate: returnDate ?? this.returnDate,
      departureTimeRaw: departureTimeRaw ?? this.departureTimeRaw,
      returnTimeRaw: returnTimeRaw ?? this.returnTimeRaw,
      companyName: companyName ?? this.companyName,
      price: price ?? this.price,
      status: status ?? this.status,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      pdfBase64: pdfBase64 ?? this.pdfBase64,
      isAllerRetour: isAllerRetour ?? this.isAllerRetour,
    );
  }

  // Getters UI
  // ⚠️ Si tu utilises fileName, convertis l'ID en string
  String get fileName => "ticket_${id}_$transactionId";
  String get route => "$departureCity → $arrivalCity";
  String get departureTime => departureTimeRaw;
  String get returnTimeDisplay => returnTimeRaw ?? "--:--";
  String get statusLabel => status;
  String get departureDate => DateFormat('dd/MM/yyyy').format(date);
}