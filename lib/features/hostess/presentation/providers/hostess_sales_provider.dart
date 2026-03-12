import 'package:flutter/material.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import '../../models/sale_model.dart';

class HostessSalesProvider extends ChangeNotifier {
  // --- ÉTAT (State) ---
  List<HostessSaleModel> _sales = []; // Remplace dynamic par HostessSaleModel
  bool _isLoading = false;
  String? _errorMessage;

  // --- GETTERS ---
  List<HostessSaleModel> get sales => _sales; // Remplace dynamic par HostessSaleModel
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- ACTIONS ---
  Future<void> fetchSalesHistory(
      AuthRepository repository, { // Remplace dynamic par AuthRepository
        DateTime? startDate,
        DateTime? endDate,
      }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Prévient l'UI de commencer à tourner (Loader)

    try {
      // 1. Appel au Repository
      final fetchedSales = await repository.getSalesHistory(startDate, endDate);

      // 2. Mise à jour des données
      _sales = fetchedSales;

    } catch (e) {
      // 3. Gestion de l'erreur propre pour l'utilisateur
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      // 4. Fin du chargement dans tous les cas
      _isLoading = false;
      notifyListeners(); // Prévient l'UI de s'actualiser avec les données ou l'erreur
    }
  }

  // Petite méthode utile si tu veux vider la liste manuellement (ex: déconnexion)
  void clearSales() {
    _sales = [];
    _errorMessage = null;
    notifyListeners();
  }
}