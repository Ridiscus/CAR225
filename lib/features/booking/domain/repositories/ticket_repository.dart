
// Fichier: lib/features/booking/domain/repositories/ticket_repository.dart

import '../../data/models/ticket_model.dart'; // Adapte le chemin selon ton projet

abstract class TicketRepository {
  // Récupérer la liste
  Future<List<TicketModel>> getMyTickets();

  // Détails
  Future<TicketModel> getTicketDetails(String ticketId);

  // Télécharger image
  Future<String> downloadTicketImage(String ticketId);

  // ✅ Annuler (On prend un String car ton ID peut être "74_aller")
  Future<Map<String, dynamic>> cancelTicket(String ticketId);

  /// Modifie une réservation existante avec les nouveaux détails (Programme, date, siège)
  Future<Map<String, dynamic>> modifyTicket(String ticketId, Map<String, dynamic> newTicketData);
}