import 'package:dio/dio.dart';
import 'package:car225/core/network/dio_client.dart';
import '../models/scanned_ticket_model.dart';
import '../models/boarding_summary_model.dart';

abstract class AgentRemoteDataSource {
  /// Appelle l'API pour scanner et valider un ticket
  Future<ScannedTicketModel> scanTicket(String qrCode);

  /// Récupère l'historique des scans de l'agent
  Future<List<ScannedTicketModel>> getScanHistory();

  /// Récupère le résumé de l'embarquement pour un trajet
  Future<BoardingSummaryModel> getBoardingSummary(String travelId);

  /// Met à jour le profil de l'agent
  Future<void> updateProfile(String firstName, String lastName, String phone);

  /// Met à jour le mot de passe
  Future<void> updatePassword(String oldPassword, String newPassword);

  /// Met à jour la photo de profil
  Future<String> updateProfilePicture(String imagePath);
}

class AgentRemoteDataSourceImpl implements AgentRemoteDataSource {
  final Dio dio = DioClient.instance;

  AgentRemoteDataSourceImpl();

  @override
  Future<ScannedTicketModel> scanTicket(String qrCode) async {
    final response = await dio.post(
      'agent/scan-ticket',
      data: {'qrcode': qrCode},
    );
    return ScannedTicketModel.fromJson(response.data);
  }

  @override
  Future<BoardingSummaryModel> getBoardingSummary(String travelId) async {
    final response = await dio.get('agent/boarding-summary/$travelId');
    return BoardingSummaryModel.fromJson(response.data);
  }

  @override
  Future<List<ScannedTicketModel>> getScanHistory() async {
    final response = await dio.get('agent/scan-history');
    final List list = response.data;
    return list.map((json) => ScannedTicketModel.fromJson(json)).toList();
  }

  @override
  Future<void> updateProfile(
    String firstName,
    String lastName,
    String phone,
  ) async {
    await dio.post(
      'agent/update-profile',
      data: {
        'first_name': firstName,
        'last_name': lastName,
        'phone_number': phone,
      },
    );
  }

  @override
  Future<void> updatePassword(String oldPassword, String newPassword) async {
    await dio.post(
      'agent/update-password',
      data: {'old_password': oldPassword, 'new_password': newPassword},
    );
  }

  @override
  Future<String> updateProfilePicture(String imagePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(imagePath),
    });
    final response = await dio.post('agent/update-avatar', data: formData);
    return response.data['avatar_url'];
  }
}
