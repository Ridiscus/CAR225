/*import 'package:intl/intl.dart';

class TicketModel {
  final String id;
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
  final String? returnTimeRaw;   // Heure Retour (NOUVEAU)

  final String companyName;
  final String price;
  final String status;
  final String? qrCodeUrl;
  final String? pdfBase64;
  final bool isAllerRetour;

  TicketModel({
    required this.id,
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
    this.returnTimeRaw, // NOUVEAU
    this.qrCodeUrl,
    this.pdfBase64,
    this.isAllerRetour = false,
  });

  // 🆕 FACTORY POUR L'ENDPOINT ROUND-TRIP (Celui qui marche pour les détails)
  factory TicketModel.fromRoundTripJson(Map<String, dynamic> json) {
    // 1. Récupération des objets Aller et Retour
    final aller = json['aller'] ?? {};
    final retour = json['retour'] ?? {};
    final programme = aller['programme'] ?? {};
    final compagnie = programme['compagnie'] ?? {};

    // 2. Gestion des Dates et Heures
    // ALLER
    String heureAller = aller['heure_depart'] ?? "00:00";
    if (heureAller.length > 5) heureAller = heureAller.substring(0, 5);
    DateTime dateAller = DateTime.tryParse(aller['date_voyage'] ?? "") ?? DateTime.now();

    // RETOUR
    DateTime? dateRetour;
    String? heureRetour; // Variable pour l'heure retour

    if (json['is_aller_retour'] == true && retour.isNotEmpty) {
      if (retour['date_voyage'] != null) {
        dateRetour = DateTime.tryParse(retour['date_voyage']);
      }
      // ✅ C'EST ICI QU'ON RÉCUPÈRE L'HEURE RETOUR
      if (retour['heure_depart'] != null) {
        heureRetour = retour['heure_depart'].toString();
        if (heureRetour.length > 5) heureRetour = heureRetour.substring(0, 5);
      }
    }

    // 3. Gestion des Sièges
    String siegeAller = aller['seat_number'].toString();
    String? siegeRetour = retour['seat_number']?.toString();

    // 4. Gestion du Statut
    String rawStatus = (aller['statut'] ?? "Inconnu").toString().toLowerCase();
    String displayStatus = "En attente";
    if (rawStatus.contains("confirm") || rawStatus.contains("pay")) displayStatus = "Confirmé";
    else if (rawStatus.contains("annul")) displayStatus = "Annulé";
    else if (rawStatus.contains("util") || rawStatus.contains("scan")) displayStatus = "Terminé";

    // 5. Villes
    String depart = programme['point_depart'] ?? aller['point_depart'] ?? "Départ";
    String arrivee = programme['point_arrive'] ?? aller['point_arrive'] ?? "Arrivée";

    return TicketModel(
      id: json['payment_transaction_id'] ?? aller['reference'] ?? "ID",
      ticketNumber: aller['reference'] ?? "REF",
      passengerName: "${aller['passager_prenom']} ${aller['passager_nom']}",

      seatNumber: siegeAller,
      returnSeatNumber: siegeRetour, // ✅ Le siège retour est bien passé ici

      departureCity: depart,
      arrivalCity: arrivee,
      companyName: compagnie['name'] ?? "Compagnie",

      departureTimeRaw: heureAller,
      returnTimeRaw: heureRetour, // ✅ L'heure retour est bien passée ici

      date: dateAller,
      status: displayStatus,
      qrCodeUrl: aller['qr_code'],
      pdfBase64: null,
      price: aller['montant']?.toString() ?? "0",
      isAllerRetour: true,
      returnDate: dateRetour,
    );
  }

  // Getters de compatibilité pour ton UI
  String get fileName => id;
  String get route => "$departureCity → $arrivalCity";
  String get departureTime => departureTimeRaw;

  // Getter intelligent pour l'affichage de l'heure retour dans l'UI
  String get returnTimeDisplay => returnTimeRaw ?? "--:--";

  String get statusLabel => status;
  String get departureDate => DateFormat('dd/MM/yyyy').format(date);
}*/






