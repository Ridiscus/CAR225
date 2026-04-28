import 'package:car225/core/services/networking/api_config.dart';

class DriverProfileModel {
  final int id;
  final String? codeId;
  final String? name;
  final String? prenom;
  final String? email;
  final String? contact;
  final String? contactUrgence;
  final String? role;
  final String? statut;
  final String? commune;
  final String? profilePictureUrl;
  final CompagnieModel? compagnie;
  final GareModel? gare;

  DriverProfileModel({
    required this.id,
    this.codeId,
    this.name,
    this.prenom,
    this.email,
    this.contact,
    this.contactUrgence,
    this.role,
    this.statut,
    this.commune,
    this.profilePictureUrl,
    this.compagnie,
    this.gare,
  });

  /// Returns a full HTTPS URL even when the server returns a relative path.
  /// Uses ApiConfig.socketUrl so it works in both local (ngrok) and production.
  String? get fullProfilePictureUrl {
    final url = profilePictureUrl;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    // Relative path like /storage/chauffeurs/profiles/...
    final path = url.startsWith('/') ? url : '/$url';
    return '${ApiConfig.socketUrl}$path';
  }

  factory DriverProfileModel.fromJson(Map<String, dynamic> json) {
    return DriverProfileModel(
      id: json['id'] ?? 0,
      codeId: json['code_id'],
      name: json['name'],
      prenom: json['prenom'],
      email: json['email'],
      contact: json['contact'],
      contactUrgence: json['contact_urgence'],
      role: json['role'],
      statut: json['statut'],
      commune: json['commune'],
      profilePictureUrl: json['profile_picture_url'],
      compagnie: json['compagnie'] != null ? CompagnieModel.fromJson(json['compagnie']) : null,
      gare: json['gare'] != null ? GareModel.fromJson(json['gare']) : null,
    );
  }
}

class CompagnieModel {
  final int id;
  final String? name;
  final String? logo;

  CompagnieModel({required this.id, this.name, this.logo});

  factory CompagnieModel.fromJson(Map<String, dynamic> json) {
    return CompagnieModel(
      id: json['id'] ?? 0,
      name: json['name'],
      logo: json['logo'],
    );
  }
}

class GareModel {
  final int id;
  final String? nomGare;

  GareModel({required this.id, this.nomGare});

  factory GareModel.fromJson(Map<String, dynamic> json) {
    return GareModel(
      id: json['id'] ?? 0,
      nomGare: json['nom_gare'],
    );
  }
}
