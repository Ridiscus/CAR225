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
      id: json['id'] ?? 0,
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      statut: json['statut'] ?? '',
      photo: json['photo'],
      latitude: json['latitude']?.toString(),
      longitude: json['longitude']?.toString(),
      createdAt: json['created_at'] ?? '',
      voyage: json['voyage'] != null ? SignalementVoyageModel.fromJson(json['voyage']) : null,
      vehicule: json['vehicule']?.toString(), // Parfois c'est l'immatriculation
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
      id: json['id'] ?? 0,
      programme: json['programme'],
      gareDepart: json['gare_depart'],
    );
  }
}
