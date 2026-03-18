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
              _buildStatusBadge(trip.status),
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

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
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
      case 'confirmé':
        color = Colors.green;
        label = "Confirmé";
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
                            _buildStatusBadge(trip.status),
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
                                      "$hours:$minutes:$seconds",
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
                              "${trip.passengersCount}/${trip.totalSeats}",
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
                () {
                  Navigator.pop(context); // Close sheet
                  provider.confirmVoyage(trip.id);
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              label: const Text("CONFIRMER LE VOYAGE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
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
                "Êtes-vous sûr de vouloir marquer le départ de ce trajet ?",
                Icons.play_circle_fill_rounded,
                AppColors.primary,
                () {
                  Navigator.pop(context); // Close sheet
                  provider.markDeparture(trip.id);
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              label: const Text("DÉMARRER LE TRAJET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),

        if (trip.status != 'annulé') ...[
          const Gap(12),
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.warning_amber_rounded),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: () {
                Navigator.pop(context); // Close sheet
                provider.setSelectedTripForReport(trip);
                provider.setIndex(3); // Navigue vers l'onglet Signalements
              },
              label: const Text("SIGNALER UN PROBLÈME", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: iconColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, color: iconColor, size: 36),
                    ),
                    const Gap(20),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const Gap(12),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.5,
                      ),
                    ),
                    const Gap(32),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                            ),
                            child: const Text(
                              "ANNULER",
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
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
                              "CONFIRMER",
                              style: TextStyle(fontWeight: FontWeight.bold),
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
}

