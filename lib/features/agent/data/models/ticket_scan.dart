import 'package:intl/intl.dart';

enum ScanStatus { valid, invalid }

class TicketScan {
  final String ticketId;
  final String passengerName;
  final String startLocation;
  final String location;
  final String busNumber;
  final String seatNumber;
  final DateTime scanTime;
  final ScanStatus status;

  TicketScan({
    required this.ticketId,
    required this.passengerName,
    required this.startLocation,
    required this.location,
    required this.busNumber,
    required this.seatNumber,
    required this.scanTime,
    required this.status,
  });

  factory TicketScan.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final String? dateString = json['date_heure_scan'];

    if (dateString != null && dateString.isNotEmpty) {
      try {
        parsedDate = DateFormat("dd MMM yyyy 'à' HH:mm", "fr_FR").parse(dateString);
      } catch (e) {
        parsedDate = DateTime.now();
      }
    } else {
      parsedDate = DateTime.now();
    }

    return TicketScan(
      ticketId: json['reference'] ?? 'Inconnu',
      passengerName: json['passager_nom'] ?? 'Inconnu',
      startLocation: json['point_depart'] ?? 'N/A',
      location: json['point_arrivee'] ?? 'N/A',
      busNumber: json['num_car']?.toString() ?? 'N/A',
      seatNumber: json['seat_number']?.toString() ?? 'N/A',
      scanTime: parsedDate,
      status: (json['statut'] == 'VALIDE') ? ScanStatus.valid : ScanStatus.invalid,
    );
  }
}