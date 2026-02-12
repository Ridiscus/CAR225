import 'package:flutter/material.dart';
import '../../features/booking/data/models/compagnie_program_model2.dart';
import '../../features/booking/data/models/company_model.dart';
import '../../features/booking/domain/repositories/company_repository.dart';




class CompanyProvider extends ChangeNotifier {
  final CompanyRepository repository;

  CompanyProvider({required this.repository});

  List<CompanyModel> _companies = [];
  bool _isLoading = false;
  String? _error;

  List<CompanyModel> get companies => _companies;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchCompanies() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _companies = await repository.getAllCompanies();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  // --- ÉTAT POUR LES DÉTAILS ---
  CompanyModel? _selectedCompany;
  List<ProgrammeModel> _selectedCompanyProgrammes = [];
  bool _isLoadingDetails = false;

  CompanyModel? get selectedCompany => _selectedCompany;
  List<ProgrammeModel> get selectedCompanyProgrammes => _selectedCompanyProgrammes;
  bool get isLoadingDetails => _isLoadingDetails;

  // Méthode pour charger tout d'un coup
  Future<void> fetchCompanyDetailsWithProgrammes(int id) async {
    _isLoadingDetails = true;
    _error = null;
    notifyListeners();

    try {
      // Future.wait permet de lancer les 2 requêtes en parallèle (plus rapide)
      final results = await Future.wait([
        repository.getCompanyDetails(id),
        repository.getCompanyProgrammes(id),
      ]);

      _selectedCompany = results[0] as CompanyModel;
      _selectedCompanyProgrammes = results[1] as List<ProgrammeModel>;

    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }





}