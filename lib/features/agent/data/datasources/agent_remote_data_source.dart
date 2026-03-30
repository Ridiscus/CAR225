import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:car225/core/network/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/networking/api_config.dart';
import '../models/ticket_reservation_model.dart';
import '../models/programme_model.dart';

abstract class AgentRemoteDataSource {
  Future<Map<String, dynamic>> logout();
  Future<Map<String, dynamic>> getProfile();
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Map<String, dynamic>> getScanHistory({String? date});
  //Future<Map<String, dynamic>> getDashboardData();
  Future<TicketReservationModel> searchTicket(String qrCode);
  Future<TicketReservationModel> searchTicketByReference(String reference);
  Future<Map<String, dynamic>> confirmBoarding({
    required String reference,
    required int vehiculeId,
    required int programmeId,
  });
  Future<List<ProgrammeModel>> getTodayProgrammes();
}

class AgentRemoteDataSourceImpl implements AgentRemoteDataSource {
  late final Dio dio;

  // 🟢 1. Constructeur corrigé (plus de point-virgule parasite)
  /*AgentRemoteDataSourceImpl() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        //baseUrl: 'https://car225.com/api/',
        //baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
        /*headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },*/
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    // INTERCEPTOR : Injecte le token automatiquement
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print("🔑 [Interceptor] Token injecté");
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print("⛔ [Interceptor] Erreur 401: Non autorisé");
        }
        return handler.next(e);
      },
    ));
  }*/

  AgentRemoteDataSourceImpl() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          print("🔑 [Interceptor] Token injecté");
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        if (e.response?.statusCode == 401) {
          print("⛔ [Interceptor] Erreur 401: Non autorisé");
        }
        return handler.next(e);
      },
    ));
  }

  // 🟢 2. Méthode logout mise à jour pour utiliser DIO
  @override
  Future<Map<String, dynamic>> logout() async {
    try {
      // 3. On utilise dio.post (l'URL de base et le token sont déjà gérés par Dio !)
      final response = await dio.post('agent/logout');

      if (response.statusCode == 200) {
        // Dio décode automatiquement le JSON, pas besoin de json.decode()
        return response.data;
      } else {
        throw Exception('Erreur lors de la déconnexion');
      }
    } on DioException catch (e) {
      // Gestion des erreurs spécifiques à Dio
      throw Exception(e.response?.data['message'] ?? 'Erreur réseau lors de la déconnexion');
    }
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    try {
      // Dio gère déjà le Token et la BaseUrl !
      final response = await dio.get('agent/profile');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erreur lors de la récupération du profil');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur réseau');
    }
  }
