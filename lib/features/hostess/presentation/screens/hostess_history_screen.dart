import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:car225/core/theme/app_colors.dart';

class HostessHistoryScreen extends StatefulWidget {
  const HostessHistoryScreen({super.key});

  @override
  State<HostessHistoryScreen> createState() => _HostessHistoryScreenState();
}

class _HostessHistoryScreenState extends State<HostessHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isFiltered = false;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _allHistorySales = [
    {
      'id': 'TK-001',
      'passenger': 'Jean-Pierre Mbarga',
      'route': 'Abidjan → Yamoussoukro',
      'seat': 'A12',
      'amount': '5,000',
      'date': '09 Fév 2026',
      'time': '14:30',
      'dateTime': DateTime(2026, 2, 9, 14, 30),
      'status': 'confirmed',
    },
    {
      'id': 'TK-002',
      'passenger': 'Marie-Claire Fotso',
      'route': 'Yamoussoukro → Bouaké',
      'seat': 'B05',
      'amount': '4,500',
      'date': '09 Fév 2026',
      'time': '12:15',
      'dateTime': DateTime(2026, 2, 9, 12, 15),
      'status': 'confirmed',
    },
    {
      'id': 'TK-003',
      'passenger': 'Paul Ndjock',
      'route': 'Bouaké → Korhogo',
      'seat': 'C08',
      'amount': '3,500',
      'date': '08 Fév 2026',
      'time': '16:45',
      'dateTime': DateTime(2026, 2, 8, 16, 45),
      'status': 'cancelled',
    },
    {
      'id': 'TK-004',
      'passenger': 'Awa Diop',
      'route': 'Korhogo → Abidjan',
      'seat': 'D02',
      'amount': '15,000',
      'date': '08 Fév 2026',
      'time': '08:00',
      'dateTime': DateTime(2026, 2, 8, 8, 0),
      'status': 'confirmed',
    },
    {
      'id': 'TK-005',
      'passenger': 'Koffi Kouamé',
      'route': 'Yamoussoukro → Abidjan',
      'seat': 'A03',
      'amount': '7,000',
      'date': '07 Fév 2026',
      'time': '10:30',
      'dateTime': DateTime(2026, 2, 7, 10, 30),
      'status': 'confirmed',
    },
  ];

  List<Map<String, dynamic>> get _filteredSales {
    if (!_isFiltered || (_startDate == null && _endDate == null)) {
      return _allHistorySales;
    }

    return _allHistorySales.where((sale) {
      final saleDate = sale['dateTime'] as DateTime;
      final start = _startDate != null
          ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
          : DateTime(2000);
      final end = _endDate != null
          ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
          : DateTime(2100);
      return saleDate.isAfter(start) && saleDate.isBefore(end);
    }).toList();
  }

  Future<void> _selectStartDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: _endDate ?? DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _selectEndDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? (_startDate ?? DateTime.now()),
      firstDate: _startDate ?? DateTime(2025),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            onSurface: Color(0xFF1E293B),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _applyFilter() async {
    setState(() {
      _isLoading = true;
    });

    // Simulation d'un chargement réseau
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      setState(() {
        _isFiltered = true;
        _isLoading = false;
      });
    }
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _isFiltered = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredSales;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildPremiumHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : (filtered.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          key: const PageStorageKey('hostess_history_scroll'),
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            20,
                            10,
                            20,
                            120,
                          ), // Padding bas pour CurvedNavigationBar
                          itemCount: filtered.length,
                          itemBuilder: (context, index) =>
                              _buildHistoryItem(context, filtered[index]),
                        )),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final fmt = DateFormat('dd/MM/yyyy');
    final startLabel = _startDate != null
        ? fmt.format(_startDate!)
        : 'jj/mm/aaaa';
    final endLabel = _endDate != null ? fmt.format(_endDate!) : 'jj/mm/aaaa';
    final hasFilter = _startDate != null || _endDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 5,
        20,
        22,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 12,
            // offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Titre + bouton reset ──────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique des ventes',
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.8,
                    ),
                  ),
                  Text(
                    'Suivi de vos transactions',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (hasFilter || _isFiltered)
                GestureDetector(
                  onTap: _resetFilter,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(20),
          // ── Deux champs date + bouton recherche ───────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Champ Du
              Expanded(
                child: _buildDateField(
                  label: 'Du',
                  value: startLabel,
                  isEmpty: _startDate == null,
                  onTap: () => _selectStartDate(context),
                ),
              ),
              const Gap(10),
              // Champ Au
              Expanded(
                child: _buildDateField(
                  label: 'Au',
                  value: endLabel,
                  isEmpty: _endDate == null,
                  onTap: () => _selectEndDate(context),
                ),
              ),
              const Gap(12),
              // Bouton recherche
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _isLoading
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            _applyFilter();
                          },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: AppColors.primary.withOpacity(0.1),
                    highlightColor: AppColors.primary.withOpacity(0.05),
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: _isLoading
                          ? const Center(
                              child: SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            )
                          : const Icon(
                              Icons.search_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required String value,
    required bool isEmpty,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const Gap(6),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isEmpty
                    ? Colors.white.withOpacity(0.4)
                    : Colors.white,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_rounded,
                  size: 14,
                  color: isEmpty ? const Color(0xFFB0BEC5) : AppColors.primary,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isEmpty
                          ? const Color.fromARGB(255, 103, 105, 106)
                          : const Color(0xFF1E293B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Gap(100),
          SizedBox(
            height: 40,
            width: 40,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          Gap(24),
          Text(
            'Recherche en cours...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          Gap(8),
          Text(
            'Nous récupérons vos ventes',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 70),
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: Color(0xFF94A3B8),
            ),
          ),
          const Gap(24),
          const Text(
            'Aucune vente trouvée',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const Gap(8),
          const Text(
            'Essayez une autre période de temps.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map<String, dynamic> sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
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
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      sale['id'],
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    _buildStatusBadge(sale['status']),
                  ],
                ),
                const Gap(8),
                Text(
                  sale['passenger'],
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
                        sale['route'],
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
                      '${sale['date']} • ${sale['time']}',
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
                        'Place ${sale['seat']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                    Text(
                      '${sale['amount']} FCFA',
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

  void _showSaleDetails(BuildContext context, Map<String, dynamic> sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSaleDetailsContent(context, sale),
    );
  }

  Widget _buildSaleDetailsContent(
    BuildContext context,
    Map<String, dynamic> sale,
  ) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: SafeArea(
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
                _buildStatusBadge(sale['status']),
              ],
            ),
            const Gap(24),
            _buildDetailRow('N° Billet', sale['id'], isHighlight: true),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            _buildDetailRow('Passager', sale['passenger']),
            const Gap(16),
            _buildDetailRow('Trajet', sale['route']),
            const Gap(16),
            _buildDetailRow('Date', sale['date']),
            const Gap(16),
            _buildDetailRow('Heure', sale['time']),
            const Gap(16),
            _buildDetailRow('Place', sale['seat']),
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
                  '${sale['amount']} FCFA',
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
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
    final isConfirmed = status == 'confirmed';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
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
