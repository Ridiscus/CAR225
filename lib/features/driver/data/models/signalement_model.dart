class SignalementModel {
  final int id;
  final String type;
  final String description;
  final String statut;
  final String? photo;
  final String? latitude;
  final String? longitude;
  final String createdAt;
  final SignalementVoyageModel? voyage;
  final String? vehicule;
  final String? compagnie;

  SignalementModel({
    required this.id,
    required this.type,
    required this.description,
    required this.statut,
    this.photo,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.voyage,
    this.vehicule,
    this.compagnie,
  });

  factory SignalementModel.fromJson(Map<String, dynamic> json) {
    return SignalementModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      type: json['type']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      statut: json['statut']?.toString() ?? '',
      photo: json['photo']?.toString(),
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      voyage: json['voyage'] != null ? SignalementVoyageModel.fromJson(json['voyage']) : null,
      vehicule: json['vehicule']?.toString(),
      compagnie: json['compagnie']?.toString(),
    );
  }
}

class SignalementVoyageModel {
  final int id;
  final String? programme;
  final String? gareDepart;

  SignalementVoyageModel({
    required this.id,
    this.programme,
    this.gareDepart,
  });

  factory SignalementVoyageModel.fromJson(Map<String, dynamic> json) {
    return SignalementVoyageModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      programme: json['programme']?.toString(),
      gareDepart: json['gare_depart']?.toString(),
    );
  }
}
