/*import 'package:car225/features/auth/data/models/user_model.dart';

class AuthResponseModel {
  final bool success;
  final bool requiresOtp;
  final String message;
  final String? contact; // Pour savoir où envoyer l'OTP
  final String? token;   // Sera null si requiresOtp est true
  final UserModel? user;
  final String? role;

  AuthResponseModel({
    required this.success,
    required this.requiresOtp,
    required this.message,
    this.contact,
    this.token,
    this.user,
    this.role
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      requiresOtp: json['requires_otp'] ?? false,
      message: json['message'] ?? "",
      contact: json['contact']?.toString(),
      // Le token peut être dans 'token' ou 'access_token' selon le dev
      token: json['token'] ?? json['access_token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      role: json['role'],
    );
  }
}*/


import 'package:car225/features/auth/data/models/user_model.dart';

class AuthResponseModel {
  final bool success;
  final bool requiresOtp;
  final String message;
  final String? contact; // Pour savoir où envoyer l'OTP
  final String? token;   // Sera null si requiresOtp est true
  final UserModel? user;
  final String? role;

  AuthResponseModel({
    required this.success,
    required this.requiresOtp,
    required this.message,
    this.contact,
    this.token,
    this.user,
    this.role
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      requiresOtp: json['requires_otp'] ?? false,
      message: json['message'] ?? "",
      contact: json['contact']?.toString(),
      // Le token peut être dans 'token' ou 'access_token' selon le dev
      token: json['token'] ?? json['access_token'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      role: json['role'],
    );
  }
}