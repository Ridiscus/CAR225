import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/boarding_summary.dart';
import '../repositories/agent_repository.dart';

class GetBoardingSummaryUseCase {
  final AgentRepository repository;

  GetBoardingSummaryUseCase(this.repository);

  Future<Either<Failure, BoardingSummary>> call(String travelId) async {
    return await repository.getBoardingSummary(travelId);
  }
}
