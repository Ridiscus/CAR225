import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

import '../../features/booking/data/repositories/notification_repository.dart'; // Ajuste l'import

class NotificationProvider extends ChangeNotifier {
  int _unreadCount = 0;
  final NotificationRepository _repository;

  // Injection du repo
  NotificationProvider({required NotificationRepository repository})
      : _repository = repository;

  int get unreadCount => _unreadCount;

  // 1. Charger le nombre depuis l'API
  Future<void> fetchUnreadCount() async {
    try {
      final count = await _repository.getUnreadCount();
      _unreadCount = count;
      notifyListeners(); // 🔔 Ding Dong ! Tout le monde met à jour son UI
    } catch (e) {
      // Gérer l'erreur silencieusement ou log
    }
  }

  // 2. Méthode pour décrémenter localement (pour l'effet instantané)
  void decreaseCount() {
    if (_unreadCount > 0) {
      _unreadCount--;
      notifyListeners();
    }
  }

  // 3. Méthode pour tout remettre à zéro (si on marque tout lu)
  void resetCount() {
    _unreadCount = 0;
    notifyListeners();
  }
}