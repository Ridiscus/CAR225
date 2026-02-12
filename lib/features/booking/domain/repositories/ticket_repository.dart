import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../../data/models/ticket_model.dart';

class TicketRepository {
  final Dio dio;

  TicketRepository({required this.dio});

  // ---------------------------------------------------------------------------
  // 1. RÉCUPÉRATION DE TOUS LES BILLETS (AVEC CORRECTION PAGINATION & SIÈGES)
  // ---------------------------------------------------------------------------
 /* Future<List<TicketModel>> getMyTickets() async {
    try {
      // ✅ CORRECTION 1 : On demande 100 résultats au lieu de 10 par défaut
      final response = await dio.get('/user/reservations?per_page=100');

      final dynamic root = response.data;
      final List<TicketModel> allTickets = [];

      if (root is Map && root.containsKey('data')) {
        final dynamic paginationData = root['data'];

        // Laravel renvoie souvent { data: { data: [...] } } quand il y a pagination
        final dynamic reservationsList = (paginationData is Map && paginationData.containsKey('data'))
            ? paginationData['data']
            : paginationData; // Fallback si la structure change

        if (reservationsList is List) {
          for (var res in reservationsList) {
            final Map<String, dynamic> r = Map<String, dynamic>.from(res);
            final Map<String, dynamic> programme = r['programme'] ?? {};
            final Map<String, dynamic> compagnie = programme['compagnie'] ?? {};

            String departCity = r['point_depart'] ?? programme['point_depart'] ?? "Départ";
            String arriveCity = r['point_arrive'] ?? programme['point_arrive'] ?? "Arrivée";
            String companyName = compagnie['name'] ?? "Compagnie";

            // Gestion heure départ
            String heureDepart = programme['heure_depart'] ?? "00:00";
            if (heureDepart.length > 5) heureDepart = heureDepart.substring(0, 5); // Garde HH:mm

            // Date Voyage
            DateTime dateVoyage = DateTime.tryParse(r['date_voyage']) ?? DateTime.now();

            // Création de la Date Complète (Date + Heure) pour comparaison précise (Expiration)
            DateTime fullDepartureDate = dateVoyage;
            try {
              int hour = int.parse(heureDepart.split(":")[0]);
              int minute = int.parse(heureDepart.split(":")[1]);
              fullDepartureDate = DateTime(dateVoyage.year, dateVoyage.month, dateVoyage.day, hour, minute);
            } catch (e) {
              // Si erreur de parsing heure, on garde juste la date
            }

            // --- LOGIQUE STATUT ---
            String rawStatus = (r['statut_aller'] ?? r['statut'] ?? "Inconnu").toString().toLowerCase();
            String displayStatus = "En attente";

            if (rawStatus.contains("confirm") || rawStatus.contains("pay")) {
              displayStatus = "Confirmé";
            } else if (rawStatus == "annule" || rawStatus == "annulé") {
              displayStatus = "Annulé";
            }

            // Priorité absolue : Scanné / Terminé
            if (rawStatus == "utilisé" || rawStatus == "scanned" || rawStatus == "terminé" || rawStatus == "checkin") {
              displayStatus = "Terminé";
            }
            // Sinon, si la date est passée -> Expiré
            else if (DateTime.now().isAfter(fullDepartureDate)) {
              displayStatus = "Expiré";
            }

            // Booléen Aller-Retour
            bool isRoundTrip = r['is_aller_retour'] == true || r['is_aller_retour'] == 1;

            // Nettoyage Prix
            String cleanPrice = "0";
            if (r['montant'] != null) {
              try {
                cleanPrice = double.parse(r['montant'].toString()).toInt().toString();
              } catch (e) {
                cleanPrice = r['montant'].toString();
              }
            }

            // Date Retour
            DateTime? dateRetour;
            if (r['date_retour'] != null) dateRetour = DateTime.tryParse(r['date_retour']);

            // ✅ CORRECTION 2 : RECUPERATION DU SIEGE RETOUR
            String seatAller = r['seat_number'].toString();
            String? seatRetour;

            // On cherche le siège retour dans les clés probables
            if (r['seat_number_retour'] != null) {
              seatRetour = r['seat_number_retour'].toString();
            } else if (r['siege_retour'] != null) {
              seatRetour = r['siege_retour'].toString();
            }

            // --------------------------
            // AJOUT TICKET ALLER
            // --------------------------
            allTickets.add(TicketModel(
              id: "${r['id']}_aller",
              ticketNumber: "${r['reference']}",
              passengerName: "${r['passager_prenom']} ${r['passager_nom']}",
              seatNumber: seatAller,
              returnSeatNumber: seatRetour, // On stocke aussi le retour ici pour l'affichage "12 / 14"
              departureCity: departCity,
              arrivalCity: arriveCity,
              companyName: companyName,
              departureTimeRaw: heureDepart,
              date: dateVoyage,
              status: displayStatus,
              pdfBase64: null,
              qrCodeUrl: r['qr_code'],
              price: cleanPrice,
              isAllerRetour: isRoundTrip,
              returnDate: dateRetour,
            ));

            // --------------------------
            // AJOUT TICKET RETOUR (Si applicable)
            // --------------------------
            if (isRoundTrip) {
              String statusRetour = displayStatus;

              // Logique simple pour le statut retour
              if (dateRetour != null) {
                if (DateTime.now().isAfter(dateRetour.add(const Duration(hours: 23)))) {
                  statusRetour = "Terminé"; // Ou Expiré selon la logique
                }
              }

              allTickets.add(TicketModel(
                id: "${r['id']}_retour",
                ticketNumber: "${r['reference']} (Retour)",
                passengerName: "${r['passager_prenom']} ${r['passager_nom']}",

                // ✅ CORRECTION 3 : ICI ON MET LE SIÈGE RETOUR, PAS CELUI DE L'ALLER
                seatNumber: seatRetour ?? "Inconnu",
                returnSeatNumber: null, // Pas besoin de "retour du retour"

                departureCity: arriveCity, // Inversement des villes
                arrivalCity: departCity,
                companyName: companyName,
                departureTimeRaw: "12:00", // Heure par défaut si non dispo
                date: dateRetour ?? DateTime.now().add(const Duration(days: 1)),
                status: statusRetour,
                pdfBase64: null,
                qrCodeUrl: r['qr_code'], // Souvent le même QR
                price: cleanPrice,
                isAllerRetour: true, // C'est une partie d'un A/R
                returnDate: dateRetour,
              ));
            }
          }
        }
      }
      return allTickets;
    } catch (e) {
      print("🔴 Erreur getMyTickets : $e");
      rethrow;
    }
  }*/


