class UnifiedLoginRequestModel {
  final String codeId;
  final String password;
  final String? fcmToken;
  final String? nomDevice;

  UnifiedLoginRequestModel({
    required this.codeId,
    required this.password,
    this.fcmToken,
    this.nomDevice,
  });

  Map<String, dynamic> toJson() {
    return {
      "code_id": codeId,
      "password": password,
      "fcm_token": fcmToken ?? "no_token",
      "nom_device": nomDevice ?? "Unknown Device",
    };
  }
}