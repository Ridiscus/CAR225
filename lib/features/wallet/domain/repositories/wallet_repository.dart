// lib/features/wallet/domain/repositories/wallet_repository.dart
import '../../data/datasources/wallet_remote_data_source.dart';
import '../../data/models/wallet_model.dart';


class WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepository({required this.remoteDataSource});

  Future<WalletModel> getWalletData() async {
    return await remoteDataSource.getWalletDetails();
  }
}