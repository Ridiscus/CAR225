import 'voyage_model.dart';
import 'driver_reservation_model.dart';

class DriverScanInfoModel {
  final VoyageModel? voyageActif;
  final List<DriverReservationModel> derniersScans;

  DriverScanInfoModel({
    this.voyageActif,
    required this.derniersScans,
  });

  factory DriverScanInfoModel.fromJson(Map<String, dynamic> json) {
    return DriverScanInfoModel(
      voyageActif: json['voyage_actif'] != null
          ? VoyageModel.fromJson(json['voyage_actif'])
          : null,
      derniersScans: json['derniers_scans'] != null
          ? (json['derniers_scans'] as List)
              .map((i) => DriverReservationModel.fromJson(i))
              .toList()
          : [],
    );
  }
}
