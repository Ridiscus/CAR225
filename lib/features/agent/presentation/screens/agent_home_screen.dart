import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../data/models/programme_model.dart';
import '../../data/models/ticket_scan.dart';
import '../providers/agent_profile_provider.dart';
import '../widgets/agent_header.dart';
import 'agent_history_screen.dart';
import 'all_programs_screen.dart';
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/repositories/agent_repository_impl.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});
  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

// Dans _AgentHomeScreenState
class _AgentHomeScreenState extends State<AgentHomeScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  int _scannedTodayCount = 0;
  List<ProgrammeModel> _todayProgrammes = []; // Seule liste pour les programmes
  late final AgentRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    _repository = AgentRepositoryImpl(remoteDataSource: AgentRemoteDataSourceImpl());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProfileProvider>().fetchProfile();
      _fetchData();
    });
  }
  Future<void> _fetchData() async {
    print('🔄 [UI] Lancement de _fetchData() depuis AgentHomeScreen');

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('⏳ [UI] Lancement en parallèle de getScanHistory et getTodayProgrammes...');

      // 🟢 On ne garde que les deux requêtes valides !
      final results = await Future.wait([
        _repository.getScanHistory(date: DateTime.now()),
        _repository.getTodayProgrammes(),
      ]);

      print('✅ [UI] Future.wait terminé ! Les deux requêtes ont répondu.');

      if (mounted) {
        setState(() {
          final todayScans = results[0] as List<TicketScan>;
          _scannedTodayCount = todayScans.length;
          print('📊 [UI] Historique appliqué : $_scannedTodayCount scans aujourd\'hui');
          _todayProgrammes = results[1] as List<ProgrammeModel>;
          print('🚌 [UI] Programmes appliqués : ${_todayProgrammes.length} trajets prévus');

          _isLoading = false;
        });
        print('✨ [UI] Interface mise à jour avec succès.');
      } else {
        print('⚠️ [UI] Le widget n\'est plus monté, on annule le setState.');
      }
    } catch (e) {
      print('❌ [UI] Erreur attrapée dans _fetchData() : $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll("Exception: ", ""); // Nettoie le texte affiché à l'agent
          _isLoading = false;
        });
        print('⚠️ [UI] Interface mise à jour avec l\'état d\'erreur.');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Stack(
        children: [
          SafeArea(
            top: Platform.isAndroid ? false : false,
            bottom: Platform.isAndroid ? true : false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AgentHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _errorMessage != null
                      ? _buildErrorState()
                  // 🟢 AJOUT DU REFRESH INDICATOR ICI
                      : RefreshIndicator(
                    onRefresh: _fetchData, // Appelle notre méthode globale
                    color: AppColors.primary,
                    backgroundColor: Colors.white,
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            onPressed: _fetchData,
            child: const Text("Réessayer"),
          )
        ],
      ),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      physics: const AlwaysScrollableScrollPhysics(
        parent: BouncingScrollPhysics(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(20),
          const Text(
            'Statistiques des billets',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
              letterSpacing: -0.5,
            ),
          ),
          const Gap(20),
          _buildStatsRow(),
          const Gap(20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Programmes du jour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                  letterSpacing: -0.5,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const AllProgramsScreen(),
                    ),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Row(
                  children: [
                    Text('Voir tout', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                    Gap(4),
                    Icon(Icons.arrow_forward_ios_rounded, size: 10, fontWeight: FontWeight.w900),
                  ],
                ),
              ),
            ],
          ),
          const Gap(12),

          if (_todayProgrammes.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Aucun programme prévu pour aujourd'hui."),
              ),
            )
          else
            ..._todayProgrammes.take(2).map((program) {
              return _buildDepartureCard(
                // 🟢 On utilise tes getters pour nettoyer la chaîne (enlève ", Côte d'Ivoire")
                from: program.depart,
                to: program.arrivee,

                // 🟢 On utilise les vraies données de l'API
                departureTime: program.heureDepart ?? 'N/A',
                arrivalTime: program.heureArrivee ?? '--:--',
                departureStation: program.gareDepart ?? 'Inconnue',
                arrivalStation: program.gareArrivee ?? 'Inconnue',
                busId: program.immatriculation ?? 'BUS',
                driverName: program.chauffeurNom, // Nullable, c'est géré par _buildDepartureCard
              );
            }).toList(),

          const Gap(20),
        ],
      ),
    );
  }



  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            label: 'BILLETS SCANNÉS',
            value: _scannedTodayCount.toString(),
            valueColor: const Color(0xFF2E7D32),
            icon: Icons.qr_code_scanner_rounded,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),
            trend: '', // Optionnel
            isPositive: true,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(builder: (context) => const AgentHistoryScreen()),
              ).then((_) => _fetchData());
            },
          ),
        ),
        const Gap(15),
        Expanded(
          child: _buildStatCard(
            label: 'DÉPARTS AUJOURD\'HUI', // 🟢 On change le libellé
            value: _todayProgrammes.length.toString(), // 🟢 On affiche le nombre de bus prévus
            valueColor: AppColors.primary,
            icon: Icons.directions_bus_filled_rounded, // 🟢 Nouvelle icône
            iconBgColor: const Color(0xFFE3F2FD),
            iconColor: const Color(0xFF1565C0),
            trend: '',
            isPositive: true,
            onTap: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required Color valueColor,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String trend,
    required bool isPositive,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Watermark Decorator
            Positioned(
              right: 0,
              bottom: 0,
              child: Icon(
                icon,
                size: 80,
                color: iconColor.withOpacity(0.1),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: iconColor.withOpacity(0.05),
                highlightColor: iconColor.withOpacity(0.02),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: iconColor, size: 20),
                          ),
                          Text(
                            value,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: valueColor,
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      const Gap(24),
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color.fromARGB(255, 43, 43, 43),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDepartureCard({
    required String from,
    required String to,
    required String departureTime,
    required String arrivalTime,
    required String departureStation,
    required String arrivalStation,
    required String busId,
    String? driverName,
    String? driverPhone,
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
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
                  // --- TOP HEADER ---
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
                      const Icon(
                        Icons.more_horiz_rounded,
                        color: Color(0xFFCBD5E1),
                      ),
                    ],
                  ),
                  const Gap(16),

                  // --- ROUTE PATH ---
                  Row(
                    children: [
                      _buildCityInfo(from),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Divider(color: Color(0xFFF1F5F9), thickness: 2),
                              Icon(
                                Icons.directions_bus_rounded,
                                size: 16,
                                color: Color(0xFF94A3B8),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _buildCityInfo(to, isEnd: true),
                    ],
                  ),
                  const Gap(24),

                  // --- DETAILS SECTION (Times & Stations) ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(
                        0xFFF8FAFC,
                      ), // Gardé clair pour le contraste interne
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFEDF2F7)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildTimeStationColumn(
                          label: 'DÉPART',
                          time: departureTime,
                          station: departureStation,
                        ),
                        _buildTimeStationColumn(
                          label: 'ARRIVÉE',
                          time: arrivalTime,
                          station: arrivalStation,
                          isEnd: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
                      "28 / 50 Places",
                      const Color(0xFFEF6C00),
                    ),
                  ],
                ),

                const Gap(32),
                SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 231, 62, 36),
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
                    decoration: BoxDecoration(color: Colors.orange[400]),
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
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
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

  Widget _buildTimeStationColumn({
    required String label,
    required String time,
    required String station,
    bool isEnd = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: isEnd
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: Colors.grey[500],
              letterSpacing: 1,
            ),
          ),
          const Gap(4),
          Text(
            time,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: isEnd ? const Color(0xFF1E293B) : AppColors.primary,
            ),
          ),
          const Gap(4),
          Text(
            station,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
        ],
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
                  "Le programme $from ➔ $to n'a pas encore de chauffeur. Vous ne pourrez voir les détails du programme qu'une fois l'assignation effectuée par l'administration.",
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
                      backgroundColor: AppColors.primary,
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

  Widget _buildCityInfo(String city, {bool isEnd = false}) {
    return Text(
      city,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w500,
        color: Color(0xFF1E293B),
        letterSpacing: -0.5,
      ),
    );
  }

}
