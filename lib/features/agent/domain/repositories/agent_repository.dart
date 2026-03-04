import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/scanned_ticket.dart';
import '../entities/boarding_summary.dart';

abstract class AgentRepository {
  /// Scanne un ticket via son code QR/Barre
  Future<Either<Failure, ScannedTicket>> scanTicket(String qrCode);

  /// Récupère l'historique des scans de l'agent
  Future<Either<Failure, List<ScannedTicket>>> getScanHistory();

  /// Récupère le résumé de l'embarquement actuel (nombre de passagers attendus vs scannés)
  Future<Either<Failure, BoardingSummary>> getBoardingSummary(String travelId);

  /// Met à jour les informations personnelles de l'agent
  Future<Either<Failure, Unit>> updatePersonalInfo({
    required String firstName,
    required String lastName,
    required String phone,
  });

  /// Met à jour le mot de passe de l'agent
  Future<Either<Failure, Unit>> updatePassword({
    required String oldPassword,
    required String newPassword,
  });

  /// Met à jour la photo de profil de l'agent
  Future<Either<Failure, String>> updateProfilePicture(String imagePath);
}