// 🟢 4. Méthode changePassword (totalement adaptée à Dio avec Logs !)
  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    print('====== 🚀 DÉBUT DE LA REQUÊTE CHANGE PASSWORD ======');

    final Map<String, dynamic> requestData = {
      "current_password": currentPassword,
      "password": newPassword,
      "password_confirmation": confirmPassword,
    };

    print('👉 Payload envoyé : $requestData');

    try {
      final response = await dio.post(
        'agent/change-password',
        data: requestData,
      );

      print('✅ [SUCCÈS HTTP] Code : ${response.statusCode}');
      print('✅ [SUCCÈS HTTP] Data : ${response.data}');
      print('====================================================');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'message': 'Mot de passe modifié avec succès'};
      } else {
        return {
          'success': false,
          'message': response.data['message'] ?? 'Erreur lors de la modification'
        };
      }
    } on DioException catch (e) {
      print('⛔ [ERREUR DIO] Type : ${e.type}');
      print('⛔ [ERREUR DIO] Message interne : ${e.message}');
      print('⛔ [ERREUR DIO] Status Code : ${e.response?.statusCode}');
      print('⛔ [ERREUR DIO] Response Data brut : ${e.response?.data}'); // C'est ici qu'on verra la vraie réponse !
      print('====================================================');

      String errorMessage = 'Erreur réseau ou mot de passe actuel incorrect.';

      // 🛠️ EXTRACTION INTELLIGENTE DU MESSAGE (Spécial Laravel)
      if (e.response?.data != null && e.response?.data is Map) {
        final errorData = e.response?.data;

        // 1. Si Laravel renvoie les erreurs de validation dans "errors" (ex: 422 Unprocessable Entity)
        if (errorData.containsKey('errors')) {
          // On convertit l'objet des erreurs en string pour le debug
          errorMessage = errorData['errors'].toString();
        }
        // 2. S'il y a juste un champ "message"
        else if (errorData.containsKey('message')) {
          errorMessage = errorData['message'];
        }
      }

      return {
        'success': false,
        'message': errorMessage
      };
    } catch (e) {
      print('⛔ [ERREUR INATTENDUE] : $e');
      print('====================================================');
      return {'success': false, 'message': 'Erreur inattendue.'};
    }
  }

  // 🟢 NOUVELLE MÉTHODE AVEC LOGS
  @override
  Future<Map<String, dynamic>> getScanHistory({String? date}) async {
    print('====== 🚀 DÉBUT REQUÊTE: getScanHistory ======');

    try {
      final queryParams = date != null ? {'date': date} : null;
      print('👉 GET /agent/reservations/scan-history | Query: $queryParams');

      final response = await dio.get(
        'agent/reservations/scan-history',
        queryParameters: queryParams,
      );

      // 🟢 LOG DE LA RÉPONSE GLOBALE
      print('✅ [SUCCÈS HTTP] Code : ${response.statusCode}');
      print('✅ [SUCCÈS HTTP] Data brute de l\'historique : ${response.data}');

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Erreur lors de la récupération de l\'historique');
      }
    } on DioException catch (e) {
      print('⛔ [ERREUR DIO HISTORIQUE] : ${e.response?.data}');
      throw Exception(e.response?.data['message'] ?? 'Erreur réseau');
    } finally {
      print('====== 🏁 FIN REQUÊTE: getScanHistory ======');
    }
  }


  @override
  Future<TicketReservationModel> searchTicket(String qrCode) async {
    try {
      print("🚀 [API REQUEST] Données scannées : $qrCode");

      // 1. On prépare les données à envoyer
      Map<String, dynamic> payload;

      try {
        // On essaie de lire le QR code comme du JSON (Ton nouveau format)
        payload = jsonDecode(qrCode);
      } catch (_) {
        // Sécurité : Si le QR code n'est pas du JSON (ex: un vieux billet), on l'envoie comme une simple référence
        payload = {'reference': qrCode};
      }

      print("🚀 [API REQUEST] POST /agent/reservations/search | Payload envoyé : $payload");

      // 2. On envoie l'objet entier au backend
      final response = await dio.post(
        '/agent/reservations/search',
        data: payload, // 👈 C'est ici que la magie opère !
      );

      print("✅ [API RESPONSE] Status: ${response.statusCode} | Data: ${response.data}");

      if (response.data['success'] == true) {
        return TicketReservationModel.fromJson(response.data['reservation']);
      }

      throw Exception("Billet introuvable");

    } on DioException catch (e) {
      print("❌ [DIO ERROR] Status: ${e.response?.statusCode}");
      print("🛑 [BACKEND MESSAGE] : ${e.response?.data}");

      // Si on a un message d'erreur clair du backend, on l'utilise pour l'afficher à l'utilisateur
      final backendMessage = e.response?.data['message'];
      if (backendMessage != null) {
        throw Exception(backendMessage);
      }
      rethrow;
    } catch (e) {
      print("❌ [API ERROR] searchTicket a échoué: $e");
      rethrow;
    }
  }

  @override
  Future<TicketReservationModel> searchTicketByReference(String reference) async {
    try {
      print("🚀 [API REQUEST] POST /agent/reservations/search-by-reference | reference: $reference");
      final response = await dio.post('/agent/reservations/search-by-reference', data: {'reference': reference});
      print("✅ [API RESPONSE] Status: ${response.statusCode} | Data: ${response.data}");

      if (response.data['success'] == true) {
        return TicketReservationModel.fromJson(response.data['reservation']);
      }

      print("⚠️ [API WARNING] searchTicketByReference renvoie success = false");
      throw Exception("Référence introuvable");

    } catch (e) {
      print("❌ [API ERROR] searchTicketByReference a échoué: $e");
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> confirmBoarding({
    required String reference,
    required int vehiculeId,
    required int programmeId,
  }) async {
    try {
      // On construit EXACTEMENT le JSON attendu par ton API
      final payload = {
        "reference": reference,
        "vehicule_id": vehiculeId,
        "programme_id": programmeId
      };

      print("🚀 [API REQUEST] POST /agent/reservations/confirm | Payload : $payload");

      final response = await dio.post(
        '/agent/reservations/confirm',
        data: payload,
      );

      print("✅ [API RESPONSE] Status: ${response.statusCode} | Data: ${response.data}");

      if (response.data['success'] == true) {
        return response.data;
      }

      throw Exception("Erreur lors de la confirmation");

    } on DioException catch (e) {
      print("❌ [DIO ERROR] Status: ${e.response?.statusCode}");
      print("🛑 [BACKEND MESSAGE] : ${e.response?.data}");

      final backendMessage = e.response?.data['message'];
      if (backendMessage != null) {
        throw Exception(backendMessage);
      }
      rethrow;
    } catch (e) {
      print("❌ [API ERROR] confirmBoarding a échoué: $e");
      rethrow;
    }
  }

  @override
  Future<List<ProgrammeModel>> getTodayProgrammes() async {
    print('====== 🚀 DÉBUT REQUÊTE: getTodayProgrammes ======');
    print('👉 GET /agent/programmes/today');

    try {
      final response = await dio.get('/agent/programmes/today');

      print('✅ [SUCCÈS HTTP] Code : ${response.statusCode}');
      print('✅ [SUCCÈS HTTP] Data brute : ${response.data}'); // Affiche le JSON reçu

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> data = response.data['programmes'];
        print('✅ [PARSING] Nombre de programmes à convertir : ${data.length}');

        final programmes = data.map((json) => ProgrammeModel.fromJson(json)).toList();
        print('✅ [SUCCÈS] Conversion terminée. Retour des programmes.');
        return programmes;
      } else {
        print('⚠️ [ÉCHEC LOGIQUE] Le serveur a répondu mais success est false ou code n\'est pas 200');
        throw Exception("Échec de la récupération des programmes.");
      }
    } on DioException catch (e) {
      print('⛔ [ERREUR DIO PROGRAMMES] Type : ${e.type}');
      print('⛔ [ERREUR DIO PROGRAMMES] Status Code : ${e.response?.statusCode}');
      print('⛔ [ERREUR DIO PROGRAMMES] Response Data : ${e.response?.data}');

      final message = e.response?.data != null && e.response?.data is Map
          ? e.response?.data['message'] ?? "Erreur de connexion serveur."
          : "Erreur de connexion serveur.";
      throw Exception(message);
    } catch (e) {
      print('⛔ [ERREUR INATTENDUE PROGRAMMES] : $e');
      throw Exception("Une erreur inattendue s'est produite : $e");
    } finally {
      print('====== 🏁 FIN REQUÊTE: getTodayProgrammes ======');
    }
  }



}