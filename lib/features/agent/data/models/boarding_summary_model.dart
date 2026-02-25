import '../../domain/entities/boarding_summary.dart';

class BoardingSummaryModel extends BoardingSummary {

  BoardingSummaryModel({
    required super.travelId,
    required super.carPlateNumber,
    required super.destination,
    required super.totalTicketsSold,
    required super.alreadyScanned,
    required super.remainingToBoard,
    required super.departureTime,
  });

  factory BoardingSummaryModel.fromJson(Map<String, dynamic> json) {
    return BoardingSummaryModel(
      travelId: json['travel_id'].toString(),
      carPlateNumber: json['immatriculation_car'] ?? '',
      destination: json['destination'] ?? '',
      totalTicketsSold: json['tickets_vendus'] ?? 0,
      alreadyScanned: json['deja_scannes'] ?? 0,
      remainingToBoard: json['restant_a_embarquer'] ?? 0,
      departureTime: json['heure_depart'] != null 
          ? DateTime.parse(json['heure_depart']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'travel_id': travelId,
      'immatriculation_car': carPlateNumber,
      'destination': destination,
      'tickets_vendus': totalTicketsSold,
      'deja_scannes': alreadyScanned,
      'restant_a_embarquer': remainingToBoard,
      'heure_depart': departureTime.toIso8601String(),
    };
  }
  
}
