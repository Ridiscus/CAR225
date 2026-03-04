/*class UserModel {
  final int id;
  final String name;
  final String prenom;
  final String email;
  final String contact;
  final String? photoUrl;

  // 🟢 Nouveaux champs urgence alignés avec le backend
  final String? nomUrgence;
  final String? lienParenteUrgence; // <-- Remplacé
  final String? contactUrgence;

  UserModel({
    required this.id,
    required this.name,
    required this.prenom,
    required this.email,
    required this.contact,
    this.photoUrl,
    this.nomUrgence,
    this.lienParenteUrgence, // <-- Remplacé
    this.contactUrgence,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? "",
      prenom: json['prenom'] ?? "",
      email: json['email'] ?? "",
      contact: json['contact'] ?? "",
      photoUrl: json['photo_profile_url'] ?? json['photo_url'],
      nomUrgence: json['nom_urgence'],
      lienParenteUrgence: json['lien_parente_urgence'], // <-- Remplacé
      contactUrgence: json['contact_urgence'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prenom': prenom,
      'email': email,
      'contact': contact,
      'photo_profile_url': photoUrl,
      'nom_urgence': nomUrgence,
      'lien_parente_urgence': lienParenteUrgence, // <-- Remplacé
      'contact_urgence': contactUrgence,
    };
  }



// ===========================================================================
  // 🧹 LE NETTOYEUR D'URL ULTIME
  // ===========================================================================
  String get fullPhotoUrl {
    // 1. Sécurité de base
    if (photoUrl == null || photoUrl!.isEmpty) {
      print("⚠️ [UserModel] Pas de photo, image par défaut utilisée.");
      return "https://ui-avatars.com/api/?name=$prenom+$name&background=random&size=200";
    }

    print("🔍 [UserModel] URL brute reçue de la DB : '$photoUrl'");

    // 2. CAS CRITIQUE : L'URL Google a été 'salie' par le backend
    // Ex: "storage/https://lh3.google..." ou "public/https://..."
    if (photoUrl!.contains('https://')) {
      // On extrait juste la partie qui commence par https://
      final cleanUrl = photoUrl!.substring(photoUrl!.indexOf('https://'));
      print("✅ [UserModel] URL nettoyée (Google) : $cleanUrl");
      return cleanUrl;
    }

    // 3. CAS STANDARD : C'est déjà une URL web propre (http ou https)
    if (photoUrl!.startsWith('http')) {
      return photoUrl!;
    }

    // 4. CAS LOCAL : Image stockée sur Laravel (storage/avatars/...)
    // ⚠️ Vérifie bien que cette URL ngrok est active !
    //const String baseUrl = "https://jingly-lindy-unminding.ngrok-free.dev";
    const String baseUrl = "https://car225.com";

    // On nettoie les slashs en double au cas où
    String path = photoUrl!;
    if (path.startsWith('/')) path = path.substring(1); // Enlève le premier slash
    if (path.startsWith('storage/')) path = path.replaceFirst('storage/', ''); // Évite le double storage

    final localUrl = "$baseUrl/storage/$path";
    print("✅ [UserModel] URL Locale générée : $localUrl");
    return localUrl;
  }

}*/



class UserModel {
  final int id;
  final String? codeId; // 🆕 Ajouté (ex: USR-XXXX)
  final String name;
  final String prenom;
  final String email;
  final String contact;
  final String? photoUrl;
  final String? nomUrgence;
  final String? lienParenteUrgence;
  final String? contactUrgence;

  UserModel({
    required this.id,
    this.codeId,
    required this.name,
    required this.prenom,
    required this.email,
    required this.contact,
    this.photoUrl,
    this.nomUrgence,
    this.lienParenteUrgence,
    this.contactUrgence,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      codeId: json['code_id'], // 🆕 Récupération du matricule
      name: json['name'] ?? "",
      prenom: json['prenom'] ?? "",
      email: json['email'] ?? "",
      contact: json['contact'] ?? "",
      photoUrl: json['photo_profile_url'] ?? json['photo_url'] ?? json['photo_profile_path'],
      nomUrgence: json['nom_urgence'],
      lienParenteUrgence: json['lien_parente_urgence'],
      contactUrgence: json['contact_urgence'],
    );
  }



  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'prenom': prenom,
      'email': email,
      'contact': contact,
      'photo_profile_url': photoUrl,
      'nom_urgence': nomUrgence,
      'lien_parente_urgence': lienParenteUrgence, // <-- Remplacé
      'contact_urgence': contactUrgence,
    };
  }


  // 🧹 LE NETTOYEUR D'URL ULTIME
  // ===========================================================================
  String get fullPhotoUrl {
    // 1. Sécurité de base
    if (photoUrl == null || photoUrl!.isEmpty) {
      print("⚠️ [UserModel] Pas de photo, image par défaut utilisée.");
      return "https://ui-avatars.com/api/?name=$prenom+$name&background=random&size=200";
    }

    print("🔍 [UserModel] URL brute reçue de la DB : '$photoUrl'");

    // 2. CAS CRITIQUE : L'URL Google a été 'salie' par le backend
    // Ex: "storage/https://lh3.google..." ou "public/https://..."
    if (photoUrl!.contains('https://')) {
      // On extrait juste la partie qui commence par https://
      final cleanUrl = photoUrl!.substring(photoUrl!.indexOf('https://'));
      print("✅ [UserModel] URL nettoyée (Google) : $cleanUrl");
      return cleanUrl;
    }

    // 3. CAS STANDARD : C'est déjà une URL web propre (http ou https)
    if (photoUrl!.startsWith('http')) {
      return photoUrl!;
    }

    // 4. CAS LOCAL : Image stockée sur Laravel (storage/avatars/...)
    // ⚠️ Vérifie bien que cette URL ngrok est active !
    //const String baseUrl = "https://jingly-lindy-unminding.ngrok-free.dev";
    const String baseUrl = "https://car225.com";

    // On nettoie les slashs en double au cas où
    String path = photoUrl!;
    if (path.startsWith('/')) path = path.substring(1); // Enlève le premier slash
    if (path.startsWith('storage/')) path = path.replaceFirst('storage/', ''); // Évite le double storage

    final localUrl = "$baseUrl/storage/$path";
    print("✅ [UserModel] URL Locale générée : $localUrl");
    return localUrl;
  }

}