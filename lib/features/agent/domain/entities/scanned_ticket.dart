class ScannedTicket {
  final String id;
  final String ticketNumber;
  final String passengerName;
  final String seatNumber;
  final DateTime scanDate;
  final bool isValid;
  final String? errorMessage;

  ScannedTicket({
    required this.id,
    required this.ticketNumber,
    required this.passengerName,
    required this.seatNumber,
    required this.scanDate,
    required this.isValid,
    this.errorMessage,
  });
}
