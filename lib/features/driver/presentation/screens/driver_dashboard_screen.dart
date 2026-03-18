import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';
import '../widgets/driver_header.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          const DriverHeader(title: "Tableau de Bord", isDashboard: true),
          Expanded(
            child: driverProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Prêt pour votre mission ?",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                        const Gap(25),

                        // TRAJET EN COURS (SI EXISTE)
                        const Text(
                          "TRAJET DU JOUR",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(10),
                        if (driverProvider.currentTrip != null) ...[
                          InkWell(
                            onTap: () => driverProvider.setIndex(1),
                            borderRadius: BorderRadius.circular(20),
                            child: _buildTripCard(
                              context,
                              driverProvider.currentTrip!,
                            ),
                          ),
                          const Gap(20),
                          _buildActionButtons(
                            context,
                            driverProvider,
                            driverProvider.currentTrip!,
                          ),
                        ] else
                          _buildEmptyState(
                            icon: Icons.assignment_late_outlined,
                            title: "Aucun trajet assigné",
                            message:
                                "Il n'y a actuellement aucun voyage ou trajet actif qui vous est assigné. Votre planning de mission apparaîtra ici dès qu'il sera configuré.",
                          ),

                        const Gap(35),

                        // TRAJETS à€ VENIR
                        const Text(
                          "VOYAGES à€ VENIR",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            fontSize: 12,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(10),
                        if (driverProvider.upcomingTrips.isNotEmpty)
                          ...driverProvider.upcomingTrips
                              .take(2)
                              .map(
                                (trip) => Padding(
                                  padding: const EdgeInsets.only(bottom: 15.0),
                                  child: InkWell(
                                    onTap: () => driverProvider.setIndex(1),
                                    borderRadius: BorderRadius.circular(15),
                                    child: _buildUpcomingCard(trip),
                                  ),
                                ),
                              )
                        else
                          _buildEmptyState(
                            icon: Icons.calendar_month_outlined,
                            title: "Planning libre",
                            message:
                                "Aucun autre voyage n'est prévu dans votre planning pour les prochains jours.",
                          ),

                        if (driverProvider.upcomingTrips.length > 2)
                          Center(
                            child: TextButton(
                              onPressed: () => driverProvider.setIndex(1),
                              child: const Text("Voir tout le planning"),
                            ),
                          ),
                        const Gap(120),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
        color: (Colors.grey[50] ?? Colors.white).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: AppColors.primary, size: 30),
          ),
          const Gap(15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3142),
            ),
          ),
          const Gap(5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildUpcomingCard(VoyageModel trip) {
    final dayFormat = DateFormat('EEEE dd MMM', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dayFormat.format(trip.scheduledDepartureTime).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: AppColors.primary,
                ),
              ),
              Text(
                trip.carRegistration,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  "${trip.departureStation} âž” ${trip.arrivalStation}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                timeFormat.format(trip.scheduledDepartureTime),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard(BuildContext context, VoyageModel trip) {
    final timeFormat = DateFormat('HH:mm');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  trip.carRegistration,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildStatusBadge(trip.status),
            ],
          ),
          const SizedBox(height: 25),
          IntrinsicHeight(
            child: Row(
              children: [
                // Colonne de gauche : Icônes et Barre verticale
                Column(
                  children: [
                    const Gap(8),
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    Expanded(
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.flag_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                    const Gap(8),
                  ],
                ),
                const Gap(15),
                // Colonne de droite : Informations textuelles
                Expanded(
                  child: Column(
                    children: [
                      _buildStationInfoOnly(
                        label: "Gare de Départ",
                        value: trip.departureStation,
                        time: timeFormat.format(trip.scheduledDepartureTime),
                      ),
                      const Gap(25),
                      _buildStationInfoOnly(
                        label: "Gare de Destination",
                        value: trip.arrivalStation,
                        time: timeFormat.format(trip.scheduledArrivalTime),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Gap(20),
          const Divider(),
          const Gap(15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTripDetailIndicator(
                icon: Icons.calendar_today_rounded,
                label: "Date",
                value: DateFormat(
                  'dd MMM yyyy',
                  'fr_FR',
                ).format(trip.scheduledDepartureTime),
              ),
              _buildTripDetailIndicator(
                icon: Icons.people_outline_rounded,
                label: "Passagers",
                value: "${trip.passengersCount}/${trip.totalSeats}",
              ),
              _buildTripDetailIndicator(
                icon: Icons.payments_outlined,
                label: "Tarif",
                value: "${trip.price.toInt()} FCFA",
                isPrice: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTripDetailIndicator({
    required IconData icon,
    required String label,
    required String value,
    bool isPrice = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: Colors.grey[500]),
            const Gap(4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
          ],
        ),
        const Gap(4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: isPrice ? AppColors.secondary : Colors.black,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'confirmé':
        color = Colors.green;
        label = "Confirmé";
        break;
      case 'en_cours':
      case 'started':
        color = Colors.blue;
        label = "En cours";
        break;
      case 'terminé':
      case 'completed':
        color = AppColors.secondary;
        label = "Terminé";
        break;
      case 'annulé':
      case 'cancelled':
        color = Colors.red;
        label = "Annulé";
        break;
      default:
        color = Colors.orange;
        label = "En attente";
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStationInfoOnly({
    required String label,
    required String value,
    required String time,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    DriverProvider provider,
    VoyageModel trip,
  ) {
    if (trip.status == 'terminé') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "Trajet terminé avec succès ! ðŸŽ‰",
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        if (trip.status == 'en_attente')
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_outline_rounded),
              onPressed: () => _confirmAction(
                context,
                "Confirmer le voyage",
                "Êtes-vous sûr de vouloir confirmer votre disponibilité pour ce voyage ?",
                Icons.check_circle_rounded,
                AppColors.primary,
                () => provider.confirmVoyage(trip.id),
              ),
              label: const Text(
                "CONFIRMER LE VOYAGE",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        if (trip.status == 'confirmé')
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_filled_rounded),
              onPressed: () => _confirmAction(
                context,
                "Confirmation du Départ",
                "Êtes-vous sûr de vouloir marquer le départ de ce trajet ? Cela informera les passagers du démarrage effectif.",
                Icons.play_circle_fill_rounded,
                AppColors.primary,
                () => provider.markDeparture(trip.id),
              ),
              label: const Text(
                "DÉMARRER LE TRAJET",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        if (trip.status == 'en_cours' && false) // Bouton retiré à la demande de l'utilisateur
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              onPressed: () => _confirmAction(
                context,
                "Confirmation de l'Arrivée",
                "Êtes-vous sûr de vouloir marquer l'arrivée à destination ? Le trajet sera alors clôturé définitivement.",
                Icons.check_circle_rounded,
                AppColors.secondary,
                () => provider.markArrival(trip.id),
              ),
              label: const Text(
                "MARQUER L'ARRIVÉE",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
      ],
    );
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    IconData icon,
    Color iconColor,
    VoidCallback onConfirm,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) => const SizedBox(),
      transitionBuilder: (context, anim1, anim2, child) {
        return Transform.scale(
          scale: anim1.value,
          child: Opacity(
            opacity: anim1.value,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 25,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 45),
                    ),
                    const Gap(24),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A1B2E),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey[600],
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Gap(32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: Text(
                              "Annuler",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              onConfirm();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: iconColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "Confirmer",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
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
      },
    );
  }
}

