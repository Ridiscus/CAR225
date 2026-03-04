// 📂 data/models/user_stats_model.dart

class UserStatsModel {
  final int totalReservations;
  final int voyagesEffectues;

  UserStatsModel({
    required this.totalReservations,
    required this.voyagesEffectues,
  });

  factory UserStatsModel.fromJson(Map<String, dynamic> json) {
    final global = json['data']['global'] ?? {};
    return UserStatsModel(
      totalReservations: global['total_reservations'] ?? 0,
      voyagesEffectues: global['voyages_effectues'] ?? 0,
    );
  }
}

class TripLocationModel {
  final String city;
  final int count;

  TripLocationModel({required this.city, required this.count});

  // On utilise un booléen pour savoir si on cherche la clé 'point_depart' ou 'point_arrive'
  factory TripLocationModel.fromJson(Map<String, dynamic> json, {required bool isDepart}) {
    return TripLocationModel(
      city: json[isDepart ? 'point_depart' : 'point_arrive'] ?? "Inconnu",
      count: json['count'] ?? 0,
    );
  }
}

class TripDetailsModel {
  final List<TripLocationModel> departsFrequents;
  final List<TripLocationModel> arriveesFrequentes;

  TripDetailsModel({
    required this.departsFrequents,
    required this.arriveesFrequentes,
  });

  factory TripDetailsModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};

    var departsJson = data['villes_depart_frequentes'] as List? ?? [];
    var arriveesJson = data['villes_arrivee_frequentes'] as List? ?? [];

    return TripDetailsModel(
      departsFrequents: departsJson.map((e) => TripLocationModel.fromJson(e, isDepart: true)).toList(),
      arriveesFrequentes: arriveesJson.map((e) => TripLocationModel.fromJson(e, isDepart: false)).toList(),
    );
  }
}