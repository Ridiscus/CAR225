/*class ProgramModel {
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
  final int capacity; // 👈 AJOUTE ÇA (Le total : places libres + occupées)

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
    required this.capacity, //
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

    // --- CORRECTION ICI ---
    // 1. On cherche d'abord si une 'capacity' est fournie directement (plus fiable)
    // 2. Sinon, on cherche dans le véhicule
    // 3. Sinon 0
    int placesTotal = int.tryParse(json['capacity'].toString()) ??
        int.tryParse(vehicule['nombre_place'].toString()) ?? 0;

    // --- CORRECTION OCCUPATION ---
    // Parfois 'nbre_siege_occupe' est null, on assure le 0
    final placesOccup = int.tryParse(json['nbre_siege_occupe'].toString()) ?? 0;

    String cleanCity(String? val) {
      if (val == null) return "Ville inconnue";
      try {
        return val.split(',')[0].trim();
      } catch (e) {
        return val;
      }
    }

    String dateRaw = json['date_depart'] ?? DateTime.now().toString().split(' ')[0];

    return ProgramModel(
      id: json['id'],
      compagnieName: compagnie['name'] ?? "Compagnie Inconnue",
      prix: prixInt,
      heureDepart: _formatHeure(json['heure_depart']),
      heureArrivee: _formatHeure(json['heure_arrive']),
      duree: json['durer_parcours'] ?? "--",
      // On s'assure que ça ne descend pas en dessous de 0
      placesDisponibles: (placesTotal - placesOccup) < 0 ? 0 : (placesTotal - placesOccup),
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
}*/









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

  // ✅ 1. NOUVEAU CHAMP
  final int capacity;

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
    required this.capacity, // ✅ Ajouté au constructeur
  });

  // ✅ 2. COPYWITH MIS À JOUR
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
    int? capacity, // ✅ Ajouté ici
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
      capacity: capacity ?? this.capacity, // ✅ Et là
    );
  }

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    final compagnie = json['compagnie'] ?? {};
    final vehicule = json['vehicule'] ?? {};

    final prixInt = int.tryParse(json['montant_billet'].toString()) ?? 0;

    // ✅ 3. LOGIQUE DE CALCUL DE LA CAPACITÉ TOTALE (Source de vérité pour la grille)
    // Ordre de priorité :
    // A. 'capacity' injecté manuellement depuis le DataSource (le plus fiable)
    // B. 'nombre_place' dans l'objet vehicule
    // C. 'nombre_place' à la racine (parfois présent)
    // D. 48 par défaut (pour éviter un crash UI si tout manque)
    int placesTotal = int.tryParse(json['capacity'].toString()) ??
        int.tryParse(vehicule['nombre_place'].toString()) ??
        int.tryParse(json['nombre_place'].toString()) ??
        48;

    // ✅ 4. LOGIQUE DES PLACES DISPONIBLES
    // On récupère le nombre de sièges déjà pris
    final placesOccup = int.tryParse(json['nbre_siege_occupe'].toString()) ?? 0;

    // Calcul sécurisé (jamais en dessous de 0)
    final int placesDispoCalculated = (placesTotal - placesOccup) < 0 ? 0 : (placesTotal - placesOccup);

    // --- Helpers internes ---
    String cleanCity(String? val) {
      if (val == null) return "Ville inconnue";
      try {
        return val.split(',')[0].trim();
      } catch (e) {
        return val;
      }
    }

    String dateRaw = json['date_depart'] ?? DateTime.now().toString().split(' ')[0];

    return ProgramModel(
      id: json['id'],
      compagnieName: compagnie['name'] ?? "Compagnie Inconnue",
      prix: prixInt,
      heureDepart: _formatHeure(json['heure_depart']),
      heureArrivee: _formatHeure(json['heure_arrive']),
      duree: json['durer_parcours'] ?? "--",

      // On utilise soit la valeur calculée ici, soit celle fournie par l'API si elle existe explicitement
      placesDisponibles: json['places_disponibles'] != null
          ? (int.tryParse(json['places_disponibles'].toString()) ?? placesDispoCalculated)
          : placesDispoCalculated,

      isAllerRetour: (json['is_aller_retour'] == 1),
      villeDepart: cleanCity(json['point_depart']),
      villeArrivee: cleanCity(json['point_arrive']),
      dateDepart: dateRaw,

      capacity: placesTotal, // ✅ On stocke le total pour la grille UI
    );
  }

  static String _formatHeure(String? time) {
    if (time == null) return "--:--";
    if (time.length > 5) return time.substring(0, 5);
    return time;
  }
}