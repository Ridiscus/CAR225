import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:car225/core/theme/app_colors.dart';

// 🟢 N'oublie pas d'importer tes services !
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';

import 'hostess_main_wrapper.dart';
import '../widgets/hostess_header.dart';

class HostessHomeScreen extends StatefulWidget {
  const HostessHomeScreen({super.key});
  @override
  State<HostessHomeScreen> createState() => _HostessHomeScreenState();
}

class _HostessHomeScreenState extends State<HostessHomeScreen> {
  // 🟢 Nouvelles variables d'état pour les données dynamiques
  bool _isLoading = true;
  String _errorMessage = '';

  int _ventesAujourdhui = 0;
  num _revenuAujourdhui = 0;
  List<dynamic> _recentSales = [];

  @override
  void initState() {
    super.initState();
    // Lance la récupération des données au démarrage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
    });
  }


  Future<void> _fetchDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final repo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      final response = await repo.getHostessDashboard();

      if (response['success'] == true) {
        setState(() {
          // 🟢 2. On parse tout en .toString() d'abord pour éviter l'erreur "String is not a subtype of int"
          _ventesAujourdhui = int.tryParse(response['stats']['ventes_aujourdhui'].toString()) ?? 0;
          _revenuAujourdhui = num.tryParse(response['stats']['revenu_aujourdhui'].toString()) ?? 0;

          _recentSales = response['recent_reservations'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Impossible de charger les données.";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Erreur de connexion : $e";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 1. HEADER FIXE
          const HostessHeader(),

          // 2. CONTENU SCROLLABLE (Avec Pull-to-refresh !)
          Expanded(
            child: RefreshIndicator(
              onRefresh: _fetchDashboardData, // 🟢 Permet de rafraîchir en tirant
              color: AppColors.primary,
              backgroundColor: Colors.white,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDashboardHeader(),
                    const Gap(10),

                    // 🟢 Gestion de l'affichage (Chargement, Erreur ou Données)
                    if (_isLoading)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
                      )
                    else if (_errorMessage.isNotEmpty)
                      _buildErrorState()
                    else ...[
                        _buildMetricsGrid(),
                        const Gap(20),
                        _buildActionButton(),
                        const Gap(30),
                        _buildSalesTableHeader(),
                        const Gap(12),
                        _buildRecentSales(),
                      ],

                    const Gap(120), // Espace en bas pour le menu
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 🟢 Widget pour afficher les erreurs
  Widget _buildErrorState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 40),
          const Gap(10),
          Text(
            _errorMessage,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
          ),
          const Gap(10),
          ElevatedButton(
            onPressed: _fetchDashboardData,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Réessayer'),
          )
        ],
      ),
    );
  }

  Widget _buildDashboardHeader() {
    return const Padding(
      padding: EdgeInsets.fromLTRB(0, 20, 0, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tableau de bord',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -0.5,
                ),
              ),
              Gap(4),
              Text(
                'Vue d\'ensemble des ventes du jour',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF757575),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _DigitalClock(),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    // 🟢 Formatage du prix pour avoir des espaces (ex: 450 000)
    final formatter = NumberFormat('#,###', 'fr_FR');
    final formattedRevenue = formatter.format(_revenuAujourdhui);

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Tickets vendus',
            value: _ventesAujourdhui.toString(), // 🟢 Dynamique
            subtitle: 'Aujourd\'hui',
            icon: Icons.confirmation_number_rounded,
            iconColor: AppColors.primary,
            iconBgColor: const Color(0xFFFFF3E0),
          ),
        ),
        const Gap(12),
        Expanded(
          child: _buildMetricCard(
            title: 'Revenus du jour',
            value: formattedRevenue, // 🟢 Dynamique
            subtitle: 'FCFA',
            icon: Icons.account_balance_wallet_rounded,
            iconColor: AppColors.primary,
            iconBgColor: const Color(0xFFFFF3E0),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
  }) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 26, // Légèrement réduit pour éviter que les grands nombres dépassent
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF9E9E9E),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          final state = context.findAncestorStateOfType<HostessMainWrapperState>();
          if (state != null) state.setIndex(1);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.confirmation_number_rounded, size: 22),
            Gap(10),
            Text(
              'Vendre un ticket',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesTableHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Dernières ventes',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.3,
          ),
        ),
        TextButton(
          onPressed: () {
            final state = context.findAncestorStateOfType<HostessMainWrapperState>();
            if (state != null) state.setIndex(2);
          },
          child: const Row(
            children: [
              Text(
                'Voir tout',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              Gap(4),
              Icon(Icons.arrow_forward, color: AppColors.primary, size: 16),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentSales() {
    // 🟢 Gestion du cas où la liste est vide
    if (_recentSales.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Column(
          children: [
            Icon(Icons.receipt_long_rounded, color: Colors.grey, size: 40),
            Gap(10),
            Text(
              "Aucune vente récente.",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _recentSales.map((sale) => _buildSaleCard(sale)).toList(),
    );
  }



  Widget _buildSaleCard(dynamic sale) {
    // 🟢 3. On utilise les VRAIES clés renvoyées par ton API
    final id = sale['reference']?.toString() ?? sale['id']?.toString() ?? 'N/A';

    // Concaténation du nom et prénom
    final nom = sale['passager_nom'] ?? '';
    final prenom = sale['passager_prenom'] ?? '';
    final passenger = '$nom $prenom'.trim().isEmpty ? 'Client inconnu' : '$nom $prenom';

    // Ton API ne renvoie pas le nom du trajet complet ici, tu peux adapter selon tes besoins
    final route = 'Trajet standard'; // À modifier si tu as les noms des gares dans l'API

    // Nettoyage de la date (ex: 2026-03-12T00:00:00.000000Z -> 12/03/2026)
    String date = '--';
    if (sale['date_voyage'] != null) {
      try {
        final parsedDate = DateTime.parse(sale['date_voyage']);
        date = DateFormat('dd/MM/yyyy').format(parsedDate);
      } catch (e) {
        date = sale['date_voyage'].toString().substring(0, 10);
      }
    }

    final time = sale['heure_depart'] ?? '--';
    final seat = sale['seat_number']?.toString() ?? '-';

    // Formatage propre du montant (enlève les .00 si présent)
    final amountDouble = num.tryParse(sale['montant'].toString()) ?? 0;
    final amount = NumberFormat('#,###', 'fr_FR').format(amountDouble);

    final status = sale['statut'] ?? 'en attente';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showSaleDetails(context, sale),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    _buildStatusBadge(status),
                  ],
                ),
                const Gap(8),
                Text(
                  passenger,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Gap(6),
                Row(
                  children: [
                    const Icon(
                      Icons.route_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const Gap(6),
                    Expanded(
                      child: Text(
                        route,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_rounded,
                      size: 14,
                      color: Color(0xFF94A3B8),
                    ),
                    const Gap(6),
                    Text(
                      '$date • $time',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Place $seat',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Text(
                      '$amount FCFA',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1E293B),
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
  }

  void _showSaleDetails(BuildContext context, dynamic sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSaleDetailsContent(context, sale),
    );
  }
  Widget _buildSaleDetailsContent(BuildContext context, dynamic sale) {
    // 🟢 1. Mapping sécurisé avec les VRAIES clés de ton API
    final id = sale['reference']?.toString() ?? sale['id']?.toString() ?? 'N/A';

    // Concaténation du nom et prénom pour le passager
    final nom = sale['passager_nom']?.toString() ?? '';
    final prenom = sale['passager_prenom']?.toString() ?? '';
    final passenger = '$nom $prenom'.trim().isEmpty ? 'Client inconnu' : '$nom $prenom';

    // Ton API ne renvoyant pas les noms des gares dans ce payload, on met une valeur par défaut
    final route = 'Trajet standard';

    // Formatage de la date (ex: 2026-03-12T00:00:00.000000Z -> 12/03/2026)
    String date = '--';
    if (sale['date_voyage'] != null) {
      try {
        final parsedDate = DateTime.parse(sale['date_voyage'].toString());
        date = DateFormat('dd/MM/yyyy').format(parsedDate);
      } catch (e) {
        // En cas d'erreur de parsing, on prend juste la partie YYYY-MM-DD
        date = sale['date_voyage'].toString().substring(0, 10);
      }
    }

    // Récupération de l'heure et de la place
    final time = sale['heure_depart']?.toString() ?? '--';
    final seat = sale['seat_number']?.toString() ?? '-';

    // Formatage propre du montant (enlève les .00 inutiles et ajoute les espaces)
    final amountDouble = num.tryParse(sale['montant'].toString()) ?? 0;
    final amount = NumberFormat('#,###', 'fr_FR').format(amountDouble);

    // Récupération du statut (ex: "confirmee")
    final status = sale['statut']?.toString() ?? 'en attente';

    // 🟢 2. Le reste de l'UI reste identique, les variables sont maintenant pleines !
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
        top: false,
        bottom: Platform.isAndroid ? true : false,
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
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Détails de la vente',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                _buildStatusBadge(status),
              ],
            ),
            const Gap(24),
            _buildDetailRow('N° Billet', id, isHighlight: true),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            _buildDetailRow('Passager', passenger),
            const Gap(16),
            _buildDetailRow('Trajet', route),
            const Gap(16),
            _buildDetailRow('Date', date),
            const Gap(16),
            _buildDetailRow('Heure', time),
            const Gap(16),
            _buildDetailRow('Place', seat),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Montant total',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF757575),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$amount FCFA',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 168, 166, 166),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Fermer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      String label,
      String value, {
        bool isHighlight = false,
      }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF757575),
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : const Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    // 🟢 On nettoie la chaîne pour éviter les bugs liés aux espaces ou aux majuscules
    final cleanStatus = status.trim().toLowerCase();

    // 🟢 On gère toutes les variations possibles de "confirmé" venant du backend
    final isConfirmed = cleanStatus == 'confirmed' ||
        cleanStatus == 'confirmé' ||
        cleanStatus == 'confirmée' ||
        cleanStatus == 'confirmee';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        // Le texte qu'on affiche à l'écran
        isConfirmed ? 'Confirmé' : 'En attente',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isConfirmed
              ? const Color(0xFF2E7D32)
              : const Color(0xFFE65100),
        ),
      ),
    );
  }
}

// ── Horloge digitale (Inchgée) ─────────────────────────────────────────────
class _DigitalClock extends StatefulWidget {
  const _DigitalClock();
  @override
  State<_DigitalClock> createState() => _DigitalClockState();
}

class _DigitalClockState extends State<_DigitalClock> {
  late Timer _timer;
  late String _currentTime;
  late String _currentDate;

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _updateDateTime());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateDateTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('HH:mm:ss').format(now);
    _currentDate = DateFormat('d MMMM yyyy', 'fr_FR').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _currentTime,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primary,
              fontFamily: 'monospace',
            ),
          ),
          Text(
            _currentDate,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF757575),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}