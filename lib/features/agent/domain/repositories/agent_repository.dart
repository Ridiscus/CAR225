

// ⚠️ Vérifie l'import ici aussi !
import '../../data/models/programme_model.dart';
import '../../data/models/agent_dashboard_data.dart';
import '../../data/models/ticket_reservation_model.dart';
import '../../data/models/ticket_scan.dart';

abstract class AgentRepository {
  // 🟢 AJOUTE CECI
  Future<Map<String, dynamic>> logout();

  // 🟢 AJOUTE CECI
  Future<Map<String, dynamic>> getProfile();

  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  });

  // 🟢 AJOUTE LA SIGNATURE ICI
  Future<List<TicketScan>> getScanHistory({DateTime? date});
  Future<AgentDashboardData> getDashboardData();
  Future<TicketReservationModel> searchTicket(String qrCode);
  Future<TicketReservationModel> searchTicketByReference(String reference);
  Future<Map<String, dynamic>> confirmBoarding({
    required String reference,
    required int vehiculeId,
    required int programmeId,
  });
  Future<List<ProgrammeModel>> getTodayProgrammes();
}
