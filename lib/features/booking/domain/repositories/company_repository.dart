import 'package:dio/dio.dart';
import '../../data/models/compagnie_program_model2.dart';
import '../../data/models/company_model.dart';



class CompanyRepository {
  final Dio dio;

  CompanyRepository({required this.dio});
  Future<List<CompanyModel>> getAllCompanies() async {
    try {
      final response = await dio.get('/user/compagnies');

      if (response.data['success'] == true) {
        final List<dynamic> data = response.data['data']['compagnies'];
        return data.map((json) => CompanyModel.fromJson(json)).toList();
      } else {
        // Si l'API répond mais dit success: false
        throw Exception(response.data['message'] ?? "Erreur inconnue du serveur.");
      }

    } on DioException catch (e) {
      // 🔥 C'est ici qu'on filtre les erreurs sales pour faire propre
      String message;

      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = "Le serveur met trop de temps à répondre.";
          break;
        case DioExceptionType.connectionError:
          message = "Impossible de se connecter. Vérifiez votre internet ou si le serveur est allumé.";
          break;
        case DioExceptionType.badResponse:
        // Erreur 404, 500, etc.
          final statusCode = e.response?.statusCode;
          if (statusCode == 500) {
            message = "Problème technique sur le serveur (Erreur 500).";
          } else if (statusCode == 404) {
            message = "Les compagnies sont introuvables.";
          } else {
            message = "Erreur serveur ($statusCode).";
          }
          break;
        case DioExceptionType.cancel:
          message = "La requête a été annulée.";
          break;
        default:
          message = "Une erreur de connexion est survenue.";
      }

      // On lance une exception propre, sans le blabla technique
      throw Exception(message);

    } catch (e) {
      // Pour les erreurs qui ne viennent pas de Dio (ex: erreur de parsing JSON)
      throw Exception("Une erreur inattendue est survenue.");
    }
  }



  // 1. Récupérer les détails d'une compagnie
  Future<CompanyModel> getCompanyDetails(int id) async {
    try {
      final response = await dio.get('/user/compagnies/$id');
      if (response.data['success'] == true) {
        return CompanyModel.fromJson(response.data['data']);
      } else {
        throw Exception(response.data['message']);
      }
    } catch (e) {
      throw Exception("Erreur détails compagnie: $e");
    }
  }



// --- MISE À JOUR AVEC DÉBOGAGE ---
  Future<List<ProgrammeModel>> getCompanyProgrammes(int companyId) async {
    print("🔍 [DEBUG] getCompanyProgrammes appelé pour ID: $companyId");

    try {
      // On loggue l'URL appelée pour être sûr
      final String url = '/user/itineraires?compagnie_id=$companyId';
      print("🚀 [DEBUG] Appel API : $url");

      final response = await dio.get(
        '/user/itineraires',
        queryParameters: {'compagnie_id': companyId},
      );

      print("✅ [DEBUG] Réponse HTTP reçue: ${response.statusCode}");

      // On vérifie le succès
      if (response.data['success'] == true) {

        // On inspecte la structure "data"
        final dynamic rootData = response.data['data'];
        print("📦 [DEBUG] Contenu de 'data' (root): $rootData");

        // Cas 1 : Structure paginée standard Laravel (data -> data)
        if (rootData is Map && rootData.containsKey('data')) {
          final List<dynamic> list = rootData['data'];
          print("🔢 [DEBUG] Nombre de trajets trouvés dans la liste : ${list.length}");

          if (list.isNotEmpty) {
            print("📄 [DEBUG] Exemple du premier trajet : ${list.first}");
          } else {
            print("⚠️ [DEBUG] La liste 'data' est vide !");
          }

          return list.map((json) => ProgrammeModel.fromJson(json)).toList();
        }
        // Cas 2 : Structure liste directe (au cas où l'API change)
        else if (rootData is List) {
          print("⚠️ [DEBUG] Attention : Structure liste directe détectée (pas de pagination ?)");
          return rootData.map((json) => ProgrammeModel.fromJson(json)).toList();
        }
        else {
          print("❌ [DEBUG] Structure JSON inattendue : ni Map paginée, ni List.");
          return [];
        }

      } else {
        print("❌ [DEBUG] API success = false : ${response.data['message']}");
        throw Exception(response.data['message']);
      }
    } catch (e) {
      print("🔥 [DEBUG] Exception attrapée : $e");
      throw Exception("Erreur programmes: $e");
    }
  }

}







