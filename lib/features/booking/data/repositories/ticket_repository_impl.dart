import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Importe l'interface et le modèle (vérifie tes chemins)
import '../../domain/repositories/ticket_repository.dart';
import '../../data/models/ticket_model.dart';

class TicketRepositoryImpl implements TicketRepository {
  final Dio dio;

  TicketRepositoryImpl({required this.dio});

  @override
  Future<List<TicketModel>> getMyTickets() async {
    debugPrint("🚀 [API START] getMyTickets : Lancement de la requête...");

    try {
      final String url = '${dio.options.baseUrl}/user/reservations?per_page=100';
      debugPrint("🔗 [API URL] : $url");

      final response = await dio.get('/user/reservations?per_page=100');

      final dynamic root = response.data;
      final List<TicketModel> allTickets = [];

      if (root is Map && root.containsKey('data')) {
        final dynamic paginationData = root['data'];
        final dynamic reservationsList = (paginationData is Map && paginationData.containsKey('data'))
            ? paginationData['data']
            : paginationData;

        if (reservationsList is List) {
          final DateTime now = DateTime.now();

          for (var i = 0; i < reservationsList.length; i++) {
            try {
              var res = reservationsList[i];
              final Map<String, dynamic> r = Map<String, dynamic>.from(res);
              final Map<String, dynamic> programme = r['programme'] ?? {};
              final Map<String, dynamic> compagnie = programme['compagnie'] ?? {};

              // --- 1. EXTRACTION DES DONNÉES DE BASE ---
              String departCity = r['point_depart'] ?? programme['point_depart'] ?? "Départ";
              String arriveCity = r['point_arrive'] ?? programme['point_arrive'] ?? "Arrivée";
              String companyName = compagnie['name'] ?? "Compagnie";
              String cleanPrice = r['montant']?.toString() ?? "0";
              String qrCodeUrl = r['qr_code'] ?? "";

              // --- 2. GESTION DES DATES PRÉCISES ---
              String heureDepart = programme['heure_depart'] ?? "00:00";
              if (heureDepart.length > 5) heureDepart = heureDepart.substring(0, 5);
              DateTime dateVoyage = DateTime.tryParse(r['date_voyage'] ?? "") ?? DateTime.now();

              // --- 3. LOGIQUE STATUTS (CORRIGÉE) ---

              // A. On récupère le statut brut (nécessaire pour la logique retour plus bas)
              String rawStatus = (r['statut_aller'] ?? r['statut'] ?? "Inconnu").toString().toLowerCase();

              // B. On détermine le statut d'affichage (finalStatus)
              String finalStatus;

              // Priorité absolue au display_statut du backend
              if (r['display_statut'] != null && r['display_statut'].toString().isNotEmpty) {
                finalStatus = r['display_statut'].toString();
              } else {
                // Fallback sur le statut technique si display_statut est vide
                finalStatus = rawStatus;
              }

              // C. Nettoyage cosmétique (ex: "en_voyage" -> "En voyage")
              finalStatus = finalStatus.replaceAll('_', ' ');
              if (finalStatus.isNotEmpty) {
                finalStatus = "${finalStatus[0].toUpperCase()}${finalStatus.substring(1)}";
              }

              // --- 4. GESTION DES PASSAGERS ---
              String seatAller = "??";
              String? seatRetour;
              String passagerNom = "Moi";

              if (r['passagers'] != null && (r['passagers'] as List).isNotEmpty) {
                var firstPax = r['passagers'][0];
                seatAller = firstPax['seat_number'].toString();
                if (firstPax['return_seat_number'] != null) {
                  seatRetour = firstPax['return_seat_number'].toString();
                }
                passagerNom = "${firstPax['prenom']} ${firstPax['nom']}";
              } else {
                seatAller = r['seat_number']?.toString() ?? "??";
                seatRetour = r['seat_number_return']?.toString();
                passagerNom = "${r['passager_prenom']} ${r['passager_nom']}";
              }

              // --- 5. AJOUT TICKET ---
              allTickets.add(TicketModel(
                id: int.tryParse(r['id'].toString()) ?? 0,
                transactionId: "${r['reference']}",
                ticketNumber: "${r['reference']}",
                passengerName: passagerNom,
                seatNumber: seatAller,
                returnSeatNumber: seatRetour,
                departureCity: departCity,
                arrivalCity: arriveCity,
                companyName: companyName,
                departureTimeRaw: heureDepart,
                date: dateVoyage,

                // 🔴 CORRECTION ICI : On utilise finalStatus au lieu de displayStatus
                status: finalStatus,

                pdfBase64: null,
                qrCodeUrl: qrCodeUrl,
                price: cleanPrice,
                isAllerRetour: r['is_aller_retour'] == true,
                returnDate: r['date_retour'] != null ? DateTime.tryParse(r['date_retour']) : null,
                isReturnLeg: true,
              ));

              // --- 6. GESTION RETOUR ---
              if (r['is_aller_retour'] == true && r['date_retour'] != null) {
                DateTime dateRetour = DateTime.tryParse(r['date_retour'])!;
                DateTime exactReturnTime = dateRetour.add(const Duration(hours: 23, minutes: 59));

                // 🔴 CORRECTION ICI : On initialise avec finalStatus
                String statusRetour = finalStatus;

                // Logique spécifique retour (si nécessaire)
                if (now.isAfter(exactReturnTime) && !rawStatus.contains("annul")) {
                  statusRetour = "Terminé";
                } else if (['payé', 'validé', 'confirmé'].contains(finalStatus.toLowerCase())) {
                  statusRetour = "Confirmé";
                }

                allTickets.add(TicketModel(
                  id: int.tryParse(r['id'].toString()) ?? 0,
                  transactionId: "${r['reference']} (Retour)",
                  ticketNumber: "${r['reference']} (Retour)",
                  passengerName: passagerNom,
                  seatNumber: seatRetour ?? "??",
                  returnSeatNumber: null,
                  departureCity: arriveCity,
                  arrivalCity: departCity,
                  companyName: companyName,
                  departureTimeRaw: "12:00",
                  date: dateRetour,
                  status: statusRetour,
                  pdfBase64: null,
                  qrCodeUrl: qrCodeUrl,
                  price: cleanPrice,
                  isAllerRetour: true,
                  isReturnLeg: true,
                  returnDate: dateRetour,
                ));
              }

            } catch (e) {
              debugPrint("⚠️ [PARSING ERROR] Erreur index $i: $e");
              continue;
            }
          }
        }
      }
      return allTickets;

    } on DioException catch (e) {
      debugPrint("🔴 [DIO ERROR] : ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("🔴 [UNKNOWN ERROR] : $e");
      rethrow;
    }
  }


// ---------------------------------------------------------------------------
  // 5. MODIFICATION (Adapté pour DIO)
  // ---------------------------------------------------------------------------
  @override
  Future<Map<String, dynamic>> modifyTicket(String ticketId, Map<String, dynamic> newTicketData) async {
    // 1. Nettoyage de l'ID (ex: "15_aller" devient "15")
    String cleanId = ticketId.contains('_') ? ticketId.split('_')[0] : ticketId;

    // 2. Construction du chemin URL
    // Vérifie avec ton Backend si c'est PUT ou POST. Souvent 'modify' est un PUT.
    final String path = '/user/reservations/$cleanId/modify';

    debugPrint("🚀 [API START] Modification du ticket ID: $cleanId");
    debugPrint("🔗 [API URL] : ${dio.options.baseUrl}$path");
    debugPrint("📦 [API SEND DATA] : $newTicketData");

    try {
      // 3. Appel API via DIO
      // Note: Pas besoin de jsonEncode, Dio gère la Map dans 'data'
      // Note: Pas besoin de header Authorization manuel si ton instance 'dio' a déjà un Interceptor (ce qui est le standard).
      // Si tu n'as pas d'interceptor, ajoute options: Options(headers: {...})

      final response = await dio.put( // Ou dio.post selon ton API
        path,
        data: newTicketData,
        options: Options(
          contentType: Headers.jsonContentType, // Force le header application/json
          validateStatus: (status) => status! < 500, // On gère nous-même les 400
        ),
      );

      debugPrint("✅ [API RESPONSE STATUS] : ${response.statusCode}");
      debugPrint("📄 [API RESPONSE BODY] : ${response.data}");

      // 4. Gestion de la réponse
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Succès
        return {
          'success': true,
          'message': response.data['message'] ?? 'Modification effectuée avec succès',
          'data': response.data
        };
      } else {
        // Erreur métier (ex: plus de place, erreur validation)
        debugPrint("⚠️ [API LOGIC ERROR] : ${response.data}");
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la modification',
          'errors': response.data['errors'] // Si Laravel renvoie des erreurs de validation
        };
      }

    } on DioException catch (e) {
      // 5. Erreurs techniques (Réseau, Timeout, 500, 404)
      debugPrint("🔴 [DIO ERROR] Type: ${e.type}");
      debugPrint("🔴 [DIO ERROR] Message: ${e.message}");
      debugPrint("🔴 [SERVER DATA] : ${e.response?.data}");

      String errorMsg = "Erreur de connexion serveur";

      if (e.response != null) {
        // Si le serveur a répondu quelque chose (ex: 404, 422)
        if (e.response?.data is Map && e.response?.data['message'] != null) {
          errorMsg = e.response?.data['message'];
        } else {
          errorMsg = "Erreur ${e.response?.statusCode}";
        }
      }

      return {
        'success': false,
        'message': errorMsg
      };
    } catch (e, stack) {
      // 6. Autres erreurs (Parsing, Code Dart)
      debugPrint("🔴 [UNKNOWN ERROR] modifyTicket: $e");
      debugPrint("StackTrace: $stack");
      return {
        'success': false,
        'message': "Une erreur inattendue est survenue: $e"
      };
    }
  }




  // ---------------------------------------------------------------------------
  // 2. ANNULATION
  // ---------------------------------------------------------------------------

  @override
  Future<Map<String, dynamic>> cancelTicket(String ticketId) async {
    try {
      // 1. Nettoyage de l'ID (On garde la logique pour enlever "_aller" si présent)
      String cleanId = ticketId.contains('_') ? ticketId.split('_')[0] : ticketId;
      int dbId = int.parse(cleanId);

      // LOG: Vérifie ici si ça affiche 2 ou 74. Si ça affiche 2, le problème vient du Model !
      debugPrint("🔵 [API] Annulation ID : $dbId (Brut: $ticketId)");

      // 2. URL : /user/reservations/{id}
      // ATTENTION : Si l'URL n'a pas de verbe (/cancel), on utilise souvent DELETE
      final String path = '/user/reservations/$dbId';

      debugPrint("👉 URL Appellée : ${dio.options.baseUrl}$path");

      // 3. Appel avec DELETE (Standard pour supprimer/annuler une ressource sur son ID)
      final response = await dio.delete(path);

      debugPrint("🟢 [API] Réponse : ${response.statusCode}");

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          "success": true,
          "message": response.data['message'] ?? "Annulation réussie.",
          "refund_amount": response.data['refund_amount'] ?? 0
        };
      } else {
        throw Exception("Statut invalide : ${response.statusCode}");
      }
    } on DioException catch (e) {
      debugPrint("🔴 [API ERROR] : ${e.response?.statusCode} - ${e.response?.data}");

      // Gestion spécifique 404
      if (e.response?.statusCode == 404) {
        return {
          "success": false,
          "message": "Erreur 404: L'ID $ticketId n'existe pas sur le serveur. (Vérifiez si l'app envoie l'ID local au lieu de l'ID serveur)",
          "refund_amount": 0
        };
      }

      return {
        "success": false,
        "message": e.response?.data['message'] ?? "Erreur lors de l'annulation",
        "refund_amount": 0
      };
    } catch (e) {
      return {"success": false, "message": "Erreur : $e", "refund_amount": 0};
    }
  }


  /*@override
  Future<TicketModel> getTicketDetails(String ticketId) async {
    debugPrint("\n🔵🔵🔵 [START DEBUG] getTicketDetails pour ID BRUT: $ticketId 🔵🔵🔵");

    try {
      String cleanId = ticketId.contains('_') ? ticketId.split('_')[0] : ticketId;
      debugPrint("🧹 Clean ID utilisé: $cleanId");

      // -----------------------------------------------------------
      // 1. TENTATIVE ENDPOINT SPÉCIAL (round-trip-tickets)
      // -----------------------------------------------------------
      try {
        debugPrint("📡 [API TRY 1] Appel de: /user/reservations/$cleanId/round-trip-tickets");

        final responseAR = await dio.get('/user/reservations/$cleanId/round-trip-tickets');

        debugPrint("📥 [API 1 RESPONSE] Code: ${responseAR.statusCode}");
        // debugPrint("📦 [API 1 DATA] : ${responseAR.data}");

        /*if (responseAR.data['success'] == true && responseAR.data['is_aller_retour'] == true) {
          debugPrint("✅ [LOGIC] Détecté comme AR via endpoint spécial. Utilisation de fromRoundTripJson.");
          return TicketModel.fromRoundTripJson(responseAR.data);
        } else {
          debugPrint("⚠️ [LOGIC] Endpoint spécial OK, mais success=false ou is_aller_retour=false.");
        }
      } catch (e) {
        debugPrint("❌ [API 1 ERROR] Échec de l'appel spécial AR (C'est peut-être normal) : $e");
      }*/

        if (responseAR.data['success'] == true && responseAR.data['is_aller_retour'] == true) {
          debugPrint("✅ [LOGIC] Détecté comme AR via endpoint spécial. Utilisation de fromRoundTripJson.");

          // 🟢 C'EST ICI QUE LA MAGIE OPÈRE : On passe le targetId !
          return TicketModel.fromRoundTripJson(
            responseAR.data, // On passe les données brutes
            targetId: int.tryParse(ticketId), // On donne l'ID exact sur lequel on a cliqué
          );
        } else {
          debugPrint("⚠️ [LOGIC] Endpoint spécial OK, mais success=false ou is_aller_retour=false.");
        }
      } catch (e) {
        debugPrint("❌ [API 1 ERROR] Échec de l'appel spécial AR (C'est peut-être normal) : $e");
      }

      // -----------------------------------------------------------
      // 2. TENTATIVE ENDPOINT STANDARD (reservations/ID)
      // -----------------------------------------------------------
      debugPrint("📡 [API TRY 2] Appel de fallback: /user/reservations/$cleanId");

      final response = await dio.get('/user/reservations/$cleanId');
      final dynamic root = response.data;

      debugPrint("📦 [API 2 DATA RAW] : $root");

      final Map<String, dynamic> r = (root is Map && root.containsKey('data')) ? root['data'] : root;

      final Map<String, dynamic> programme = r['programme'] ?? {};
      final Map<String, dynamic> compagnie = programme['compagnie'] ?? {};

      // --- ANALYSE DES CHAMPS ---
      debugPrint("🧐 [ANALYSE CHAMPS] is_aller_retour: ${r['is_aller_retour']} (Type: ${r['is_aller_retour'].runtimeType})");
      debugPrint("🧐 [ANALYSE CHAMPS] date_retour: ${r['date_retour']}");
      debugPrint("🧐 [ANALYSE CHAMPS] seat_number: ${r['seat_number']}");

      // --- 🟢 LOGIQUE CORRIGÉE : DETECTION BOOLEEN ---
      // On accepte true, 1 ou "1"
      bool isAR = r['is_aller_retour'] == true ||
          r['is_aller_retour'] == 1 ||
          r['is_aller_retour'].toString() == "1";

      debugPrint("🛠️ [FIX LOGIC] isAR calculé: $isAR");

      String heureDepart = programme['heure_depart'] ?? "00:00";
      if (heureDepart.length > 5) heureDepart = heureDepart.substring(0, 5);

      // ===========================================================
      // 🟠 DEBUT LOGIQUE STATUT (DEBUG & FIX)
      // ===========================================================
      debugPrint("\n🕵️♂️ [STATUS DEBUG] Analyse des statuts reçus :");

      String rawStatut = r['statut']?.toString() ?? "NULL";
      String displayStatut = r['display_statut']?.toString() ?? "NULL";
      String voyageStatut = r['voyage_statut']?.toString() ?? "NULL";

      debugPrint("   👉 JSON 'statut' (Transaction ?) : $rawStatut");
      debugPrint("   👉 JSON 'display_statut' (Backend Pref) : $displayStatut");
      debugPrint("   👉 JSON 'voyage_statut' : $voyageStatut");

      // 1. CHOIX DE LA SOURCE
      // Si display_statut existe, on l'utilise en priorité absolu
      String finalStatus;
      bool statusIsFromBackend = false;

      if (r['display_statut'] != null && r['display_statut'].toString().isNotEmpty) {
        finalStatus = r['display_statut'];
        statusIsFromBackend = true; // On marque que c'est le backend qui décide
        debugPrint("✅ Choix : Utilisation de 'display_statut' ($finalStatus)");
      } else {
        finalStatus = r['statut'] ?? "En attente";
        debugPrint("⚠️ Fallback : Utilisation de 'statut' ($finalStatus) car display_statut absent");
      }

      DateTime dateVoyage = DateTime.tryParse(r['date_voyage'] ?? "") ?? DateTime.now();
      DateTime now = DateTime.now();

      // Calcul expiration précise
      DateTime exactDeparture = dateVoyage;
      try {
        var parts = heureDepart.split(':');
        exactDeparture = dateVoyage.add(Duration(hours: int.parse(parts[0]), minutes: int.parse(parts[1])));
      } catch(e) {
        exactDeparture = dateVoyage.add(const Duration(hours: 23, minutes: 59));
      }

      debugPrint("🕒 [TIME CHECK] Départ exact: $exactDeparture | Maintenant: $now");

      // 2. LOGIQUE LOCALE (Seulement si nécessaire ou pour formater)
      // On ne surcharge pas si le backend nous dit explicitement "en_voyage" ou "scanned"
      if (statusIsFromBackend) {
        // Juste un formatage cosmétique si besoin (enlever les underscore)
        finalStatus = finalStatus.replaceAll('_', ' ');
        // Capitalize first letter
        if (finalStatus.isNotEmpty) {
          finalStatus = "${finalStatus[0].toUpperCase()}${finalStatus.substring(1)}";
        }
        debugPrint("🛑 [LOGIC] Statut final dicté par Backend : $finalStatus");
      }
      else {
        // ANCIENNE LOGIQUE (Fallback si le backend n'envoie pas display_statut)
        debugPrint("⚙️ [LOGIC] Application de la logique locale (Date/Heure)...");

        if (now.isAfter(exactDeparture) && !finalStatus.toLowerCase().contains("annul")) {
          finalStatus = "Terminé";
          debugPrint("   -> Passé en 'Terminé' (Date dépassée)");
        } else if (['payé', 'validé', 'terminee'].contains(finalStatus.toLowerCase())) {
          // Attention : 'terminee' dans 'statut' veut souvent dire 'paiement terminé' et non 'voyage terminé'
          finalStatus = "Confirmé";
          debugPrint("   -> Passé en 'Confirmé' (Basé sur statut transaction)");
        }
      }

      debugPrint("🏁 [STATUS RESULT] Statut final affiché : $finalStatus\n");
      // --- 🟢 LOGIQUE CORRIGÉE : GESTION DATE RETOUR MANQUANTE ---
      DateTime? dateRetour;

      // 1. On essaie de lire la vraie date retour
      if (r['date_retour'] != null) {
        dateRetour = DateTime.tryParse(r['date_retour']);
      }
      // 2. SI c'est null MAIS que c'est déclaré comme Aller-Retour
      else if (isAR) {
        debugPrint("⚠️ [FIX LOGIC] C'est un aller-retour mais date_retour est NULL.");

        // 🚑 SAUVETAGE : On utilise la date de voyage principale.
        // Vu que ton log montre "reference: ...-RET-5", ce ticket EST probablement le retour.
        // Donc date_voyage (21/02) est la bonne date pour le retour.
        dateRetour = dateVoyage;
      }

      debugPrint("✅ [FIN DEBUG] Création du TicketModel standard et retour.");

      return TicketModel(
        // 🟢 1. Conversion ID
        id: int.tryParse(ticketId.toString()) ?? 0,

        // 🟢 2. Référence
        transactionId: r['reference'] ?? "",

        ticketNumber: "${r['reference']}",
        passengerName: "${r['passager_prenom']} ${r['passager_nom']}",

        seatNumber: r['seat_number'].toString(),
        // Mapping intelligent du siège retour
        returnSeatNumber: r['return_seat_number']?.toString() ?? r['seat_number_return']?.toString(),

        departureCity: r['point_depart'] ?? "Départ",
        arrivalCity: r['point_arrive'] ?? "Arrivée",
        companyName: compagnie['name'] ?? "Compagnie",

        departureTimeRaw: heureDepart,
        // Mapping intelligent heure retour
        returnTimeRaw: r['heure_arrive'] ?? "--:--",

        date: dateVoyage,

        // 🟢 La date retour traitée
        returnDate: dateRetour,

        status: finalStatus,
        qrCodeUrl: r['qr_code'],
        price: r['montant']?.toString() ?? "0",

        // 🟢 Le booléen corrigé
        isAllerRetour: isAR,
      );

    } catch (e) {
      debugPrint("🔴🔴🔴 [CRASH] Erreur dans getTicketDetails : $e");
      rethrow;
    }
  }*/

  @override
  Future<TicketModel> getTicketDetails(String ticketId) async {
    debugPrint("\n🔵🔵🔵 [START DEBUG] getTicketDetails pour ID BRUT: $ticketId 🔵🔵🔵");

    try {
      String cleanId = ticketId.contains('_') ? ticketId.split('_')[0] : ticketId;
      debugPrint("🧹 Clean ID utilisé: $cleanId");

      // -----------------------------------------------------------
      // 1. TENTATIVE ENDPOINT SPÉCIAL (round-trip-tickets)
      // -----------------------------------------------------------
      try {
        debugPrint("📡 [API TRY 1] Appel de: /user/reservations/$cleanId/round-trip-tickets");

        final responseAR = await dio.get('/user/reservations/$cleanId/round-trip-tickets');

        debugPrint("📥 [API 1 RESPONSE] Code: ${responseAR.statusCode}");

        if (responseAR.data['success'] == true && responseAR.data['is_aller_retour'] == true) {
          debugPrint("✅ [LOGIC] Détecté comme AR via endpoint spécial. Utilisation de fromRoundTripJson.");

          // 🟢 C'EST ICI QUE LA MAGIE OPÈRE : On passe le targetId !
          return TicketModel.fromRoundTripJson(
            responseAR.data, // On passe les données brutes
            targetId: int.tryParse(ticketId), // On donne l'ID exact sur lequel on a cliqué
          );
        } else {
          debugPrint("⚠️ [LOGIC] Endpoint spécial OK, mais success=false ou is_aller_retour=false.");
        }
      } catch (e) {
        debugPrint("❌ [API 1 ERROR] Échec de l'appel spécial AR (C'est peut-être normal) : $e");
      }

      // -----------------------------------------------------------
      // 2. TENTATIVE ENDPOINT STANDARD (reservations/ID)
      // -----------------------------------------------------------
      debugPrint("📡 [API TRY 2] Appel de fallback: /user/reservations/$cleanId");

      final response = await dio.get('/user/reservations/$cleanId');
      final dynamic root = response.data;

      debugPrint("📦 [API 2 DATA RAW] : $root");

      final Map<String, dynamic> r = (root is Map && root.containsKey('data')) ? root['data'] : root;

      final Map<String, dynamic> programme = r['programme'] ?? {};
      final Map<String, dynamic> compagnie = programme['compagnie'] ?? {};

      // --- ANALYSE DES CHAMPS ---
      bool isAR = r['is_aller_retour'] == true ||
          r['is_aller_retour'] == 1 ||
          r['is_aller_retour'].toString() == "1";

      debugPrint("🛠️ [FIX LOGIC] isAR calculé: $isAR");

      String heureDepart = programme['heure_depart'] ?? "00:00";
      if (heureDepart.length > 5) heureDepart = heureDepart.substring(0, 5);

      // ===========================================================
      // 🟠 DEBUT LOGIQUE STATUT (DEBUG & FIX)
      // ===========================================================
      String rawStatut = r['statut']?.toString() ?? "NULL";
      String displayStatut = r['display_statut']?.toString() ?? "NULL";
      String voyageStatut = r['voyage_statut']?.toString() ?? "NULL";

      String finalStatus;
      bool statusIsFromBackend = false;

      if (r['display_statut'] != null && r['display_statut'].toString().isNotEmpty) {
        finalStatus = r['display_statut'];
        statusIsFromBackend = true;
      } else {
        finalStatus = r['statut'] ?? "En attente";
      }

      DateTime dateVoyage = DateTime.tryParse(r['date_voyage'] ?? "") ?? DateTime.now();
      DateTime now = DateTime.now();
      DateTime exactDeparture = dateVoyage;

      try {
        var parts = heureDepart.split(':');
        exactDeparture = dateVoyage.add(Duration(hours: int.parse(parts[0]), minutes: int.parse(parts[1])));
      } catch(e) {
        exactDeparture = dateVoyage.add(const Duration(hours: 23, minutes: 59));
      }

      if (statusIsFromBackend) {
        finalStatus = finalStatus.replaceAll('_', ' ');
        if (finalStatus.isNotEmpty) {
          finalStatus = "${finalStatus[0].toUpperCase()}${finalStatus.substring(1)}";
        }
      } else {
        if (now.isAfter(exactDeparture) && !finalStatus.toLowerCase().contains("annul")) {
          finalStatus = "Terminé";
        } else if (['payé', 'validé', 'terminee'].contains(finalStatus.toLowerCase())) {
          finalStatus = "Confirmé";
        }
      }

      DateTime? dateRetour;
      if (r['date_retour'] != null) {
        dateRetour = DateTime.tryParse(r['date_retour']);
      } else if (isAR) {
        dateRetour = dateVoyage;
      }

      return TicketModel(
        id: int.tryParse(ticketId.toString()) ?? 0,
        transactionId: r['reference'] ?? "",
        ticketNumber: "${r['reference']}",
        passengerName: "${r['passager_prenom']} ${r['passager_nom']}",
        seatNumber: r['seat_number'].toString(),
        returnSeatNumber: r['return_seat_number']?.toString() ?? r['seat_number_return']?.toString(),
        departureCity: r['point_depart'] ?? "Départ",
        arrivalCity: r['point_arrive'] ?? "Arrivée",
        companyName: compagnie['name'] ?? "Compagnie",
        departureTimeRaw: heureDepart,
        returnTimeRaw: r['heure_arrive'] ?? "--:--",
        date: dateVoyage,
        returnDate: dateRetour,
        status: finalStatus,
        qrCodeUrl: r['qr_code'],
        price: r['montant']?.toString() ?? "0",
        isAllerRetour: isAR,
      );

    } catch (e) {
      debugPrint("🔴🔴🔴 [CRASH] Erreur dans getTicketDetails : $e");
      rethrow;
    }
  }



  // ---------------------------------------------------------------------------
  // 4. TÉLÉCHARGEMENT IMAGE (QR)
  // ---------------------------------------------------------------------------
  @override
  Future<String> downloadTicketImage(String ticketId) async {
    try {
      String cleanId = ticketId.contains('_') ? ticketId.split('_')[0] : ticketId;
      final directory = await getApplicationDocumentsDirectory();
      // On nettoie le nom de fichier pour éviter les erreurs de caractères spéciaux
      final fileName = "ticket_$cleanId.png";
      final filePath = '${directory.path}/$fileName';

      // On utilise Dio download ou get bytes
      final response = await dio.get(
        '/user/reservations/$cleanId/download',
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: false,
          validateStatus: (status) => status! < 500,
        ),
      );

      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.data);
        return filePath;
      } else {
        throw Exception("Erreur serveur lors du téléchargement");
      }
    } catch (e) {
      rethrow;
    }
  }
}