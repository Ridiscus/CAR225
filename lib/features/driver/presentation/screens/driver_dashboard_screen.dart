import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/core/services/networking/api_config.dart';
import 'package:car225/core/services/background_location_service.dart';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';
import '../../data/models/convoi_model.dart';
import 'driver_tracking_screen.dart';

const _kNavy = Color(0xFF0f172a);
const _kNavyCard = Color(0xFF1e293b);
const _kNavyMid = Color(0xFF1e3a5f);

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen>
    with WidgetsBindingObserver {
  StreamSubscription<String>? _notifSub;

  // ── GPS auto-refresh (uniquement si voyage en_cours) ──────────────────────
  bool _isGpsRefreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Écoute le stream de refresh par notification (voyage_assigned, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<DriverProvider>(context, listen: false);
      _notifSub = provider.notifRefreshStream.listen((message) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            duration: const Duration(seconds: 4),
          ),
        );
      });

      // Actualisation GPS ponctuelle au chargement initial
      _autoRefreshGpsIfNeeded(provider);
      // Démarrage du service GPS arrière-plan si voyage en cours
      _syncBackgroundService(provider);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _notifSub?.cancel();
    // On arrête le service arrière-plan seulement si l'utilisateur se DéCONNECTE
    // (pas quand il navigue vers le tracking, sinon on coupe le GPS en plein voyage)
    super.dispose();
  }

  /// Quand l'app revient au premier plan (ex: utilisateur a cliqué la notif
  /// depuis le background), on rafraîchit automatiquement le dashboard
  /// ET la position GPS si un voyage est en cours.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final provider = Provider.of<DriverProvider>(context, listen: false);
      provider.loadDashboard();
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          _autoRefreshGpsIfNeeded(provider);
          _syncBackgroundService(provider);
        }
      });
    }
  }

  /// Démarre ou arrête le service GPS arrière-plan selon le statut du voyage.
  Future<void> _syncBackgroundService(DriverProvider provider) async {
    final voyage = provider.currentVoyage;
    final isActive = voyage != null && voyage.statut == 'en_cours';
    final isRunning = await BackgroundLocationService.isRunning;

    if (isActive && !isRunning) {
      await BackgroundLocationService.start(voyage!.id);
    } else if (!isActive && isRunning) {
      await BackgroundLocationService.stop();
    }
  }

  /// Envoie la position GPS au serveur si et seulement si un voyage
  /// avec statut [en_cours] existe. Ne fait rien sinon.
  Future<void> _autoRefreshGpsIfNeeded(DriverProvider provider) async {
    if (_isGpsRefreshing) return;

    // Vérification : y a-t-il un voyage actif (en_cours) ?
    final voyage = provider.currentVoyage;
    if (voyage == null || voyage.statut != 'en_cours') return;

    _isGpsRefreshing = true;
    try {
      // 1. Vérifier les permissions GPS
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) return;

      // 2. Récupérer la position actuelle
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // 3. Envoyer au serveur
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      await dio.post(
        'chauffeur/voyages/${voyage.id}/update-location',
        data: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'speed': pos.speed * 3.6,
          'heading': pos.heading,
        },
      );
    } catch (_) {
      // Échec silencieux — le chauffeur ne doit pas être dérangé pour ça
    } finally {
      _isGpsRefreshing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: provider.isLoading
          ? const _LoadingState()
          : RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => provider.loadDashboard(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: _DashboardHeader(provider: provider),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Bannière voyages/convois bloqués (oubli "Terminer") ──
                  if (provider.blockedVoyages.isNotEmpty ||
                      provider.blockedConvois.isNotEmpty) ...[
                    _BlockedTripsBanner(
                      blockedVoyages: provider.blockedVoyages,
                      blockedConvois: provider.blockedConvois,
                      onCompleteVoyage: (v) => _confirmCompleteVoyage(
                        context,
                        provider,
                        v,
                      ),
                      onCompleteConvoi: (c) => _confirmCompleteConvoi(
                        context,
                        provider,
                        c,
                      ),
                    ),
                    const Gap(20),
                  ],

                  // ── Voyage du jour ──
                  _SectionTitle(title: 'VOYAGE DU JOUR'),
                  const Gap(10),
                  if (provider.currentVoyage != null) ...[
                    _ActiveVoyageCard(
                      voyage: provider.currentVoyage!,
                      provider: provider,
                      context: context,
                    ),
                    const Gap(12),
                    _ActionButtons(
                      voyage: provider.currentVoyage!,
                      provider: provider,
                      context: context,
                    ),
                  ] else
                    _EmptyCard(
                      icon: Icons.assignment_turned_in_outlined,
                      title: 'Aucun voyage aujourd\'hui',
                      subtitle: 'Votre planning est libre pour aujourd\'hui.',
                    ),

                  const Gap(28),

                  // ── Voyages à venir ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(title: 'PROCHAINS VOYAGES'),
                      if (provider.upcomingVoyages.length > 2)
                        TextButton(
                          onPressed: () => provider.setIndex(1),
                          child: const Text(
                            'Voir tout',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const Gap(10),
                  if (provider.upcomingVoyages.isNotEmpty)
                    ...provider.upcomingVoyages.take(2).map(
                          (v) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _UpcomingVoyageCard(voyage: v),
                      ),
                    )
                  else
                    _EmptyCard(
                      icon: Icons.calendar_today_outlined,
                      title: 'Planning libre',
                      subtitle:
                      'Aucun voyage planifié pour les prochains jours.',
                    ),

                  const Gap(28),

                  // ── Convois du jour ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SectionTitle(title: 'CONVOIS DU JOUR'),
                      if (provider.todayConvois.isNotEmpty)
                        TextButton(
                          onPressed: () => provider.setIndex(1),
                          child: const Text(
                            'Voir tout',
                            style: TextStyle(color: AppColors.primary),
                          ),
                        ),
                    ],
                  ),
                  const Gap(10),
                  if (provider.todayConvois.isNotEmpty)
                    ...provider.todayConvois.take(3).map(
                          (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ConvoiDashboardCard(
                          convoi: c,
                          onTap: () => provider.setIndex(1),
                          onStart: () =>
                              _confirmStartConvoi(context, provider, c),
                          onComplete: () =>
                              _confirmCompleteConvoi(context, provider, c),
                        ),
                      ),
                    )
                  else
                    _EmptyCard(
                      icon: Icons.airport_shuttle_outlined,
                      title: 'Aucun convoi aujourd\'hui',
                      subtitle: 'Aucune mission de convoyage pour aujourd\'hui.',
                    ),

                  const Gap(28),

                  // ── Convois à venir ──
                  if (provider.upcomingConvois.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _SectionTitle(title: 'PROCHAINS CONVOIS'),
                        if (provider.upcomingConvois.length > 2)
                          TextButton(
                            onPressed: () => provider.setIndex(1),
                            child: const Text(
                              'Voir tout',
                              style: TextStyle(color: AppColors.primary),
                            ),
                          ),
                      ],
                    ),
                    const Gap(10),
                    ...provider.upcomingConvois.take(2).map(
                          (c) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _UpcomingConvoiCard(convoi: c),
                      ),
                    ),
                  ],
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEADER ORANGE (inspiré du web)
// ─────────────────────────────────────────────────────────────────────────────
class _DashboardHeader extends StatelessWidget {
  final DriverProvider provider;

