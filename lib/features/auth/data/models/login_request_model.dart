class LoginRequestModel {
  final String email;
  final String password;
  final String fcmToken;
  final String deviceName; // Nouveau champ

  LoginRequestModel({
    required this.email,
    required this.password,
    required this.fcmToken,
    required this.deviceName,
  });

  // Transformation en JSON pour l'envoyer à l'API
  Map<String, dynamic> toJson() {
    return {
      "email": email,
      "password": password,
      "fcm_token": fcmToken,
      "nom_device": deviceName, // Mapping exact demandé par le backend
    };
  }
}