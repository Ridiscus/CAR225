class ProgramModel {
  final int id;
  final String compagnieName; // Ex: UTB
  final String? compagnieLogo; // URL ou path
  final String departVille;
  final String arriveeVille;
  final String heureDepart; // "08:00"
  final String heureArrivee; // "12:30"
  final String dateDepart; // "2024-03-05"
  final int prix;
  final int placesDisponibles;
  final int capacity; // Ajout du champ capacity
  final bool isAllerRetour; // true = Aller-Retour, false = Simple
  final List<String> services; // ["Wifi", "Clim"]

  ProgramModel({
    required this.id,
    required this.compagnieName,
    this.compagnieLogo,
    required this.departVille,
    required this.arriveeVille,
    required this.heureDepart,
    required this.heureArrivee,
    required this.dateDepart,
    required this.prix,
    required this.placesDisponibles,
    this.capacity = 50,
    required this.isAllerRetour,
    this.services = const [],
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    return ProgramModel(
      id: json['id'] ?? 0,
      compagnieName:
          json['compagnie']?['nom'] ??
          json['compagnie_name'] ??
          "Compagnie Inconnue",
      compagnieLogo: json['compagnie']?['logo'],
      departVille: json['point_depart'] ?? "Départ",
      arriveeVille: json['point_arrive'] ?? "Arrivée",
      heureDepart: json['heure_depart'] ?? "--:--",
      heureArrivee: json['heure_arrivee'] ?? "--:--",
      dateDepart: json['date_depart'] ?? "--",
      prix: int.tryParse(json['prix'].toString()) ?? 0,
      placesDisponibles:
          int.tryParse(json['places_disponibles'].toString()) ?? 0,
      capacity:
          int.tryParse(json['capacity'].toString()) ??
          int.tryParse(json['places_totales'].toString()) ??
          50, // Fallback à 50
      isAllerRetour: json['type_trajet'] == 'aller-retour',
      services:
          (json['services'] as List?)?.map((e) => e.toString()).toList() ??
          ["Clim", "Usb"],
    );
  }

  ProgramModel copyWith({
    int? id,
    String? compagnieName,
    String? compagnieLogo,
    String? departVille,
    String? arriveeVille,
    String? heureDepart,
    String? heureArrivee,
    String? dateDepart,
    int? prix,
    int? placesDisponibles,
    int? capacity,
    bool? isAllerRetour,
    List<String>? services,
  }) {
    return ProgramModel(
      id: id ?? this.id,
      compagnieName: compagnieName ?? this.compagnieName,
      compagnieLogo: compagnieLogo ?? this.compagnieLogo,
      departVille: departVille ?? this.departVille,
      arriveeVille: arriveeVille ?? this.arriveeVille,
      heureDepart: heureDepart ?? this.heureDepart,
      heureArrivee: heureArrivee ?? this.heureArrivee,
      dateDepart: dateDepart ?? this.dateDepart,
      prix: prix ?? this.prix,
      placesDisponibles: placesDisponibles ?? this.placesDisponibles,
      capacity: capacity ?? this.capacity,
      isAllerRetour: isAllerRetour ?? this.isAllerRetour,
      services: services ?? this.services,
    );
  }
}
