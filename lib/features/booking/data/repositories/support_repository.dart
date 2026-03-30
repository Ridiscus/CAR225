import 'dart:developer' as dev;
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/networking/api_config.dart';
import '../models/categorie_models.dart';
import '../models/claim_model.dart';
import '../models/voyage_model.dart';

class SupportRepository {
  late Dio _dio;

  /*SupportRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      //baseUrl: 'https://car225.com/api/', // On utilise ta vraie URL
      /*headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },*/
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // On réinjecte ton intercepteur pour que le token soit envoyé
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          dev.log("🔑 [Interceptor] Token injecté pour Support", name: 'SupportAPI');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        dev.log("❌ [API Error] ${e.response?.statusCode} : ${e.message}", name: 'SupportAPI');
        return handler.next(e);
      },
    ));
  }*/

  SupportRepository() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token');

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
          dev.log("🔑 [Interceptor] Token injecté pour Support", name: 'SupportAPI');
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        dev.log("❌ [API Error] ${e.response?.statusCode} : ${e.message}", name: 'SupportAPI');
        return handler.next(e);
      },
    ));
  }

  // GET: /user/stats/historique-voyages
  Future<List<Voyage>> fetchVoyages() async {
    dev.log('📡 Appel: GET /user/stats/historique-voyages', name: 'SupportAPI');
    try {
      final response = await _dio.get('user/stats/historique-voyages');

      // On log la réponse pour debug
      dev.log('✅ Voyages reçus: ${response.statusCode}', name: 'SupportAPI');

      // Vérifie si la structure match ton JSON (data -> voyages_effectues)
      final List data = response.data['data']['voyages_effectues'];
      return data.map((e) => Voyage.fromJson(e)).toList();
    } on DioException catch (e) {
      dev.log('❌ Erreur Fetch: ${e.response?.data}', name: 'SupportAPI');
      throw Exception("Impossible de charger l'historique");
    }
  }

  // POST: /user/support
  Future<bool> sendClaim({
    required String type,
    int? reservationId,
    required String objet,
    required String description,
  }) async {
    final payload = {
      "type": type,
      "reservation_id": reservationId,
      "objet": objet,
      "description": description,
    };

    dev.log('🚀 Envoi réclamation: $payload', name: 'SupportAPI');

    try {
      final response = await _dio.post('user/support', data: payload);
      dev.log('✅ Succès POST: ${response.data}', name: 'SupportAPI');
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      dev.log('❌ Erreur POST: ${e.response?.data}', name: 'SupportAPI');
      return false;
    }
  }


  // Dans SupportRepository
  Future<List<SupportCategory>> fetchCategories() async {
    dev.log('📡 Fetching Support Categories...', name: 'SupportAPI');
    try {
      final response = await _dio.get('user/support/categories');
      if (response.data['success'] == true) {
        final List data = response.data['categories'];
        return data.map((e) => SupportCategory.fromJson(e)).toList();
      }
      return [];
    } on DioException catch (e) {
      dev.log('❌ Erreur Categories: ${e.response?.data}', name: 'SupportAPI');
      throw Exception("Erreur chargement catégories");
    }
  }

  Future<List<Claim>> fetchClaimsHistory(String? type) async {
    try {
      // Si type est null ou "all", on appelle l'URL sans filtre ou avec un paramètre global
      final response = await _dio.get('user/support');

      if (response.data['success'] == true) {
        final List typesData = response.data['par_type'];
        List<Claim> allClaims = [];

        for (var section in typesData) {
          // Si on a filtré par type et que ça match, ou si on veut "Tout voir"
          if (type == null || type == "all" || section['type'] == type) {
            final List declarations = section['declarations'];
            allClaims.addAll(declarations.map((e) => Claim.fromJson(e)).toList());
          }
        }
        return allClaims;
      }
      return [];
    } on DioException catch (e) {
      throw Exception("Erreur historique");
    }
  }
  Future<bool> sendSupportReply(int supportId, String message) async {
    // LOG : On vérifie l'URL complète avant l'envoi
    print('--- [SupportAPI] Tentative de réponse ---');
    print('📍 URL: user/support/$supportId/repondre');
    print('📦 Payload: {"reponse": "$message"}');

    try {
      final response = await _dio.post(
        'user/support/$supportId/repondre',
        data: {'reponse': message},
      );

      print('✅ [SupportAPI] Réponse reçue: ${response.data}');
      return response.data['success'] == true;

    } on DioException catch (e) {
      // LOG détaillé de l'erreur
      print('❌ [SupportAPI] Erreur Dio');
      print('🔗 URL complète: ${e.requestOptions.uri}');
      print('🔢 Code Status: ${e.response?.statusCode}');
      print('📄 Données erreur: ${e.response?.data}');

      if (e.response?.statusCode == 404) {
        print('⚠️ ATTENTION: L\'URL semble incorrecte ou l\'ID $supportId n\'existe pas.');
      }

      throw Exception("Erreur lors de l'envoi de la réponse");
    } catch (e) {
      print('🧨 [SupportAPI] Erreur inconnue: $e');
      rethrow;
    }
  }

}