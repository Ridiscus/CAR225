import '../../../booking/data/models/user_stats_model.dart';
import '../../../hostess/models/hostess_profile_model.dart';
import '../../../hostess/models/sale_model.dart';
import '../../data/models/auth_response.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/register_request_model.dart';
import '../../data/models/unified_login_request_model.dart';
import '../../data/models/user_model.dart';

abstract class AuthRepository {
  Future<void> verifyPasswordOtp(String email, String otpCode);
  Future<AuthResponseModel> login(LoginRequestModel params);
  Future<AuthResponseModel> unifiedLogin(UnifiedLoginRequestModel params);
  Future<void> logout();
  Future<HostessProfileModel> getHostessProfile();
  Future<HostessProfileModel> updateProfile(Map<String, dynamic> data);
  Future<void> changePasswordHotesse(Map<String, dynamic> data);
  Future<List<HostessSaleModel>> getSalesHistory(DateTime? startDate, DateTime? endDate);
  Future<Map<String, dynamic>> searchTickets({
    required String dateDepart,
    required String pointDepart,
    required String pointArrive,
  });
  Future<Map<String, dynamic>> bookTicket(Map<String, dynamic> payload);
  Future<Map<String, dynamic>> getHostessDashboard();
  Future<AuthResponseModel> register(RegisterRequestModel params);
  
  Future<void> loginWithGoogle({
    required String googleId,
    required String idToken,
    required String fcmToken,
    String? email,
    String? fullName,
    String? photoUrl,
  });

  Future<void> verifyOtp(String email, String otpCode);
  Future<void> sendOtp(String email);
  Future<void> resetPassword({
    required String email,
    required String otpCode,
    required String password,
    required String passwordConfirmation,
  });

  Future<UserModel> getUserProfile();
  Future<UserModel> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String nomUrgence,
    required String lienParenteUrgence,
    required String contactUrgence,
    String? photoPath,
  });
  Future<void> deactivateAccount(String password);
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  Future<UserStatsModel> getUserStats();
  Future<TripDetailsModel> getTripDetails();
}
