import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/agent_header.dart';

class TicketSearchScreen extends StatefulWidget {
  const TicketSearchScreen({super.key});
  @override
  State<TicketSearchScreen> createState() => _TicketSearchScreenState();
}

class _TicketSearchScreenState extends State<TicketSearchScreen> {
  // 1. VARIABLES D'ÉTAT & CONTROLLERS
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = false;
  bool _isLoading = false;

  // 2. CYCLE DE VIE (Lifecycle)
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 3. LOGIQUE & ACTIONS
  void _performSearch(String query) async {
    if (query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _hasSearched = false;
    });

    // Simulation d'une recherche (1 seconde)
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isLoading = false;
        _hasSearched = true;
      });
    }
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onSubmitted: _performSearch,
      onChanged: (value) {
        if (value.isEmpty) {
          setState(() {
            _hasSearched = false;
          });
        }
      },
      decoration: InputDecoration(
        hintText: 'Entrez la référence du billet',
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
        prefixIcon: const Icon(
          Icons.search_rounded,
          color: AppColors.primary,
          size: 28,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: BorderSide(
            color: Colors.black.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(25),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        children: [
          const Gap(60),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFECEFF1)),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 48,
              color: Color(0xFFCFD8DC),
            ),
          ),
          const Gap(24),
          const Text(
            'Aucune recherche effectuée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const Gap(10),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Saisissez un numéro de billet ou le nom d\'un client pour voir les détails de sa réservation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF90A4AE),
                fontSize: 14,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Résultat trouvé',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F5E9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'VALIDE',
                style: TextStyle(
                  color: Color(0xFF2E7D32),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const Gap(25),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFF0F2F5)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow(
                Icons.person_outline_rounded,
                'PASSAGER',
                'Bakayoko Moussa',
              ),
              _buildDivider(),
              _buildDetailRow(
                Icons.confirmation_number_outlined,
                'N° BILLET',
                _searchController.text.toUpperCase(),
              ),
              _buildDivider(),
              _buildDetailRow(
                Icons.location_on_outlined,
                'DÉPART',
                'Gare de Yamoussoukro',
              ),
              _buildDivider(),
              _buildDetailRow(
                Icons.flag_outlined,
                'DESTINATION',
                'Gare d\'Abidjan (Adjamé)',
              ),
              _buildDivider(),
              _buildDetailRow(
                Icons.calendar_today_outlined,
                'DATE & HEURE',
                'Aujourd\'hui • 14:00',
              ),
              _buildDivider(),
              _buildDetailRow(
                Icons.airline_seat_recline_normal_outlined,
                'PLACE & CLASSE',
                'Siège #14',
              ),
            ],
          ),
        ),
        const Gap(40),
      ],
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFFB0BEC5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const Gap(2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(color: Color.fromARGB(230, 232, 229, 229), height: 24);
  }

  Widget _buildLoader() {
    return Center(
      child: Column(
        children: [
          const Gap(60),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 80,
                width: 80,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.primary.withOpacity(0.1),
                  ),
                ),
              ),
              const SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              Icon(
                Icons.search_rounded,
                color: AppColors.primary.withOpacity(0.5),
                size: 24,
              ),
            ],
          ),
          const Gap(30),
          const Text(
            'Recherche en cours...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF78909C),
              letterSpacing: 0.5,
            ),
          ),
          const Gap(8),
          Text(
            'Nous vérifions la base de données',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF78909C).withValues(alpha: 0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // 5. MÉTHODE BUILD (Assemblage Final)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- HEADER PORTAIL AGENT ---
              const AgentHeader(),
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Gap(35),
                      const Text(
                        'Recherche de billet',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF263238),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const Gap(8),
                      const Text(
                        'Vérifiez un billet en saisissant la référence du billet',
                        style: TextStyle(
                          color: Color(0xFF78909C),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(30),
                      _buildSearchField(),
                      const Gap(40),
                      if (_isLoading)
                        _buildLoader()
                      else if (_hasSearched)
                        _buildSearchResults()
                      else
                        _buildEmptyState(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
