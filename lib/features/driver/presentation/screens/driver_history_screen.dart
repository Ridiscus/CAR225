import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';

const _kNavy = Color(0xFF0f172a);

class DriverHistoryScreen extends StatefulWidget {
  const DriverHistoryScreen({super.key});

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  DateTime? _selectedDate;
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = 'tous'; // 'tous' | 'termine' | 'annule'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadHistory();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();

    List<VoyageModel> voyages = provider.historyVoyages;

    // Status filter
    if (_statusFilter != 'tous') {
      voyages = voyages.where((v) => v.statut == _statusFilter).toList();
    }

    // Date filter
    if (_selectedDate != null) {
      voyages = voyages.where((v) {
        final date = DateTime.tryParse(v.dateVoyage);
        if (date == null) return false;
        return date.day == _selectedDate!.day &&
            date.month == _selectedDate!.month &&
            date.year == _selectedDate!.year;
      }).toList();
    }

    // Search filter (by immatriculation)
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      voyages = voyages.where((v) {
        final immat = (v.vehicule?.immatriculation ?? '').toLowerCase();
        final depart = (v.programme?.gareDepart ??
                v.programme?.pointDepart ??
                '')
            .toLowerCase();
        final arrivee = (v.programme?.gareArrivee ??
                v.programme?.pointArrive ??
                '')
            .toLowerCase();
        return immat.contains(query) ||
            depart.contains(query) ||
            arrivee.contains(query);
      }).toList();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Historique',
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.close_rounded,
                  color: Colors.white70, size: 20),
              tooltip: 'Effacer le filtre',
              onPressed: () => setState(() => _selectedDate = null),
            ),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.calendar_month_rounded,
                  color: Colors.white, size: 18),
            ),
            onPressed: () => _pickDate(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter bar ──
          Container(
            color: _kNavy,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                if (_selectedDate != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.filter_alt_rounded,
                            color: AppColors.primary, size: 14),
                        const Gap(6),
                        Text(
                          DateFormat('dd MMMM yyyy', 'fr_FR')
                              .format(_selectedDate!),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Gap(8),
                ],
                // ── Status chips ──
                Row(
                  children: [
                    _StatusChip(
                      label: 'Tous',
                      active: _statusFilter == 'tous',
                      color: Colors.white,
                      onTap: () => setState(() => _statusFilter = 'tous'),
                    ),
                    const Gap(8),
                    _StatusChip(
                      label: 'Terminés',
                      active: _statusFilter == 'termine',
                      color: const Color(0xFF10B981),
                      onTap: () =>
                          setState(() => _statusFilter = 'termine'),
                    ),
                    const Gap(8),
                    _StatusChip(
                      label: 'Annulés',
                      active: _statusFilter == 'annule',
                      color: const Color(0xFFEF4444),
                      onTap: () =>
                          setState(() => _statusFilter = 'annule'),
                    ),
                  ],
                ),
                const Gap(10),

                // Search bar
                Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Rechercher par immatriculation, ville...',
                      hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4), fontSize: 12),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.white.withOpacity(0.5), size: 18),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.white.withOpacity(0.5),
                                  size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── List ──
          Expanded(
            child: provider.isLoadingHistory
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : voyages.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => provider.loadHistory(),
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: voyages.length,
                          itemBuilder: (_, i) =>
                              _HistoryCard(voyage: voyages[i]),
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
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_rounded,
                size: 48, color: AppColors.primary),
          ),
          const Gap(16),
          const Text(
            'Aucun historique',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          const Gap(6),
          Text(
            'Vos voyages terminés apparaîtront ici.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE HISTORIQUE
// ─────────────────────────────────────────────────────────────────────────────
// ─────────────────────────────────────────────────────────────────────────────
// CHIP FILTRE STATUT
// ─────────────────────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _StatusChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.18) : Colors.white.withOpacity(0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withOpacity(0.7) : Colors.white.withOpacity(0.2),
            width: active ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? color : Colors.white.withOpacity(0.6),
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final VoyageModel voyage;

  const _HistoryCard({required this.voyage});

  @override
  Widget build(BuildContext context) {
    final isTermine = voyage.statut == 'termine';
    final isAnnule = voyage.statut == 'annule';
    final statusColor = isTermine
        ? const Color(0xFF10B981)
        : isAnnule
            ? const Color(0xFFEF4444)
            : Colors.grey;
    final statusLabel =
        isTermine ? 'Terminé' : isAnnule ? 'Annulé' : voyage.statut;
    final statusIcon =
        isTermine ? Icons.check_circle_rounded : Icons.cancel_rounded;

    final dateStr = voyage.dateVoyage.isNotEmpty
        ? DateFormat('dd MMM yyyy', 'fr_FR')
            .format(DateTime.tryParse(voyage.dateVoyage) ?? DateTime.now())
        : '—';

    final depart = voyage.programme?.gareDepart ??
        voyage.programme?.pointDepart ??
        '—';
    final arrivee = voyage.programme?.gareArrivee ??
        voyage.programme?.pointArrive ??
        '—';
    final heureDepart = voyage.programme?.heureDepart ?? '—';
    final immat = voyage.vehicule?.immatriculation ?? '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Status strip ──
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                top: BorderSide(color: statusColor.withOpacity(0.3)),
                left: BorderSide(color: statusColor.withOpacity(0.3)),
                right: BorderSide(color: statusColor.withOpacity(0.3)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    immat,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                const Gap(8),
                Text(
                  dateStr,
                  style: TextStyle(color: Colors.grey[500], fontSize: 11),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withOpacity(0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, color: statusColor, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Route ──
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Depart
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DÉPART',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const Gap(3),
                      Text(
                        depart,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(2),
                      Text(
                        heureDepart,
                        style: TextStyle(
                          color: isTermine
                              ? AppColors.primary
                              : Colors.grey[400],
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: isTermine ? AppColors.primary : Colors.grey,
                    size: 16,
                  ),
                ),
                // Arrivee
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ARRIVÉE',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const Gap(3),
                      Text(
                        arrivee,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                      const Gap(2),
                      Text(
                        voyage.programme?.heureArrive ?? '—',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
