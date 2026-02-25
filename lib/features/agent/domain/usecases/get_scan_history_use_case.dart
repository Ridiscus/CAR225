import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/scanned_ticket.dart';
import '../repositories/agent_repository.dart';

class GetScanHistoryUseCase {
  final AgentRepository repository;
  GetScanHistoryUseCase(this.repository);
  Future<Either<Failure, List<ScannedTicket>>> call() async {
    return await repository.getScanHistory();
  }
}
