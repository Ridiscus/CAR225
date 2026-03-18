import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';

// 🟢 NOUVEAUX IMPORTS POUR L'API
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/repositories/agent_repository_impl.dart';
import '../../data/models/programme_model.dart'; // 🟢 On importe le bon modèle !

class AllProgramsScreen extends StatefulWidget {
  const AllProgramsScreen({super.key});

  @override
  State<AllProgramsScreen> createState() => _AllProgramsScreenState();
}

class _AllProgramsScreenState extends State<AllProgramsScreen> {
  // --- VARIABLES D'ÉTAT ---
  bool _isLoading = true;
  String? _errorMessage;
  // 🟢 On utilise ProgrammeModel
  List<ProgrammeModel> _programs = [];
  late final AgentRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    _repository = AgentRepositoryImpl(
      remoteDataSource: AgentRemoteDataSourceImpl(),
    );
    _fetchPrograms();
  }

  // --- APPEL API ---
  Future<void> _fetchPrograms() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 🟢 On appelle uniquement getTodayProgrammes()
      final data = await _repository.getTodayProgrammes();
      if (mounted) {
        setState(() {
          _programs = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: const CustomAppBar(title: 'Tous les programmes'),
      body: SafeArea(
        top: Platform.isAndroid ? false : false,
        bottom: Platform.isAndroid ? true : false,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _errorMessage != null
            ? _buildErrorState()
            : RefreshIndicator(
          onRefresh: _fetchPrograms,
          color: AppColors.primary,
          backgroundColor: Colors.white,
          child: _buildProgramsList(),
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const Gap(16),
          Text(
            _errorMessage ?? "Erreur de chargement",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const Gap(20),
          ElevatedButton(
            onPressed: _fetchPrograms,
            child: const Text("Réessayer"),
          )
        ],
      ),
    );
  }

  // 🟢 MÉTHODE POUR CONSTRUIRE LA LISTE DYNAMIQUE
  Widget _buildProgramsList() {
    if (_programs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 100),
          Center(
            child: Text(
              "Aucun programme prévu pour aujourd'hui.",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ),
        ],
      );
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProgramGroup('PROGRAMMES DU JOUR'),

            // 🟢 ON MAPPE LES DONNÉES AVEC ProgrammeModel
            ..._programs.map((program) {

              // On vérifie si un chauffeur a été assigné par le backend
              final isAssigned = program.chauffeurNom != null && program.chauffeurNom!.isNotEmpty;

              return _buildDepartureCard(
                context,
                from: program.depart, // Utilise le getter de ProgrammeModel
                to: program.arrivee,   // Utilise le getter de ProgrammeModel
                departureTime: program.heureDepart ?? '--:--',
                arrivalTime: program.heureArrivee ?? '--:--',
                busId: program.immatriculation ?? 'BUS',
                departureStation: program.gareDepart ?? 'Gare Inconnue',
                arrivalStation: program.gareArrivee ?? 'Gare Inconnue',
                driverName: program.chauffeurNom, // Sera null si non assigné
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProgramGroup(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color.fromARGB(255, 46, 46, 46),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDepartureCard(
      BuildContext context, {
        required String from,
        required String to,
        required String departureTime,
        required String arrivalTime,
        required String departureStation,
        required String arrivalStation,
        required String busId,
        String? driverName,
      }) {
    final bool isAssigned = driverName != null && driverName.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            if (isAssigned) {
              _showProgramActionsBottomSheet(
                context: context,
                from: from,
                to: to,
                departureTime: departureTime,
                arrivalTime: arrivalTime,
                busId: busId,
                departureStation: departureStation,
                arrivalStation: arrivalStation,
                isAssigned: isAssigned,
                driverName: driverName,
              );
            } else {
              _showAssignmentErrorBottomSheet(
                context: context,
                from: from,
                to: to,
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        busId,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isAssigned
                            ? const Color(0xFFF0FDF4)
                            : const Color(0xFFFFFBFA),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isAssigned
                                ? Icons.check_circle_rounded
                                : Icons.warning_amber_rounded,
                            size: 14,
                            color: isAssigned
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD92D20),
                          ),
                          const Gap(4),
                          Text(
                            isAssigned ? 'ASSIGNÉ' : 'EN ATTENTE',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              color: isAssigned
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF912018),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      from,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 16,
                      color: Color(0xFFCBD5E1),
                    ),
                    Text(
                      to,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_filled_rounded,
                      size: 14,
                      color: Colors.grey[400],
                    ),
                    const Gap(6),
                    Text(
                      "$departureTime - $arrivalTime",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProgramActionsBottomSheet({
    required BuildContext context,
    required String from,
    required String to,
    required String departureTime,
    required String arrivalTime,
    required String busId,
    required String departureStation,
    required String arrivalStation,
    required bool isAssigned,
    String? driverName,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(32),

                // --- TICKET HEADER ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.directions_bus_filled_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const Gap(16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              busId,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1E293B),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              "Programme de voyage",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFDCFCE7)),
                        ),
                        child: const Text(
                          "ASSIGNÉ",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF166534),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Gap(24),

                // --- ROUTE TIMELINE ---
                IntrinsicHeight(
                  child: Column(
                    children: [
                      _buildRouteStep(
                        label: "DÉPART",
                        city: from,
                        time: departureTime,
                        station: departureStation,
                        icon: Icons.trip_origin_rounded,
                        color: AppColors.primary,
                        showLine: true,
                      ),
                      _buildRouteStep(
                        label: "ARRIVÉE",
                        city: to,
                        time: arrivalTime,
                        station: arrivalStation,
                        icon: Icons.location_on_rounded,
                        color: Colors.orange[800]!,
                        showLine: false,
                      ),
                    ],
                  ),
                ),

                const Gap(32),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const Gap(24),

                // --- SECONDARY INFO GRID ---
                Row(
                  children: [
                    _buildModernGridItem(
                      Icons.person_pin_rounded,
                      "Chauffeur",
                      driverName ?? "Non assigné",
                      const Color(0xFF1976D2),
                    ),
                    const Gap(16),
                    _buildModernGridItem(
                      Icons.people_alt_rounded,
                      "Occupation",
                      "-- / -- Places", // Plus de places dispos dans ce JSON pour le moment
                      const Color(0xFFEF6C00),
                    ),
                  ],
                ),
                const Gap(16),

                const Gap(32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "FERMER",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRouteStep({
    required String label,
    required String city,
    required String time,
    required String station,
    required IconData icon,
    required Color color,
    required bool showLine,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withOpacity(0.2)),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              if (showLine)
                Expanded(
                  child: Container(
                    width: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color,
                          Colors.orange[400]!.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[400],
                        letterSpacing: 1,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(
                  city,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1E293B),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  station,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600],
                    height: 1.2,
                  ),
                ),
                const Gap(16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernGridItem(
      IconData icon,
      String label,
      String value,
      Color color,
      ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const Gap(12),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.grey[500],
              ),
            ),
            const Gap(2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAssignmentErrorBottomSheet({
    required BuildContext context,
    required String from,
    required String to,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: SafeArea(
          bottom: true,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(30),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBFA),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFEE4E2),
                      width: 8,
                    ),
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFD92D20),
                    size: 40,
                  ),
                ),
                const Gap(24),
                const Text(
                  "Chauffeur non assigné",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Gap(12),
                Text(
                  "Le programme $from ➔ $to n'a pas encore de chauffeur. Vous ne pourrez valider les billets qu'une fois l'assignation terminée par l'administration.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
                const Gap(32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E293B),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "COMPRIS",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}