  const _DashboardHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;
    final stats = provider.stats;
    final today = DateFormat('EEEE dd MMMM', 'fr_FR').format(DateTime.now());

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, Color(0xFFFF9B3C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Salutation ──
              Text(
                'Bonjour, ${profile?.prenom ?? 'Chauffeur'} 👋',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
              const Gap(4),
              Text(
                today,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 13,
                ),
              ),
              const Gap(20),

              // ── Cartes statistiques ──
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.directions_bus_rounded,
                      label: 'Aujourd\'hui',
                      value:
                      '${provider.todayVoyages.length}',
                      color: Colors.white,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.schedule_rounded,
                      label: 'À venir',
                      value: '${provider.upcomingVoyages.length}',
                      color: Colors.white,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline_rounded,
                      label: 'Terminés',
                      value:
                      '${stats['completed_voyages'] ?? 0}',
                      color: Colors.white,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const Gap(6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE VOYAGE ACTIF
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveVoyageCard extends StatelessWidget {
  final VoyageModel voyage;
  final DriverProvider provider;
  final BuildContext context;

  const _ActiveVoyageCard({
    required this.voyage,
    required this.provider,
    required this.context,
  });

  @override
  Widget build(BuildContext ctx) {
    final timeFormat = DateFormat('HH:mm');

    return Container(
      decoration: BoxDecoration(
        color: _kNavyCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kNavy.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── En-tête carte ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Badge immatriculation
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: AppColors.primary.withOpacity(0.4)),
                  ),
                  child: Text(
                    voyage.vehicule?.immatriculation ?? '—',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
                _StatusBadge(statut: voyage.statut),
              ],
            ),
          ),

          // ── Route ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _RouteColumn(
                    label: 'DÉPART',
                    station: voyage.programme?.gareDepart ??
                        voyage.programme?.pointDepart ??
                        '—',
                    time: voyage.programme?.heureDepart ?? '—',
                    isDepart: true,
                  ),
                ),
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                  ],
                ),
                Expanded(
                  child: _RouteColumn(
                    label: 'ARRIVÉE',
                    station: voyage.programme?.gareArrivee ??
                        voyage.programme?.pointArrive ??
                        '—',
                    time: voyage.programme?.heureArrive ?? '—',
                    isDepart: false,
                  ),
                ),
              ],
            ),
          ),

          const Gap(16),
          const Divider(color: Color(0xFF334155), height: 1),
          const Gap(12),

          // ── Infos détaillées ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  icon: Icons.people_outline_rounded,
                  label: 'Passagers',
                  value:
                  '${voyage.occupancy}/${voyage.vehicule?.places ?? voyage.programme?.capacity ?? 0}',
                ),
                _InfoChip(
                  icon: Icons.payments_outlined,
                  label: 'Tarif',
                  value: '${(voyage.programme?.tarif ?? 0).toInt()} F',
                ),
                _InfoChip(
                  icon: Icons.calendar_today_rounded,
                  label: 'Date',
                  value: voyage.dateVoyage.isNotEmpty
                      ? DateFormat('dd/MM').format(
                      DateTime.tryParse(voyage.dateVoyage) ??
                          DateTime.now())
                      : '—',
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05);
  }
}

