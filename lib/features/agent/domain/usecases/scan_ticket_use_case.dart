import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/scanned_ticket.dart';
import '../repositories/agent_repository.dart';

class ScanTicketUseCase {
  final AgentRepository repository;

  ScanTicketUseCase(this.repository);

  Future<Either<Failure, ScannedTicket>> call(String qrCode) async {
    return await repository.scanTicket(qrCode);
  }
}
