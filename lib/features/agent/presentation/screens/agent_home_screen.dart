import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/agent_header.dart';
import 'program_details_screen.dart';

class AgentHomeScreen extends StatefulWidget {
  const AgentHomeScreen({super.key});
  @override
  State<AgentHomeScreen> createState() => _AgentHomeScreenState();
}

class _AgentHomeScreenState extends State<AgentHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: Platform.isAndroid ? false : true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER PORTAIL AGENT ---
            const AgentHeader(),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- GREETING CARD ---
                    // _buildGreetingCard(),
                    const Gap(30),

                    // --- STATISTICS SECTION ---
                    const Text(
                      'Statistiques des billets',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF263238),
                      ),
                    ),
                    const Gap(20),
                    _buildStatsRow(),
                    const Gap(30),

                    // --- NEXT DEPARTURES TITLE ---
                    const Text(
                      'Programmes du jour',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        fontStyle: FontStyle.normal,
                        color: Color(0xFF263238),
                      ),
                    ),

                    const Gap(20),

                    // --- DEPARTURES LIST ---
                    _buildDepartureCard(
                      from: 'Abidjan',
                      to: 'Yamoussoukro',
                      time: '14:30',
                      busId: '#225',
                      type: 'VIP',
                    ),
                    const Gap(15),
                    _buildDepartureCard(
                      from: 'Abidjan',
                      to: 'Bouaké',
                      time: '15:45',
                      busId: '#228',
                      type: 'Standard',
                    ),

                    const Gap(20), // Space for floating nav bar
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'BILLETS SCANNES',
            '1,240',
            const Color.fromARGB(255, 27, 166, 22),
            Icons.qr_code_scanner_rounded,
            const Color(0xFFE8F5E9),
            const Color(0xFF2E7D32),
          ),
        ),
        const Gap(15),
        Expanded(
          child: _buildStatCard(
            'BILLETS A SCANNER',
            '12',
            AppColors.primary,
            Icons.receipt,
            const Color(0xFFFFF3E0),
            const Color(0xFFEF6C00),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    Color valueColor,
    IconData icon,
    Color iconBgColor,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8ECEF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
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
              // const Icon(Icons.trending_up, color: Color(0xFFCFD8DC), size: 16),
            ],
          ),
          const Gap(20),
          Text(
            value,
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w700,
              color: valueColor,
              // letterSpacing: -1,
            ),
          ),
          const Gap(4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF90A4AE),
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartureCard({
    required String from,
    required String to,
    required String time,
    required String busId,
    required String type,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProgramDetailsScreen(
              from: from,
              to: to,
              time: time,
              busId: busId,
              type: type,
              departureStation: 'Gare Routière $from',
              arrivalStation: 'Gare Routière $to',
              duration: '3h 30min',
              driverName: 'Kouassi Jean-Marc',
              driverPhone: '+225 07 12 34 56 78',
              licensePlate: 'CI 1234 AB 01',
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(30),
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Stack(
            children: [
              // 1. Conteneur de la bordure grise globale
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: const Color(0xFFE8ECEF),
                    width: 1.5,
                  ),
                ),
              ),

              // 2. Bordure orange solide à gauche (superposée)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 6, // Épaisseur de la bordure orange
                  decoration: const BoxDecoration(color: AppColors.primary),
                ),
              ),

              // 3. Contenu de la carte
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 20),
                child: Row(
                  children: [
                    // Icône du Car / Bus
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: const Icon(
                        Icons.directions_bus_rounded,
                        color: AppColors.primary,
                        size: 30,
                      ),
                    ),
                    const Gap(16),
                    // Informations de trajet
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            spacing: 5,
                            children: [
                              Text(
                                from,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 6),
                                child: Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 18,
                                  color: Color(0xFFB0BEC5),
                                ),
                              ),
                              Text(
                                to,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF263238),
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              // Badge Heure/ID
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF5F7F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 14,
                                      color: Color(0xFF78909C),
                                    ),
                                    const Gap(6),
                                    Text(
                                      time,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF546E7A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Gap(8),
                              const Text(
                                '•',
                                style: TextStyle(color: Color(0xFFB0BEC5)),
                              ),
                              const Gap(8),
                              Text(
                                'Car $busId',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Icône de navigation
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFFB0BEC5),
                      size: 28,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
