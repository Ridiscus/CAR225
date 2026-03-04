import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../models/trip_model.dart';
import '../widgets/driver_header.dart';

class DriverDashboardScreen extends StatelessWidget {
  const DriverDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
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
                            fontWeight: FontWeight.bold,
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
                            onTap: () => _showTripDetailsSheet(
                              context,
                              driverProvider.currentTrip!,
                            ),
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
                            icon: Icons.assignment_turned_in_outlined,
                            title: "Tout est à jour",
                            message: "Aucun trajet actif pour aujourd'hui.",
                          ),

                        const Gap(35),

                        // TRAJETS À VENIR
                        const Text(
                          "VOYAGES À VENIR",
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
                                    onTap: () =>
                                        _showTripDetailsSheet(context, trip),
                                    borderRadius: BorderRadius.circular(15),
                                    child: _buildUpcomingCard(trip),
                                  ),
                                ),
                              )
                        else
                          _buildEmptyState(
                            icon: Icons.calendar_today_outlined,
                            title: "Planning libre",
                            message:
                                "Aucun voyage prévu pour les prochains jours.",
                          ),

                        if (driverProvider.upcomingTrips.length > 2)
                          Center(
                            child: TextButton(
                              onPressed: () => driverProvider.setIndex(1),
                              child: const Text("Voir tout le planning"),
                            ),
                          ),
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

  void _showTripDetailsSheet(BuildContext context, TripModel trip) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildTripDetailsContent(context, trip),
    );
  }

  Widget _buildTripDetailsContent(BuildContext context, TripModel trip) {
    final fullDateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const Gap(25),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Détails du Voyage",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                _buildStatusBadge(trip.status),
              ],
            ),
            const Gap(8),
            Text(
              fullDateFormat.format(trip.scheduledDepartureTime),
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const Gap(30),

            // Itinerary
            Row(
              children: [
                Column(
                  children: [
                    const Icon(
                      Icons.circle,
                      color: AppColors.primary,
                      size: 12,
                    ),
                    Container(
                      width: 2,
                      height: 50,
                      color: AppColors.primary.withValues(alpha: 0.2),
                    ),
                    const Icon(
                      Icons.location_on,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ],
                ),
                const Gap(16),
                Expanded(
                  child: Column(
                    children: [
                      _buildStationDetailItem(
                        label: "Départ",
                        station: trip.departureStation,
                        time: timeFormat.format(trip.scheduledDepartureTime),
                      ),
                      const Gap(20),
                      _buildStationDetailItem(
                        label: "Destination",
                        station: trip.arrivalStation,
                        time: timeFormat.format(trip.scheduledArrivalTime),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(30),
            const Divider(),
            const Gap(25),

            // Vehicle & Passenger Info
            Row(
              children: [
                _buildInfoCircle(Icons.directions_bus_outlined),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Véhicule",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        trip.carRegistration,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildInfoCircle(Icons.people_outline_rounded),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Passagers",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      Text(
                        "${trip.passengersCount}/${trip.totalSeats}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const Gap(25),

            // Fare Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: AppColors.secondary.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.payments_outlined,
                        color: AppColors.secondary,
                      ),
                      const Gap(12),
                      Text(
                        "Tarif du trajet",
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "${trip.price.toInt()} FCFA",
                    style: const TextStyle(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),

            const Gap(35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A1A1A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text("FERMER"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationDetailItem({
    required String label,
    required String station,
    required String time,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            Text(
              station,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCircle(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 24),
    );
  }

  Widget _buildUpcomingCard(TripModel trip) {
    final dayFormat = DateFormat('EEEE dd MMM', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
                  "${trip.departureStation} ➔ ${trip.arrivalStation}",
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

  Widget _buildTripCard(BuildContext context, dynamic trip) {
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
          _buildStationInfo(
            icon: Icons.location_on_outlined,
            label: "Gare de Départ",
            value: trip.departureStation,
            time: timeFormat.format(trip.scheduledDepartureTime),
            isDeparture: true,
          ),
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4, bottom: 4),
            child: Container(
              height: 30,
              width: 2,
              color: AppColors.primary.withOpacity(0.3),
            ),
          ),
          _buildStationInfo(
            icon: Icons.flag_outlined,
            label: "Gare de Destination",
            value: trip.arrivalStation,
            time: timeFormat.format(trip.scheduledArrivalTime),
            isDeparture: false,
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
            fontWeight: FontWeight.bold,
            fontSize: 13,
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
      case 'started':
        color = Colors.blue;
        label = "En cours";
        break;
      case 'completed':
        color = AppColors.secondary;
        label = "Terminé";
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

  Widget _buildStationInfo({
    required IconData icon,
    required String label,
    required String value,
    required String time,
    required bool isDeparture,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 28),
        const SizedBox(width: 15),
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
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
    dynamic trip,
  ) {
    if (trip.status == 'completed') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Center(
          child: Text(
            "Trajet terminé avec succès ! 🎉",
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
        if (trip.status == 'pending')
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => _confirmAction(
                context,
                "Confirmation du Départ",
                "Êtes-vous sûr de vouloir marquer le départ de ce trajet ?",
                Icons.play_circle_fill_rounded,
                AppColors.primary,
                () => provider.markDeparture(),
              ),
              child: const Text(
                "MARQUER LE DÉPART",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        if (trip.status == 'started')
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
              ),
              onPressed: () => _confirmAction(
                context,
                "Confirmation de l'Arrivée",
                "Êtes-vous sûr de vouloir marquer l'arrivée à destination ? Le trajet sera alors clôturé.",
                Icons.check_circle_rounded,
                AppColors.secondary,
                () => provider.markArrival(),
              ),
              child: const Text(
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
                        fontWeight: FontWeight.w700,
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
