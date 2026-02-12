// lib/features/wallet/data/datasources/wallet_remote_data_source.dart
import 'package:dio/dio.dart';
import '../models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<WalletModel> getWalletDetails();
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final Dio dio;

  WalletRemoteDataSourceImpl({required this.dio});

 /* @override
  Future<WalletModel> getWalletDetails() async {
    try {
      // GET /user/wallet
      final response = await dio.get('/user/wallet');

      // On suppose que la réponse est { "success": true, "data": { "solde": 50000, "transactions": [] } }
      final data = response.data['data'];

      return WalletModel.fromJson(data);
    } catch (e) {
      throw Exception("Erreur récupération wallet: $e");
    }
  }*/



  /*@override
  Future<WalletModel> getWalletDetails() async {
    try {
      final response = await dio.get('/user/wallet');

      // --- AJOUT DEBUG ---
      print("💰 JSON WALLET REÇU: ${response.data}");
      // -------------------

      // Vérifie si la réponse est directe ou dans "data"
      final data = response.data['data'] ?? response.data;

      return WalletModel.fromJson(data);
    } catch (e) {
      throw Exception("Erreur récupération wallet: $e");
    }
  }*/


  @override
  Future<WalletModel> getWalletDetails() async {
    try {
      final response = await dio.get('/user/wallet');

      // Tes logs montrent : { "success": true, "data": { "solde": ... } }
      // Donc on doit passer response.data['data'] au modèle
      final data = response.data['data'];

      return WalletModel.fromJson(data);
    } catch (e) {
      throw Exception("Erreur récupération wallet: $e");
    }
  }




}