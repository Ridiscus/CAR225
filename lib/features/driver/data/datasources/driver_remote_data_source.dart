import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/driver_profile_model.dart';
import 'package:car225/core/services/networking/api_config.dart';
import '../models/voyage_model.dart';
import '../models/driver_message_model.dart';
import '../models/signalement_model.dart';
import '../models/driver_scan_info_model.dart';

abstract class DriverRemoteDataSource {
  Future<Map<String, dynamic>> logout();
  Future<DriverProfileModel> getProfile();
  Future<DriverProfileModel> updateProfile(Map<String, dynamic> data);
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<Map<String, dynamic>> getDashboardData();
  
  Future<Map<String, dynamic>> getVoyages({String? date, int page = 1});
  Future<Map<String, dynamic>> getVoyageHistory({int page = 1});
  Future<VoyageModel> confirmVoyage(int voyageId);
  Future<VoyageModel> startVoyage(int voyageId);
  Future<Map<String, dynamic>> completeVoyage(int voyageId);
  Future<Map<String, dynamic>> cancelVoyage(int voyageId, {String? reason});
  Future<Map<String, dynamic>> updateLocation(int voyageId, double latitude, double longitude, {double? speed, double? heading});

  Future<Map<String, dynamic>> getMessages({int page = 1});
  Future<DriverMessageModel> getMessageDetails(int id, String source);
  Future<Map<String, dynamic>> sendMessageToGare(String subject, String message);

  Future<Map<String, dynamic>> getSignalements({int page = 1});
  Future<Map<String, dynamic>> getVoyagesForSignalement();
  Future<SignalementModel> getSignalementDetails(int id);
  Future<SignalementModel> createSignalement(Map<String, dynamic> formData); // Use FormData for file upload

  Future<DriverScanInfoModel> getScanInfo();
  Future<Map<String, dynamic>> searchReservation(String reference);
  Future<Map<String, dynamic>> confirmEmbarquement(String reference);
}

class DriverRemoteDataSourceImpl implements DriverRemoteDataSource {
  late final Dio dio;

  DriverRemoteDataSourceImpl() {
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
        }
        return handler.next(options);
      },
      onError: (DioException e, handler) {
        return handler.next(e);
      },
    ));
  }

  Exception _handleError(DioException e) {
    if (e.response?.data != null && e.response?.data is Map) {
      if (e.response?.data.containsKey('errors')) {
        return Exception(e.response?.data['errors'].toString());
      } else if (e.response?.data.containsKey('message')) {
        return Exception(e.response?.data['message']);
      }
    }
    return Exception(e.message ?? 'Erreur réseau inattendue');
  }

  @override
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await dio.post('chauffeur/logout');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<DriverProfileModel> getProfile() async {
    try {
      final response = await dio.get('chauffeur/profile');
      if (response.data['success'] == true) {
        return DriverProfileModel.fromJson(response.data['chauffeur']);
      }
      throw Exception('Erreur de récupération du profil');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<DriverProfileModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await dio.post('chauffeur/profile', data: FormData.fromMap(data));
      if (response.data['success'] == true) {
        return DriverProfileModel.fromJson(response.data['chauffeur']);
      }
      throw Exception('Erreur de mise à jour du profil');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    try {
      final response = await dio.post('chauffeur/change-password', data: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': confirmPassword,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await dio.get('chauffeur/dashboard');
      if (response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
      throw Exception('Erreur dashboard');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getVoyages({String? date, int page = 1}) async {
    try {
      final response = await dio.get('chauffeur/voyages', queryParameters: {
        if (date != null) 'date': date,
        'page': page,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getVoyageHistory({int page = 1}) async {
    try {
      final response = await dio.get('chauffeur/voyages/history', queryParameters: {
        'page': page,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<VoyageModel> confirmVoyage(int voyageId) async {
    try {
      final response = await dio.post('chauffeur/voyages/$voyageId/confirm');
      if (response.data['success'] == true) {
        return VoyageModel.fromJson(response.data['voyage']);
      }
      throw Exception('Erreur confirmation');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<VoyageModel> startVoyage(int voyageId) async {
    try {
      final response = await dio.post('chauffeur/voyages/$voyageId/start');
      if (response.data['success'] == true) {
        return VoyageModel.fromJson(response.data['voyage']);
      }
      throw Exception('Erreur démarrage');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> completeVoyage(int voyageId) async {
    try {
      final response = await dio.post('chauffeur/voyages/$voyageId/complete');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> cancelVoyage(int voyageId, {String? reason}) async {
    try {
      final response = await dio.post('chauffeur/voyages/$voyageId/annuler', data: {
        if (reason != null) 'reason': reason,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> updateLocation(int voyageId, double latitude, double longitude, {double? speed, double? heading}) async {
    try {
      final response = await dio.post('chauffeur/voyages/$voyageId/update-location', data: {
        'latitude': latitude,
        'longitude': longitude,
        if (speed != null) 'speed': speed,
        if (heading != null) 'heading': heading,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getMessages({int page = 1}) async {
    try {
      final response = await dio.get('chauffeur/messages', queryParameters: {'page': page});
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<DriverMessageModel> getMessageDetails(int id, String source) async {
    try {
      final response = await dio.get('chauffeur/messages/$id', queryParameters: {'source': source});
      if (response.data['success'] == true) {
        return DriverMessageModel.fromJson(response.data['message']);
      }
      throw Exception('Erreur lecture message');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> sendMessageToGare(String subject, String message) async {
    try {
      final response = await dio.post('chauffeur/messages', data: {
        'subject': subject,
        'message': message,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getSignalements({int page = 1}) async {
    try {
      final response = await dio.get('chauffeur/signalements', queryParameters: {'page': page});
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> getVoyagesForSignalement() async {
    try {
      final response = await dio.get('chauffeur/signalements/voyages');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<SignalementModel> getSignalementDetails(int id) async {
    try {
      final response = await dio.get('chauffeur/signalements/$id');
      if (response.data['success'] == true) {
        return SignalementModel.fromJson(response.data['signalement']);
      }
      throw Exception('Erreur détails signalement');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<SignalementModel> createSignalement(Map<String, dynamic> formData) async {
    try {
      final response = await dio.post('chauffeur/signalements', data: FormData.fromMap(formData));
      if (response.data['success'] == true) {
        return SignalementModel.fromJson(response.data['signalement']);
      }
      throw Exception('Erreur création signalement');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<DriverScanInfoModel> getScanInfo() async {
    try {
      final response = await dio.get('chauffeur/reservations/scan-info');
      if (response.data['success'] == true) {
        return DriverScanInfoModel.fromJson(response.data);
      }
      throw Exception('Erreur scan info');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> searchReservation(String reference) async {
    try {
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(reference);
      } catch (_) {
        payload = {'reference': reference};
      }
      final response = await dio.post('chauffeur/reservations/search', data: payload);
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Billet introuvable');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  @override
  Future<Map<String, dynamic>> confirmEmbarquement(String reference) async {
    try {
      Map<String, dynamic> payload;
      try {
        payload = jsonDecode(reference);
      } catch (_) {
        payload = {'reference': reference};
      }
      final response = await dio.post('chauffeur/reservations/confirm', data: payload);
      if (response.data['success'] == true) {
        return response.data;
      }
      throw Exception(response.data['message'] ?? 'Erreur confirmation embarquement');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
}