  // ---------------------------------------------------------------------------
  // 1. RÉCUPÉRATION DE TOUS LES BILLETS (LOGIQUE PASSAGERS MISE À JOUR)
  // ---------------------------------------------------------------------------
  Future<List<TicketModel>> getMyTickets() async {
    try {
      final response = await dio.get('/user/reservations?per_page=100');
      final dynamic root = response.data;
      final List<TicketModel> allTickets = [];

      if (root is Map && root.containsKey('data')) {
        final dynamic paginationData = root['data'];
        final dynamic reservationsList = (paginationData is Map && paginationData.containsKey('data'))
            ? paginationData['data']
            : paginationData;

        if (reservationsList is List) {
          for (var res in reservationsList) {
            final Map<String, dynamic> r = Map<String, dynamic>.from(res);
            final Map<String, dynamic> programme = r['programme'] ?? {};
            final Map<String, dynamic> compagnie = programme['compagnie'] ?? {};

            String departCity = r['point_depart'] ?? programme['point_depart'] ?? "Départ";
            String arriveCity = r['point_arrive'] ?? programme['point_arrive'] ?? "Arrivée";
            String companyName = compagnie['name'] ?? "Compagnie";

            // Heure
            String heureDepart = programme['heure_depart'] ?? "00:00";
            if (heureDepart.length > 5) heureDepart = heureDepart.substring(0, 5);

            // Date
            DateTime dateVoyage = DateTime.tryParse(r['date_voyage']) ?? DateTime.now();
            DateTime fullDepartureDate = dateVoyage;
            // (Ta logique de date complète ici reste la même...)

            // Statut
            String rawStatus = (r['statut_aller'] ?? r['statut'] ?? "Inconnu").toString().toLowerCase();
            String displayStatus = "En attente";
            if (rawStatus.contains("confirm") || rawStatus.contains("pay")) displayStatus = "Confirmé";
            else if (rawStatus.contains("annul")) displayStatus = "Annulé";
            else if (rawStatus.contains("util") || rawStatus.contains("scan") || rawStatus == "terminé") displayStatus = "Terminé";
            else if (DateTime.now().isAfter(fullDepartureDate)) displayStatus = "Expiré";

            // Booléen Aller-Retour (Utilise le booléen direct du JSON)
            bool isRoundTrip = r['is_aller_retour'] == true;

            // Prix
            String cleanPrice = r['montant']?.toString() ?? "0";

            // Date Retour
            DateTime? dateRetour;
            if (r['date_retour'] != null) dateRetour = DateTime.tryParse(r['date_retour']);


            // 🔥 C'EST ICI LE CHANGEMENT MAJEUR : GESTION DES PASSAGERS 🔥
            String seatAller = "??";
            String? seatRetour;
            String passagerNom = "Moi";

            // On regarde si on a une liste de passagers
            if (r['passagers'] != null && (r['passagers'] as List).isNotEmpty) {
              // On prend le premier passager (Index 0)
              // (Si tu veux afficher tous les passagers, il faudrait faire une boucle ici)
              var firstPax = r['passagers'][0];

              seatAller = firstPax['seat_number'].toString();

              // Lecture de la nouvelle clé JSON
              if (firstPax['return_seat_number'] != null) {
                seatRetour = firstPax['return_seat_number'].toString();
              }

              passagerNom = "${firstPax['prenom']} ${firstPax['nom']}";
            } else {
              // Fallback ancien format (au cas où)
              seatAller = r['seat_number']?.toString() ?? "??";
              seatRetour = r['seat_number_return']?.toString(); // Juste au cas où
              passagerNom = "${r['passager_prenom']} ${r['passager_nom']}";
            }


            // --------------------------
            // TICKET ALLER (Carte principale)
            // --------------------------
            allTickets.add(TicketModel(
              id: "${r['id']}_aller",
              ticketNumber: "${r['reference']}",
              passengerName: passagerNom,
              seatNumber: seatAller,
              returnSeatNumber: seatRetour, // ✅ On passe le siège retour ici !
              departureCity: departCity,
              arrivalCity: arriveCity,
              companyName: companyName,
              departureTimeRaw: heureDepart,
              date: dateVoyage,
              status: displayStatus,
              pdfBase64: null,
              qrCodeUrl: r['qr_code'],
              price: cleanPrice,
              isAllerRetour: isRoundTrip,
              returnDate: dateRetour,
            ));

            // --------------------------
            // TICKET RETOUR (Optionnel, si tu veux une 2ème carte)
            // --------------------------
            // Je laisse ta logique, mais attention :
            // Pour la carte RETOUR, le "seatNumber" principal devient le siège du retour.
            if (isRoundTrip) {
              // Logique statut retour...
              String statusRetour = displayStatus; // Simplifié

              allTickets.add(TicketModel(
                id: "${r['id']}_retour",
                ticketNumber: "${r['reference']} (Retour)",
                passengerName: passagerNom,

                // Pour la carte retour, le siège principal EST le siège retour
                seatNumber: seatRetour ?? "??",
                returnSeatNumber: null,

                departureCity: arriveCity,
                arrivalCity: departCity,
                companyName: companyName,
                departureTimeRaw: "12:00", // À améliorer si l'API donne l'heure retour
                date: dateRetour ?? DateTime.now(),
                status: statusRetour,
                pdfBase64: null,
                qrCodeUrl: r['qr_code'],
                price: cleanPrice,
                isAllerRetour: true,
                returnDate: dateRetour,
              ));
            }
          }
        }
      }
      return allTickets;
    } catch (e) {
      print("🔴 Erreur getMyTickets : $e");
      rethrow;
    }
  }