class _RouteColumn extends StatelessWidget {
  final String label;
  final String station;
  final String time;
  final bool isDepart;

  const _RouteColumn({
    required this.label,
    required this.station,
    required this.time,
    required this.isDepart,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      isDepart ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isDepart)
              const Icon(Icons.circle, color: AppColors.primary, size: 8),
            if (isDepart) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.5),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            if (!isDepart) const SizedBox(width: 4),
            if (!isDepart)
              const Icon(Icons.location_on_rounded,
                  color: Colors.redAccent, size: 8),
          ],
        ),
        const Gap(4),
        Text(
          station,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: isDepart ? TextAlign.left : TextAlign.right,
        ),
        const Gap(2),
        Text(
          time,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white54),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(color: Colors.white54, fontSize: 10)),
          ],
        ),
        const Gap(3),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOUTONS D'ACTION (Confirmer / Démarrer / GPS / Terminer)
// ─────────────────────────────────────────────────────────────────────────────
class _ActionButtons extends StatefulWidget {
  final VoyageModel voyage;
  final DriverProvider provider;
  final BuildContext context;

  const _ActionButtons({
    required this.voyage,
    required this.provider,
    required this.context,
  });

  @override
  State<_ActionButtons> createState() => _ActionButtonsState();
}

class _ActionButtonsState extends State<_ActionButtons> {
  bool _gpsRefreshing = false;