/*import 'package:intl/intl.dart';

class TicketModel {
  final String id;
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

  TicketModel({
    required this.id,
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
  });

  // 1. FACTORY STANDARD (Utilisé par GetMyTickets / Liste)
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    // Gestion propre du Booléen
    bool isAR = json['is_aller_retour'] == true;

    // Récupération des sièges depuis la liste 'passagers' si elle existe
    // On prend le premier passager pour l'affichage principal dans la liste
    String seat = "??";
    String? returnSeat;
    String name = "Passager";

    if (json['passagers'] != null && (json['passagers'] as List).isNotEmpty) {
      final firstPassenger = json['passagers'][0];
      seat = firstPassenger['seat_number']?.toString() ?? "??";

      // ✅ C'EST ICI LA CLÉ DU SUCCÈS : on lit return_seat_number
      returnSeat = firstPassenger['return_seat_number']?.toString();

      name = "${firstPassenger['prenom']} ${firstPassenger['nom']}";
    } else {
      // Fallback si pas de liste passagers (ancien format)
      seat = json['seat_number']?.toString() ?? "??";
      name = "${json['passager_prenom']} ${json['passager_nom']}";
    }

    return TicketModel(
      id: json['id'].toString(),
      ticketNumber: json['reference'] ?? "",
      passengerName: name,
      seatNumber: seat,
      returnSeatNumber: returnSeat, // Sera "12" par exemple
      departureCity: json['point_depart'] ?? "Départ",
      arrivalCity: json['point_arrive'] ?? "Arrivée",
      companyName: json['company_name'] ?? "Compagnie", // Adapte la clé si besoin
      departureTimeRaw: "00:00", // Souvent manquant dans la liste simplifiée
      date: DateTime.tryParse(json['date_voyage'] ?? "") ?? DateTime.now(),
      status: json['statut'] ?? "En attente",
      price: json['montant']?.toString() ?? "0",
      isAllerRetour: isAR,
      qrCodeUrl: json['qr_code'],
    );
  }

  // 2. FACTORY DÉTAILLÉE (Celle que tu avais déjà, je la garde telle quelle)
  factory TicketModel.fromRoundTripJson(Map<String, dynamic> json) {
    final aller = json['aller'] ?? {};
    final retour = json['retour'] ?? {};
    final programme = aller['programme'] ?? {};
    final compagnie = programme['compagnie'] ?? {};

    String heureAller = aller['heure_depart'] ?? "00:00";
    if (heureAller.length > 5) heureAller = heureAller.substring(0, 5);
    DateTime dateAller = DateTime.tryParse(aller['date_voyage'] ?? "") ?? DateTime.now();

    DateTime? dateRetour;
    String? heureRetour;

    if (json['is_aller_retour'] == true && retour.isNotEmpty) {
      if (retour['date_voyage'] != null) {
        dateRetour = DateTime.tryParse(retour['date_voyage']);
      }
      if (retour['heure_depart'] != null) {
        heureRetour = retour['heure_depart'].toString();
        if (heureRetour.length > 5) heureRetour = heureRetour.substring(0, 5);
      }
    }

    String siegeAller = aller['seat_number'].toString();
    // Ici aussi, on peut tenter de lire le return_seat_number s'il est dispo dans le JSON global
    // Mais ta logique actuelle base sur l'objet retour fonctionne aussi.
    String? siegeRetour = retour['seat_number']?.toString();

    String rawStatus = (aller['statut'] ?? "Inconnu").toString().toLowerCase();
    String displayStatus = "En attente";
    if (rawStatus.contains("confirm") || rawStatus.contains("pay")) displayStatus = "Confirmé";
    else if (rawStatus.contains("annul")) displayStatus = "Annulé";
    else if (rawStatus.contains("util") || rawStatus.contains("scan")) displayStatus = "Terminé";

    String depart = programme['point_depart'] ?? aller['point_depart'] ?? "Départ";
    String arrivee = programme['point_arrive'] ?? aller['point_arrive'] ?? "Arrivée";

    return TicketModel(
      id: json['payment_transaction_id'] ?? aller['reference'] ?? "ID",
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
  }

  // Getters UI
  String get fileName => id;
  String get route => "$departureCity → $arrivalCity";
  String get departureTime => departureTimeRaw;
  String get returnTimeDisplay => returnTimeRaw ?? "--:--";
  String get statusLabel => status;
  String get departureDate => DateFormat('dd/MM/yyyy').format(date);
}*/



/*import 'package:intl/intl.dart';

class TicketModel {
  final String id;
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

  TicketModel({
    required this.id,
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
  });

  // 1. FACTORY STANDARD
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    bool isAR = json['is_aller_retour'] == true;
    String seat = "??";
    String? returnSeat;
    String name = "Passager";

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
      id: json['id'].toString(),
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

  // 2. FACTORY DÉTAILLÉE
  factory TicketModel.fromRoundTripJson(Map<String, dynamic> json) {
    final aller = json['aller'] ?? {};
    final retour = json['retour'] ?? {};
    final programme = aller['programme'] ?? {};
    final compagnie = programme['compagnie'] ?? {};

    String heureAller = aller['heure_depart'] ?? "00:00";
    if (heureAller.length > 5) heureAller = heureAller.substring(0, 5);
    DateTime dateAller = DateTime.tryParse(aller['date_voyage'] ?? "") ?? DateTime.now();

    DateTime? dateRetour;
    String? heureRetour;

    if (json['is_aller_retour'] == true && retour.isNotEmpty) {
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
      id: json['payment_transaction_id'] ?? aller['reference'] ?? "ID",
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
  }

  // ✅ AJOUT DE LA MÉTHODE COPYWITH ICI
  TicketModel copyWith({
    String? id,
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
  String get fileName => id;
  String get route => "$departureCity → $arrivalCity";
  String get departureTime => departureTimeRaw;
  String get returnTimeDisplay => returnTimeRaw ?? "--:--";
  String get statusLabel => status;
  String get departureDate => DateFormat('dd/MM/yyyy').format(date);
}*/









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
  factory TicketModel.fromRoundTripJson(Map<String, dynamic> json) {
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