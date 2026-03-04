import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import '../../data/models/active_reservation_model.dart';
import '../../data/models/live_trip_location.dart';

class AlertRepository {
  final Dio _dio;

  AlertRepository({required Dio dio}) : _dio = dio;

  // Récupérer les réservations
  /*Future<List<ActiveReservationModel>> getActiveReservations() async {
    try {
      final response = await _dio.get('/user/signalements/active-reservations');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['reservations'];
        return data.map((json) => ActiveReservationModel.fromJson(json)).toList();
      } else {
        throw Exception("Erreur lors de la récupération des réservations");
      }
    } catch (e) {
      rethrow;
    }
  }*/

  // Récupérer les réservations
  Future<List<ActiveReservationModel>> getActiveReservations() async {
    try {
      debugPrint("📡 [API] Appel : /user/signalements/active-reservations");

      final response = await _dio.get('/user/signalements/active-reservations');

      debugPrint("📥 [API] StatusCode : ${response.statusCode}");
      debugPrint("📥 [API] Réponse brute : ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['reservations'];

        debugPrint("📦 [API] Nombre total de réservations reçues : ${data.length}");

        for (int i = 0; i < data.length; i++) {
          final json = data[i];

          debugPrint("──────── RÉSERVATION #$i ────────");
          debugPrint("🆔 ID réservation : ${json['id']}");
          debugPrint("📌 Référence : ${json['reference']}");
          debugPrint("📅 Date voyage : ${json['date_voyage']}");
          debugPrint("🚦 Statut brut : ${json['display_statut'] ?? json['statut']}");
          debugPrint("🚌 Programme ID : ${json['programme']?['id']}");
          debugPrint("🚍 Vehicule ID : ${json['programme']?['vehicule']?['id']}");
          debugPrint("───────────────────────────────");
        }

        final reservations =
        data.map((json) => ActiveReservationModel.fromJson(json)).toList();

        debugPrint("✅ [API] Mapping terminé avec succès");

        return reservations;
      } else {
        debugPrint("❌ [API] Réponse invalide ou success=false");
        throw Exception("Erreur lors de la récupération des réservations");
      }
    } catch (e) {
      debugPrint("❌ [API] Erreur attrapée dans getActiveReservations : $e");
      rethrow;
    }
  }

  // ✅ CORRECTION ICI : "File? photo" (plus de 'required', et nullable)
  Future<void> createSignalement({
    required int programmeId,
    int? vehiculeId,
    required String type,
    required String description,
    required double latitude,
    required double longitude,
    File? photo, // <-- Peut être null maintenant
  }) async {
    print("🚀 --- DÉBUT ENVOI SIGNALEMENT ---");
    print("📝 Données : ProgID=$programmeId, VehiculeID=$vehiculeId, Type=$type");

    // On sécurise le print de la photo pour ne pas faire planter si null
    if (photo != null) {
      print("📸 Fichier : ${photo.path} (Taille: ${await photo.length()} octets)");
    } else {
      print("📸 Fichier : Aucune photo (Optionnel)");
    }

    try {
      // 1. On prépare d'abord les données texte de base dans une Map
      Map<String, dynamic> mapData = {
        "programme_id": programmeId,
        "vehicule_id": vehiculeId,
        "type": type,
        "description": description,
        "latitude": latitude,
        "longitude": longitude,
      };

      if (vehiculeId != null && vehiculeId > 0) {
        mapData["vehicule_id"] = vehiculeId;
      }

      // 2. On ajoute la photo SEULEMENT si elle n'est pas null
      if (photo != null) {
        mapData["photo"] = await MultipartFile.fromFile(
            photo.path,
            filename: "signalement.jpg"
        );
      }

      // 3. On crée le FormData à partir de la Map dynamique
      FormData formData = FormData.fromMap(mapData);

      // Appel API
      final response = await _dio.post(
        '/user/signalements',
        data: formData,
        options: Options(
            validateStatus: (status) {
              return status! < 500;
            }
        ),
      );

      print("📥 Réponse Code : ${response.statusCode}");
      print("📥 Réponse Data : ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['success'] == true) {
          print("✅ Signalement créé avec succès !");
          return;
        } else {
          throw Exception(response.data['message'] ?? "Erreur API (success false)");
        }
      } else {
        String errorMsg = "Erreur serveur (${response.statusCode})";
        if (response.data is Map && response.data.containsKey('message')) {
          errorMsg = response.data['message'];
        }
        throw Exception(errorMsg);
      }
    } catch (e) {
      print("❌ ERREUR CRITIQUE DANS REPO : $e");
      rethrow;
    }
  }


  // 🔹 Nouvelle fonction pour récupérer la localisation du trip live
  Future<LiveTripLocation> getLiveTripLocation() async {
    try {
      debugPrint("📡 [API] Appel : /user/tracking/location");
      final response = await _dio.get('/user/tracking/location');

      debugPrint("📥 [API] StatusCode : ${response.statusCode}");
      debugPrint("📥 [API] Réponse brute : ${response.data}");

      if (response.statusCode == 200 && response.data['success'] == true) {
        return LiveTripLocation.fromJson(response.data);
      } else {
        throw Exception(
          "Erreur API : response non valide ou success=false",
        );
      }
    } catch (e) {
      debugPrint("❌ [API] Erreur dans getLiveTripLocation : $e");
      rethrow;
    }
  }

}