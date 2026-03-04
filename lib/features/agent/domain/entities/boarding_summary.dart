class BoardingSummary {
  final String travelId;
  final String carPlateNumber;
  final String destination;
  final int totalTicketsSold;
  final int alreadyScanned;
  final int remainingToBoard;
  final DateTime departureTime;

  BoardingSummary({
    required this.travelId,
    required this.carPlateNumber,
    required this.destination,
    required this.totalTicketsSold,
    required this.alreadyScanned,
    required this.remainingToBoard,
    required this.departureTime,
  });

  double get boardingProgress => totalTicketsSold > 0 ? alreadyScanned / totalTicketsSold : 0.0;
}
