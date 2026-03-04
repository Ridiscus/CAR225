class UserEntity {
  final int id;
  final String name;
  final String prenom;
  final String email;
  final String contact;
  final String adresse;
  final String? photoUrl;

  UserEntity({
    required this.id,
    required this.name,
    required this.prenom,
    required this.email,
    required this.contact,
    required this.adresse,
    this.photoUrl,
  });
}