  Future<void> _refreshGps() async {
    if (_gpsRefreshing) return;
    setState(() => _gpsRefreshing = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) throw Exception('GPS désactivé');

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        throw Exception('Permission GPS refusée');
      }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
        const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      await dio.post(
        'chauffeur/voyages/${widget.voyage.id}/update-location',
        data: {
          'latitude': pos.latitude,
          'longitude': pos.longitude,
          'speed': pos.speed * 3.6,
          'heading': pos.heading,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.gps_fixed_rounded, color: Colors.white, size: 16),
                SizedBox(width: 8),
                Text('Position GPS actualisée'),
              ],
            ),
            backgroundColor: Color(0xFF22c55e),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gpsRefreshing = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    final voyage = widget.voyage;
    final provider = widget.provider;

    switch (voyage.statut) {
      case 'en_attente':
      case 'confirme':
        return Column(
          children: [
            _PrimaryBtn(
              label: 'DÉMARRER LE VOYAGE',
              icon: Icons.play_circle_fill_rounded,
              color: AppColors.primary,
              onTap: () => _confirm(
                widget.context,
                'Démarrer le voyage ?',
                'Confirmer le démarrage du voyage ?',
                    () => provider.confirmAndStartVoyage(voyage.id),
              ),
            ),
            const Gap(10),
            _PrimaryBtn(
              label: 'ANNULER LE VOYAGE',
              icon: Icons.cancel_outlined,
              color: Colors.red.shade700,
              outlined: true,
              onTap: () => _cancelWithReason(widget.context),
            ),
          ],
        );

      case 'en_cours':
        return Column(
          children: [
            // Suivi GPS
            _PrimaryBtn(
              label: 'SUIVI EN TEMPS RÉEL',
              icon: Icons.satellite_alt_rounded,
              color: _kNavyMid,
              onTap: () => Navigator.of(widget.context).push(
                MaterialPageRoute(
                  builder: (_) => DriverTrackingScreen(
                    voyageId: voyage.id,
                    gareDepartNom: voyage.programme?.gareDepart ??
                        voyage.programme?.pointDepart ??
                        '',
                    gareArriveeNom: voyage.programme?.gareArrivee ??
                        voyage.programme?.pointArrive ??
                        '',
                    gareDepartLat: voyage.programme?.gareDepartLat,
                    gareDepartLng: voyage.programme?.gareDepartLng,
                    gareArriveeLat: voyage.programme?.gareArriveeLat,
                    gareArriveeLng: voyage.programme?.gareArriveeLng,
                    vehiculeImmat: voyage.vehicule?.immatriculation ?? '',
                    dateVoyage: voyage.dateVoyage,
                  ),
                ),
              ),
            ),
            const Gap(10),

            // Actualiser GPS
            _PrimaryBtn(
              label: _gpsRefreshing ? 'ACTUALISATION...' : 'ACTUALISER GPS',
              icon: _gpsRefreshing
                  ? Icons.hourglass_top_rounded
                  : Icons.gps_fixed_rounded,
              color: const Color(0xFF0ea5e9),
              outlined: true,
              onTap: _gpsRefreshing ? () {} : _refreshGps,
            ),
            const Gap(10),

            // Terminer
            _PrimaryBtn(
              label: 'TERMINER LE VOYAGE',
              icon: Icons.flag_rounded,
              color: AppColors.secondary,
              onTap: () => _confirm(
                ctx,
                'Terminer le voyage ?',
                'Êtes-vous arrivé à destination ? Cette action est irréversible.',
                    () => provider.completeVoyage(voyage.id),
              ),
            ),
          ],
        );

      case 'termine':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.secondary.withOpacity(0.3)),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.secondary),
              Gap(10),
              Text(
                'Voyage terminé avec succès !',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  void _cancelWithReason(BuildContext ctx) {
    final reasonCtrl = TextEditingController();
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Annuler le voyage',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Veuillez indiquer la raison de l\'annulation :'),
            const Gap(12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Raison (optionnel)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Retour', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final reason = reasonCtrl.text.trim().isEmpty
                  ? null
                  : reasonCtrl.text.trim();
              try {
                await widget.provider.cancelVoyage(widget.voyage.id, reason: reason);
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(
                        e.toString().replaceAll('Exception:', '').trim()),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('Confirmer l\'annulation',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _confirm(BuildContext ctx, String title, String message,
      Future<void> Function() action) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
            Text('Annuler', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await action();
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                    content: Text(
                        e.toString().replaceAll('Exception:', '').trim()),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('Confirmer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _PrimaryBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool outlined;

  const _PrimaryBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton.icon(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color, width: 1.5),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
      )
          : ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        icon: Icon(icon, size: 20),
        label: Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE VOYAGE À VENIR
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingVoyageCard extends StatelessWidget {
  final VoyageModel voyage;

  const _UpcomingVoyageCard({required this.voyage});

  @override
  Widget build(BuildContext context) {
    final dateStr = voyage.dateVoyage.isNotEmpty
        ? DateFormat('EEE dd MMM', 'fr_FR')
        .format(DateTime.tryParse(voyage.dateVoyage) ?? DateTime.now())
        .toUpperCase()
        : '—';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Date badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dateStr,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${voyage.programme?.gareDepart ?? voyage.programme?.pointDepart ?? '—'} → ${voyage.programme?.gareArrivee ?? voyage.programme?.pointArrive ?? '—'}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(2),
                Text(
                  '${voyage.vehicule?.immatriculation ?? '—'} · ${voyage.programme?.heureDepart ?? '—'}',
                  style:
                  TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          _StatusBadge(statut: voyage.statut, small: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPOSANTS PARTAGÉS
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  final String statut;
  final bool small;

  const _StatusBadge({required this.statut, this.small = false});

  @override
  Widget build(BuildContext context) {
    final label = _label(statut);
    final color = _color(statut);
    final isEnCours = statut == 'en_cours';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 8 : 10,
        vertical: small ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isEnCours) ...[
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).fadeOut(duration: 800.ms),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: small ? 10 : 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _label(String s) {
    switch (s) {
      case 'en_attente':
        return 'En attente';
      case 'confirme':
        return 'Confirmé';
      case 'en_cours':
        return 'En cours';
      case 'termine':
        return 'Terminé';
      case 'annule':
        return 'Annulé';
      default:
        return s;
    }
  }

  Color _color(String s) {
    switch (s) {
      case 'en_attente':
        return Colors.orange;
      case 'confirme':
        return Colors.blue;
      case 'en_cours':
        return Colors.green;
      case 'termine':
        return AppColors.secondary;
      case 'annule':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w800,
        color: Color(0xFF64748B),
        fontSize: 11,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.07),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 28),
          ),
          const Gap(12),
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Gap(4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.primary),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BANNIÈRE : VOYAGES / CONVOIS BLOQUÉS (oubli de "Terminer")
// ─────────────────────────────────────────────────────────────────────────────
class _BlockedTripsBanner extends StatelessWidget {
  final List<VoyageModel> blockedVoyages;
  final List<ConvoiModel> blockedConvois;
  final void Function(VoyageModel) onCompleteVoyage;
  final void Function(ConvoiModel) onCompleteConvoi;

  const _BlockedTripsBanner({
    required this.blockedVoyages,
    required this.blockedConvois,
    required this.onCompleteVoyage,
    required this.onCompleteConvoi,
  });

  @override
  Widget build(BuildContext context) {
    final total = blockedVoyages.length + blockedConvois.length;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFdc2626), Color(0xFFf97316)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFdc2626).withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    color: Colors.white, size: 22),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '⚠️ Trajet(s) non terminé(s)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '$total trajet(s) de jours précédents à clôturer. '
                      'Cliquez sur "Terminer" pour les clôturer.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(14),

          // Voyages bloqués
          ...blockedVoyages.map((v) {
            final dateStr = (() {
              try {
                final d = DateTime.parse(v.dateVoyage);
                return DateFormat('dd/MM/yyyy').format(d);
              } catch (_) {
                return v.dateVoyage;
              }
            })();
            final route =
                '${v.departureStation.isNotEmpty ? v.departureStation : 'Départ'} → ${v.arrivalStation.isNotEmpty ? v.arrivalStation : 'Arrivée'}';
            return _BlockedTile(
              kind: 'Voyage',
              icon: Icons.directions_bus_rounded,
              title: route,
              subtitle: dateStr,
              onComplete: () => onCompleteVoyage(v),
            );
          }),

          // Convois bloqués
          ...blockedConvois.map((c) {
            final dateRef =
                c.allerDone ? c.dateRetour : c.dateDepart;
            final dateStr = (() {
              if (dateRef == null || dateRef.isEmpty) return '—';
              try {
                final d = DateTime.parse(dateRef);
                return DateFormat('dd/MM/yyyy').format(d);
              } catch (_) {
                return dateRef;
              }
            })();
            final route =
                '${c.trajet.depart.isNotEmpty ? c.trajet.depart : 'Départ'} → ${c.trajet.arrivee.isNotEmpty ? c.trajet.arrivee : 'Arrivée'}';
            final label = c.allerDone ? '$route (retour)' : route;
            return _BlockedTile(
              kind: 'Convoi',
              icon: Icons.airport_shuttle_rounded,
              title: label,
              subtitle: dateStr,
              onComplete: () => onCompleteConvoi(c),
            );
          }),
        ],
      ),
    );
  }
}

class _BlockedTile extends StatelessWidget {
  final String kind;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onComplete;

  const _BlockedTile({
    required this.kind,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
          const Gap(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        kind.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(4),
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    )),
                const Gap(2),
                Text(subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 11,
                    )),
              ],
            ),
          ),
          const Gap(8),
          GestureDetector(
            onTap: onComplete,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Terminer',
                style: TextStyle(
                  color: Color(0xFFdc2626),
                  fontWeight: FontWeight.w900,
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE CONVOI DU JOUR (avec actions Démarrer / Terminer)
// ─────────────────────────────────────────────────────────────────────────────
class _ConvoiDashboardCard extends StatelessWidget {
  final ConvoiModel convoi;
  final VoidCallback onTap;
  final VoidCallback onStart;
  final VoidCallback onComplete;

  const _ConvoiDashboardCard({
    required this.convoi,
    required this.onTap,
    required this.onStart,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = (() {
      final d = convoi.trajet.date;
      if (d == null || d.isEmpty) return '—';
      try {
        return DateFormat('dd/MM/yyyy').format(DateTime.parse(d));
      } catch (_) {
        return d;
      }
    })();
    final heure = convoi.trajet.heure ?? '';
    final isRetour = convoi.trajet.isRetour;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kNavyCard,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _kNavy.withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            // En-tête
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                          color: AppColors.primary.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.airport_shuttle_rounded,
                            color: AppColors.primary, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          isRetour ? 'RETOUR' : 'ALLER',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                  if (convoi.reference != null)
                    Expanded(
                      child: Text(
                        convoi.reference!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                  else
                    const Spacer(),
                  _StatusBadge(statut: convoi.statut, small: true),
                ],
              ),
            ),
            // Trajet
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DÉPART',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          convoi.trajet.depart,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.arrow_forward_rounded,
                        color: AppColors.primary, size: 16),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'ARRIVÉE',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.7,
                          ),
                        ),
                        const Gap(2),
                        Text(
                          convoi.trajet.arrivee,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(10),
            // Infos compactes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MiniInfo(
                    icon: Icons.calendar_today_rounded,
                    label: dateStr,
                  ),
                  _MiniInfo(
                    icon: Icons.access_time_rounded,
                    label: heure.isNotEmpty ? heure : '—',
                  ),
                  if (convoi.nombrePersonnes != null)
                    _MiniInfo(
                      icon: Icons.people_outline_rounded,
                      label: '${convoi.nombrePersonnes} pax',
                    ),
                  if (convoi.vehicule != null)
                    _MiniInfo(
                      icon: Icons.directions_car_rounded,
                      label: convoi.vehicule!.immatriculation,
                    ),
                ],
              ),
            ),
            const Gap(10),
            const Divider(color: Color(0xFF334155), height: 1),
            // Actions
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Row(
                children: [
                  if (convoi.canStart)
                    Expanded(
                      child: _MiniActionBtn(
                        icon: Icons.play_arrow_rounded,
                        label: convoi.startLabel.toUpperCase(),
                        color: AppColors.primary,
                        onTap: onStart,
                      ),
                    ),
                  if (convoi.canComplete)
                    Expanded(
                      child: _MiniActionBtn(
                        icon: Icons.flag_rounded,
                        label: convoi.completeLabel.toUpperCase(),
                        color: AppColors.secondary,
                        onTap: onComplete,
                      ),
                    ),
                  if (!convoi.canStart && !convoi.canComplete)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          convoi.startBlockedReason ??
                              'Détails du convoi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                          ),
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
}

class _MiniInfo extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MiniInfo({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

class _MiniActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ElevatedButton.icon(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
        icon: Icon(icon, size: 16),
        label: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: 11,
            )),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE CONVOI À VENIR (compacte)
// ─────────────────────────────────────────────────────────────────────────────
class _UpcomingConvoiCard extends StatelessWidget {
  final ConvoiModel convoi;

  const _UpcomingConvoiCard({required this.convoi});

  @override
  Widget build(BuildContext context) {
    final dateRaw = convoi.trajet.date;
    final dateStr = (() {
      if (dateRaw == null || dateRaw.isEmpty) return '—';
      try {
        return DateFormat('EEE dd MMM', 'fr_FR')
            .format(DateTime.parse(dateRaw))
            .toUpperCase();
      } catch (_) {
        return dateRaw;
      }
    })();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              dateStr,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.airport_shuttle_rounded,
                        size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${convoi.trajet.depart} → ${convoi.trajet.arrivee}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  '${convoi.vehicule?.immatriculation ?? '—'} · ${convoi.trajet.heure ?? '—'}',
                  style:
                      TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
              ],
            ),
          ),
          _StatusBadge(statut: convoi.statut, small: true),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS DE CONFIRMATION (voyage / convoi)
// ─────────────────────────────────────────────────────────────────────────────
void _confirmCompleteVoyage(
    BuildContext context, DriverProvider provider, VoyageModel voyage) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Terminer le voyage ?',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: const Text(
          'Confirmer la clôture de ce voyage ? Cette action est irréversible.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await provider.completeVoyage(voyage.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Voyage terminé avec succès.'),
                    backgroundColor: Color(0xFF22c55e),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(e.toString().replaceAll('Exception:', '').trim()),
                  backgroundColor: Colors.red,
                ));
              }
            }
          },
          child: const Text('Confirmer',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _confirmCompleteConvoi(
    BuildContext context, DriverProvider provider, ConvoiModel convoi) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('${convoi.completeLabel} ?',
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: const Text(
          'Confirmer la clôture de ce convoi ? Cette action est irréversible.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              final res = await provider.completeConvoi(convoi.id);
              await provider.loadDashboard();
              if (context.mounted) {
                final msg = res['message']?.toString() ??
                    'Convoi terminé avec succès.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    backgroundColor: const Color(0xFF22c55e),
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(e.toString().replaceAll('Exception:', '').trim()),
                  backgroundColor: Colors.red,
                ));
              }
            }
          },
          child: const Text('Confirmer',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

void _confirmStartConvoi(
    BuildContext context, DriverProvider provider, ConvoiModel convoi) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('${convoi.startLabel} ?',
          style:
              const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      content: const Text('Confirmer le démarrage du convoi ?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text('Annuler', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: () async {
            Navigator.pop(ctx);
            try {
              await provider.startConvoi(convoi.id);
              await provider.loadDashboard();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Convoi démarré avec succès.'),
                    backgroundColor: Color(0xFF22c55e),
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content:
                      Text(e.toString().replaceAll('Exception:', '').trim()),
                  backgroundColor: Colors.red,
                ));
              }
            }
          },
          child: const Text('Confirmer',
              style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}
