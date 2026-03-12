import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../widgets/confirmation_modal.dart';
import '../widgets/success_modal.dart';

class ScanResultScreen extends StatelessWidget {
  final String ticketReference;
  const ScanResultScreen({super.key, required this.ticketReference});

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
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
      bottomNavigationBar: _buildActionButtons(context),
    );
  }

  Widget _buildStatusBadge() {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.secondary.withOpacity(0.1),
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
            fontSize: 17,
            fontWeight: FontWeight.w500,
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
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
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

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 15),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton(
                    onPressed: () {
                      HapticFeedback.heavyImpact();
                      ConfirmationModal.show(
                        context: context,
                        title: 'Refuser ?',
                        message:
                            'Êtes-vous vraiment sûr de vouloir refuser la confirmation de ce billet ?',
                        confirmText: 'OUI, REFUSER',
                        cancelText: 'ANNULER',
                        onConfirm: () {
                          Navigator.pop(context);
                        },
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(
                        color: Colors.redAccent,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Refuser',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(16),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () async {
                      // Action de confirmation
                      HapticFeedback.heavyImpact();
                      if (context.mounted) {
                        SuccessModal.show(
                          context: context,
                          message:
                              'L\'embarquement du passager a été confirmé avec succès.',
                          onPressed: () => Navigator.pop(context),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Confirmer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
