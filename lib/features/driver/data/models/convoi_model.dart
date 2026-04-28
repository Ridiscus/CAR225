/// Modèle représentant un convoi (mission de convoyage) assigné au chauffeur.
///
/// Fait le miroir de l'endpoint `GET /api/chauffeur/convois`.
class ConvoiModel {
  final int id;
  final String? reference;
  final String statut;
  final String statutLabel;

  final int? nombrePersonnes;
  final double? montant;

  final String? lieuDepart;
  final String? lieuRetour;
  final String? lieuRassemblement;
  final String? lieuRassemblementRetour;

  final String? dateDepart;
  final String? heureDepart;
  final String? dateRetour;
  final String? heureRetour;

  final bool isGarant;
  final bool allerDone;
  final bool hasRetour;
  final bool passagersSoumis;

  final String? motifAnnulationChauffeur;

  final ConvoiDemandeur demandeur;
  final ConvoiTrajet trajet;

  final ConvoiGare? gare;
  final ConvoiItineraire? itineraire;
  final ConvoiVehicule? vehicule;

  final bool canStart;
  final bool canComplete;
  final bool canCancel;
  final bool canTrack;
  final String? startBlockedReason;

  final List<ConvoiPassager> passagers;
  final ConvoiLocation? latestLocation;

  ConvoiModel({
    required this.id,
    this.reference,
    required this.statut,
    required this.statutLabel,
    this.nombrePersonnes,
    this.montant,
    this.lieuDepart,
    this.lieuRetour,
    this.lieuRassemblement,
    this.lieuRassemblementRetour,
    this.dateDepart,
    this.heureDepart,
    this.dateRetour,
    this.heureRetour,
    required this.isGarant,
    required this.allerDone,
    required this.hasRetour,
    required this.passagersSoumis,
    this.motifAnnulationChauffeur,
    required this.demandeur,
    required this.trajet,
    this.gare,
    this.itineraire,
    this.vehicule,
    required this.canStart,
    required this.canComplete,
    required this.canCancel,
    required this.canTrack,
    this.startBlockedReason,
    this.passagers = const [],
    this.latestLocation,
  });

