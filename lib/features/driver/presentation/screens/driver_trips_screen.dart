import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';
import 'driver_tracking_screen.dart';

const _kNavy = Color(0xFF0f172a);

class DriverTripsScreen extends StatefulWidget {
  const DriverTripsScreen({super.key});

  @override
  State<DriverTripsScreen> createState() => _DriverTripsScreenState();
}

class _DriverTripsScreenState extends State<DriverTripsScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadVoyages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();

    // Voyages normaux du jour filtré
    List<VoyageModel> voyages = provider.voyages.where((v) {
      return v.statut == 'en_attente' ||
          v.statut == 'confirme' ||
          v.statut == 'en_cours';
    }).toList();

    if (_selectedDate != null) {
      voyages = voyages.where((v) {
        final date = DateTime.tryParse(v.dateVoyage);
        if (date == null) return false;
        return date.day == _selectedDate!.day &&
            date.month == _selectedDate!.month &&
            date.year == _selectedDate!.year;
      }).toList();
    }

    // Voyages bloqués : en_cours depuis une date passée
    final today = DateTime.now();
    final blockedVoyages = provider.blockedVoyages.where((v) {
      final date = DateTime.tryParse(v.dateVoyage);
      if (date == null) return false;
      return v.statut == 'en_cours' &&
          date.isBefore(DateTime(today.year, today.month, today.day));
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _TripsHeader(
            selectedDate: _selectedDate,
            onDatePick: () => _pickDate(context),
            onClearDate: () => setState(() => _selectedDate = null),
          ),
          Expanded(
            child: provider.isLoadingVoyages
                ? const Center(
                child:
                CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => provider.loadVoyages(),
              child: (voyages.isEmpty && blockedVoyages.isEmpty)
                  ? SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: _buildEmpty(),
                ),
              )
                  : ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                children: [
                  // ---- BANNIÈRE VOYAGES BLOQUÉS ----
                  if (blockedVoyages.isNotEmpty) ...[
                    _BlockedVoyagesBanner(
                      blockedVoyages: blockedVoyages,
                      onComplete: (v) => _showActions(context, v, provider),
                    ),
                    const Gap(12),
                  ],
                  // ---- VOYAGES DU JOUR ----
                  ...voyages.map((v) => _VoyageCard(
                    voyage: v,
                    onTap: () => _showActions(context, v, provider),
                  )),
                ],
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
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme:
          const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  void _showActions(
      BuildContext context, VoyageModel voyage, DriverProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VoyageActionsSheet(voyage: voyage, provider: provider),
    );
  }

  Widget _buildEmpty() {
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
            child: const Icon(Icons.directions_bus_outlined,
                size: 48, color: AppColors.primary),
          ),
          const Gap(16),
          const Text('Aucun voyage actif',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const Gap(6),
          Text(
            _selectedDate != null
                ? 'Aucun voyage pour cette date.'
                : 'Vous n\'avez pas de voyages en cours ou à venir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EN-TÊTE
// ─────────────────────────────────────────────────────────────────────────────
class _TripsHeader extends StatelessWidget {
  final DateTime? selectedDate;
  final VoidCallback onDatePick;
  final VoidCallback onClearDate;

  const _TripsHeader({
    required this.selectedDate,
    required this.onDatePick,
    required this.onClearDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNavy,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.directions_bus_rounded,
              color: AppColors.primary, size: 22),
          const Gap(10),
          const Text(
            'Mes Voyages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          if (selectedDate != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE VOYAGE (tappable)
// ─────────────────────────────────────────────────────────────────────────────
class _VoyageCard extends StatelessWidget {
  final VoyageModel voyage;
  final VoidCallback onTap;

  const _VoyageCard({required this.voyage, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final dateStr = voyage.dateVoyage.isNotEmpty
        ? DateFormat('dd MMM yyyy', 'fr_FR').format(
        DateTime.tryParse(voyage.dateVoyage) ?? DateTime.now())
        : '—';

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
            // ── Header row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      voyage.vehicule?.immatriculation ?? '—',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Gap(8),
                  Text(dateStr,
                      style:
                      TextStyle(color: Colors.grey[500], fontSize: 12)),
                  const Spacer(),
                  _StatusPill(statut: voyage.statut),
                ],
              ),
            ),

            const Divider(height: 1, color: Color(0xFFF1F5F9)),

            // ── Route ──
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
                          voyage.programme?.gareDepart ??
                              voyage.programme?.pointDepart ??
                              '—',
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
                          voyage.programme?.heureDepart ?? '—',
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
                          voyage.programme?.gareArrivee ??
                              voyage.programme?.pointArrive ??
                              '—',
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
                          voyage.programme?.heureArrive ?? '—',
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Hint tap ──
            Container(
              padding: const EdgeInsets.symmetric(vertical: 9),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app_rounded,
                      color: Colors.grey[400], size: 14),
                  const Gap(5),
                  Text(
                    'Appuyer pour les actions',
                    style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 11,
                        fontWeight: FontWeight.w500),
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
// BOTTOM SHEET ACTIONS
// ─────────────────────────────────────────────────────────────────────────────
class _VoyageActionsSheet extends StatefulWidget {
  final VoyageModel voyage;
  final DriverProvider provider;

  const _VoyageActionsSheet(
      {required this.voyage, required this.provider});

  @override
  State<_VoyageActionsSheet> createState() => _VoyageActionsSheetState();
}

class _VoyageActionsSheetState extends State<_VoyageActionsSheet> {
  bool _loading = false;

  Future<void> _doAction(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      if (mounted) Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    final v = widget.voyage;
    final depart = v.programme?.gareDepart ?? v.programme?.pointDepart ?? '—';
    final arrivee =
        v.programme?.gareArrivee ?? v.programme?.pointArrive ?? '—';
    final immat = v.vehicule?.immatriculation ?? '—';
    final dateStr = v.dateVoyage.isNotEmpty
        ? DateFormat('dd MMM yyyy', 'fr_FR')
        .format(DateTime.tryParse(v.dateVoyage) ?? DateTime.now())
        : '—';

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Poignée ──
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4)),
            ),

            // ── Info voyage ──
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _kNavy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.directions_bus_rounded,
                        color: AppColors.primary, size: 22),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$depart → $arrivee',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(3),
                        Text(
                          '$dateStr · $immat',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(statut: v.statut),
                ],
              ),
            ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child:
                CircularProgressIndicator(color: AppColors.primary),
              )
            else ...[
              // ── Actions selon statut ──
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Column(
                  children: [
                    // Démarrer (en_attente ou confirme)
                    if (v.statut == 'en_attente' || v.statut == 'confirme')
                      _ActionBtn(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Démarrer le voyage',
                        color: AppColors.primary,
                        onTap: () => _doAction(
                                () => widget.provider.confirmAndStartVoyage(v.id)),
                      ),

                    // En cours: Suivi + Terminer
                    if (v.statut == 'en_cours') ...[
                      _ActionBtn(
                        icon: Icons.satellite_alt_rounded,
                        label: 'Suivi en temps réel',
                        color: const Color(0xFF1e3a5f),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DriverTrackingScreen(
                                voyageId: v.id,
                                gareDepartNom: depart,
                                gareArriveeNom: arrivee,
                                gareDepartLat: v.programme?.gareDepartLat,
                                gareDepartLng: v.programme?.gareDepartLng,
                                gareArriveeLat: v.programme?.gareArriveeLat,
                                gareArriveeLng: v.programme?.gareArriveeLng,
                                vehiculeImmat: immat,
                                dateVoyage: v.dateVoyage,
                              ),
                            ),
                          );
                        },
                      ),
                      const Gap(8),
                      _ActionBtn(
                        icon: Icons.flag_rounded,
                        label: 'Terminer le voyage',
                        color: const Color(0xFF10B981),
                        onTap: () => _doAction(
                                () => widget.provider.completeVoyage(v.id)),
                      ),
                    ],

                    const Gap(8),

                    // Signaler (toujours disponible) — switch to tab 4
                    _ActionBtn(
                      icon: Icons.warning_amber_rounded,
                      label: 'Faire un signalement',
                      color: Colors.orange,
                      outlined: true,
                      onTap: () {
                        Navigator.pop(context);
                        context.read<DriverProvider>().setIndex(4);
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

class _StatusPill extends StatelessWidget {
  final String statut;
  const _StatusPill({required this.statut});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (statut) {
      case 'en_attente':
        color = Colors.orange;
        label = 'En attente';
        break;
      case 'confirme':
        color = Colors.blue;
        label = 'Confirmé';
        break;
      case 'en_cours':
        color = Colors.green;
        label = 'En cours';
        break;
      default:
        color = Colors.grey;
        label = statut;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label,
          style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }
}

// ======== BANNIÈRE VOYAGES BLOQUÉS ========
class _BlockedVoyagesBanner extends StatelessWidget {
  final List<VoyageModel> blockedVoyages;
  final void Function(VoyageModel) onComplete;

  const _BlockedVoyagesBanner({
    required this.blockedVoyages,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
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
      child: Padding(
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
                        '⚠️ Voyage(s) non terminé(s)',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${blockedVoyages.length} voyage(s) de jours précédents à clôturer',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(14),
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
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(route,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              )),
                          const Gap(2),
                          Text(dateStr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.7),
                                fontSize: 11,
                              )),
                        ],
                      ),
                    ),
                    const Gap(8),
                    GestureDetector(
                      onTap: () => onComplete(v),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 7),
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
            }),
          ],
        ),
      ),
    );
  }
}
