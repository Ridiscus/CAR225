import 'package:flutter/material.dart';
import '../../domain/entities/scanned_ticket.dart';
import '../../domain/entities/boarding_summary.dart';
import '../../domain/usecases/scan_ticket_use_case.dart';
import '../../domain/usecases/get_scan_history_use_case.dart';
import '../../domain/usecases/get_boarding_summary_use_case.dart';

class AgentProvider extends ChangeNotifier {

  final ScanTicketUseCase scanTicketUseCase;
  final GetScanHistoryUseCase getScanHistoryUseCase;
  final GetBoardingSummaryUseCase getBoardingSummaryUseCase;

  AgentProvider({
    required this.scanTicketUseCase,
    required this.getScanHistoryUseCase,
    required this.getBoardingSummaryUseCase,
  });

  // États 
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ScannedTicket> _scanHistory = [];
  List<ScannedTicket> get scanHistory => _scanHistory;

  BoardingSummary? _currentBoarding;
  BoardingSummary? get currentBoarding => _currentBoarding;

  // --- LOGIQUE ---

  /// Charger l'historique des scans
  Future<void> fetchScanHistory() async {
    _setLoading(true);
    final result = await getScanHistoryUseCase();
    
    result.fold(
      (failure) => _errorMessage = "Impossible de charger l'historique",
      (history) {
        _scanHistory = history;
        _errorMessage = null;
      },
    );
    _setLoading(false);
  }

  /// Récupérer les stats d'embarquement
  Future<void> fetchBoardingSummary(String travelId) async {
    _setLoading(true);
    final result = await getBoardingSummaryUseCase(travelId);
    
    result.fold(
      (failure) => _errorMessage = "Erreur lors de la récupération du résumé",
      (summary) {
        _currentBoarding = summary;
        _errorMessage = null;
      },
    );
    _setLoading(false);
  }

  /// Scanner un ticket
  Future<ScannedTicket?> performScan(String qrCode) async {
    _setLoading(true);
    final result = await scanTicketUseCase(qrCode);
    
    ScannedTicket? ticket;
    result.fold(
      (failure) => _errorMessage = "Erreur lors du scan du ticket",
      (scannedTicket) {
        ticket = scannedTicket;
        if (scannedTicket.isValid) {
          _scanHistory.insert(0, scannedTicket); // Ajouter en haut de la liste
        }
        _errorMessage = null;
      },
    );
    _setLoading(false);
    return ticket;
  }

  // Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  
}
