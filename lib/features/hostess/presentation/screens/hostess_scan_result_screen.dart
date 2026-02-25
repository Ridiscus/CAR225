import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../agent/presentation/widgets/custom_app_bar.dart';

class HostessScanResultScreen extends StatelessWidget {
  final String ticketReference;

  const HostessScanResultScreen({super.key, required this.ticketReference});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Détails Réservation',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Gap(30),
              _buildStatusBadge(),
              const Gap(30),
              _buildPassengerDetails(),
              const Gap(35),
              _buildTravelDetails(),
              const Gap(40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(30),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: AppColors.secondary, size: 20),
            Gap(8),
            Text(
              'BILLET VALIDE',
              style: TextStyle(
                color: AppColors.secondary,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPassengerDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Informations Passager',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF263238),
          ),
        ),
        const Gap(20),
        _buildDetailRow(
          Icons.person_outline_rounded,
          'NOM COMPLET',
          'Bakayoko Moussa',
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.qr_code_scanner_outlined,
          'RÉFÉRENCE',
          ticketReference,
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.airline_seat_recline_normal_outlined,
          'SIÈGE / CLASSE',
          'Place #14A',
        ),
      ],
    );
  }

  Widget _buildTravelDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Détails du Trajet',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Gap(20),
        _buildDetailRow(
          Icons.location_on_outlined,
          'DÉPART',
          'Gare de Yamoussoukro',
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.flag_outlined,
          'DESTINATION',
          'Gare d\'Abidjan (Adjamé)',
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.calendar_today_outlined,
          'DATE & HEURE',
          'Aujourd\'hui • 14:00',
        ),
        _buildDivider(),
        _buildDetailRow(
          Icons.directions_bus_outlined,
          'CAR',
          '#225 - Compagnie Express',
        ),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const Gap(16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 50),
      child: Divider(color: Colors.grey[200], height: 20),
    );
  }
}
