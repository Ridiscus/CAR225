/*import 'dart:io';
import 'package:dio/dio.dart';
import '../../data/models/active_reservation_model.dart';

class AlertRepository {
  final Dio _dio;

  AlertRepository({required Dio dio}) : _dio = dio;

  // Récupérer les réservations (Ton code existant)
  Future<List<ActiveReservationModel>> getActiveReservations() async {
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
  }



  // Dans alert_repository.dart

  Future<void> createSignalement({
    required int programmeId,
    required int vehiculeId,
    required String type,
    required String description,
    required double latitude,
    required double longitude,
    required File photo,
  }) async {
    print("🚀 --- DÉBUT ENVOI SIGNALEMENT ---");
    print("📝 Données : ProgID=$programmeId, VehiculeID=$vehiculeId, Type=$type");
    print("📍 Position : $latitude, $longitude");
    print("📸 Fichier : ${photo.path} (Taille: ${await photo.length()} octets)");

    try {
      // Préparation des données
      FormData formData = FormData.fromMap({
        "programme_id": programmeId,
        "vehicule_id": vehiculeId,
        "type": type,
        "description": description,
        "latitude": latitude,
        "longitude": longitude,
        "photo": await MultipartFile.fromFile(photo.path, filename: "signalement.jpg"),
      });

      // Appel API
      final response = await _dio.post(
        '/user/signalements',
        data: formData,
        options: Options(
          // On demande à Dio de ne pas lancer d'exception pour les codes < 500
          // afin de pouvoir lire le message d'erreur du serveur proprement
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
        // Gestion des erreurs de validation (ex: 422)
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


}*/






import 'dart:io';
import 'package:dio/dio.dart';
import '../../data/models/active_reservation_model.dart';

class AlertRepository {
  final Dio _dio;

  AlertRepository({required Dio dio}) : _dio = dio;

  // Récupérer les réservations
  Future<List<ActiveReservationModel>> getActiveReservations() async {
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
  }

  // ✅ CORRECTION ICI : "File? photo" (plus de 'required', et nullable)
  Future<void> createSignalement({
    required int programmeId,
    required int vehiculeId,
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
}