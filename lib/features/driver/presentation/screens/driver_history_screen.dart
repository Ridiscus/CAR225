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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadVoyagesHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          children: [
            const DriverHeader(
              title: "Historique",
              showBack: true,
            ),
            Container(
              color: AppColors.primary,
              child: const TabBar(
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: [
                  Tab(text: "En cours / À venir"),
                  Tab(text: "Non effectués"),
                  Tab(text: "Effectués"),
                ],
              ),
            ),
            Expanded(
              child: Consumer<DriverProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  return TabBarView(
                    children: [
                      _buildTripList(provider.historyTrips.where((t) => t.status == 'en_cours' || t.status == 'confirmé' || t.status == 'en_attente').toList()),
                      _buildTripList(provider.historyTrips.where((t) => t.status == 'annulé').toList()),
                      _buildTripList(provider.historyTrips.where((t) => t.status == 'terminé' || t.status == 'completed').toList()),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripList(List<VoyageModel> trips) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_toggle_off_rounded, size: 64, color: Colors.grey[300]),
            const Gap(16),
            Text("Aucun voyage trouvé", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: trips.length,
      separatorBuilder: (context, index) => const Gap(12),
      itemBuilder: (context, index) {
        final trip = trips[index];
        return _buildHistoryItem(trip);
      },
    );
  }

  Widget _buildHistoryItem(VoyageModel trip) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isDone = trip.status == 'terminé' || trip.status == 'completed';
    final isCancelled = trip.status == 'annulé';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
                ? Colors.red.withOpacity(0.1) 
                : (isDone ? AppColors.secondary.withOpacity(0.1) : AppColors.primary.withOpacity(0.1)),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCancelled ? Icons.close : (isDone ? Icons.check : Icons.directions_bus),
              color: isCancelled ? Colors.red : (isDone ? AppColors.secondary : AppColors.primary),
              size: 20,
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
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  "Le ${dateFormat.format(trip.scheduledDepartureTime)} • ${trip.carRegistration}",
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCFD8DC), size: 20),
        ],
      ),
    );
  }
}
