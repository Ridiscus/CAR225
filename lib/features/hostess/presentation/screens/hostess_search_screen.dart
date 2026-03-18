import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import 'hostess_booking_details_screen.dart';

class HostessSearchScreen extends StatefulWidget {
  const HostessSearchScreen({super.key});
  @override
  State<HostessSearchScreen> createState() => _HostessSearchScreenState();
}

class _HostessSearchScreenState extends State<HostessSearchScreen>
    with SingleTickerProviderStateMixin {
  DateTime _selectedDate = DateTime.now();
  bool _isSearching = false;
  String _selectedDeparture = '';
  String _selectedArrival = '';
  bool _showDepartureDropdown = false;
  bool _showArrivalDropdown = false;

  late final AnimationController _swapController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );

// On remplace la liste en dur par une liste vide qui se remplira via l'API
  List<String> _availableCities = [];
  bool _isLoadingCities = true; // Pour afficher un petit chargement au début

  List<Map<String, dynamic>> _filteredTrips = [];

  // Les listes déroulantes liront désormais cette liste dynamique
  List<String> get _departureCities => List.from(_availableCities)..sort();

  List<String> get _arrivalCities {
    if (_selectedDeparture.isEmpty) return List.from(_availableCities)..sort();
    return _availableCities.where((c) => c != _selectedDeparture).toList()..sort();
  }
  @override
  void initState() {
    super.initState();
    _filteredTrips = [];

    // On lance la récupération des villes juste après la construction de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialCities();
    });
  }

  // 🟢 LA NOUVELLE MÉTHODE QUI EXTRAIT LES VILLES DE TON API
  Future<void> _loadInitialCities() async {
    try {
      final repo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      // On appelle l'API avec la date d'aujourd'hui, mais SANS ville de départ ni d'arrivée
      // pour que le backend nous renvoie tous les trajets possibles.
      final String today = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

      final apiResponse = await repo.searchTickets(
        dateDepart: today,
        pointDepart: '', // Vide pour tout récupérer
        pointArrive: '', // Vide pour tout récupérer
      );

      if (apiResponse['success'] == true && apiResponse['routes'] != null) {
        // Un "Set" permet d'éviter les doublons automatiquement
        Set<String> extractedCities = {};

        // On parcourt ton JSON pour extraire toutes les villes !
        for (var route in apiResponse['routes']) {
          if (route['point_depart'] != null) extractedCities.add(route['point_depart']);
          if (route['point_arrive'] != null) extractedCities.add(route['point_arrive']);
        }

        if (mounted) {
          setState(() {
            _availableCities = extractedCities.toList();
            _isLoadingCities = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCities = false);
        // Si ça échoue, on peut mettre 2-3 villes par défaut pour ne pas bloquer l'hôtesse
        setState(() {
          _availableCities = ["Abidjan, Côte d'Ivoire", "Daloa, Côte d'Ivoire", "Bouaké, Côte d'Ivoire"];
        });
      }
    }
  }


  void _swapCities() {
    final tmp = _selectedDeparture;
    setState(() {
      _selectedDeparture = _selectedArrival;
      _selectedArrival = tmp;
      _showDepartureDropdown = false;
      _showArrivalDropdown = false;
    });
    _swapController.forward(from: 0);
  }

  void _closeAllDropdowns() => setState(() {
    _showDepartureDropdown = false;
    _showArrivalDropdown = false;
  });

  @override
  void dispose() {
    _swapController.dispose();
    super.dispose();
  }



  void _searchTrips() async {
    _closeAllDropdowns();

    if (_selectedDeparture.isEmpty || _selectedArrival.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Veuillez choisir un point de départ et d\'arrivée'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSearching = true);

    try {
      // 1. Formatage de la date (ex: 2026-03-15)
      final String formattedDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

      // 2. Instanciation du Repository (avec tes imports)
      final repo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      // 3. Appel à l'API
      final apiResponse = await repo.searchTickets(
        dateDepart: formattedDate,
        pointDepart: _selectedDeparture,
        pointArrive: _selectedArrival,
      );

      // 4. Transformation du JSON en liste pour ton UI
      List<Map<String, dynamic>> fetchedTrips = [];

      if (apiResponse['success'] == true && apiResponse['routes'] != null) {
        for (var route in apiResponse['routes']) {
          if (route['aller_horaires'] != null) {
            for (var horaire in route['aller_horaires']) {

              final int totalSeats = horaire['total_seats'] ?? 0;
              final int reserved = horaire['reserved_count'] ?? 0;
              final int availableSeats = totalSeats - reserved;
              String price = route['montant_billet'].toString().replaceAll('.00', '');

              fetchedTrips.add({
                'company': route['compagnie']['name'],
                'departure': route['point_depart'],
                'arrival': route['point_arrive'],
                'time': horaire['heure_depart'].substring(0, 5), // Coupe les secondes si "06:00:00"
                'seats': '$availableSeats place(s)',
                'status': route['has_retour'] == true ? 'Retour disponible' : 'Aller simple',
                'price': price,
                'route_id': route['id_group'],
                'horaire_id': horaire['id'],
              });
            }
          }
        }
      }

      // 5. Mise à jour de l'interface
      if (mounted) {
        setState(() {
          _filteredTrips = fetchedTrips;
          _isSearching = false;
        });

        if (fetchedTrips.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Aucun trajet trouvé pour cette date.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSearching = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: const Text('Erreur de connexion. Veuillez réessayer.'),
              backgroundColor: Colors.redAccent
          ),
        );
      }
    }
  }


  void _viewAllTrips() {
    setState(() {
      // 1. On vide les champs de sélection
      _selectedDeparture = '';
      _selectedArrival = '';

      // 2. On remet la date à aujourd'hui
      _selectedDate = DateTime.now();

      // 3. On vide la liste des résultats de recherche
      _filteredTrips = [];

      // 4. On ferme les menus déroulants s'ils étaient ouverts
      _showDepartureDropdown = false;
      _showArrivalDropdown = false;
    });

    // On efface les petits messages d'erreur éventuels en bas de l'écran
    ScaffoldMessenger.of(context).clearSnackBars();
  }


  void _reserveTrip(Map<String, dynamic> trip) {
    // 1. On formate la date globale sélectionnée par l'hôtesse
    final String formattedDate = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => HostessBookingDetailsScreen(
          departure: trip['departure'],
          arrival: trip['arrival'],
          isRoundTrip: trip['status'] == 'Retour disponible',
          horaireId: trip['horaire_id'],
          price: int.parse(trip['price'].toString()),
          time: trip['time'],
          // 2. 🟢 ON PASSE LA DATE FORMATÉE ICI AU LIEU DE trip['date']
          date: formattedDate,
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(title: 'Réservations', showLeading: false),
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          FocusScope.of(context).unfocus();
          _closeAllDropdowns();
        },
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
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
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
          _CityDropdownField(
            label: 'Point de départ',
            icon: Icons.location_on_rounded,
            value: _selectedDeparture,
            hint: 'Choisir une ville de départ',
            cities: _departureCities,
            isOpen: _showDepartureDropdown,
            onToggle: () => setState(() {
              _showDepartureDropdown = !_showDepartureDropdown;
              _showArrivalDropdown = false;
            }),
            onSelected: (city) => setState(() {
              _selectedDeparture = city;
              _selectedArrival = '';
              _showDepartureDropdown = false;
              _showArrivalDropdown = true;
            }),
            onClear: () => setState(() {
              _selectedDeparture = '';
              _selectedArrival = '';
              _showDepartureDropdown = false;
            }),
          ),

          // ── Bouton d'inversion ──
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
                const Gap(12),
                GestureDetector(
                  onTap: _swapCities,
                  child: AnimatedBuilder(
                    animation: _swapController,
                    builder: (ctx, child) => Transform.rotate(
                      angle: _swapController.value * 3.1415926,
                      child: child,
                    ),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.swap_vert_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                const Expanded(child: Divider(color: Color(0xFFEEEEEE))),
              ],
            ),
          ),

          _CityDropdownField(
            label: 'Point d\'arrivée',
            icon: Icons.flag_rounded,
            value: _selectedArrival,
            hint: _selectedDeparture.isEmpty
                ? 'Choisir d\'abord un départ'
                : 'Choisir une ville d\'arrivée',
            cities: _arrivalCities,
            isOpen: _showArrivalDropdown,
            onToggle: () => setState(() {
              _showArrivalDropdown = !_showArrivalDropdown;
              _showDepartureDropdown = false;
            }),
            onSelected: (city) => setState(() {
              _selectedArrival = city;
              _showArrivalDropdown = false;
            }),
            onClear: () => setState(() {
              _selectedArrival = '';
              _showArrivalDropdown = false;
            }),
          ),
          const Gap(12),
          _buildCompactDatePicker(),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: _isSearching ? null : _searchTrips,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.primary.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    icon: _isSearching
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.search_rounded, size: 20),
                    label: Text(
                      _isSearching ? 'Recherche...' : 'Rechercher',
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
              const Gap(10),
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _viewAllTrips,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1A1A1A),
                    side: const BorderSide(color: Color(0xFFE0E0E0)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  label: const Text(
                    'Restaurer',
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

  Widget _buildCompactDatePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Date du voyage',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF757575),
          ),
        ),
        const Gap(6),
        GestureDetector(
          onTap: () async {
            _closeAllDropdowns();
            final picked = await showDatePicker(
              context: context,
              initialDate: _selectedDate,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
              builder: (context, child) => Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: const ColorScheme.light(
                    primary: AppColors.primary,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _selectedDate = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F8F8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
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
                const Spacer(),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFBDBDBD),
                  size: 20,
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
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 48,
                  color: Colors.grey[400],
                ),
              ),
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
                'Modifiez vos critères de recherche',
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
        children: _filteredTrips.map((t) => _buildTripCard(t)).toList(),
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    // 🟢 1. LOGIQUE DE VÉRIFICATION DE L'HEURE
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;

    bool isPassed = false;
    if (isToday && trip['time'] != null) {
      try {
        final parts = trip['time'].toString().split(':');
        if (parts.length >= 2) {
          final tripHour = int.parse(parts[0]);
          final tripMinute = int.parse(parts[1]);
          // On crée un objet DateTime pour l'heure du trajet d'aujourd'hui
          final tripTime = DateTime(now.year, now.month, now.day, tripHour, tripMinute);

          // Si l'heure actuelle a dépassé l'heure du trajet, c'est expiré
          isPassed = now.isAfter(tripTime);
        }
      } catch (e) {
        // En cas de format d'heure inattendu, on ne bloque pas par défaut
        isPassed = false;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  trip['arrival'],
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ],
          ),
          const Gap(12),
          Row(
            children: [
              // 🟢 2. On met l'icône de temps en rouge si c'est dépassé
              _badge(
                  Icons.access_time,
                  trip['time'],
                  isPassed ? Colors.redAccent : const Color(0xFF00C853)
              ),
              const Gap(8),
              _badge(
                Icons.event_seat_rounded,
                trip['seats'],
                const Color(0xFF2196F3),
              ),
              const Gap(8),
              _badge(
                Icons.sync_rounded,
                trip['status'],
                const Color(0xFFFF9800),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFF0F0F0)),
          ),
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
                // 🟢 3. On adapte le bouton selon le statut "isPassed"
                child: ElevatedButton.icon(
                  onPressed: isPassed ? null : () => _reserveTrip(trip),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isPassed ? Colors.grey[300] : AppColors.primary,
                    foregroundColor: isPassed ? Colors.grey[600] : Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  icon: Icon(
                      isPassed ? Icons.block_rounded : Icons.check_circle_outline,
                      size: 18
                  ),
                  label: Text(
                    isPassed ? 'Dépassé' : 'Réserver',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
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

}

// ─── CITY DROPDOWN FIELD ────────────────────────────────────────────────────
class _CityDropdownField extends StatefulWidget {
  final String label;
  final IconData icon;
  final String value;
  final String hint;
  final List<String> cities;
  final bool isOpen;
  final VoidCallback onToggle;
  final ValueChanged<String> onSelected;
  final VoidCallback onClear;

  const _CityDropdownField({
    required this.label,
    required this.icon,
    required this.value,
    required this.hint,
    required this.cities,
    required this.isOpen,
    required this.onToggle,
    required this.onSelected,
    required this.onClear,
  });

  @override
  State<_CityDropdownField> createState() => _CityDropdownFieldState();
}

class _CityDropdownFieldState extends State<_CityDropdownField> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _query = '';

  @override
  void didUpdateWidget(_CityDropdownField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Réinitialise la recherche quand la dropdown se ferme
    if (!widget.isOpen && oldWidget.isOpen) {
      _searchController.clear();
      setState(() => _query = '');
    }
    // Auto-focus le champ de recherche à l'ouverture
    if (widget.isOpen && !oldWidget.isOpen) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<String> get _filtered {
    if (_query.isEmpty) return widget.cities;
    return widget.cities
        .where((c) => c.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = widget.value.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF757575),
          ),
        ),
        const Gap(6),

        // ── Champ cliquable (affiche la valeur ou le hint) ──
        GestureDetector(
          onTap: widget.onToggle,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: widget.isOpen
                  ? AppColors.primary.withValues(alpha: 0.04)
                  : const Color(0xFFF8F8F8),
              borderRadius: widget.isOpen
                  ? const BorderRadius.vertical(top: Radius.circular(12))
                  : BorderRadius.circular(12),
              border: Border.all(
                color: widget.isOpen
                    ? AppColors.primary
                    : const Color(0xFFE0E0E0),
                width: widget.isOpen ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  color: widget.isOpen || hasValue
                      ? AppColors.primary
                      : const Color(0xFFBDBDBD),
                  size: 20,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    hasValue ? widget.value : widget.hint,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasValue
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: hasValue
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFBDBDBD),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (hasValue)
                  GestureDetector(
                    onTap: widget.onClear,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Color(0xFF757575),
                      ),
                    ),
                  )
                else
                  AnimatedRotation(
                    turns: widget.isOpen ? 0.5 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFBDBDBD),
                      size: 22,
                    ),
                  ),
              ],
            ),
          ),
        ),

        // ── Liste déroulante : animation HAUT → BAS ──
        ClipRect(
          child: AnimatedAlign(
            alignment: Alignment.topCenter,
            heightFactor: widget.isOpen ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeInOutCubic,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                border: Border.all(color: AppColors.primary, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Champ de recherche ──
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF1A1A1A),
                      ),
                      decoration: InputDecoration(
                        hintText: 'Rechercher une ville...',
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFBDBDBD),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: Color(0xFF9E9E9E),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: const Color(0xFFF8F8F8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8E8E8),
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF0F0F0)),

                  // ── Liste filtrée ──
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: _filtered.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.search_off_rounded,
                                  color: Colors.grey[400],
                                  size: 20,
                                ),
                                const Gap(10),
                                Flexible(
                                  child: Text(
                                    'Aucune ville pour "$_query"',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shrinkWrap: true,
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const Divider(
                              height: 1,
                              indent: 16,
                              endIndent: 16,
                              color: Color(0xFFF5F5F5),
                            ),
                            itemBuilder: (ctx, i) {
                              final city = _filtered[i];
                              final selected = city == widget.value;
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => widget.onSelected(city),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 11,
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? AppColors.primary
                                                : AppColors.primary.withValues(
                                                    alpha: 0.08,
                                                  ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Icon(
                                            Icons.location_city_rounded,
                                            color: selected
                                                ? Colors.white
                                                : AppColors.primary,
                                            size: 16,
                                          ),
                                        ),
                                        const Gap(12),
                                        Expanded(
                                          child: _highlightText(
                                            city,
                                            _query,
                                            selected,
                                          ),
                                        ),
                                        if (selected)
                                          const Icon(
                                            Icons.check_circle_rounded,
                                            color: AppColors.primary,
                                            size: 18,
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _highlightText(String city, String query, bool selected) {
    if (query.isEmpty) {
      return Text(
        city,
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : const Color(0xFF1A1A1A),
        ),
      );
    }
    final lo = city.toLowerCase();
    final lq = query.toLowerCase();
    final start = lo.indexOf(lq);
    if (start == -1) {
      return Text(
        city,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF1A1A1A),
        ),
      );
    }
    final end = start + query.length;
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : const Color(0xFF1A1A1A),
        ),
        children: [
          TextSpan(text: city.substring(0, start)),
          TextSpan(
            text: city.substring(start, end),
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              background: Paint()
                ..color = AppColors.primary.withValues(alpha: 0.15)
                ..style = PaintingStyle.fill,
            ),
          ),
          TextSpan(text: city.substring(end)),
        ],
      ),
    );
  }
}
