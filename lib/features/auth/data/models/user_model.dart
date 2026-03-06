class UserModel {
  final int id;
  final String? codeId;
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
      codeId: json['code_id'],
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
      'lien_parente_urgence': lienParenteUrgence,
      'contact_urgence': contactUrgence,
    };
  }

  // 🧹 LE NETTOYEUR D'URL ULTIME (CORRIGÉ)
  // ===========================================================================
  String get fullPhotoUrl {
    // 1. Sécurité de base
    if (photoUrl == null || photoUrl!.isEmpty) {
      print("⚠️ [UserModel] Pas de photo, image par défaut utilisée.");
      return "https://ui-avatars.com/api/?name=$prenom+$name&background=random&size=200";
    }

    String url = photoUrl!;
    print("🔍 [UserModel] URL brute reçue de la DB : '$url'");

    // 2. CAS CRITIQUE : L'URL Google a été 'salie' par le backend
    // On cherche la DERNIÈRE apparition de "http" (gère http et https)
    int lastHttpIndex = url.lastIndexOf('http');

    if (lastHttpIndex != -1) {
      // Si on trouve un http/https, on coupe tout ce qu'il y a avant !
      // Ex: "https://car225.../storage/https://lh3..." devient "https://lh3..."
      final cleanUrl = url.substring(lastHttpIndex);
      print("✅ [UserModel] URL nettoyée (Web/Google) : $cleanUrl");
      return cleanUrl;
    }

    // 3. CAS LOCAL : Aucun "http" trouvé, c'est un chemin relatif (ex: "avatars/123.jpg")
    const String baseUrl = "https://car225.com";

    // On nettoie les slashs et les doublons de "storage"
    String path = url;
    if (path.startsWith('/')) path = path.substring(1);
    if (path.startsWith('storage/')) path = path.replaceFirst('storage/', '');

    final localUrl = "$baseUrl/storage/$path";
    print("✅ [UserModel] URL Locale générée : $localUrl");
    return localUrl;
  }
}