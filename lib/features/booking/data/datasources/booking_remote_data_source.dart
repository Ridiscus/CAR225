import 'package:dio/dio.dart';
import '../models/program_model.dart';

abstract class BookingRemoteDataSource {
  Future<List<String>> getVillesDisponibles();

  Future<List<ProgramModel>> searchProgrammes({
    required dynamic depart,
    required dynamic arrivee,
    required String date,
    required bool isAllerRetour,
  });

  Future<List<ProgramModel>> getAllTrips();
  Future<List<ProgramModel>> getAllProgrammes();
  Future<List<int>> getReservedSeats(int programId, String date);
}

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final Dio dio;

  // AJOUTE CECI : Une mémoire pour savoir quel nom court correspond à quel nom long
  static Map<String, String> _villeMapping = {};

  BookingRemoteDataSourceImpl({required this.dio});







  // ---------------------------------------------------------------------------
  // 1. RÉCUPÉRATION DES VILLES + REMPLISSAGE DU DICTIONNAIRE
  // ---------------------------------------------------------------------------
  @override
  Future<List<String>> getVillesDisponibles() async {
    print("------------------------------------------------------------------");
    print("🌍 [DEBUG] Début de getVillesDisponibles()");

    try {
      final response = await dio.get('/user/itineraires');

      final paginationData = response.data['data'];
      final List rawList = paginationData?['data'] ?? [];

      print("🔢 [DEBUG] ${rawList.length} itinéraires trouvés pour construire la liste.");

      Set<String> villesCourtesUniques = {};

      for (var item in rawList) {
        // Récupération des noms BRUTS (ex: "Abidjan, Côte d'Ivoire")
        String departLong = item['point_depart']?.toString() ?? "";
        String arriveeLong = item['point_arrive']?.toString() ?? "";

        // Calcul des noms COURTS (ex: "Abidjan")
        String departCourt = departLong.split(',')[0].trim();
        String arriveeCourt = arriveeLong.split(',')[0].trim();

        // --- REMPLISSAGE DU MAPPING ---
        if (departLong.isNotEmpty) {
          _villeMapping[departCourt] = departLong; // On associe Court -> Long
          villesCourtesUniques.add(departCourt);
        }
        if (arriveeLong.isNotEmpty) {
          _villeMapping[arriveeCourt] = arriveeLong; // On associe Court -> Long
          villesCourtesUniques.add(arriveeCourt);
        }
      }

      final listeFinale = villesCourtesUniques.toList();
      listeFinale.sort();

      print("✅ [DEBUG] Mapping généré : $_villeMapping");
      print("🏁 [DEBUG] Liste affichée user : $listeFinale");

      return listeFinale;

    } catch (e, stackTrace) {
      print("❌ [DEBUG] ERREUR : $e");
      print("👉 Stack : $stackTrace");
      return ["Abidjan", "Bouaké", "Yamoussoukro", "San-Pédro", "Korhogo"];
    }
  }

  // ---------------------------------------------------------------------------
  // 2. RECHERCHE INTELLIGENTE (Utilise le Mapping)
  // ---------------------------------------------------------------------------
  /*@override
  Future<List<ProgramModel>> searchProgrammes({
    required dynamic depart,
    required dynamic arrivee,
    required String date,
    required bool isAllerRetour,
  }) async {
    try {
      Response response;

      // Nettoyage des entrées utilisateur
      String departCourt = depart.toString().trim();
      String arriveeCourt = arrivee.toString().trim();
      final bool isSearch = departCourt.isNotEmpty && arriveeCourt.isNotEmpty;

      if (isSearch) {
        // --- TRADUCTION AVANT ENVOI ---
        // On cherche le vrai nom dans la mémoire.
        // Si on ne trouve pas, on ajoute ", Côte d'Ivoire" par défaut par sécurité.
        String departAPI = _villeMapping[departCourt] ?? "$departCourt, Côte d'Ivoire";
        String arriveeAPI = _villeMapping[arriveeCourt] ?? "$arriveeCourt, Côte d'Ivoire";

        print("🔄 TRADUCTION : '$departCourt' devient '$departAPI'");
        print("🔄 TRADUCTION : '$arriveeCourt' devient '$arriveeAPI'");

        print("====== 📡 API REQUEST: POST /user/itineraires/search ======");

        final requestBody = {
          "point_depart": departAPI,   // <--- Vrai nom envoyé au backend
          "point_arrive": arriveeAPI,  // <--- Vrai nom envoyé au backend
          "date_depart": date,
          "type_trajet": isAllerRetour ? "aller-retour" : "aller-simple"
        };
        print("📤 Body envoyé : $requestBody");

        response = await dio.post('/user/itineraires/search', data: requestBody);
      } else {
        print("====== 📡 API REQUEST: GET /user/programmes ======");
        response = await dio.get('/user/programmes');
      }

      // --- EXTRACTION ET PARSING (CODE STANDARD) ---
      final rootData = response.data['data'];
      if (rootData == null) {
        print("⚠️ API a renvoyé NULL dans 'data'.");
        return [];
      }

      List listJSON = [];
      if (rootData is Map && rootData.containsKey('data')) {
        listJSON = rootData['data'] ?? [];
      } else if (rootData is List) {
        listJSON = rootData;
      }

      print("🔢 Résultats bruts reçus : ${listJSON.length}");
      final List<ProgramModel> extractedPrograms = [];

      for (var jsonItem in listJSON) {
        List horaires = jsonItem['horaires_disponibles'] ?? [];

        if (horaires.isNotEmpty) {
          for (var horaire in horaires) {
            Map<String, dynamic> mergedJson = Map.from(jsonItem);
            mergedJson['id'] = horaire['programme_id'];
            mergedJson['heure_depart'] = horaire['heure_depart'];
            mergedJson['heure_arrive'] = horaire['heure_arrive'];

            double prixDouble = double.tryParse(horaire['prix'].toString()) ?? 0.0;
            mergedJson['montant_billet'] = prixDouble.toInt();

            if (horaire['vehicule'] != null) mergedJson['vehicule'] = horaire['vehicule'];
            if (horaire['chauffeur'] != null) mergedJson['chauffeur'] = horaire['chauffeur'];
            mergedJson['is_aller_retour'] = isAllerRetour ? 1 : 0;

            extractedPrograms.add(ProgramModel.fromJson(mergedJson));
          }
        } else {
          // Fallback sans horaires détaillés
          if (jsonItem['montant_billet'] != null) {
            double prixRaacine = double.tryParse(jsonItem['montant_billet'].toString()) ?? 0.0;
            jsonItem['montant_billet'] = prixRaacine.toInt();
          }
          jsonItem['is_aller_retour'] = isAllerRetour ? 1 : 0;
          extractedPrograms.add(ProgramModel.fromJson(jsonItem));
        }
      }

      // --- FILTRAGE FINAL DE SÉCURITÉ ---
      if (isSearch) {
        final targetDepart = departCourt.toLowerCase();
        final targetArrivee = arriveeCourt.toLowerCase();

        final filteredResults = extractedPrograms.where((prog) {
          // On nettoie aussi les données reçues pour comparer "pomme" avec "pomme"
          String pDepart = prog.villeDepart.split(',')[0].trim().toLowerCase();
          String pArrivee = prog.villeArrivee.split(',')[0].trim().toLowerCase();

          bool matchDepart = pDepart.contains(targetDepart) || targetDepart.contains(pDepart);
          bool matchArrivee = pArrivee.contains(targetArrivee) || targetArrivee.contains(pArrivee);

          return matchDepart && matchArrivee;
        }).toList();

        print("✅ ${filteredResults.length} trajets valides après filtrage.");
        return filteredResults;
      }

      return extractedPrograms;

    } on DioException catch (e) {
      print("❌ ERREUR API: ${e.response?.data}");
      return [];
    } catch (e) {
      print("❌ ERREUR INCONNUE: $e");
      return [];
    }
  }*/


  // ---------------------------------------------------------------------------
  // 2. RECHERCHE INTELLIGENTE (CORRIGÉE)
  // ---------------------------------------------------------------------------
  @override
  Future<List<ProgramModel>> searchProgrammes({
    required dynamic depart,
    required dynamic arrivee,
    required String date,
    required bool isAllerRetour,
  }) async {
    try {
      Response response;

      // Nettoyage initial
      String rawDepart = depart.toString().trim();
      String rawArrivee = arrivee.toString().trim();

      // On vérifie si on a bien des valeurs pour lancer une recherche
      final bool isSearch = rawDepart.isNotEmpty && rawArrivee.isNotEmpty;

      if (isSearch) {
        // --- 🔧 FIX : NETTOYAGE RADICAL ---
        // 1. On prend tout ce qui est avant la première virgule (ex: "Bouaké, CI" -> "Bouaké")
        String departVilleSeule = rawDepart.split(',')[0].trim();
        String arriveeVilleSeule = rawArrivee.split(',')[0].trim();

        // 2. On reconstruit PROPREMENT le format API (ex: "Bouaké, Côte d'Ivoire")
        // Tu peux adapter le pays si besoin, mais ça évite les doublons.
        String departAPI = "$departVilleSeule, Côte d'Ivoire";
        String arriveeAPI = "$arriveeVilleSeule, Côte d'Ivoire";

        print("🟦 --- DEBUG APPEL API ---");
        print("Entrée brute : '$rawDepart' -> Ville seule : '$departVilleSeule'");
        print("Sortie API   : '$departAPI'");
        print("---------------------------");

        final requestBody = {
          "point_depart": departAPI,
          "point_arrive": arriveeAPI,
          "date_depart": date,
          "type_trajet": isAllerRetour ? "aller-retour" : "aller-simple"
        };

        print("====== 📡 API REQUEST: POST /user/itineraires/search ======");
        print("📤 Body envoyé : $requestBody");

        response = await dio.post('/user/itineraires/search', data: requestBody);
      } else {
        // Pas de recherche, on récupère tout (GET classique)
        print("====== 📡 API REQUEST: GET /user/programmes ======");
        response = await dio.get('/user/programmes');
      }

      // --- EXTRACTION ET PARSING (CODE STANDARD) ---
      final rootData = response.data;
      if (rootData == null) {
        print("⚠️ API a renvoyé NULL.");
        return [];
      }

      // Gestion flexible data (Map ou List)
      List listJSON = [];
      if (rootData is Map && rootData.containsKey('data')) {
        // Parfois l'API met les résultats dans data['data'] (pagination) ou juste data (liste)
        if (rootData['data'] is Map && rootData['data'].containsKey('data')) {
          listJSON = rootData['data']['data'] ?? [];
        } else {
          listJSON = rootData['data'] ?? [];
        }
      } else if (rootData is List) {
        listJSON = rootData;
      }

      print("🔢 Résultats bruts reçus : ${listJSON.length}");
      final List<ProgramModel> extractedPrograms = [];

      for (var jsonItem in listJSON) {
        // Gestion des horaires multiples (si structure complexe)
        List horaires = jsonItem['horaires_disponibles'] ?? [];

        if (horaires.isNotEmpty) {
          for (var horaire in horaires) {
            Map<String, dynamic> mergedJson = Map.from(jsonItem);
            // On écrase les infos globales par les infos spécifiques de l'horaire
            mergedJson['id'] = horaire['programme_id'];
            mergedJson['heure_depart'] = horaire['heure_depart'];
            mergedJson['heure_arrive'] = horaire['heure_arrive'];

            // Prix
            double prix = double.tryParse(horaire['prix'].toString()) ?? 0.0;
            mergedJson['montant_billet'] = prix.toInt();

            if (horaire['vehicule'] != null) mergedJson['vehicule'] = horaire['vehicule'];
            if (horaire['chauffeur'] != null) mergedJson['chauffeur'] = horaire['chauffeur'];

            mergedJson['is_aller_retour'] = isAllerRetour ? 1 : 0;

            extractedPrograms.add(ProgramModel.fromJson(mergedJson));
          }
        } else {
          // Fallback structure simple
          if (jsonItem['montant_billet'] != null) {
            double prix = double.tryParse(jsonItem['montant_billet'].toString()) ?? 0.0;
            jsonItem['montant_billet'] = prix.toInt();
          }
          jsonItem['is_aller_retour'] = isAllerRetour ? 1 : 0;
          extractedPrograms.add(ProgramModel.fromJson(jsonItem));
        }
      }

      print("✅ ${extractedPrograms.length} trajets parsés avec succès.");
      return extractedPrograms;

    } on DioException catch (e) {
      print("❌ ERREUR API (${e.response?.statusCode}): ${e.response?.data}");
      return [];
    } catch (e) {
      print("❌ ERREUR INCONNUE: $e");
      return [];
    }
  }









  // ---------------------------------------------------------------------------
  // 2. RÉCUPÉRATION DE TOUS LES PROGRAMMES (Sans filtre)
  // ---------------------------------------------------------------------------
  @override
  Future<List<ProgramModel>> getAllProgrammes() async {
    // On appelle la méthode search avec des paramètres vides pour tout récupérer
    // et profiter de la logique de parsing (éclatement des horaires) commune.
    return searchProgrammes(depart: "", arrivee: "", date: "", isAllerRetour: false);
  }

  @override
  Future<List<ProgramModel>> getAllTrips() async {
    return await getAllProgrammes();
  }

  // ---------------------------------------------------------------------------
  // 4. SIÈGES RÉSERVÉS (CORRIGÉ & ROBUSTE)
  // ---------------------------------------------------------------------------
  @override
  Future<List<int>> getReservedSeats(int programId, String date) async {
    // 1. Log pour vérifier ce qu'on envoie (Super important pour le debug)
    print("🔍 API CALL: /user/programmes/$programId/reserved-seats?date=$date");

    try {
      final response = await dio.get(
        '/user/programmes/$programId/reserved-seats',
        queryParameters: {
          'date': date, // Assure-toi que c'est formaté "yyyy-MM-dd"
        },
      );

      // 2. Log pour voir la réponse brute
      print("📩 API RESPONSE (${response.statusCode}): ${response.data}");

      // 3. Vérification de sécurité sur la réponse
      if (response.statusCode == 200) {
        final dynamic rootData = response.data;

        // Cas où l'API renvoie null ou success: false
        if (rootData == null) return [];

        List<dynamic> listData = [];

        // Gestion flexible : est-ce que 'data' est direct ou dans une map ?
        if (rootData is Map && rootData.containsKey('data')) {
          listData = rootData['data'] ?? [];
        } else if (rootData is List) {
          listData = rootData;
        }

        // 4. Conversion propre en List<int>
        // On utilise toString() avant int.tryParse pour gérer à la fois
        // les réponses [1, 2] (int) et ["1", "2"] (String)
        final List<int> seats = listData
            .map((e) => int.tryParse(e.toString()) ?? 0)
            .where((element) => element != 0) // On retire les 0 si le parse a échoué
            .toList();

        print("✅ Sièges parsés : $seats");
        return seats;
      }

      return [];

    } on DioException catch (e) {
      print("❌ ERREUR HTTP (Sièges): ${e.response?.statusCode} - ${e.response?.data}");
      return [];
    } catch (e) {
      print("❌ ERREUR LOGIQUE (Sièges): $e");
      return [];
    }
  }
}