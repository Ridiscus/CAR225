import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  UserModel({
    required super.id,
    required super.name,
    required super.prenom,
    required super.email,
    required super.contact,
    required super.adresse,
    super.photoUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
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
