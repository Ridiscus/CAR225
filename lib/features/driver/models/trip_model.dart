class TripModel {
  final String id;
  final String departureStation;
  final String arrivalStation;
  final String carRegistration;
  final DateTime scheduledDepartureTime;
  final DateTime scheduledArrivalTime;
  final String status; // 'pending', 'started', 'completed'
  final DateTime? actualDepartureTime;
  final DateTime? actualArrivalTime;
  final double price;
  final int passengersCount;
  final int totalSeats;

  TripModel({
    required this.id,
    required this.departureStation,
    required this.arrivalStation,
    required this.carRegistration,
    required this.scheduledDepartureTime,
    required this.scheduledArrivalTime,
    this.status = 'started',
    this.actualDepartureTime,
    this.actualArrivalTime,
    this.price = 0.0,
    this.passengersCount = 0,
    this.totalSeats = 0,
  });

  TripModel copyWith({
    String? status,
    DateTime? actualDepartureTime,
    DateTime? actualArrivalTime,
    double? price,
    int? passengersCount,
    int? totalSeats,
  }) {
    return TripModel(
      id: id,
      departureStation: departureStation,
      arrivalStation: arrivalStation,
      carRegistration: carRegistration,
      scheduledDepartureTime: scheduledDepartureTime,
      scheduledArrivalTime: scheduledArrivalTime,
      status: status ?? this.status,
      actualDepartureTime: actualDepartureTime ?? this.actualDepartureTime,
      actualArrivalTime: actualArrivalTime ?? this.actualArrivalTime,
      price: price ?? this.price,
      passengersCount: passengersCount ?? this.passengersCount,
      totalSeats: totalSeats ?? this.totalSeats,
    );
  }
}
