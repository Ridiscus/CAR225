import '../../data/models/driver_profile_model.dart';
import '../../data/models/voyage_model.dart';
import '../../data/models/driver_message_model.dart';
import '../../data/models/signalement_model.dart';
import '../../data/models/driver_scan_info_model.dart';

abstract class DriverRepository {
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
  Future<SignalementModel> createSignalement(Map<String, dynamic> formData);

  Future<DriverScanInfoModel> getScanInfo();
  Future<Map<String, dynamic>> searchReservation(String reference);
  Future<Map<String, dynamic>> confirmEmbarquement(String reference);
}
