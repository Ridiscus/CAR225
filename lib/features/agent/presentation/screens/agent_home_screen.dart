import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/agent_header.dart';
import 'program_details_screen.dart';
import 'agent_history_screen.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});
  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          SafeArea(
            top: false,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- HEADER PORTAIL AGENT ---
                const AgentHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Gap(20),
                        // --- STATISTICS SECTION ---
                        const Text(
                          'Statistiques des billets',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Gap(20),
                        _buildStatsRow(),
                        const Gap(20),

                        // --- NEXT DEPARTURES TITLE ---
                        const Text(
                          'Programmes du jour',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),

                        const Gap(20),

                        // --- DEPARTURES LIST ---
                        _buildDepartureCard(
                          from: 'Abidjan',
                          to: 'Yamoussoukro',
                          departureTime: '14:30',
                          arrivalTime: '17:45',
                          departureStation: 'Gare du Nord (Adjame)',
                          arrivalStation: 'Gare Centrale (YAKRO)',
                          busId: '#225',
                          driverName: 'Kouassi Jean-Marc',
                          driverPhone: '+225 07 12 34 56 78',
                        ),
                        _buildDepartureCard(
                          from: 'Abidjan',
                          to: 'Bouaké',
                          departureTime: '15:45',
                          arrivalTime: '21:00',
                          departureStation: 'Gare de Bassam',
                          arrivalStation: 'Gare de Bouaké-Sud',
                          busId: '#228',
                          driverName: '', // Simule l'absence de chauffeur
                        ),
                        const Gap(20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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
            value: '1,240',
            valueColor: const Color(0xFF2E7D32),
            icon: Icons.qr_code_scanner_rounded,
            iconBgColor: const Color(0xFFE8F5E9),
            iconColor: const Color(0xFF2E7D32),
            trend: '+12%',
            isPositive: true,
            onTap: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const AgentHistoryScreen(),
                ),
              );
            },
          ),
        ),
        const Gap(15),
        Expanded(
          child: _buildStatCard(
            label: 'À SCANNER',
            value: '12',
            valueColor: AppColors.primary,
            icon: Icons.receipt_long_rounded,
            iconBgColor: const Color(0xFFFFF3E0),
            iconColor: const Color(0xFFEF6C00),
            trend: '-5%',
            isPositive: false,
            onTap: () {
              // Action pour les billets à scanner si nécessaire
            },
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
        border: Border.all(
          color: const Color.fromARGB(255, 214, 214, 220),
          width: 1.5,
        ),
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
                color: iconColor.withValues(alpha: 0.1),
              ),
            ),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                splashColor: iconColor.withValues(alpha: 0.05),
                highlightColor: iconColor.withValues(alpha: 0.02),
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
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              _showProgramActionsBottomSheet(
                context: context,
                from: from,
                to: to,
                departureTime: departureTime,
                busId: busId,
                departureStation: departureStation,
                arrivalStation: arrivalStation,
                isAssigned: isAssigned,
                driverName: driverName,
              );
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
                          color: AppColors.primary.withValues(alpha: 0.1),
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
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 30),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(24),
              // Trip Overview Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.departure_board_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$from ➔ $to',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1E293B),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Text(
                          '$departureTime • $busId • $departureStation',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(32),

              // Condition Check Box
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isAssigned
                      ? const Color(0xFFF0FDF4)
                      : const Color(0xFFFFFBFA),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isAssigned
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEE4E2),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isAssigned
                              ? Icons.check_circle_rounded
                              : Icons.warning_amber_rounded,
                          color: isAssigned
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD92D20),
                          size: 24,
                        ),
                        const Gap(12),
                        Expanded(
                          child: Text(
                            isAssigned
                                ? 'Chauffeur assigné : $driverName'
                                : 'Chauffeur non assigné',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isAssigned
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF912018),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (!isAssigned) ...[
                      const Gap(12),
                      const Text(
                        'Vous ne pouvez pas entamer les scans tant qu\'aucun chauffeur n\'est assigné à ce programme.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF912018),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Gap(32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isAssigned
                      ? () {
                          Navigator.pop(context);
                          // Navigation vers l'écran de scan ici
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[200],
                    disabledForegroundColor: Colors.grey[400],
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'DÉMARRER LES SCANS',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const Gap(12),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => ProgramDetailsScreen(
                          from: from,
                          to: to,
                          time: departureTime,
                          busId: busId,
                          type: 'Standard',
                          departureStation: departureStation,
                          arrivalStation: arrivalStation,
                          duration: '3h 15min',
                          driverName: driverName ?? 'Non assigné',
                          driverPhone: '+225 00 00 00 00 00',
                          licensePlate: 'En attente',
                          price: '5 000 FCFA',
                          passengersCount: isAssigned ? '28' : '0',
                          totalSeats: '50',
                          tripDate: 'Lundi 02 Mars 2026',
                        ),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF64748B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'VOIR LES DÉTAILS COMPLETS',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCityInfo(String city, {bool isEnd = false}) {
    return Text(
      city,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        color: Color(0xFF1E293B),
        letterSpacing: -0.5,
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
}
