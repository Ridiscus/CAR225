class ProgramModel {
  final int id;
  final String compagnieName;
  final int prix;
  final String heureDepart;
  final String heureArrivee;
  final String duree;
  final int placesDisponibles;
  final bool isAllerRetour;

  final String villeDepart;
  final String villeArrivee;
  final String dateDepart;

  ProgramModel({
    required this.id,
    required this.compagnieName,
    required this.prix,
    required this.heureDepart,
    required this.heureArrivee,
    required this.duree,
    required this.placesDisponibles,
    required this.isAllerRetour,
    required this.villeDepart,
    required this.villeArrivee,
    required this.dateDepart,
  });

  // ✅ AJOUT DE LA MÉTHODE COPYWITH ICI
  ProgramModel copyWith({
    int? id,
    String? compagnieName,
    int? prix,
    String? heureDepart,
    String? heureArrivee,
    String? duree,
    int? placesDisponibles,
    bool? isAllerRetour,
    String? villeDepart,
    String? villeArrivee,
    String? dateDepart,
  }) {
    return ProgramModel(
      id: id ?? this.id,
      compagnieName: compagnieName ?? this.compagnieName,
      prix: prix ?? this.prix,
      heureDepart: heureDepart ?? this.heureDepart,
      heureArrivee: heureArrivee ?? this.heureArrivee,
      duree: duree ?? this.duree,
      placesDisponibles: placesDisponibles ?? this.placesDisponibles,
      isAllerRetour: isAllerRetour ?? this.isAllerRetour,
      villeDepart: villeDepart ?? this.villeDepart,
      villeArrivee: villeArrivee ?? this.villeArrivee,
      dateDepart: dateDepart ?? this.dateDepart,
    );
  }

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    final compagnie = json['compagnie'] ?? {};
    final vehicule = json['vehicule'] ?? {};

    final prixInt = int.tryParse(json['montant_billet'].toString()) ?? 0;
    final placesTotal = int.tryParse(vehicule['nombre_place'].toString()) ?? 0;
    final placesOccup = int.tryParse(json['nbre_siege_occupe'].toString()) ?? 0;

    String cleanCity(String? val) {
      if (val == null) return "Ville inconnue";
      return val.split(',')[0].trim();
    }

    String dateRaw = json['date_depart'] ?? DateTime.now().toString().split(' ')[0];

    return ProgramModel(
      id: json['id'],
      compagnieName: compagnie['name'] ?? "Compagnie Inconnue",
      prix: prixInt,
      heureDepart: _formatHeure(json['heure_depart']),
      heureArrivee: _formatHeure(json['heure_arrive']),
      duree: json['durer_parcours'] ?? "--",
      placesDisponibles: placesTotal - placesOccup,
      isAllerRetour: (json['is_aller_retour'] == 1),
      villeDepart: cleanCity(json['point_depart']),
      villeArrivee: cleanCity(json['point_arrive']),
      dateDepart: dateRaw,
    );
  }

  static String _formatHeure(String? time) {
    if (time == null) return "--:--";
    if (time.length > 5) return time.substring(0, 5);
    return time;
  }
}