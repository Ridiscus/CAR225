import 'dart:ui';

class CompanyModel {
  final int id;
  final String name;
  final String sigle;
  final String slogan;
  final String logoUrl;
  final double rating;
  final int reviewsCount;
  final CompanyStats stats;
  final List<CompanyTag> tags;
  final CompanyContact? contact; // Ajout du contact

  CompanyModel({
    required this.id,
    required this.name,
    required this.sigle,
    required this.slogan,
    required this.logoUrl,
    required this.rating,
    required this.reviewsCount,
    required this.stats,
    required this.tags,
    this.contact,
  });

  factory CompanyModel.fromJson(Map<String, dynamic> json) {
    return CompanyModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? "Compagnie",
      sigle: json['sigle'] ?? "",
      slogan: json['slogan'] ?? "",
      logoUrl: json['logo_url'] ?? "",
      rating: (json['rating'] ?? 0).toDouble(),
      reviewsCount: json['reviews_count'] ?? 0,
      stats: CompanyStats.fromJson(json['stats'] ?? {}),
      tags: (json['tags'] as List? ?? [])
          .map((t) => CompanyTag.fromJson(t))
          .toList(),
      contact: json['contact'] != null
          ? CompanyContact.fromJson(json['contact'])
          : null,
    );
  }
}

// --- CLASSE STATS ---
class CompanyStats {
  final int personnels;
  final int vehicules;
  final int programmes;
  final int reservations;

  CompanyStats({
    required this.personnels,
    required this.vehicules,
    required this.programmes,
    required this.reservations,
  });

  factory CompanyStats.fromJson(Map<String, dynamic> json) {
    return CompanyStats(
      personnels: json['personnels'] ?? 0,
      vehicules: json['vehicules'] ?? 0,
      programmes: json['programmes'] ?? 0,
      reservations: json['reservations'] ?? 0,
    );
  }
}

// --- CLASSE TAG ---
class CompanyTag {
  final String label;
  final Color color;

  CompanyTag({required this.label, required this.color});

  factory CompanyTag.fromJson(Map<String, dynamic> json) {
    return CompanyTag(
      label: json['label'] ?? "",
      color: _hexToColor(json['color'] ?? "#000000"),
    );
  }

  // Helper pour convertir le code Hex (#10b981) en Color Flutter
  static Color _hexToColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return const Color(0xFF000000); // Noir par défaut si erreur
    }
  }
}

// --- CLASSE CONTACT ---
class CompanyContact {
  final String email;
  final String telephone;
  final String adresse;
  final String commune;

  CompanyContact({
    required this.email,
    required this.telephone,
    required this.adresse,
    required this.commune
  });

  factory CompanyContact.fromJson(Map<String, dynamic> json) {
    return CompanyContact(
      email: json['email'] ?? "",
      telephone: json['telephone'] ?? "",
      adresse: json['adresse'] ?? "",
      commune: json['commune'] ?? "",
    );
  }
}