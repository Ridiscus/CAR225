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
    {
      'company': 'UTB EXPRESS',
      'departure': 'Bouaké, Côte d\'Ivoire',
      'arrival': 'Abidjan, Côte d\'Ivoire',
      'time': '09:00',
      'seats': '15 place(s)',
      'status': 'Retour disponible',
      'price': '7500',
    },
    {
      'company': 'UTB EXPRESS',
      'departure': 'Man, Côte d\'Ivoire',
      'arrival': 'Abidjan, Côte d\'Ivoire',
      'time': '05:30',
      'seats': '10 place(s)',
      'status': 'Aller simple',
      'price': '9000',
    },
  ];

  List<Map<String, dynamic>> _filteredTrips = [];

  List<String> get _departureCities =>
      _allTrips.map((t) => t['departure'] as String).toSet().toList()..sort();

  List<String> get _arrivalCities {
    if (_selectedDeparture.isEmpty) {
      return _allTrips.map((t) => t['arrival'] as String).toSet().toList()
        ..sort();
    }
    return _allTrips
        .where((t) => t['departure'] == _selectedDeparture)
        .map((t) => t['arrival'] as String)
        .toSet()
        .toList()
      ..sort();
  }

  @override
  void initState() {
    super.initState();
    _filteredTrips = List.from(_allTrips);
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
              _badge(Icons.access_time, trip['time'], const Color(0xFF00C853)),
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

  void _searchTrips() async {
    _closeAllDropdowns();
    if (_selectedDeparture.isEmpty && _selectedArrival.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Veuillez choisir un point de départ ou d\'arrivée',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }
    setState(() => _isSearching = true);
    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() {
      _filteredTrips = _allTrips.where((trip) {
        final matchDep =
            _selectedDeparture.isEmpty ||
            trip['departure'] == _selectedDeparture;
        final matchArr =
            _selectedArrival.isEmpty || trip['arrival'] == _selectedArrival;
        return matchDep && matchArr;
      }).toList();
      _isSearching = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_filteredTrips.length} voyage(s) trouvé(s)'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _viewAllTrips() {
    setState(() {
      _selectedDeparture = '';
      _selectedArrival = '';
      _selectedDate = DateTime.now();
      _filteredTrips = List.from(_allTrips);
      _showDepartureDropdown = false;
      _showArrivalDropdown = false;
    });
    ScaffoldMessenger.of(context).clearSnackBars();
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
