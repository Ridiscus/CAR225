class AgentDashboardData {
  final int ticketsScanned;
  final int ticketsToScan;
  final int totalPrograms;
  final String agentName;
  final String agentRole;
  final List<BusProgram> programs;

  AgentDashboardData({
    required this.ticketsScanned,
    required this.ticketsToScan,
    required this.totalPrograms,
    required this.agentName,
    required this.agentRole,
    required this.programs,
  });

  factory AgentDashboardData.fromJson(Map<String, dynamic> json) {
    final stats = json['stats'] ?? {};
    final agent = json['agent'] ?? {};
    final programsData = json['programmes_du_jour'] as List<dynamic>? ?? [];

    return AgentDashboardData(
      ticketsScanned: stats['billets_scannes'] ?? 0,
      ticketsToScan: stats['a_scanner'] ?? 0,
      totalPrograms: stats['total_programmes'] ?? 0,
      agentName: agent['name'] ?? 'Agent',
      agentRole: agent['role'] ?? 'Agent CAR225',
      programs: programsData.map((p) => BusProgram.fromJson(p)).toList(),
    );
  }
}

class BusProgram {
  final int id;
  final String busNumber;
  final String departure;
  final String destination;
  final String departureTime;
  final String arrivalTime;
  final String occupation;
  final String status;

  BusProgram({
    required this.id,
    required this.busNumber,
    required this.departure,
    required this.destination,
    required this.departureTime,
    required this.arrivalTime,
    required this.occupation,
    required this.status,
  });

  factory BusProgram.fromJson(Map<String, dynamic> json) {
    return BusProgram(
      id: json['id'] ?? 0,
      busNumber: json['num_car'] ?? 'Inconnu',
      departure: json['point_depart']?.toString().split(',')[0] ?? 'N/A', // Récupère juste la ville
      destination: json['point_arrivee']?.toString().split(',')[0] ?? 'N/A',
      departureTime: json['heure_depart'] ?? '--:--',
      arrivalTime: json['heure_arrivee'] ?? '--:--',
      occupation: json['occupation'] ?? '0 / 0 Places',
      status: json['statut'] ?? 'EN ATTENTE',
    );
  }
}