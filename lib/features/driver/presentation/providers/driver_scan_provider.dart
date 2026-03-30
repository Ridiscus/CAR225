import 'package:flutter/material.dart';
import '../../data/datasources/driver_remote_data_source.dart';
import '../../data/repositories/driver_repository_impl.dart';
import '../../data/models/driver_reservation_model.dart';
import '../../data/models/driver_scan_info_model.dart';

class DriverScanProvider extends ChangeNotifier {
  final DriverRepositoryImpl _repo = DriverRepositoryImpl(remoteDataSource: DriverRemoteDataSourceImpl());

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;
  
  DriverScanInfoModel? _scanInfo;
  DriverScanInfoModel? get scanInfo => _scanInfo;

  DriverReservationModel? _lastScannedTicket;
  DriverReservationModel? get lastScannedTicket => _lastScannedTicket;

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String? msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void clearError() => _setError(null);

  Future<void> fetchScanInfo() async {
    _setLoading(true);
    _setError(null);
    try {
      final info = await _repo.getScanInfo();
      _scanInfo = info;
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<DriverReservationModel?> scanTicket(String qrCode) async {
    _setLoading(true);
    _setError(null);
    _lastScannedTicket = null;
    try {
      final data = await _repo.searchReservation(qrCode);
      if (data['success'] == true) {
        _lastScannedTicket = DriverReservationModel.fromJson(data['reservation']);
        // Auto-confirm
        await confirmScannedTicket(qrCode);
      }
      return _lastScannedTicket;
    } catch (e) {
      _setError(e.toString());
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> confirmScannedTicket(String qrCode) async {
    try {
      final data = await _repo.confirmEmbarquement(qrCode);
      if (data['success'] == true) {
        await fetchScanInfo(); // Refresh list of recent scans
        return true;
      }
      return false;
    } catch (e) {
      _setError(e.toString());
      return false;
    }
  }
}
