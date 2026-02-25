import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../models/trip_model.dart';
import '../widgets/driver_header.dart';

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  DateTime? _selectedDate;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    List<TripModel> trips = driverProvider.historyTrips;

    // Filtrage par date si sélectionnée
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
          Padding(
            padding: const EdgeInsets.all(15.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Rechercher par immatriculation...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() {}),
            ),
          ),
          Expanded(
            child: trips.isEmpty
                ? const Center(child: Text("Aucun historique trouvé."))
                : ListView.builder(
                    padding: const EdgeInsets.all(15),
                    itemCount: trips.length,
                    itemBuilder: (context, index) {
                      final trip = trips[index];
                      // Filtrage par texte
                      if (_searchController.text.isNotEmpty &&
                          !trip.carRegistration.toLowerCase().contains(
                            _searchController.text.toLowerCase(),
                          )) {
                        return const SizedBox.shrink();
                      }
                      return _buildHistoryItem(trip);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(TripModel trip) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isCancelled = trip.status == 'cancelled';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.black.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isCancelled
                  ? Colors.red.withOpacity(0.1)
                  : AppColors.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCancelled ? Icons.close : Icons.check,
              color: isCancelled ? Colors.red : AppColors.secondary,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${trip.departureStation} ➔ ${trip.arrivalStation}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "Le ${dateFormat.format(trip.scheduledDepartureTime)} • ${trip.carRegistration}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            isCancelled ? "Annulé" : "Terminé",
            style: TextStyle(
              color: isCancelled ? Colors.red : AppColors.secondary,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
