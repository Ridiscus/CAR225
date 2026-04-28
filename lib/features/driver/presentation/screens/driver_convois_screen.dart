import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/core/services/networking/api_config.dart';
import '../providers/driver_provider.dart';
import '../../data/models/convoi_model.dart';
import 'driver_tracking_screen.dart';

const _kNavy = Color(0xFF0f172a);

/// Écran listant les convois (missions de convoyage) assignés au chauffeur.
/// Reproduit la logique du web chauffeur : onglets actifs / effectués / non effectués,
/// gestion aller/retour, désistement, signalement.
class DriverConvoisScreen extends StatefulWidget {
  const DriverConvoisScreen({super.key});

  @override
  State<DriverConvoisScreen> createState() => _DriverConvoisScreenState();
}

class _DriverConvoisScreenState extends State<DriverConvoisScreen> {
  String _tab = 'active'; // 'active' | 'effectues' | 'non_effectues'
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _load();
    });
  }

  Future<void> _load() async {
    final date = _selectedDate != null
        ? DateFormat('yyyy-MM-dd').format(_selectedDate!)
        : DateFormat('yyyy-MM-dd').format(DateTime.now());
    await context
        .read<DriverProvider>()
        .loadConvois(tab: _tab, date: date);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final convois = provider.convois;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _ConvoisHeader(
            tab: _tab,
            selectedDate: _selectedDate,
            onTabChange: (t) {
              setState(() => _tab = t);
              _load();
            },
            onDatePick: () => _pickDate(context),
            onClearDate: () {
              setState(() => _selectedDate = null);
              _load();
            },
          ),
          Expanded(
            child: provider.isLoadingConvois
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: _load,
                    child: convois.isEmpty
                        ? SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: SizedBox(
                              height:
                                  MediaQuery.of(context).size.height * 0.6,
                              child: _buildEmpty(),
                            ),
                          )
                        : ListView(
                            padding:
                                const EdgeInsets.fromLTRB(16, 8, 16, 100),
                            children: convois
                                .map((c) => _ConvoiCard(
                                      convoi: c,
                                      onTap: () =>
                                          _showActions(context, c, provider),
                                    ))
                                .toList(),
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
              const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
      _load();
    }
  }

  void _showActions(
      BuildContext context, ConvoiModel convoi, DriverProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConvoiActionsSheet(convoi: convoi, provider: provider),
    );
  }

  Widget _buildEmpty() {
    String label;
    switch (_tab) {
      case 'effectues':
        label = 'Aucun convoi terminé.';
        break;
      case 'non_effectues':
        label = 'Aucun convoi annulé.';
        break;
      default:
        label = _selectedDate != null
            ? 'Aucun convoi actif pour cette date.'
            : 'Vous n\'avez pas de convoi actif.';
    }
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.airport_shuttle_rounded,
                size: 48, color: AppColors.primary),
          ),
          const Gap(16),
          const Text('Aucun convoi',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const Gap(6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EN-TÊTE (onglets + date)
// ─────────────────────────────────────────────────────────────────────────────
class _ConvoisHeader extends StatelessWidget {
  final String tab;
  final DateTime? selectedDate;
  final ValueChanged<String> onTabChange;
  final VoidCallback onDatePick;
  final VoidCallback onClearDate;

  const _ConvoisHeader({
    required this.tab,
    required this.selectedDate,
    required this.onTabChange,
    required this.onDatePick,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNavy,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.airport_shuttle_rounded,
                  color: AppColors.primary, size: 22),
              const Gap(10),
              const Text(
                'Mes Convois',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (selectedDate != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(selectedDate!),
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const Gap(4),
                GestureDetector(
                  onTap: onClearDate,
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white70, size: 18),
                ),
                const Gap(8),
              ],
              GestureDetector(
                onTap: onDatePick,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          const Gap(12),
          // Onglets
          Row(
            children: [
              _TabChip(
                  label: 'Actifs',
                  active: tab == 'active',
                  onTap: () => onTabChange('active')),
              const Gap(8),
              _TabChip(
                  label: 'Effectués',
                  active: tab == 'effectues',
                  onTap: () => onTabChange('effectues')),
              const Gap(8),
              _TabChip(
                  label: 'Annulés',
                  active: tab == 'non_effectues',
                  onTap: () => onTabChange('non_effectues')),
            ],
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _TabChip(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active
                ? AppColors.primary
                : Colors.white.withOpacity(0.2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.white70,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE CONVOI
// ─────────────────────────────────────────────────────────────────────────────
class _ConvoiCard extends StatelessWidget {
  final ConvoiModel convoi;
  final VoidCallback onTap;

  const _ConvoiCard({required this.convoi, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final date = convoi.trajet.date;
    final dateStr = (date != null && date.isNotEmpty)
        ? DateFormat('dd MMM yyyy', 'fr_FR')
            .format(DateTime.tryParse(date) ?? DateTime.now())
        : '—';
    final heure = convoi.trajet.heure ?? '';
    final isRetour = convoi.trajet.isRetour;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  // Badge CONVOI
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'CONVOI',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Gap(8),
                  if (convoi.reference != null)
                    Flexible(
                      child: Text(
                        convoi.reference!,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  const Spacer(),
                  // Badge aller/retour si applicable
                  if (convoi.hasRetour) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isRetour
                            ? Colors.purple.withOpacity(0.1)
                            : Colors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isRetour ? 'RETOUR' : 'ALLER',
                        style: TextStyle(
                          color: isRetour ? Colors.purple : Colors.teal,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const Gap(6),
                  ],
                  _ConvoiStatusPill(statut: convoi.statut, label: convoi.statutLabel),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // Trajet
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DÉPART',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            )),
                        const Gap(3),
                        Text(
                          convoi.trajet.depart,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(3),
                        Text(
                          heure.isNotEmpty ? heure : '—',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF1F5F9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('ARRIVÉE',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            )),
                        const Gap(3),
                        Text(
                          convoi.trajet.arrivee,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                        const Gap(3),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Meta row : véhicule + passagers
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  if (convoi.vehicule != null) ...[
                    const Icon(Icons.directions_car_filled_rounded,
                        size: 14, color: Color(0xFF94A3B8)),
                    const Gap(4),
                    Text(
                      convoi.vehicule!.immatriculation,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Gap(10),
                  ],
                  const Icon(Icons.people_rounded,
                      size: 14, color: Color(0xFF94A3B8)),
                  const Gap(4),
                  Text(
                    '${convoi.nombrePersonnes ?? 0} pers.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.touch_app_rounded,
                      color: Colors.grey[400], size: 13),
                  const Gap(3),
                  Text(
                    'Appuyer',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
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

// ─────────────────────────────────────────────────────────────────────────────
// STATUS PILL
// ─────────────────────────────────────────────────────────────────────────────
class _ConvoiStatusPill extends StatelessWidget {
  final String statut;
  final String label;

  const _ConvoiStatusPill({required this.statut, required this.label});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (statut) {
      case 'paye':
        color = Colors.blue;
        break;
      case 'en_cours':
        color = Colors.green;
        break;
      case 'termine':
        color = Colors.grey;
        break;
      case 'annule':
        color = Colors.red;
        break;
      default:
        color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label.isNotEmpty ? label : statut,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM SHEET ACTIONS
// ─────────────────────────────────────────────────────────────────────────────
class _ConvoiActionsSheet extends StatefulWidget {
  final ConvoiModel convoi;
  final DriverProvider provider;

  const _ConvoiActionsSheet(
      {required this.convoi, required this.provider});

  @override
  State<_ConvoiActionsSheet> createState() => _ConvoiActionsSheetState();
}

class _ConvoiActionsSheetState extends State<_ConvoiActionsSheet> {
  bool _loading = false;

  Future<void> _doAction(
    Future<void> Function() action, {
    String? successMessage,
  }) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) {
        Navigator.pop(context);
        if (successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(successMessage),
            backgroundColor: Colors.green.shade700,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Récupère la position GPS courante et la pousse vers le serveur pour
  /// le convoi indiqué, puis ouvre l'écran de tracking en mode convoi.
  Future<void> _openConvoiTracking(BuildContext context, ConvoiModel c) async {
    // ⚠️ On capture le NavigatorState AVANT de pop, sinon la bottom sheet
    // ferme son sous-arbre et le `context` n'est plus monté pour faire
    // le `Navigator.push` qui ouvre l'écran de tracking.
    final navigator = Navigator.of(context, rootNavigator: true);

    navigator.pop(); // Ferme la bottom sheet

    // Mise à jour immédiate de la position avant d'ouvrir le tracking.
    // Échec silencieux : l'écran de tracking re-tentera dès qu'il sera ouvert.
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (serviceEnabled &&
          perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.high),
        );
        await _pushConvoiLocation(c.id, pos);
      }
    } catch (_) {
      // Silencieux — le stream GPS prendra le relais sur l'écran de tracking
    }

    // Coordonnées : la gare a une latitude/longitude, le lieu de retour est
    // une adresse libre (donc sans coords). On NE passe PAS les mêmes coords
    // des deux côtés — sinon `flutter_map`'s fitCamera collapse à un point
    // unique et calcule un zoom infini → crash « Infinity or NaN toInt ».
    // L'écran de tracking centrera la carte sur la position du chauffeur.
    final gareLat = c.gare?.latitude;
    final gareLng = c.gare?.longitude;

    navigator.push(
      MaterialPageRoute(
        builder: (_) => DriverTrackingScreen.convoi(
          convoiId: c.id,
          gareDepartNom: c.trajet.depart,
          gareArriveeNom: c.trajet.arrivee,
          gareDepartLat: gareLat,
          gareDepartLng: gareLng,
          // Pas de coords pour le point d'arrivée (lieu libre).
          gareArriveeLat: null,
          gareArriveeLng: null,
          vehiculeImmat: c.vehicule?.immatriculation ?? '',
          dateVoyage: c.trajet.date ?? '',
        ),
      ),
    );
  }

  Future<void> _pushConvoiLocation(int convoiId, Position pos) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ));
    await dio.post(
      'chauffeur/convois/$convoiId/update-location',
      data: {
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'speed': pos.speed * 3.6,
        'heading': pos.heading,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.convoi;
    final dateStr = (c.trajet.date != null && c.trajet.date!.isNotEmpty)
        ? DateFormat('dd MMM yyyy', 'fr_FR')
            .format(DateTime.tryParse(c.trajet.date!) ?? DateTime.now())
        : '—';

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(4)),
              ),

              // Bandeau convoi
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kNavy,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.airport_shuttle_rounded,
                              color: Colors.blue,
                              size: 22),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${c.trajet.depart} → ${c.trajet.arrivee}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const Gap(3),
                              Text(
                                '$dateStr · ${c.vehicule?.immatriculation ?? 'N/A'}',
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                        _ConvoiStatusPill(
                            statut: c.statut, label: c.statutLabel),
                      ],
                    ),
                    if (c.hasRetour) ...[
                      const Gap(10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              c.allerDone
                                  ? Icons.u_turn_left_rounded
                                  : Icons.keyboard_double_arrow_right_rounded,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const Gap(6),
                            Expanded(
                              child: Text(
                                c.allerDone
                                    ? 'Trajet RETOUR en attente de démarrage'
                                    : 'Aller-retour · trajet ALLER en cours',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Détails : demandeur, rassemblement, passagers
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    _InfoRow(
                      icon: Icons.person_rounded,
                      label: 'Demandeur',
                      value: c.demandeur.nom,
                    ),
                    if (c.demandeur.contact != null &&
                        c.demandeur.contact!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.phone_rounded,
                        label: 'Contact',
                        value: c.demandeur.contact!,
                      ),
                    if (c.lieuRassemblement != null &&
                        c.lieuRassemblement!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.place_rounded,
                        label: 'Lieu de rassemblement',
                        value: c.lieuRassemblement!,
                      ),
                    if (c.allerDone &&
                        c.lieuRassemblementRetour != null &&
                        c.lieuRassemblementRetour!.isNotEmpty)
                      _InfoRow(
                        icon: Icons.place_rounded,
                        label: 'Rassemblement retour',
                        value: c.lieuRassemblementRetour!,
                      ),
                    if (c.nombrePersonnes != null)
                      _InfoRow(
                        icon: Icons.people_rounded,
                        label: 'Nombre de personnes',
                        value: '${c.nombrePersonnes}',
                      ),
                    if (c.isGarant)
                      _InfoRow(
                        icon: Icons.shield_rounded,
                        label: 'Garant',
                        value: 'Oui (responsable du groupe)',
                        valueColor: Colors.orange,
                      ),
                  ],
                ),
              ),

              // Liste des passagers si présents
              if (c.passagers.isNotEmpty) ...[
                const Gap(8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Passagers (${c.passagers.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
                const Gap(6),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: c.passagers.map((p) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline_rounded,
                                  size: 16, color: Color(0xFF64748B)),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  p.fullName.isNotEmpty
                                      ? p.fullName
                                      : 'Passager',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                              if (p.contact != null && p.contact!.isNotEmpty)
                                Text(
                                  p.contact!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],

              const Gap(14),

              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child:
                      CircularProgressIndicator(color: AppColors.primary),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    children: [
                      // Démarrer
                      if (c.canStart)
                        _ActionBtn(
                          icon: Icons.play_circle_outline_rounded,
                          label: c.startLabel,
                          color: AppColors.primary,
                          onTap: () => _doAction(
                            () async {
                              await widget.provider.startConvoi(c.id);
                            },
                          ),
                        )
                      else if (c.statut == 'paye' &&
                          c.startBlockedReason != null)
                        // Message explicatif non démarrable
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.orange.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded,
                                  color: Colors.orange, size: 18),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  c.startBlockedReason!,
                                  style: const TextStyle(
                                    color: Color(0xFF78350F),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Suivre en temps réel (avant le bouton Terminer)
                      if (c.canTrack) ...[
                        const Gap(8),
                        _ActionBtn(
                          icon: Icons.satellite_alt_rounded,
                          label: 'Suivre en temps réel',
                          color: const Color(0xFF1e3a5f),
                          onTap: () => _openConvoiTracking(context, c),
                        ),
                      ],

                      // Terminer
                      if (c.canComplete) ...[
                        const Gap(8),
                        _ActionBtn(
                          icon: Icons.flag_rounded,
                          label: c.completeLabel,
                          color: const Color(0xFF10B981),
                          onTap: () => _doAction(() async {
                            final r = await widget.provider
                                .completeConvoi(c.id);
                            // Si l'aller vient d'être marqué terminé, on affiche le message serveur
                            if (r['is_aller_done'] == true && mounted) {
                              final msg = r['message']?.toString();
                              if (msg != null && msg.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(msg),
                                    backgroundColor: Colors.blue.shade700,
                                    duration:
                                        const Duration(seconds: 5),
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                  ),
                                );
                              }
                            }
                          }),
                        ),
                      ],

                      // Se désister (paye ou en_cours)
                      if (c.canCancel) ...[
                        const Gap(8),
                        _ActionBtn(
                          icon: Icons.cancel_outlined,
                          label: 'Se désister du convoi',
                          color: Colors.red.shade700,
                          outlined: true,
                          onTap: () => _askMotifAndCancel(context, c),
                        ),
                      ],

                      const Gap(8),

                      // Signaler (tjrs disponible sauf si annulé/terminé)
                      if (c.statut == 'paye' || c.statut == 'en_cours')
                        _ActionBtn(
                          icon: Icons.warning_amber_rounded,
                          label: 'Faire un signalement',
                          color: Colors.orange,
                          outlined: true,
                          onTap: () {
                            Navigator.pop(context);
                            // Pré-sélectionne le convoi côté provider, puis ouvre
                            // l'onglet Signalements (qui consommera la cible).
                            final p = context.read<DriverProvider>();
                            p.setSignalementTarget(convoi: c);
                            p.setIndex(4);
                          },
                        ),
                    ],
                  ),
                ),
              ],

              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _askMotifAndCancel(BuildContext context, ConvoiModel c) async {
    final motifCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Se désister du convoi',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Indiquez le motif. La gare sera notifiée et pourra réaffecter le convoi.',
                style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
              const Gap(12),
              TextFormField(
                controller: motifCtrl,
                maxLines: 3,
                maxLength: 500,
                validator: (v) {
                  if (v == null || v.trim().length < 10) {
                    return 'Motif : au moins 10 caractères.';
                  }
                  return null;
                },
                decoration: InputDecoration(
                  hintText: 'Motif du désistement (10 caractères min)…',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState?.validate() == true) {
                Navigator.pop(ctx, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirmer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _doAction(
        () => widget.provider.cancelConvoi(c.id, motifCtrl.text.trim()),
        successMessage:
            'Désistement enregistré. La gare a été notifiée.',
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Petits helpers UI
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF64748B)),
          const Gap(10),
          Text(
            '$label : ',
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF1E293B),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool outlined;
  final VoidCallback onTap;

  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: outlined
          ? OutlinedButton.icon(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color, width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              icon: Icon(icon, color: color, size: 20),
              label: Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700)),
            )
          : ElevatedButton.icon(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: Icon(icon, color: Colors.white, size: 20),
              label: Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
    );
  }
}
