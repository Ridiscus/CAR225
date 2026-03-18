import 'package:shared_preferences/shared_preferences.dart';

// ⚠️ Vérifie l'import ici aussi !
import '../../data/models/programme_model.dart';
import '../../domain/repositories/agent_repository.dart';
import '../../presentation/screens/agent_history_screen.dart';
import '../datasources/agent_remote_data_source.dart';
import '../models/agent_dashboard_data.dart';
import '../models/ticket_reservation_model.dart';
import '../models/ticket_scan.dart';

class AgentRepositoryImpl implements AgentRepository {
  final AgentRemoteDataSource remoteDataSource;

  AgentRepositoryImpl({required this.remoteDataSource});

  // 🟢 AJOUTE CECI
  @override
  Future<Map<String, dynamic>> logout() async {
    try {
      final response = await remoteDataSource.logout();

      // Si la déconnexion réussit côté serveur, on nettoie le token localement
      if (response['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('auth_token');
        await prefs.remove('user_role');
        await prefs.remove('user_data');
      }

      return response;
    } catch (e) {
      // Même si l'API échoue, on force la déconnexion locale par sécurité
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_role');
      await prefs.remove('user_data');

      throw Exception('Erreur de déconnexion: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getProfile() async {
    return await remoteDataSource.getProfile();
  }

  @override
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    // Dans une Clean Architecture plus stricte, c'restit ici qu'on catcherait
    // les exceptions pour renvoyer des entités "Failure" (ex: avec le package dartz ou fpdart).
    // Mais on garde la logique de Map demandée :
    return await remoteDataSource.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
      confirmPassword: confirmPassword,
    );
  }

  @override
  Future<List<TicketScan>> getScanHistory({DateTime? date}) async {
    try {
      String? dateString;
      if (date != null) {
        dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
      }

      final response = await remoteDataSource.getScanHistory(date: dateString);

      if (response['success'] == true && response['scans'] != null) {
        final List<dynamic> scansData = response['scans'];
        // L'erreur disparaîtra car il connaît maintenant fromJson !
        return scansData.map((json) => TicketScan.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  @override
  Future<AgentDashboardData> getDashboardData() async {
    try {
      final response = await remoteDataSource.getDashboardData();
      if (response['success'] == true) {
        return AgentDashboardData.fromJson(response);
      }
      throw Exception("Données invalides");
    } catch (e) {
      throw Exception(e.toString().replaceAll("Exception: ", ""));
    }
  }

  // 🟢 1. RECHERCHE PAR SCAN QR CODE
  @override
  Future<TicketReservationModel> searchTicket(String qrCode) async {
    try {
      // On délègue l'appel au DataSource
      return await remoteDataSource.searchTicket(qrCode);
    } catch (e) {
      // Tu pourras ajouter des logs ou transformer l'exception ici plus tard si besoin
      rethrow;
    }
  }

  // 🟢 2. RECHERCHE PAR SAISIE MANUELLE (RÉFÉRENCE)
  @override
  Future<TicketReservationModel> searchTicketByReference(String reference) async {
    try {
      return await remoteDataSource.searchTicketByReference(reference);
    } catch (e) {
      rethrow;
    }
  }
  @override
  Future<Map<String, dynamic>> confirmBoarding({
    required String reference,
    required int vehiculeId,
    required int programmeId,
  }) async {
    try {
      // On passe les 3 paramètres au DataSource
      return await remoteDataSource.confirmBoarding(
        reference: reference,
        vehiculeId: vehiculeId,
        programmeId: programmeId,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<List<ProgrammeModel>> getTodayProgrammes() async {
    // Le "await" ici transforme la Future du DataSource en List,
    // mais comme la méthode est marquée "async", Dart ré-emballe automatiquement
    // le résultat dans une Future pour correspondre au type de retour.
    return await remoteDataSource.getTodayProgrammes();
  }

}
