import '../../data/datasources/booking_remote_data_source.dart';
import '../../data/models/program_model.dart';

class BookingRepositoryImpl {
  final BookingRemoteDataSource remoteDataSource;

  BookingRepositoryImpl({required this.remoteDataSource});

  Future<List<String>> getCities() async {
    return await remoteDataSource.getVillesDisponibles();
  }

  Future<List<ProgramModel>> searchTrips(String depart, String arrivee, String date, bool isRoundTrip) async {
    return await remoteDataSource.searchProgrammes(
        depart: depart,
        arrivee: arrivee,
        date: date,
        isAllerRetour: isRoundTrip
    );
  }


  // AJOUTE CELLE-CI
  Future<List<ProgramModel>> getAllTrips() async {
    return await remoteDataSource.getAllProgrammes();
  }


}