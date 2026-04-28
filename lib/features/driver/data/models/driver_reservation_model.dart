import 'package:car225/core/services/networking/api_config.dart';

class DriverReservationModel {
  final int id;
  final String reference;
  final String? passagerNomComplet;
  final String? passagerTelephone;
  final String? passagerEmail;
  final String? passagerPhoto;
  final String seatNumber;
  final String? trajet;
  final String? heureDepart;
  final String? gareDepart;
  final String? gareArrivee;
  final String? montant;
  final bool? isAllerRetour;
  final String? typeScan;
  final String? statut;
  final int? vehiculeId;
  final String? scannedAt;
  final String? statutAller;
  final String? statutRetour;

  DriverReservationModel({
    required this.id,
    required this.reference,
    this.passagerNomComplet,
    this.passagerTelephone,
    this.passagerEmail,
    this.passagerPhoto,
    required this.seatNumber,
    this.trajet,
    this.heureDepart,
    this.gareDepart,
    this.gareArrivee,
    this.montant,
    this.isAllerRetour,
    this.typeScan,
    this.statut,
    this.vehiculeId,
    this.scannedAt,
    this.statutAller,
    this.statutRetour,
  });

  /// Returns full URL for passenger photo, handles relative paths.
  String? get fullPassagerPhotoUrl {
    final url = passagerPhoto;
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final path = url.startsWith('/') ? url : '/$url';
    return '${ApiConfig.socketUrl}$path';
  }

  factory DriverReservationModel.fromJson(Map<String, dynamic> json) {
    // Support nested passager object from search endpoint
    final passager = json['passager'] is Map ? json['passager'] as Map<String, dynamic> : null;

    return DriverReservationModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) ?? 0 : 0,
      reference: json['reference']?.toString() ?? '',
      passagerNomComplet: passager?['nom_complet']?.toString()
          ?? passager?['name']?.toString()
          ?? json['passager_nom_complet']?.toString()
          ?? json['passager_nom']?.toString(),
      passagerTelephone: passager?['telephone']?.toString()
          ?? passager?['phone']?.toString()
          ?? json['passager_telephone']?.toString(),
      passagerEmail: passager?['email']?.toString() ?? json['passager_email']?.toString(),
      passagerPhoto: passager?['photo']?.toString()
          ?? passager?['profile_picture']?.toString()
          ?? passager?['avatar']?.toString()
          ?? json['passager_photo']?.toString(),
      seatNumber: json['seat_number']?.toString() ?? '',
      trajet: json['trajet']?.toString(),
      heureDepart: json['heure_depart']?.toString(),
      gareDepart: json['gare_depart']?.toString(),
      gareArrivee: json['gare_arrivee']?.toString(),
      montant: json['montant']?.toString(),
      isAllerRetour: json['is_aller_retour'] == 1 || json['is_aller_retour'] == true || json['is_aller_retour'].toString() == '1',
      typeScan: json['type_scan']?.toString(),
      statut: json['statut']?.toString(),
      vehiculeId: json['vehicule_id'] != null ? int.tryParse(json['vehicule_id'].toString()) : null,
      scannedAt: json['scanned_at']?.toString(),
      statutAller: json['statut_aller']?.toString(),
      statutRetour: json['statut_retour']?.toString(),
    );
  }
}
