/// data/models/programme_model.dart

/*class ProgrammeModel {
  final int id;
  final String trajet; // "Abidjan... -> Man..."
  final int montantBillet;
  final int placesDisponibles;

  ProgrammeModel({
    required this.id,
    required this.trajet,
    required this.montantBillet,
    required this.placesDisponibles,
  });

  factory ProgrammeModel.fromJson(Map<String, dynamic> json) {
    return ProgrammeModel(
      id: json['id'] ?? 0,
      trajet: json['trajet'] ?? "Inconnu -> Inconnu",
      montantBillet: json['montant_billet'] ?? 0,
      placesDisponibles: json['places_disponibles'] ?? 0,
    );
  }

  // Helpers pour l'UI (pour séparer Départ et Arrivée)
  String get depart {
    if (trajet.contains('→')) {
      return trajet.split('→')[0].trim().split(',')[0]; // Garde juste la ville
    }
    return "Départ";
  }

  String get arrivee {
    if (trajet.contains('→')) {
      return trajet.split('→')[1].trim().split(',')[0]; // Garde juste la ville
    }
    return "Arrivée";
  }
}*/






// data/models/programme_model.dart

class ProgrammeModel {
  final int id;
  final String pointDepart; // Nouveau champ API
  final String pointArrive; // Nouveau champ API
  final String duree;       // Nouveau champ API (durer_parcours)

  // Champs conservés pour la compatibilité UI (mais absents du JSON actuel)
  final int montantBillet;
  final int placesDisponibles;

  ProgrammeModel({
    required this.id,
    required this.pointDepart,
    required this.pointArrive,
    required this.duree,
    this.montantBillet = 0,      // Valeur par défaut
    this.placesDisponibles = 0,  // Valeur par défaut
  });

  factory ProgrammeModel.fromJson(Map<String, dynamic> json) {
    return ProgrammeModel(
      id: json['id'] ?? 0,
      pointDepart: json['point_depart'] ?? "Inconnu",
      pointArrive: json['point_arrive'] ?? "Inconnu",
      duree: json['durer_parcours'] ?? "",
      // Attention : Le nouveau JSON ne renvoie pas encore le prix ni les places
      montantBillet: json['montant_billet'] ?? 0,
      placesDisponibles: json['places_disponibles'] ?? 0,
    );
  }

  // --- HELPER POUR L'UI ---
  // Ces getters permettent à ton UI existante (programme.depart) de fonctionner
  // en nettoyant le texte "Abidjan, Côte d'Ivoire" -> "Abidjan"

  String get depart {
    return pointDepart.split(',')[0].trim();
  }

  String get arrivee {
    return pointArrive.split(',')[0].trim();
  }

  // Optionnel : un getter pour reconstruire le trajet complet si besoin
  String get trajet => "$depart → $arrivee";
}