import 'package:flutter/material.dart';
import '../../data/datasources/driver_remote_data_source.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../data/models/driver_message_model.dart';

class DriverMessagesProvider extends ChangeNotifier {
  final DriverRepositoryImpl _repo = DriverRepositoryImpl(remoteDataSource: DriverRemoteDataSourceImpl());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<DriverMessageModel> _messages = [];
  List<DriverMessageModel> get messages => _messages;

  int _unreadCount = 0;
  int get unreadCount => _unreadCount;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  Future<void> loadMessages({int page = 1}) async {
    _setLoading(true);
    _setError(null);
    try {
      final data = await _repo.getMessages(page: page);
      if (data['success'] == true) {
        _unreadCount = data['unread_count'] ?? 0;
        _messages = (data['messages'] as List).map((m) => DriverMessageModel.fromJson(m)).toList();
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> markAsRead(int id, String source) async {
    try {
      await _repo.getMessageDetails(id, source);
      await loadMessages(); // refresh to update unread count
    } catch (e) {
      print("Erreur markAsRead: \$e");
    }
  }

  Future<bool> sendMessage(String subject, String message) async {
    _setLoading(true);
    try {
      await _repo.sendMessageToGare(subject, message);
      await loadMessages(); // refresh
      return true;
    } catch (e) {
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }
}
