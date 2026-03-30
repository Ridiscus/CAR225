import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';
import '../widgets/driver_header.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  DateTime? _selectedDate;
  String _selectedFilter = "Tous";

  final List<Map<String, String>> _filterOptions = [
    {"label": "Tous", "value": "Tous"},
    {"label": "Confirmés", "value": "confirmé"},
    {"label": "En cours", "value": "en_cours"},
    {"label": "Effectués", "value": "terminé"},
    {"label": "En attente", "value": "en_attente"},
    {"label": "Annulés", "value": "annulé"},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadVoyagesHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    List<VoyageModel> trips = driverProvider.historyTrips;

    // Filtrage par date si sélectionnée
    if (_selectedDate != null) {
      trips = trips.where((t) {
        return t.scheduledDepartureTime.day == _selectedDate!.day &&
            t.scheduledDepartureTime.month == _selectedDate!.month &&
            t.scheduledDepartureTime.year == _selectedDate!.year;
      }).toList();
    }

    // Filtrage par statut
    if (_selectedFilter != "Tous") {
      trips = trips.where((t) {
        final currentStatut = (t.status).toLowerCase();
        final filter = _selectedFilter.toLowerCase();
        // Supporte avec ou sans accent pour plus de sécurité
        return currentStatut == filter || 
               currentStatut.replaceAll('é', 'e') == filter.replaceAll('é', 'e');
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DriverHeader(
            title: "Historique",
            showProfile: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white),
                onPressed: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
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
          const Gap(20),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: _filterOptions.map((filter) {
                final isSelected = _selectedFilter == filter["value"];
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedFilter = filter["value"]!),
                    borderRadius: BorderRadius.circular(30),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : Colors.grey[50],
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey[200]!,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Text(
                        filter["label"]!,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Gap(20),
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppColors.primary,
                        ),
                        const Gap(8),
                        Text(
                          DateFormat(
                            'dd MMMM yyyy',
                            'fr_FR',
                          ).format(_selectedDate!),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(4),
                        GestureDetector(
                          onTap: () => setState(() => _selectedDate = null),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    "${trips.length} voyage${trips.length > 1 ? 's' : ''}",
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: trips.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: trips.length,
                    separatorBuilder: (context, index) => const Gap(12),
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      return InkWell(
                        onTap: () => _showTripDetails(context, trip),
                        borderRadius: BorderRadius.circular(20),
                        child: _buildHistoryItem(trip),
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
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history_toggle_off_rounded,
              size: 48,
              color: Colors.grey[300],
            ),
          ),
          const Gap(20),
          Text(
            _selectedDate != null ? "Aucun voyage ce jour" : "Historique vide",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const Gap(8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              _selectedDate != null
                  ? "Vous n'avez effectué aucun trajet à la date du ${DateFormat('dd MMMM yyyy', 'fr_FR').format(_selectedDate!)}."
                  : "Votre historique de voyages apparaîtra ici une fois que vous aurez terminé vos premiers trajets.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.5,
              ),
            ),
          ),
          if (_selectedDate != null) ...[
            const Gap(24),
            TextButton.icon(
              onPressed: () => setState(() => _selectedDate = null),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text("Afficher tout l'historique"),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
            ),
          ],
          const Gap(130),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(VoyageModel trip) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isCancelled = trip.status == 'annulé';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCancelled
                  ? Colors.red.withValues(alpha: 0.1)
                  : AppColors.secondary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCancelled ? Icons.close : Icons.check,
              color: isCancelled ? Colors.red : AppColors.secondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${trip.departureStation} âž” ${trip.arrivalStation}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Le ${dateFormat.format(trip.scheduledDepartureTime)} â€¢ ${trip.carRegistration}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[300], size: 20),
        ],
      ),
    );
  }

  void _showTripDetails(BuildContext context, VoyageModel trip) {
    final timeFormat = DateFormat('HH:mm');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
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
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Détails de l'historique",
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
              const Gap(24),
              _buildItineraryView(trip, timeFormat),
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
              _buildPriceInfo(trip.price),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text("FERMER"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'annulé':
      case 'cancelled':
        color = Colors.red;
        label = "Annulé";
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
      case 'confirmé':
        color = Colors.green;
        label = "Confirmé";
        break;
      case 'en_attente':
        color = Colors.orange;
        label = "En attente";
        break;
      default:
        color = Colors.grey;
        label = status.toUpperCase();
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

  Widget _buildItineraryView(VoyageModel trip, DateFormat timeFormat) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Column(
            children: [
              const Gap(4),
              const Icon(Icons.circle, color: AppColors.primary, size: 10),
              Expanded(
                child: Container(
                  width: 2,
                  color: AppColors.primary.withValues(alpha: 0.1),
                ),
              ),
              const Icon(Icons.location_on, color: AppColors.primary, size: 20),
              const Gap(4),
            ],
          ),
          const Gap(16),
          Expanded(
            child: Column(
              children: [
                _buildSheetStationRow(
                  "Départ",
                  trip.departureStation,
                  timeFormat.format(trip.scheduledDepartureTime),
                ),
                const Gap(24),
                _buildSheetStationRow(
                  "Arrivée",
                  trip.arrivalStation,
                  timeFormat.format(trip.scheduledArrivalTime),
                ),
              ],
            ),
          ),
        ],
      ),
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

  Widget _buildPriceInfo(double price) {
    return Container(
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
            "Recette totale",
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            "${price.toInt()} FCFA",
            style: const TextStyle(
              color: AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }
}

