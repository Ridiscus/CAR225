import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<void> login(String email, String password);
  Future<void> register({
    required String nom,
    required String prenom,
    required String email,
    required String password,
    required String adresse,
    required String contact,
    String? photoPath,
  });
  Future<void> logout();
  Future<UserEntity> getUserProfile();
  Future<UserEntity> updateUserProfile({
    required String name,
    required String prenom,
    required String email,
    required String contact,
    required String adresse,
    String? photoPath,
  });
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });
  Future<void> sendOtp(String contact);
  Future<void> verifyOtp(String contact, String code);
}
