class Claim {
  final int id;
  final String type;
  final String typeLabel;
  final String objet;
  final String description;
  final String statut;
  final String? reponse;
  final String createdAt;
  final Map<String, dynamic>? reservation; // Contient reference, gares, etc.

  Claim({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.objet,
    required this.description,
    required this.statut,
    this.reponse,
    required this.createdAt,
    this.reservation,
  });

  factory Claim.fromJson(Map<String, dynamic> json) {
    return Claim(
      id: json['id'],
      type: json['type'] ?? '',
      typeLabel: json['type_label'] ?? '',
      objet: json['objet'] ?? 'Sans objet',
      description: json['description'] ?? '',
      statut: json['statut'] ?? 'ouvert',
      reponse: json['reponse'], // Peut être null
      createdAt: json['created_at'] ?? '',
      // On récupère l'objet reservation s'il existe
      reservation: json['reservation'] != null
          ? Map<String, dynamic>.from(json['reservation'])
          : null,
    );
  }

  // Helpers pour faciliter l'affichage dans l'UI
  String get dateOnly => createdAt.split(' ')[0];
  String get travelRoute => reservation != null
      ? "${reservation!['gare_depart']} → ${reservation!['gare_arrivee']}"
      : "Aucun trajet lié";
}