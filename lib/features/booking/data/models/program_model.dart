

class ProgramModel {
  final int id;
  final int compagnieId; // 🟢 1. NOUVEAU CHAMP AJOUTÉ ICI
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
    required this.compagnieId, // 🟢 2. AJOUTÉ AU CONSTRUCTEUR
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
    required this.capacity,
  });

  // ✅ 2. COPYWITH MIS À JOUR
  ProgramModel copyWith({
    int? id,
    int? compagnieId, // 🟢 3. AJOUTÉ ICI
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
    int? capacity,
  }) {
    return ProgramModel(
      id: id ?? this.id,
      compagnieId: compagnieId ?? this.compagnieId, // 🟢 4. ET LÀ
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
      capacity: capacity ?? this.capacity,
    );
  }

  factory ProgramModel.fromJson(Map<String, dynamic> json) {
    final compagnie = json['compagnie'] ?? {};
    final vehicule = json['vehicule'] ?? {};

    final prixInt = int.tryParse(json['montant_billet'].toString()) ?? 0;

    // ✅ 3. LOGIQUE DE CALCUL DE LA CAPACITÉ TOTALE
    int placesTotal = int.tryParse(json['capacity'].toString()) ??
        int.tryParse(vehicule['nombre_place'].toString()) ??
        int.tryParse(json['nombre_place'].toString()) ??
        48;

    // ✅ 4. LOGIQUE DES PLACES DISPONIBLES
    final placesOccup = int.tryParse(json['nbre_siege_occupe'].toString()) ?? 0;
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

      // 🟢 5. RÉCUPÉRATION DE L'ID DE LA COMPAGNIE DEPUIS LE JSON
      compagnieId: compagnie['id'] != null ? int.tryParse(compagnie['id'].toString()) ?? 0 : 0,

      compagnieName: compagnie['name'] ?? "Compagnie Inconnue",
      prix: prixInt,
      heureDepart: _formatHeure(json['heure_depart']),
      heureArrivee: _formatHeure(json['heure_arrive']),
      duree: json['durer_parcours'] ?? "--",

      placesDisponibles: json['places_disponibles'] != null
          ? (int.tryParse(json['places_disponibles'].toString()) ?? placesDispoCalculated)
          : placesDispoCalculated,

      isAllerRetour: (json['is_aller_retour'] == 1),
      villeDepart: cleanCity(json['point_depart']),
      villeArrivee: cleanCity(json['point_arrive']),
      dateDepart: dateRaw,

      capacity: placesTotal,
    );
  }

  static String _formatHeure(String? time) {
    if (time == null) return "--:--";
    if (time.length > 5) return time.substring(0, 5);
    return time;
  }
}