  factory ConvoiModel.fromJson(Map<String, dynamic> json) {
    return ConvoiModel(
      id: _toInt(json['id']),
      reference: json['reference']?.toString(),
      statut: json['statut']?.toString() ?? '',
      statutLabel: json['statut_label']?.toString() ?? '',
      nombrePersonnes: json['nombre_personnes'] != null
          ? int.tryParse(json['nombre_personnes'].toString())
          : null,
      montant: json['montant'] != null
          ? double.tryParse(json['montant'].toString())
          : null,
      lieuDepart: json['lieu_depart']?.toString(),
      lieuRetour: json['lieu_retour']?.toString(),
      lieuRassemblement: json['lieu_rassemblement']?.toString(),
      lieuRassemblementRetour: json['lieu_rassemblement_retour']?.toString(),
      dateDepart: json['date_depart']?.toString(),
      heureDepart: json['heure_depart']?.toString(),
      dateRetour: json['date_retour']?.toString(),
      heureRetour: json['heure_retour']?.toString(),
      isGarant: _toBool(json['is_garant']),
      allerDone: _toBool(json['aller_done']),
      hasRetour: _toBool(json['has_retour']),
      passagersSoumis: _toBool(json['passagers_soumis']),
      motifAnnulationChauffeur:
          json['motif_annulation_chauffeur']?.toString(),
      demandeur: ConvoiDemandeur.fromJson(
        (json['demandeur'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      trajet: ConvoiTrajet.fromJson(
        (json['trajet'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      gare: json['gare'] != null
          ? ConvoiGare.fromJson((json['gare'] as Map).cast<String, dynamic>())
          : null,
      itineraire: json['itineraire'] != null
          ? ConvoiItineraire.fromJson(
              (json['itineraire'] as Map).cast<String, dynamic>())
          : null,
      vehicule: json['vehicule'] != null
          ? ConvoiVehicule.fromJson(
              (json['vehicule'] as Map).cast<String, dynamic>())
          : null,
      canStart: _toBool(json['can_start']),
      canComplete: _toBool(json['can_complete']),
      canCancel: _toBool(json['can_cancel']),
      canTrack: _toBool(json['can_track']),
      startBlockedReason: json['start_blocked_reason']?.toString(),
      passagers: ((json['passagers'] ?? const []) as List)
          .map((p) =>
              ConvoiPassager.fromJson((p as Map).cast<String, dynamic>()))
          .toList(),
      latestLocation: json['latest_location'] != null
          ? ConvoiLocation.fromJson(
              (json['latest_location'] as Map).cast<String, dynamic>())
          : null,
    );
  }

  /// Libellé affiché pour l'action "Démarrer" selon qu'on est sur l'aller ou le retour.
  String get startLabel => allerDone ? 'Démarrer le retour' : 'Démarrer le convoi';

  /// Libellé affiché pour "Terminer".
  String get completeLabel => allerDone ? 'Terminer le retour' : 'Terminer le convoi';
}

// =============================================================================

class ConvoiDemandeur {
  final String nom;
  final String? contact;

  ConvoiDemandeur({required this.nom, this.contact});

  factory ConvoiDemandeur.fromJson(Map<String, dynamic> json) {
    return ConvoiDemandeur(
      nom: json['nom']?.toString() ?? '',
      contact: json['contact']?.toString(),
    );
  }
}

class ConvoiTrajet {
  final String depart;
  final String arrivee;
  final bool isRetour;
  final String? date;
  final String? heure;

  ConvoiTrajet({
    required this.depart,
    required this.arrivee,
    required this.isRetour,
    this.date,
    this.heure,
  });

  factory ConvoiTrajet.fromJson(Map<String, dynamic> json) {
    return ConvoiTrajet(
      depart: json['depart']?.toString() ?? '',
      arrivee: json['arrivee']?.toString() ?? '',
      isRetour: _toBool(json['is_retour']),
      date: json['date']?.toString(),
      heure: json['heure']?.toString(),
    );
  }
}

class ConvoiGare {
  final int id;
  final String nomGare;
  final double? latitude;
  final double? longitude;

  ConvoiGare({
    required this.id,
    required this.nomGare,
    this.latitude,
    this.longitude,
  });

  factory ConvoiGare.fromJson(Map<String, dynamic> json) {
    return ConvoiGare(
      id: _toInt(json['id']),
      nomGare: json['nom_gare']?.toString() ?? '',
      latitude: json['latitude'] != null
          ? double.tryParse(json['latitude'].toString())
          : null,
      longitude: json['longitude'] != null
          ? double.tryParse(json['longitude'].toString())
          : null,
    );
  }
}

class ConvoiItineraire {
  final int id;
  final String pointDepart;
  final String pointArrive;

  ConvoiItineraire({
    required this.id,
    required this.pointDepart,
    required this.pointArrive,
  });

  factory ConvoiItineraire.fromJson(Map<String, dynamic> json) {
    return ConvoiItineraire(
      id: _toInt(json['id']),
      pointDepart: json['point_depart']?.toString() ?? '',
      pointArrive: json['point_arrive']?.toString() ?? '',
    );
  }
}

class ConvoiVehicule {
  final int id;
  final String? marque;
  final String? modele;
  final String immatriculation;
  final int? nombrePlace;

  ConvoiVehicule({
    required this.id,
    this.marque,
    this.modele,
    required this.immatriculation,
    this.nombrePlace,
  });

  factory ConvoiVehicule.fromJson(Map<String, dynamic> json) {
    return ConvoiVehicule(
      id: _toInt(json['id']),
      marque: json['marque']?.toString(),
      modele: json['modele']?.toString(),
      immatriculation: json['immatriculation']?.toString() ?? '',
      nombrePlace: json['nombre_place'] != null
          ? int.tryParse(json['nombre_place'].toString())
          : null,
    );
  }
}

class ConvoiPassager {
  final int id;
  final String nom;
  final String? prenoms;
  final String? contact;
  final String? contactUrgence;
  final String? email;

  ConvoiPassager({
    required this.id,
    required this.nom,
    this.prenoms,
    this.contact,
    this.contactUrgence,
    this.email,
  });

  factory ConvoiPassager.fromJson(Map<String, dynamic> json) {
    return ConvoiPassager(
      id: _toInt(json['id']),
      nom: json['nom']?.toString() ?? '',
      prenoms: json['prenoms']?.toString(),
      contact: json['contact']?.toString(),
      contactUrgence: json['contact_urgence']?.toString(),
      email: json['email']?.toString(),
    );
  }

  String get fullName => '${prenoms ?? ''} $nom'.trim();
}

class ConvoiLocation {
  final double latitude;
  final double longitude;
  final double? speed;
  final double? heading;
  final String? updatedAt;

  ConvoiLocation({
    required this.latitude,
    required this.longitude,
    this.speed,
    this.heading,
    this.updatedAt,
  });

  factory ConvoiLocation.fromJson(Map<String, dynamic> json) {
    return ConvoiLocation(
      latitude: double.tryParse(json['latitude']?.toString() ?? '') ?? 0,
      longitude: double.tryParse(json['longitude']?.toString() ?? '') ?? 0,
      speed: json['speed'] != null
          ? double.tryParse(json['speed'].toString())
          : null,
      heading: json['heading'] != null
          ? double.tryParse(json['heading'].toString())
          : null,
      updatedAt: json['updated_at']?.toString(),
    );
  }
}

// =============================================================================
// Helpers

int _toInt(dynamic v) {
  if (v == null) return 0;
  return int.tryParse(v.toString()) ?? 0;
}

bool _toBool(dynamic v) {
  if (v == null) return false;
  if (v is bool) return v;
  final s = v.toString().toLowerCase();
  return s == 'true' || s == '1';
}
