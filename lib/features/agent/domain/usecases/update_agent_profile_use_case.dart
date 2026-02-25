import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../repositories/agent_repository.dart';

class UpdateAgentProfileUseCase {
  final AgentRepository repository;

  UpdateAgentProfileUseCase(this.repository);

  Future<Either<Failure, void>> updateInfo({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    return await repository.updatePersonalInfo(
      firstName: firstName,
      lastName: lastName,
      phone: phone,
    );
  }

  Future<Either<Failure, void>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    return await repository.updatePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  Future<Either<Failure, String>> updateAvatar(String path) async {
    return await repository.updateProfilePicture(path);
  }
}
