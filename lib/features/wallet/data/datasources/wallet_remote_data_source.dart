// lib/features/wallet/data/datasources/wallet_remote_data_source.dart
import 'package:dio/dio.dart';
import '../models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWalletDetails();
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final Dio dio;

  WalletRemoteDataSourceImpl({required this.dio});

  @override
  Future<WalletModel> getWalletDetails() async {
    try {
      // 1. On lance la requête
      final response = await dio.get('/user/wallet');

      // 2. On extrait les données (selon le format de ton backend)
      final data = response.data['data'];

      return WalletModel.fromJson(data);

    } on DioException catch (e) {
      // 🟢 C'EST ICI QU'ON INTERCEPTE L'ERREUR 404 DE DIO
      if (e.requestOptions != null) {
        print("🔍 L'URL EXACTE appelée était : ${e.requestOptions.uri}");
      }
      throw Exception("Erreur API récupération wallet: ${e.message}");

    } catch (e) {
      // 🟠 C'est ici qu'on attrape les autres erreurs (ex: erreur de parsing JSON)
      print("❌ Erreur interne Wallet: $e");
      throw Exception("Erreur récupération wallet: $e");
    }
  }
}