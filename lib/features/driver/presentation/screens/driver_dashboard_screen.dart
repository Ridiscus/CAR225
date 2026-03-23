import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';
import '../widgets/driver_header.dart';
import 'driver_trips_screen.dart';

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
                : RefreshIndicator(
                    onRefresh: () => driverProvider.fetchAllTrips(),
                    color: AppColors.primary,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverTripsScreen())),
                            borderRadius: BorderRadius.circular(20),
                            child: _buildTripCard(
                              context,
                              driverProvider.currentTrip!,
                            ),
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
                                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverTripsScreen())),
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
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverTripsScreen())),
                              child: const Text("Voir tout le planning"),
                            ),
                          ),
                        const Gap(120),
                      ],
                    ),
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
        color: (Colors.grey[50] ?? Colors.white).withOpacity(0.8),
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
                  color: Colors.black.withOpacity(0.05),
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
            color: Colors.black.withOpacity(0.04),
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.08)),
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
                  color: AppColors.primary.withOpacity(0.1),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(trip),
                  if (trip.status == 'en_cours' && trip.tempsRestant != null) ...[
                    const Gap(8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 14, color: AppColors.primary),
                        const Gap(4),
                        Text(
                          trip.tempsRestant!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
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
                          color: AppColors.primary.withOpacity(0.2),
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
                        label: "Départ",
                        value: "${trip.programme?.pointDepart}\n(${trip.departureStation})",
                        time: timeFormat.format(trip.scheduledDepartureTime),
                      ),
                      const Gap(25),
                      _buildStationInfoOnly(
                        label: "Destination",
                        value: "${trip.programme?.pointArrive}\n(${trip.arrivalStation})",
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
                value: "${trip.passengersCount} / ${trip.totalSeats}",
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

  Widget _buildStatusBadge(VoyageModel trip) {
    Color color;
    String label;
    final s = trip.status.toLowerCase();

    // Priorité au champ d'arrivée réelle proposé par l'utilisateur
    if (trip.hasArrived || s.contains('termin') || s.contains('complet') || s.contains('arriv')) {
      color = AppColors.secondary;
      label = "Terminé";
    } else if (s.contains('confir')) {
      color = Colors.green;
      label = "Confirmé";
    } else if (s.contains('en_cours') || s.contains('start')) {
      color = Colors.blue;
      label = "En cours";
    } else if (s.contains('annul') || s.contains('cancel')) {
      color = Colors.red;
      label = "Annulé";
    } else {
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
}

