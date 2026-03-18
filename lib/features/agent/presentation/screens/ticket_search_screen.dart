/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import 'scan_result_screen.dart';
import 'package:flutter/cupertino.dart';

class TicketSearchScreen extends StatefulWidget {
  const TicketSearchScreen({super.key});
  @override
  State<TicketSearchScreen> createState() => _TicketSearchScreenState();
}

class _TicketSearchScreenState extends State<TicketSearchScreen> {
  // 1. VARIABLES D'ÉTAT & CONTROLLERS
  final TextEditingController _searchController = TextEditingController();

  // 2. CYCLE DE VIE (Lifecycle)
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 3. LOGIQUE & ACTIONS
  void _performSearch(String query) {
    if (query.isEmpty) return;
    _searchController.clear();
    // Navigation immédiate vers l'écran de résultat
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ScanResultScreen(ticketReference: query),
      ),
    );
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onSubmitted: _performSearch,
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
            color: Colors.black.withOpacity(0.1),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'RECHERCHES RÉCENTES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const Gap(16),
        _buildRecentSearchItem('TKT-2026-882', 'Aujourd\'hui'),
        _buildRecentSearchItem('TKT-2026-105', 'Hier'),
        _buildRecentSearchItem('TKT-2026-094', 'Il y a 2 jours'),
        const Gap(40),
        const Text(
          'CONSEILS DE RECHERCHE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const Gap(16),
        _buildTipItem(
          Icons.info_outline_rounded,
          'Utilisez la référence complète du billet pour un résultat précis.',
        ),
        _buildTipItem(
          Icons.history_rounded,
          'L\'historique des recherches est conservé localement.',
        ),
      ],
    );
  }

  Widget _buildRecentSearchItem(String reference, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        onTap: () => _performSearch(reference),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.history, color: Color(0xFF64748B), size: 20),
        ),
        title: Text(
          reference,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          date,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.6)),
          const Gap(12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Rechercher un billet',
        showLeading: false,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Gap(30),
                          const Text(
                            'Veuillez saisir la référence du billet ci-dessous',
                            style: TextStyle(
                              color: Color(0xFF78909C),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Gap(25),
                          _buildSearchField(),
                          const Gap(40),
                          _buildEmptyState(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/



import 'package:car225/features/agent/presentation/screens/scan_result_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/repositories/agent_repository_impl.dart';
import '../widgets/custom_app_bar.dart';
import 'package:flutter/cupertino.dart';

class TicketSearchScreen extends StatefulWidget {
  const TicketSearchScreen({super.key});
  @override
  State<TicketSearchScreen> createState() => _TicketSearchScreenState();
}


class _TicketSearchScreenState extends State<TicketSearchScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 🟢 Initialisation du Repository
  late final AgentRepositoryImpl _repository;
  bool _isSearching = false;
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _loadRecentSearches();
    _repository = AgentRepositoryImpl(remoteDataSource: AgentRemoteDataSourceImpl());
  }


  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 🟢 LOGIQUE DE RECHERCHE CONNECTÉE À L'API
  /*void _performSearch(String query) async {
    if (query.isEmpty || _isSearching) return;

    FocusScope.of(context).unfocus();
    setState(() => _isSearching = true);

    try {
      // On utilise la méthode que tu as déjà dans ton repository
      // Note : On n'a pas besoin de récupérer le résultat ici car le ScanResultScreen
      // fait déjà son propre fetch au initState via la référence.

      setState(() => _isSearching = false);

      // On navigue vers l'écran de résultat
      // ⚠️ Note : Comme c'est une recherche manuelle "hors contexte scan",
      // on peut passer des IDs par défaut ou null si ton ScanResultScreen le permet.
      if (mounted) {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => ScanResultScreen(
              ticketReference: query.trim().toUpperCase(),
              isManual: true,
              vehiculeId: 0, // Id temporaire ou à récupérer si nécessaire
              programmeId: 0, // Id temporaire
            ),
          ),
        );
      }

      _searchController.clear();

    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erreur : ${e.toString().replaceAll("Exception: ", "")}"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }*/

  void _performSearch(String query) async {
    final cleanQuery = query.trim().toUpperCase();
    if (cleanQuery.isEmpty) return;

    // 🟢 Sauvegarder la recherche localement
    await _saveSearch(cleanQuery);

    FocusScope.of(context).unfocus();

    // Navigation vers le résultat (ton code précédent)
    if (mounted) {
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (context) => ScanResultScreen(
            ticketReference: cleanQuery,
            isManual: true,
            vehiculeId: 0,
            programmeId: 0,
          ),
        ),
      );
    }
    _searchController.clear();
  }


  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // On récupère la liste, sinon une liste vide
      _recentSearches = prefs.getStringList('recent_tickets') ?? [];
    });
  }

  Future<void> _saveSearch(String reference) async {
    final prefs = await SharedPreferences.getInstance();

    // On nettoie la liste : on enlève si elle existe déjà (pour la remettre en haut)
    _recentSearches.remove(reference);
    // On l'ajoute au début
    _recentSearches.insert(0, reference);

    // On garde seulement les 5 dernières recherches
    if (_recentSearches.length > 5) {
      _recentSearches = _recentSearches.sublist(0, 5);
    }

    await prefs.setStringList('recent_tickets', _recentSearches);
    setState(() {});
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Rechercher un billet',
        showLeading: false,
      ),
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Gap(30),
                    const Text(
                      'Veuillez saisir la référence du billet ci-dessous',
                      style: TextStyle(color: Color(0xFF78909C), fontSize: 14),
                    ),
                    const Gap(25),
                    _buildSearchField(),
                    if (_isSearching) // 🟢 Petit indicateur de chargement
                      const Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    const Gap(40),
                    _buildEmptyState(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      onSubmitted: _performSearch,
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
            color: Colors.black.withOpacity(0.1),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_recentSearches.isNotEmpty) ...[
          const Text(
            'RECHERCHES RÉCENTES',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: Color(0xFF94A3B8),
              letterSpacing: 1.2,
            ),
          ),
          const Gap(16),
          // 🟢 On génère les items à partir de la liste SharedPreferences
          ..._recentSearches.map((ref) => _buildRecentSearchItem(ref, 'Recherche récente')).toList(),
          const Gap(40),
        ],

        const Text(
          'CONSEILS DE RECHERCHE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF94A3B8),
            letterSpacing: 1.2,
          ),
        ),
        const Gap(16),
        _buildTipItem(
          Icons.info_outline_rounded,
          'Utilisez la référence complète du billet pour un résultat précis.',
        ),
        _buildTipItem(
          Icons.history_rounded,
          'L\'historique des recherches est conservé localement.',
        ),
      ],
    );
  }

  Widget _buildRecentSearchItem(String reference, String date) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: ListTile(
        onTap: () => _performSearch(reference),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.history, color: Color(0xFF64748B), size: 20),
        ),
        title: Text(
          reference,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          date,
          style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: Color(0xFFCBD5E1),
        ),
      ),
    );
  }

  Widget _buildTipItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary.withOpacity(0.6)),
          const Gap(12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

}