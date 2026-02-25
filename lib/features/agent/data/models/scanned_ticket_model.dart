import '../../domain/entities/scanned_ticket.dart';

class ScannedTicketModel extends ScannedTicket {
  ScannedTicketModel({
    required super.id,
    required super.ticketNumber,
    required super.passengerName,
    required super.seatNumber,
    required super.scanDate,
    required super.isValid,
    super.errorMessage,
  });

  factory ScannedTicketModel.fromJson(Map<String, dynamic> json) {
    return ScannedTicketModel(
      id: json['id'].toString(),
      ticketNumber: json['numero_ticket'] ?? '',
      passengerName: json['nom_passager'] ?? 'Inconnu',
      seatNumber: json['numero_siege'] ?? 'N/A',
      scanDate: json['date_scan'] != null
          ? DateTime.parse(json['date_scan'])
          : DateTime.now(),
      isValid: json['est_valide'] ?? false,
      errorMessage: json['message_erreur'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero_ticket': ticketNumber,
      'nom_passager': passengerName,
      'numero_siege': seatNumber,
      'date_scan': scanDate.toIso8601String(),
      'est_valide': isValid,
      'message_erreur': errorMessage,
    };
  }
}
