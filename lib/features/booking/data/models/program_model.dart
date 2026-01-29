class ProgramModel {
  final int id;
  final String compagnieName; // Ex: UTB
  final String? compagnieLogo; // URL ou path
  final String departVille;
  final String arriveeVille;
  final String heureDepart; // "08:00"
  final String heureArrivee; // "12:30"
  final int prix;
  final int placesDisponibles;
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
    required this.prix,
    required this.placesDisponibles,
    required this.isAllerRetour,
    this.services = const [],
  });

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    // ADAPTATION: Selon la structure réelle de ton API, il faudra peut-être ajuster les clés ici.
    // J'utilise des valeurs par défaut sécurisées pour éviter les crashs si un champ manque.
    return ProgramModel(
      id: json['id'] ?? 0,
      compagnieName: json['compagnie']?['nom'] ?? json['compagnie_name'] ?? "Compagnie Inconnue",
      compagnieLogo: json['compagnie']?['logo'],
      departVille: json['point_depart'] ?? "Départ",
      arriveeVille: json['point_arrive'] ?? "Arrivée",
      heureDepart: json['heure_depart'] ?? "--:--",
      heureArrivee: json['heure_arrivee'] ?? "--:--",
      prix: int.tryParse(json['prix'].toString()) ?? 0,
      placesDisponibles: int.tryParse(json['places_disponibles'].toString()) ?? 0,
      // Si l'API ne renvoie pas explicitemnt le type, on peut le déduire ou mettre false par défaut
      isAllerRetour: json['type_trajet'] == 'aller-retour',
      services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? ["Clim", "Usb"],
    );
  }
}