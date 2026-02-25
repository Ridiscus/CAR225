import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';
import 'hostess_booking_details_screen.dart';

class HostessSearchScreen extends StatefulWidget {
  const HostessSearchScreen({super.key});
  @override
  State<HostessSearchScreen> createState() => _HostessSearchScreenState();
}

class _HostessSearchScreenState extends State<HostessSearchScreen> {
  final TextEditingController _departureController = TextEditingController();
  final TextEditingController _arrivalController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  // État de chargement
  bool _isSearching = false;

  // Liste complète des voyages
  final List<Map<String, dynamic>> _allTrips = [
    {
      'company': 'UNION DES TRANSPORTS DE BOUAKE',
      'departure': 'Abidjan, Côte d\'Ivoire',
      'arrival': 'Korhogo, Côte d\'Ivoire',
      'time': '06:30',
      'seats': '12 place(s)',
      'status': 'Retour disponible',
      'price': '12000',
    },
    {
      'company': 'UNION DES TRANSPORTS DE BOUAKE',
      'departure': 'Korhogo, Côte d\'Ivoire',
      'arrival': 'Abidjan, Côte d\'Ivoire',
      'time': '08:00',
      'seats': '8 place(s)',
      'status': 'Retour disponible',
      'price': '12000',
    },
    {
      'company': 'TRANSPORT RAPIDE DU SUD',
      'departure': 'Abidjan, Côte d\'Ivoire',
      'arrival': 'Yamoussoukro, Côte d\'Ivoire',
      'time': '07:00',
      'seats': '20 place(s)',
      'status': 'Retour disponible',
      'price': '5000',
    },
  ];

  // Liste filtrée des voyages
  List<Map<String, dynamic>> _filteredTrips = [];

  @override
  void initState() {
    super.initState();
    // Au démarrage, afficher tous les voyages
    _filteredTrips = List.from(_allTrips);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(
        title: 'Vendre des Tickets',
        showLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom + 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchCard(),
              const Gap(20),
              _buildAvailableTrips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard() {
    return Container(
      margin: const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rechercher un trajet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const Gap(20),
          _buildCompactSearchField(
            label: 'Départ ',
            icon: Icons.location_on_outlined,
            controller: _departureController,
            hint: 'Ville de...',
          ),
          const Gap(12),
          _buildCompactSearchField(
            label: 'Arrivée',
            icon: Icons.flag_outlined,
            controller: _arrivalController,
            hint: 'Ville...',
          ),
          const Gap(12),
          _buildCompactDatePicker(),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchTrips,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSearching
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.search, size: 20),
                    label: Text(
                      _isSearching ? 'En cours...' : 'Rechercher',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(10),
              SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _viewAllTrips,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.list_rounded, size: 20),
                  label: const Text(
                    'Voir tous',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSearchField({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF757575),
          ),
        ),
        const Gap(6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14, color: Color(0xFFBDBDBD)),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE0E0E0), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF757575),
          ),
        ),
        const Gap(6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  color: AppColors.primary,
                  size: 20,
                ),
                const Gap(12),
                Text(
                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableTrips() {
    if (_filteredTrips.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[400]),
              const Gap(16),
              Text(
                'Aucun voyage trouvé',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const Gap(8),
              Text(
                'Essayez de modifier vos critères de recherche',
                style: TextStyle(fontSize: 14, color: Colors.grey[500]),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: _filteredTrips.map((trip) => _buildTripCard(trip)).toList(),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.directions_bus_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const Gap(12),
              Expanded(
                child: Text(
                  trip['company'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Expanded(
                child: Text(
                  trip['departure'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.primary,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  trip['arrival'],
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              _buildInfoBadge(
                Icons.access_time,
                trip['time'],
                const Color(0xFF00C853),
              ),
              const Gap(8),
              _buildInfoBadge(
                Icons.event_seat_rounded,
                trip['seats'],
                const Color(0xFF2196F3),
              ),
              const Gap(8),
              _buildInfoBadge(
                Icons.sync_rounded,
                trip['status'],
                const Color(0xFFFF9800),
              ),
            ],
          ),
          const Gap(12),
          const Divider(height: 1, color: Color(0xFFF0F0F0)),
          const Gap(12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${trip['price']} FCFA',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
              ),
              SizedBox(
                height: 40,
                child: ElevatedButton.icon(
                  onPressed: () => _reserveTrip(trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: const Icon(Icons.check_circle_outline, size: 18),
                  label: const Text(
                    'Réserver',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBadge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _searchTrips() async {
    // Validation avant de commencer la recherche
    if (_departureController.text.isEmpty && _arrivalController.text.isEmpty) {
      // Fermer les SnackBars existants avant d'en afficher un nouveau
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Veuillez entrer un point de départ ou un point d\'arrivée',
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          dismissDirection: DismissDirection.horizontal,
          showCloseIcon: false,
          closeIconColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }

    // Activer l'état de chargement
    setState(() {
      _isSearching = true;
    });

    // Simuler un délai de recherche (1.5 secondes)
    await Future.delayed(const Duration(milliseconds: 1500));

    // Vérifier que le widget est toujours monté
    if (!mounted) return;

    // Effectuer la recherche
    setState(() {
      final departure = _departureController.text.trim().toLowerCase();
      final arrival = _arrivalController.text.trim().toLowerCase();

      if (departure.isEmpty && arrival.isEmpty) {
        // Si aucun critère, afficher tous les voyages
        _filteredTrips = List.from(_allTrips);
      } else {
        // Filtrer selon les critères
        _filteredTrips = _allTrips.where((trip) {
          final tripDeparture = trip['departure'].toString().toLowerCase();
          final tripArrival = trip['arrival'].toString().toLowerCase();

          final matchDeparture =
              departure.isEmpty || tripDeparture.contains(departure);
          final matchArrival = arrival.isEmpty || tripArrival.contains(arrival);

          return matchDeparture && matchArrival;
        }).toList();
      }

      // Désactiver l'état de chargement
      _isSearching = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_filteredTrips.length} voyage(s) trouvé(s)'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        showCloseIcon: false,
        closeIconColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _viewAllTrips() {
    setState(() {
      // Réinitialiser les champs
      _departureController.clear();
      _arrivalController.clear();
      _selectedDate = DateTime.now();

      // Afficher tous les voyages
      _filteredTrips = List.from(_allTrips);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Tous les voyages affichés'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.horizontal,
        showCloseIcon: false,
        closeIconColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _reserveTrip(Map<String, dynamic> trip) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => HostessBookingDetailsScreen(
          departure: trip['departure'],
          arrival: trip['arrival'],
          isRoundTrip: false,
        ),
      ),
    );
  }
}
