/*class HostessSaleModel {
  final int id;
  final String ticketNo;
  final String passager;
  final String trajet;
  final String prix;
  final String date;
  final String heure;
  final String siege;
  final String statut;

  HostessSaleModel({
    required this.id,
    required this.ticketNo,
    required this.passager,
    required this.trajet,
    required this.prix,
    required this.date,
    required this.heure,
    required this.siege,
    required this.statut,
  });

  factory HostessSaleModel.fromJson(Map<String, dynamic> json) {
    return HostessSaleModel(
      id: json['id'] ?? 0,
      ticketNo: json['ticket_no'] ?? '',
      passager: json['passager'] ?? 'Inconnu',
      trajet: json['trajet'] ?? '',
      // Le backend renvoie "3 000 FCFA", on peut le garder tel quel
      prix: json['prix'] ?? '0 FCFA',
      date: json['date'] ?? '',
      heure: json['heure'] ?? '',
      // Le backend renvoie "Place 1", on nettoie pour n'avoir que le numéro si on veut
      siege: json['siege']?.replaceAll('Place ', '') ?? '',
      statut: json['statut'] ?? '',
    );
  }
}

// Optionnel mais très utile pour le bloc "stats"
class SalesStatsModel {
  final int totalVentes;
  final String totalRevenu;
  final int totalAnnulations;

  SalesStatsModel({
    required this.totalVentes,
    required this.totalRevenu,
    required this.totalAnnulations,
  });

  factory SalesStatsModel.fromJson(Map<String, dynamic> json) {
    return SalesStatsModel(
      totalVentes: json['total_ventes'] ?? 0,
      totalRevenu: json['total_revenu']?.toString() ?? '0',
      totalAnnulations: json['total_annulations'] ?? 0,
    );
  }
}*/


class HostessSaleModel {
  final int id;
  final String ticketNo;
  final String reference; // 🟢 NOUVEAU
  final String passager;
  final String trajet;
  final String prix;
  final String date;
  final String heure;
  final String siege;
  final String statut;
  final String? qrCodeUrl; // 🟢 NOUVEAU

  HostessSaleModel({
    required this.id,
    required this.ticketNo,
    required this.reference,
    required this.passager,
    required this.trajet,
    required this.prix,
    required this.date,
    required this.heure,
    required this.siege,
    required this.statut,
    this.qrCodeUrl,
  });

  factory HostessSaleModel.fromJson(Map<String, dynamic> json) {
    return HostessSaleModel(
      id: json['id'] ?? 0,
      ticketNo: json['ticket_no'] ?? '',
      reference: json['reference'] ?? '', // 🟢 Ajout
      passager: json['passager'] ?? 'Inconnu',
      trajet: json['trajet'] ?? '',
      prix: json['prix'] ?? '0 FCFA',
      date: json['date'] ?? '',
      heure: json['heure'] ?? '',
      siege: json['siege']?.replaceAll('Place ', '') ?? '',
      statut: json['statut'] ?? '',
      qrCodeUrl: json['qr_code_url'], // 🟢 Ajout
    );
  }
}