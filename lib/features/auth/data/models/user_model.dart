class UserModel {
  final int id;
  final String name;
  final String prenom;
  final String email;
  final String contact;
  final String adresse;
  final String? photoUrl; // "photo_profile_url"
  // On ignore "nom_device" et "photo_profile_path" pour l'UI

  UserModel({
    required this.id,
    required this.name,
    required this.prenom,
    required this.email,
    required this.contact,
    required this.adresse,
    this.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Le JSON reçu est : { "success": true, "user": { ... } }
    // Donc on s'attend à recevoir la map "user" directement ici
    return UserModel(
      id: json['id'],
      name: json['name'] ?? "",
      prenom: json['prenom'] ?? "",
      email: json['email'] ?? "",
      contact: json['contact'] ?? "",
      adresse: json['adresse'] ?? "",
      photoUrl: json['photo_profile_url'],
    );
  }
}