import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';

class ProgramDetailsScreen extends StatelessWidget {
  final String from;
  final String to;
  final String time;
  final String busId;
  final String type;
  final String departureStation;
  final String arrivalStation;
  final String duration;
  final String driverName;
  final String driverPhone;
  final String licensePlate;

  const ProgramDetailsScreen({
    super.key,
    required this.from,
    required this.to,
    required this.time,
    required this.busId,
    required this.type,
    required this.departureStation,
    required this.arrivalStation,
    required this.duration,
    required this.driverName,
    required this.driverPhone,
    required this.licensePlate,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Détails du programme',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête du trajet
            _buildRouteHeader(),
            const Gap(24),

            // Informations du trajet
            _buildSectionTitle('Informations du trajet'),
            const Gap(12),
            _buildInfoCard([
              _buildInfoRow(
                Icons.location_on_outlined,
                'Lieu de départ',
                departureStation,
                AppColors.primary,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.location_on,
                'Destination',
                arrivalStation,
                const Color(0xFF2E7D32),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.access_time_rounded,
                'Heure de départ',
                time,
                const Color(0xFF1976D2),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.timer_outlined,
                'Durée du trajet',
                duration,
                const Color(0xFFEF6C00),
              ),
            ]),

            const Gap(24),

            // Informations du véhicule
            _buildSectionTitle('Informations du véhicule'),
            const Gap(12),
            _buildInfoCard([
              _buildInfoRow(
                Icons.directions_bus_rounded,
                'Numéro du car',
                busId,
                AppColors.primary,
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.confirmation_number_outlined,
                'Immatriculation',
                licensePlate,
                const Color(0xFF546E7A),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.star_outline,
                'Type de car',
                type,
                const Color(0xFFEF6C00),
              ),
            ]),

            const Gap(24),

            // Informations du chauffeur
            _buildSectionTitle('Informations du chauffeur'),
            const Gap(12),
            _buildInfoCard([
              _buildInfoRow(
                Icons.person_outline,
                'Nom du chauffeur',
                driverName,
                const Color(0xFF1976D2),
              ),
              const Divider(height: 24),
              _buildInfoRow(
                Icons.phone_outlined,
                'Téléphone',
                driverPhone,
                const Color(0xFF2E7D32),
              ),
            ]),

            const Gap(32),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      from,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      departureStation,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      to,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      arrivalStation,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: Colors.white,
                  size: 18,
                ),
                const Gap(8),
                Text(
                  'Départ à $time',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: Color(0xFF263238),
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8ECEF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value,
    Color iconColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const Gap(16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF90A4AE),
                  letterSpacing: 0.3,
                ),
              ),
              const Gap(4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
