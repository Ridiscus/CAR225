import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/boarding_summary.dart';
import '../../domain/entities/scanned_ticket.dart';
import '../../domain/repositories/agent_repository.dart';
import '../datasources/agent_remote_data_source.dart';

class AgentRepositoryImpl implements AgentRepository {
  final AgentRemoteDataSource remoteDataSource;

  AgentRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ScannedTicket>> scanTicket(String qrCode) async {
    try {
      final remoteTicket = await remoteDataSource.scanTicket(qrCode);
      return Right(remoteTicket);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, BoardingSummary>> getBoardingSummary(
    String travelId,
  ) async {
    try {
      final summary = await remoteDataSource.getBoardingSummary(travelId);
      return Right(summary);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<ScannedTicket>>> getScanHistory() async {
    try {
      final history = await remoteDataSource.getScanHistory();
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePersonalInfo({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      await remoteDataSource.updateProfile(firstName, lastName, phone);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> updatePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      await remoteDataSource.updatePassword(oldPassword, newPassword);
      return const Right(unit);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> updateProfilePicture(String imagePath) async {
    try {
      final imageUrl = await remoteDataSource.updateProfilePicture(imagePath);
      return Right(imageUrl);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
