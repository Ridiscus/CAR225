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



  @override
  Future<List<ProgramModel>> searchProgrammes({
    required dynamic depart,
    required dynamic arrivee,
    required String date,
    required bool isAllerRetour,
  }) async {
    try {
      Response response;

      // 1. Nettoyage et Préparation des données
      String rawDepart = depart.toString().trim();
      String rawArrivee = arrivee.toString().trim();

      // On garde uniquement le nom de la ville pour reconstruire le format propre
      // Ex: "Abidjan, Lagunes" -> "Abidjan"
      String departVilleSeule = rawDepart.split(',')[0].trim();
      String arriveeVilleSeule = rawArrivee.split(',')[0].trim();

      // Format attendu par le backend : "Ville, Côte d'Ivoire"
      String departAPI = "$departVilleSeule, Côte d'Ivoire";
      String arriveeAPI = "$arriveeVilleSeule, Côte d'Ivoire";

      // 2. Construction du Body
      final requestBody = {
        "point_depart": departAPI,
        "point_arrive": arriveeAPI,
        "date": date, // ✅ CORRECTION ICI (C'était "date_depart")
        "type_trajet": isAllerRetour ? "aller-retour" : "aller-simple"
      };

      // 🖨️ DEBUG : Ce qu'on envoie
      print("\n🔵 ================== ENVOI REQUÊTE API ==================");
      print("📍 URL : /user/itineraires/search");
      print("📤 BODY JSON : $requestBody");
      print("========================================================\n");

      // 3. Appel API
      response = await dio.post('/user/itineraires/search', data: requestBody);

      // 🖨️ DEBUG : Ce qu'on reçoit
      print("\n🟢 ================== RÉPONSE REÇUE ==================");
      print("Status Code : ${response.statusCode}");
      print("📥 DONNÉES BRUTES : ${response.data}"); // Tu verras tout le JSON ici
      print("======================================================\n");

      // 4. Traitement de la réponse
      final rootData = response.data;

      if (rootData == null) {
        print("⚠️ ERREUR : L'API a renvoyé null.");
        return [];
      }

      // Extraction de la liste (gestion flexible : map ou list)
      List listJSON = [];
      if (rootData is Map) {
        if (rootData.containsKey('data')) {
          var innerData = rootData['data'];
          if (innerData is List) {
            listJSON = innerData;
          } else if (innerData is Map && innerData.containsKey('data')) {
            // Cas pagination Laravel standard
            listJSON = innerData['data'] ?? [];
          } else {
            // Cas où data n'est ni liste ni map paginée (rare mais possible)
            print("⚠️ Structure 'data' inconnue : $innerData");
          }
        } else {
          // Si le JSON est directement un objet sans clé "data" mais qu'on attend une liste
          print("⚠️ Le JSON racine est une Map mais sans clé 'data'. Vérifier la structure.");
        }
      } else if (rootData is List) {
        listJSON = rootData;
      }

      print("🔢 Nombre d'éléments trouvés dans le JSON : ${listJSON.length}");

      // 5. Parsing vers ProgramModel
      final List<ProgramModel> extractedPrograms = [];

      for (var jsonItem in listJSON) {
        try {
          // Gestion si l'API renvoie des horaires groupés
          List horaires = jsonItem['horaires_disponibles'] ?? [];

          if (horaires.isNotEmpty) {
            for (var horaire in horaires) {
              // On fusionne les infos parentes avec les infos spécifiques de l'horaire
              Map<String, dynamic> mergedJson = Map.from(jsonItem);

              mergedJson['id'] = horaire['programme_id'] ?? jsonItem['id'];
              mergedJson['heure_depart'] = horaire['heure_depart'];
              mergedJson['heure_arrive'] = horaire['heure_arrive'];

              // Sécurisation du prix (parfois String, parfois Int, parfois Double)
              var rawPrix = horaire['montant_billet'] ?? horaire['prix'] ?? jsonItem['montant_billet'];
              mergedJson['montant_billet'] = int.tryParse(rawPrix.toString().split('.')[0]) ?? 0;

              if (horaire['vehicule'] != null) mergedJson['vehicule'] = horaire['vehicule'];
              if (horaire['chauffeur'] != null) mergedJson['chauffeur'] = horaire['chauffeur'];

              mergedJson['is_aller_retour'] = isAllerRetour ? 1 : 0;

              extractedPrograms.add(ProgramModel.fromJson(mergedJson));
            }
          } else {
            // Format standard simple
            var rawPrix = jsonItem['montant_billet'] ?? jsonItem['prix'];
            jsonItem['montant_billet'] = int.tryParse(rawPrix.toString().split('.')[0]) ?? 0;

            jsonItem['is_aller_retour'] = isAllerRetour ? 1 : 0;
            extractedPrograms.add(ProgramModel.fromJson(jsonItem));
          }
        } catch (e) {
          print("⚠️ Erreur de parsing sur un élément : $e");
          print("Élément fautif : $jsonItem");
        }
      }

      print("✅ SUCCÈS : ${extractedPrograms.length} programmes valides retournés.");
      return extractedPrograms;

    } on DioException catch (e) {
      print("\n❌ ================== ERREUR DIO ==================");
      print("Status: ${e.response?.statusCode}");
      print("Message: ${e.message}");
      print("Data erreur: ${e.response?.data}");
      print("==================================================\n");
      return [];
    } catch (e, stacktrace) {
      print("\n❌ ================== ERREUR CRITIQUE ==================");
      print("Erreur : $e");
      print("Stack : $stacktrace");
      print("======================================================\n");
      return [];
    }
  }





  // ---------------------------------------------------------------------------
  // 2. RÉCUPÉRATION DE TOUS LES PROGRAMMES (Via API dédiée /user/programmes)
  // ---------------------------------------------------------------------------
  @override
  Future<List<ProgramModel>> getAllProgrammes() async {
    print("------------------------------------------------------------------");
    print("🚀 [DEBUG] getAllProgrammes : Démarrage appel /user/programmes");

    try {
      final response = await dio.get('/user/programmes');

      // Validation simple
      if (response.statusCode != 200 || response.data == null) return [];

      final rootData = response.data;
      List<dynamic> rawList = [];

      // Récupération de la liste (gestion pagination Laravel)
      if (rootData is Map && rootData.containsKey('data')) {
        final paginationData = rootData['data'];
        if (paginationData is Map && paginationData.containsKey('data')) {
          rawList = paginationData['data'] ?? [];
        } else if (paginationData is List) {
          rawList = paginationData;
        }
      }

      print("🔢 [DEBUG] ${rawList.length} éléments parents trouvés.");

      final List<ProgramModel> extractedPrograms = [];

      for (var jsonItem in rawList) {
        try {
          // 1. Récupération des infos de capacité du PARENT
          int parentCapacity = int.tryParse(jsonItem['capacity'].toString()) ?? 0;

          // Fallback : si capacity est vide, on tente de voir si le véhicule a une info
          if (parentCapacity == 0 && jsonItem['vehicule'] != null) {
            parentCapacity = int.tryParse(jsonItem['vehicule']['nombre_place'].toString()) ?? 0;
          }
          // Ultime fallback pour éviter la division par zéro ou l'affichage vide
          if (parentCapacity == 0) parentCapacity = 48;

          // 2. Gestion des Horaires Multiples
          List horaires = jsonItem['horaires_disponibles'] ?? [];

          if (horaires.isNotEmpty) {
            // CAS A : Le programme a plusieurs horaires
            for (var horaire in horaires) {

              // ---------------------------------------------------------
              // 🔍 DEBUG LOGS (Regarde ta console après avoir rechargé)
              // ---------------------------------------------------------
              print("🔍 DEBUG ID:${jsonItem['id']} - ${horaire['heure_depart']}");
              print("   👉 Capacity Parent : $parentCapacity");
              print("   👉 Occupé (json)   : ${horaire['nbre_siege_occupe']}");
              print("   👉 Dispo (expl)    : ${horaire['nbre_place_dispo'] ?? horaire['places_disponibles']}");
              print("------------------------------------------------");
              // ---------------------------------------------------------

              // On prépare le JSON fusionné
              Map<String, dynamic> mergedJson = Map.from(jsonItem);

              // On écrase avec les infos spécifiques de l'horaire
              mergedJson['id'] = horaire['programme_id'] ?? jsonItem['id'];
              mergedJson['heure_depart'] = horaire['heure_depart'];
              mergedJson['heure_arrive'] = horaire['heure_arrive'];

              // On force la capacité qu'on a trouvée plus haut
              mergedJson['capacity'] = parentCapacity;

              // --- LOGIQUE INTELLIGENTE DES PLACES ---
              int occupation = int.tryParse(horaire['nbre_siege_occupe'].toString()) ?? 0;
              int placesDispo = 0;

              // Si l'API donne explicitement les places dispo, on prend ça
              if (horaire['nbre_place_dispo'] != null) {
                placesDispo = int.tryParse(horaire['nbre_place_dispo'].toString()) ?? (parentCapacity - occupation);
              } else {
                // Sinon on calcule
                placesDispo = parentCapacity - occupation;
              }

              // On injecte le résultat dans le json pour le Model
              mergedJson['places_disponibles'] = placesDispo > 0 ? placesDispo : 0;
              mergedJson['nbre_siege_occupe'] = occupation; // On s'assure que le modèle le reçoit

              // Nettoyage Prix
              var rawPrix = horaire['prix'] ?? horaire['montant_billet'] ?? jsonItem['montant_billet'];
              mergedJson['montant_billet'] = int.tryParse(rawPrix.toString().split('.')[0]) ?? 0;

              extractedPrograms.add(ProgramModel.fromJson(mergedJson));
            }
          } else {
            // CAS B : Programme simple sans sous-horaires
            Map<String, dynamic> cleanJson = Map.from(jsonItem);

            // ---------------------------------------------------------
            // 🔍 DEBUG LOGS (Cas Simple)
            // ---------------------------------------------------------
            print("🔍 DEBUG ID:${jsonItem['id']} (Simple)");
            print("   👉 Capacity : $parentCapacity");
            print("   👉 Occupé   : ${jsonItem['nbre_siege_occupe']}");
            print("------------------------------------------------");

            int occupation = int.tryParse(jsonItem['nbre_siege_occupe'].toString()) ?? 0;

            cleanJson['capacity'] = parentCapacity;
            cleanJson['places_disponibles'] = (parentCapacity - occupation) > 0 ? (parentCapacity - occupation) : 0;
            cleanJson['nbre_siege_occupe'] = occupation;

            // Nettoyage Prix
            var rawPrix = cleanJson['montant_billet'] ?? cleanJson['prix'] ?? 0;
            cleanJson['montant_billet'] = int.tryParse(rawPrix.toString().split('.')[0]) ?? 0;

            extractedPrograms.add(ProgramModel.fromJson(cleanJson));
          }

        } catch (e) {
          print("⚠️ [DEBUG] Erreur parsing item ${jsonItem['id']}: $e");
        }
      }

      print("✅ [DEBUG] ${extractedPrograms.length} programmes finaux générés.");
      return extractedPrograms;

    } catch (e) {
      print("❌ [DEBUG] Erreur critique: $e");
      return [];
    }
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