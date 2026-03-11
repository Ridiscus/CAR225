/*class HostessProfileModel {
  final int id;
  final String codeId;
  final String name;
  final String prenom;
  final String email;
  final String contact;
  final String? profilePicture;
  final int? compagnieId;

  HostessProfileModel({
    required this.id,
    required this.codeId,
    required this.name,
    required this.prenom,
    required this.email,
    required this.contact,
    this.profilePicture,
    this.compagnieId,
  });

  factory HostessProfileModel.fromJson(Map<String, dynamic> json) {
    return HostessProfileModel(
      id: json['id'] ?? 0,
      codeId: json['code_id'] ?? '',
      name: json['name'] ?? '',
      prenom: json['prenom'] ?? '',
      email: json['email'] ?? '',
      contact: json['contact'] ?? '',
      profilePicture: json['profile_picture'],
      compagnieId: json['compagnie_id'],
    );
  }
}*/


class HostessProfileModel {
  final int id;
  final String codeId;
  final String name;
  final String prenom;
  final String email;
  final String contact;
  final String? profilePicture;
  final String? nomCompagnie; // 🟢 On va extraire directement le nom

  HostessProfileModel({
    required this.id,
    required this.codeId,
    required this.name,
    required this.prenom,
    required this.email,
    required this.contact,
    this.profilePicture,
    this.nomCompagnie,
  });

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
      nomCompagnie: compagnie?['name'] ?? 'Inconnue', // 🟢 On extrait le nom de la compagnie
    );
  }
}