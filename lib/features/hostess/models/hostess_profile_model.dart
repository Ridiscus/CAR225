class HostessProfileModel {
  final int id;
  final String codeId;
  final String name;
  final String prenom;
  final String email;
  final String contact;
  final String? profilePicture;
  final String? nomCompagnie;
  final String? casUrgence;
  final String? commune;

  HostessProfileModel({
    required this.id,
    required this.codeId,
    required this.name,
    required this.prenom,
    required this.email,
    required this.contact,
    this.profilePicture,
    this.nomCompagnie,
    this.casUrgence,
    this.commune,
  });

  // 🟢 LA MÉTHODE COPYWITH (Sans le mot "class" devant)
  HostessProfileModel copyWith({
    int? id,
    String? codeId,
    String? name,
    String? prenom,
    String? email,
    String? contact,
    String? profilePicture,
    String? nomCompagnie,
    String? casUrgence,
    String? commune,
  }) {
    return HostessProfileModel(
      id: id ?? this.id,
      codeId: codeId ?? this.codeId,
      name: name ?? this.name,
      prenom: prenom ?? this.prenom,
      email: email ?? this.email,
      contact: contact ?? this.contact,
      profilePicture: profilePicture ?? this.profilePicture,
      nomCompagnie: nomCompagnie ?? this.nomCompagnie,
      casUrgence: casUrgence ?? this.casUrgence,
      commune: commune ?? this.commune,
    );
  }

  // 🟢 LA FACTORY FROMJSON
  factory HostessProfileModel.fromJson(Map<String, dynamic> json) {
    // Le backend envoie la compagnie dans un sous-objet
    final compagnie = json['compagnie'] as Map<String, dynamic>?;

    return HostessProfileModel(
      id: json['id'] ?? 0,
      codeId: json['code_id'] ?? '',
      name: json['name'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      contact: json['contact'] ?? '',
      profilePicture: json['profile_picture'],
      nomCompagnie: compagnie?['name'] ?? 'Inconnue', // On extrait le nom de la compagnie
      casUrgence: json['cas_urgence'] ?? '',
      commune: json['commune'] ?? '',
    );
  }
}