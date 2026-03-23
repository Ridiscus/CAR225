import '../../domain/repositories/driver_repository.dart';
import '../datasources/driver_remote_data_source.dart';
import '../models/driver_profile_model.dart';
import '../models/voyage_model.dart';
import '../models/driver_message_model.dart';
import '../models/signalement_model.dart';
import '../models/driver_scan_info_model.dart';

class DriverRepositoryImpl implements DriverRepository {
  final DriverRemoteDataSource remoteDataSource;

  DriverRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Map<String, dynamic>> logout() {
    return remoteDataSource.logout();
  }

  @override
  Future<DriverProfileModel> getProfile() {
    return remoteDataSource.getProfile();
  }

  @override
  Future<DriverProfileModel> updateProfile(Map<String, dynamic> data) {
    return remoteDataSource.updateProfile(data);
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) {
    return remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Future<Map<String, dynamic>> getDashboardData() {
    return remoteDataSource.getDashboardData();
  }

  @override
  Future<Map<String, dynamic>> getVoyages({String? date, int page = 1}) {
    return remoteDataSource.getVoyages(date: date, page: page);
  }

  @override
  Future<Map<String, dynamic>> getVoyageHistory({int page = 1}) {
    return remoteDataSource.getVoyageHistory(page: page);
  }

  @override
  Future<VoyageModel> confirmVoyage(int voyageId) {
    return remoteDataSource.confirmVoyage(voyageId);
  }

  @override
  Future<VoyageModel> startVoyage(int voyageId) {
    return remoteDataSource.startVoyage(voyageId);
  }

  @override
  Future<Map<String, dynamic>> completeVoyage(int voyageId) {
    return remoteDataSource.completeVoyage(voyageId);
  }

  @override
  Future<Map<String, dynamic>> cancelVoyage(int voyageId, {String? reason}) {
    return remoteDataSource.cancelVoyage(voyageId, reason: reason);
  }

  @override
  Future<Map<String, dynamic>> updateLocation(int voyageId, double latitude, double longitude, {double? speed, double? heading}) {
    return remoteDataSource.updateLocation(voyageId, latitude, longitude, speed: speed, heading: heading);
  }

  @override
  Future<Map<String, dynamic>> getMessages({int page = 1}) {
    return remoteDataSource.getMessages(page: page);
  }

  @override
  Future<DriverMessageModel> getMessageDetails(int id, String source) {
    return remoteDataSource.getMessageDetails(id, source);
  }

  @override
  Future<Map<String, dynamic>> sendMessageToGare(String subject, String message) {
    return remoteDataSource.sendMessageToGare(subject, message);
  }

  @override
  Future<Map<String, dynamic>> getSignalements({int page = 1}) {
    return remoteDataSource.getSignalements(page: page);
  }

  @override
  Future<Map<String, dynamic>> getVoyagesForSignalement() {
    return remoteDataSource.getVoyagesForSignalement();
  }

  @override
  Future<SignalementModel> getSignalementDetails(int id) {
    return remoteDataSource.getSignalementDetails(id);
  }

  @override
  Future<SignalementModel> createSignalement(Map<String, dynamic> formData) {
    return remoteDataSource.createSignalement(formData);
  }

  @override
  Future<DriverScanInfoModel> getScanInfo() {
    return remoteDataSource.getScanInfo();
  }

  @override
  Future<Map<String, dynamic>> searchReservation(String reference) {
    return remoteDataSource.searchReservation(reference);
  }

  @override
  Future<Map<String, dynamic>> confirmEmbarquement(String reference) {
    return remoteDataSource.confirmEmbarquement(reference);
  }
}
