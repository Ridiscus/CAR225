class Voyage {
  final int id;
  final String date;
  final String depart;
  final String arrivee;
  final String statut;

  Voyage({required this.id, required this.date, required this.depart, required this.arrivee, required this.statut});

  factory Voyage.fromJson(Map<String, dynamic> json) {
    return Voyage(
      id: json['id'],
      date: json['date_voyage'],
      depart: json['heure_depart'],
      arrivee: json['heure_arrive'],
      statut: json['statut'],
    );
  }

  // Pour l'affichage dans le dropdown
  String get displayName => "Voyage #$id - ${date.split('T')[0]} ($depart)";
}