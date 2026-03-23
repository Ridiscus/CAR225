import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';
import '../widgets/driver_header.dart';

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    List<VoyageModel> trips = driverProvider.activeTrips;

    if (_selectedDate != null) {
      trips = trips.where((t) {
        return t.scheduledDepartureTime.day == _selectedDate!.day &&
            t.scheduledDepartureTime.month == _selectedDate!.month &&
            t.scheduledDepartureTime.year == _selectedDate!.year;
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          DriverHeader(
            title: "Mes Voyages",
            showBack: true,
            showProfile: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now().add(const Duration(days: 90)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
              ),
              if (_selectedDate != null)
                IconButton(
                  icon: const Icon(Icons.clear, color: Colors.white),
                  onPressed: () => setState(() => _selectedDate = null),
                ),
            ],
          ),
          Expanded(
            child: trips.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _showTripDetails(context, trips[index]),
                          borderRadius: BorderRadius.circular(20),
                          child: _buildTripItem(trips[index]),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.event_busy_outlined,
              size: 40,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Aucun voyage prévu ",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedDate != null
                ? "Pour la date sélectionnée"
                : "Consultez votre planning plus tard",
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTripItem(VoyageModel trip) {
    final dateFormat = DateFormat('dd MMM yyyy', 'fr_FR');
    final timeFormat = DateFormat('HH:mm');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
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
                  trip.carRegistration,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    fontSize: 12,
                  ),
                ),
              ),
              _buildStatusBadge(trip),
            ],
          ),
          const SizedBox(height: 20),
          IntrinsicHeight(
            child: Row(
              children: [
                Column(
                  children: [
                    const Icon(Icons.circle, size: 8, color: AppColors.primary),
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    const Icon(
                      Icons.location_on,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              trip.departureStation,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeFormat.format(trip.scheduledDepartureTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              trip.arrivalStation,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            timeFormat.format(trip.scheduledArrivalTime),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 32),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                dateFormat.format(trip.scheduledDepartureTime),
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
              const Spacer(),
              Icon(Icons.people_outline, size: 16, color: Colors.grey[400]),
              const SizedBox(width: 6),
              Text(
                "${trip.passengersCount}/${trip.totalSeats}",
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(VoyageModel trip) {
    Color color;
    String label;
    final s = trip.status.toLowerCase();

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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showTripDetails(BuildContext context, VoyageModel trip) {
    final timeFormat = DateFormat('HH:mm');
    final fullDateFormat = DateFormat('EEEE dd MMMM yyyy', 'fr_FR');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          // Timer local pour la mise à jour du compte à rebours
          Timer? sheetTimer;
          if (trip.status == 'en_cours') {
            sheetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
              if (context.mounted) setSheetState(() {});
            });
          }

          final timeRemaining = trip.timeRemaining;
          final hours = timeRemaining.inHours.toString().padLeft(2, '0');
          final minutes = (timeRemaining.inMinutes % 60).toString().padLeft(2, '0');
          final seconds = (timeRemaining.inSeconds % 60).toString().padLeft(2, '0');

          return PopScope(
            onPopInvokedWithResult: (didPop, result) {
              sheetTimer?.cancel();
            },
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.85,
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: SafeArea(
                    bottom: true,
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
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "Détails du voyage",
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                            ),
                            _buildStatusBadge(trip),
                          ],
                        ),
                        const Gap(8),
                        Text(
                          "ID: ${trip.id}",
                          style: TextStyle(color: Colors.grey[400], fontSize: 12),
                        ),
                        
                        if (trip.status == 'en_cours') ...[
                          const Gap(20),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.timer_outlined, color: AppColors.primary, size: 20),
                                    const Gap(10),
                                    Text(
                                      "Temps restant : ",
                                      style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                                    ),
                                    Text(
                                      trip.tempsRestant ?? "$hours:$minutes:$seconds",
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: 'monospace',
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(8),
                                Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Colors.green,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const Gap(10),
                                    const Text(
                                      "Position GPS partagée",
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],

                        const Gap(24),
                        Text(
                          fullDateFormat
                              .format(trip.scheduledDepartureTime)
                              .toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Gap(20),
                        IntrinsicHeight(
                          child: Row(
                            children: [
                              Column(
                                children: [
                                  const Gap(4),
                                  const Icon(
                                    Icons.circle,
                                    color: AppColors.primary,
                                    size: 10,
                                  ),
                                  Expanded(
                                    child: Container(
                                      width: 2,
                                      color: AppColors.primary.withValues(alpha: 0.1),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.location_on,
                                    color: AppColors.primary,
                                    size: 20,
                                  ),
                                  const Gap(4),
                                ],
                              ),
                              const Gap(16),
                              Expanded(
                                child: Column(
                                  children: [
                                    _buildSheetStationRow(
                                      "Gare de départ",
                                      trip.departureStation,
                                      timeFormat.format(trip.scheduledDepartureTime),
                                    ),
                                    const Gap(24),
                                    _buildSheetStationRow(
                                      "Gare d'arrivée",
                                      trip.arrivalStation,
                                      timeFormat.format(trip.scheduledArrivalTime),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(32),
                        Row(
                          children: [
                            _buildDetailBox(
                              Icons.directions_bus_outlined,
                              "Véhicule",
                              trip.carRegistration,
                            ),
                            const Gap(12),
                            _buildDetailBox(
                              Icons.people_outline,
                              "Passagers",
                              "${trip.passengersCount} / ${trip.totalSeats}",
                            ),
                          ],
                        ),
                        const Gap(12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Tarif de base",
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              Text(
                                "${trip.price.toInt()} FCFA",
                                style: const TextStyle(
                                  color: AppColors.secondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(32),
                        _buildActionButtons(context, trip),
                        const Gap(16),
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: TextButton(
                            onPressed: () {
                              sheetTimer?.cancel();
                              Navigator.pop(context);
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey[600],
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text("FERMER"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, VoyageModel trip) {
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
            "Trajet terminé avec succès !",
            style: TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    final provider = context.read<DriverProvider>();

    return Column(
      children: [
        if (trip.status == 'en_attente' || trip.status == 'confirmé')
          Column(
            children: [
              if (trip.passengersCount == 0)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                      const Gap(10),
                      const Expanded(
                        child: Text(
                          "Au moins 1 passager doit être présent pour démarrer.",
                          style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.play_circle_filled_rounded),
                  onPressed: trip.passengersCount > 0
                      ? () {
                          Navigator.pop(context); // Close sheet
                          provider.markDeparture(trip.id);
                        }
                      : null, // Désactivé si 0 passager
                  style: ElevatedButton.styleFrom(
                    backgroundColor: trip.passengersCount > 0 ? AppColors.primary : Colors.grey[300],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                  label: const Text("DÉMARRER LE TRAJET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),

        if (trip.status != 'annulé') ...[
          const Gap(12),
          Row(
            children: [
              const Gap(10),
              if (trip.status == 'en_attente' || trip.status == 'confirmé')
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => _showCancelReasonDialog(context, trip),
                      label: const Text(
                        "ANNULER",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              if (trip.status == 'en_cours') ...[
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.flag_rounded),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () => _confirmFinishTrip(context, trip, provider),
                      label: const Text(
                        "TERMINER",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: SizedBox(
                    height: 55,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.warning_rounded),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      onPressed: () {
                         Navigator.pop(context); // Close sheet
                         provider.setSelectedTripForReport(trip);
                         provider.setIndex(3); // Go to reports tab
                      },
                      label: const Text(
                        "SIGNALER",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  void _showCancelReasonDialog(BuildContext context, VoyageModel trip) {
    final TextEditingController reasonController = TextEditingController();
    final provider = context.read<DriverProvider>();

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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.cancel_rounded,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    const Gap(20),
                    const Text(
                      "Annuler le Voyage",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    const Text(
                      "Veuillez indiquer le motif de l'annulation. Ce motif sera transmis à la gare.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(20),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: "Ex : Panne de véhicule, Problème personnel...",
                        filled: true,
                        fillColor: Colors.grey[50],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.red),
                        ),
                      ),
                    ),
                    const Gap(24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("RETOUR"),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final reason = reasonController.text.trim();
                              if (reason.length < 5) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Le motif doit faire au moins 5 caractères")),
                                );
                                return;
                              }
                              Navigator.pop(context); // Close dialog
                              final success = await provider.cancelVoyage(trip.id, reason: reason);
                              if (success && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text("Voyage annulé avec succès")),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text("ANNULER"),
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


  Widget _buildSheetStationRow(String label, String station, String time) {
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
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
        Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailBox(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: Colors.grey[400]),
            const Gap(12),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
            ),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmFinishTrip(BuildContext context, VoyageModel trip, DriverProvider provider) {
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
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.flag_rounded,
                        color: Colors.purple,
                        size: 40,
                      ),
                    ),
                    const Gap(20),
                    const Text(
                      "Arrivée à destination ?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    const Text(
                      "Voulez-vous vraiment terminer ce voyage ? Cette action est définitive.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 14,
                      ),
                    ),
                    const Gap(24),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "NON, PAS ENCORE",
                              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              Navigator.pop(context); // Close dialog
                              Navigator.pop(context); // Close sheet
                              await provider.markArrival(trip.id);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Voyage terminé ! Vous êtes maintenant disponible."),
                                    backgroundColor: Colors.purple,
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: const Text(
                              "OUI, TERMINER",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

