class RegisterRequestModel {
  final String nom;
  final String prenom;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String adresse;
  final String contact;
  final String fcmToken;
  final String deviceName;
  final String? photoPath; // <--- Nouveau champ (Optionnel au cas où l'user n'en met pas)

  RegisterRequestModel({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.adresse,
    required this.contact,
    required this.fcmToken,
    required this.deviceName,
    this.photoPath,
  });
}