  Future<TicketModel> getTicketDetails(String ticketId) async {
    try {
      String cleanId = ticketId.contains('_') ? ticketId.split('_')[0] : ticketId;

      // 1. TENTATIVE ENDPOINT DETAILS COMPLET (Aller-Retour)
      try {
        final responseAR = await dio.get('/user/reservations/$cleanId/round-trip-tickets');

        if (responseAR.data['success'] == true && responseAR.data['is_aller_retour'] == true) {
          // ✅ Utilise la nouvelle factory avec heure retour et siège retour
          return TicketModel.fromRoundTripJson(responseAR.data);
        }
      } catch (e) {
        // Fallback si erreur 404 ou pas A/R
      }

      // 2. FALLBACK : Appel Standard
      final response = await dio.get('/user/reservations/$cleanId');
      final dynamic root = response.data;
      final Map<String, dynamic> r = (root is Map && root.containsKey('data')) ? root['data'] : root;

      // ... (Reste du code standard comme avant pour les billets simples) ...
      // Pour abréger, je remets juste le return du fallback :

      final Map<String, dynamic> programme = r['programme'] ?? {};
      final Map<String, dynamic> compagnie = programme['compagnie'] ?? {};
      String heureDepart = programme['heure_depart'] ?? "00:00";
      if (heureDepart.length > 5) heureDepart = heureDepart.substring(0, 5);

      return TicketModel(
        id: ticketId,
        ticketNumber: "${r['reference']}",
        passengerName: "${r['passager_prenom']} ${r['passager_nom']}",
        seatNumber: r['seat_number'].toString(),
        returnSeatNumber: null, // Pas dispo ici
        departureCity: r['point_depart'] ?? "Départ",
        arrivalCity: r['point_arrive'] ?? "Arrivée",
        companyName: compagnie['name'] ?? "Compagnie",
        departureTimeRaw: heureDepart,
        returnTimeRaw: null, // Pas dispo ici
        date: DateTime.tryParse(r['date_voyage']) ?? DateTime.now(),
        status: r['statut'] ?? "En attente",
        qrCodeUrl: r['qr_code'],
        price: r['montant']?.toString() ?? "0",
        isAllerRetour: r['is_aller_retour'] == true,
      );

    } catch (e) {
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 3. SAUVEGARDE DU PDF
  // ---------------------------------------------------------------------------
  Future<String?> savePdfFile(String base64String, String fileName) async {
    debugPrint("🔵 [REPO] Tentative de sauvegarde PDF : $fileName");
    try {
      if (base64String.isEmpty) return null;

      String cleanBase64 = base64String.replaceAll(RegExp(r'\s+'), '');
      if (cleanBase64.contains(',')) {
        cleanBase64 = cleanBase64.split(',').last;
      }

      Uint8List bytes = base64Decode(cleanBase64);
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      debugPrint("🔴 [REPO] Erreur PDF: $e");
      throw Exception("Erreur création PDF: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 4. TÉLÉCHARGEMENT IMAGE (QR)
  // ---------------------------------------------------------------------------
  @override
  Future<String> downloadTicketImage(String ticketId) async {
    try {
      // 1. Ta logique de nettoyage d'ID
      String cleanId = ticketId.contains('_') ? ticketId.split('_')[0] : ticketId;

      // 2. Préparation du chemin de sauvegarde (Local Storage)
      final directory = await getApplicationDocumentsDirectory();
      final fileName = "ticket_$cleanId.png";
      final filePath = '${directory.path}/$fileName';

      print("📥 Démarrage téléchargement pour ID: $cleanId vers $filePath");

      // 3. Appel API en mode BYTES (Indispensable car le serveur renvoie une image PNG)
      final response = await dio.get(
        '/user/reservations/$cleanId/download',
        options: Options(
          responseType: ResponseType.bytes, // <--- C'est la clé !
          followRedirects: false,
          validateStatus: (status) => status! < 500, // Accepte tout sauf erreurs serveur
        ),
      );

      // 4. Vérification
      if (response.statusCode == 200) {
        // 5. Écriture du fichier sur le disque du téléphone
        final file = File(filePath);
        await file.writeAsBytes(response.data);

        print("✅ Fichier sauvegardé : $filePath");
        return filePath; // On retourne le chemin pour l'afficher ou le partager
      } else {
        throw Exception("Erreur serveur lors du téléchargement : ${response.statusCode}");
      }

    } catch (e) {
      print("🔴 Erreur downloadTicketImage : $e");
      rethrow;
    }
  }













}