import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:car225/core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../models/sale_model.dart';
import '../providers/hostess_sales_provider.dart';



class HostessHistoryScreen extends StatefulWidget {
  const HostessHistoryScreen({super.key});

  @override
  State<HostessHistoryScreen> createState() => _HostessHistoryScreenState();
}

class _HostessHistoryScreenState extends State<HostessHistoryScreen> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    // Charge les ventes dès l'ouverture de l'écran.
    // Utilisation de addPostFrameCallback car on ne peut pas appeler un Provider dans un initState directement.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilter();
    });
  }


  Future<void> _applyFilter() async {
    FocusScope.of(context).unfocus();

    // 1. Récupération du Provider
    final provider = context.read<HostessSalesProvider>();

    try {
      // 2. Instanciation du Repository exactement comme dans ton ChangePassword
      final repository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      // 3. On passe le repository au Provider pour qu'il fasse l'appel
      await provider.fetchSalesHistory(
        repository,
        startDate: _startDate,
        endDate: _endDate,
      );

      // 4. Si une erreur est interceptée par le Provider, on l'affiche
      if (mounted && provider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Sécurité supplémentaire au cas où l'instanciation elle-même échoue
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur inattendue : $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _resetFilter() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    // On relance la recherche sans filtre
    _applyFilter();
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
    if (picked != null) {
      setState(() => _startDate = picked);
    }
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
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. On récupère les données de l'API via le Provider
    final salesProvider = context.watch<HostessSalesProvider>();
    final isLoading = salesProvider.isLoading;
    final List<HostessSaleModel> allSales = salesProvider.sales;

    // 2. 🟢 ON FILTRE LOCALEMENT LES DONNÉES ICI
    List<HostessSaleModel> filtered = allSales.where((sale) {
      // S'il n'y a aucun filtre, on affiche tout
      if (_startDate == null && _endDate == null) return true;

      try {
        // Attention : Adapte le format 'yyyy-MM-dd' ou 'dd/MM/yyyy' selon
        // la façon dont ton API renvoie la date (sale.date) !
        final saleDate = DateFormat('yyyy-MM-dd').parse(sale.date);

        final start = _startDate != null
            ? DateTime(_startDate!.year, _startDate!.month, _startDate!.day)
            : DateTime(2000);

        final end = _endDate != null
            ? DateTime(_endDate!.year, _endDate!.month, _endDate!.day, 23, 59, 59)
            : DateTime(2100);

        return saleDate.isAfter(start) && saleDate.isBefore(end);
      } catch (e) {
        // Si la date n'est pas "parsable", on l'affiche par défaut
        return true;
      }
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildPremiumHeader(isLoading), // Ton header parfait
          Expanded(
            child: isLoading
                ? _buildLoadingState()
                : (filtered.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              key: const PageStorageKey('hostess_history_scroll'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 120),
              itemCount: filtered.length,
              itemBuilder: (context, index) =>
                  _buildHistoryItem(context, filtered[index]),
            )),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumHeader(bool isLoading) {
    final fmt = DateFormat('dd/MM/yyyy');
    final startLabel = _startDate != null ? fmt.format(_startDate!) : 'jj/mm/aaaa';
    final endLabel = _endDate != null ? fmt.format(_endDate!) : 'jj/mm/aaaa';
    final hasFilter = _startDate != null || _endDate != null;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 5, 20, 22),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(36)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Historique des ventes',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.8),
                  ),
                  Text(
                    'Suivi de vos transactions',
                    style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              if (hasFilter)
                GestureDetector(
                  onTap: _resetFilter,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
          const Gap(20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'Du',
                  value: startLabel,
                  isEmpty: _startDate == null,
                  onTap: () => _selectStartDate(context),
                ),
              ),
              const Gap(10),
              Expanded(
                child: _buildDateField(
                  label: 'Au',
                  value: endLabel,
                  isEmpty: _endDate == null,
                  onTap: () => _selectEndDate(context),
                ),
              ),
              const Gap(12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 8)),
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2)),
                  ],
                ),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: isLoading
                        ? null
                        : () {
                      HapticFeedback.mediumImpact();
                      _applyFilter();
                    },
                    borderRadius: BorderRadius.circular(16),
                    splashColor: AppColors.primary.withValues(alpha: 0.1),
                    child: SizedBox(
                      height: 50,
                      width: 50,
                      child: isLoading
                          ? const Center(
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        ),
                      )
                          : const Icon(Icons.search_rounded, color: AppColors.primary, size: 28),
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

  Widget _buildDateField({required String label, required String value, required bool isEmpty, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
          ),
          const Gap(6),
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isEmpty ? Colors.white.withValues(alpha: 0.4) : Colors.white, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, size: 14, color: isEmpty ? const Color(0xFFB0BEC5) : AppColors.primary),
                const Gap(8),
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isEmpty ? const Color.fromARGB(255, 103, 105, 106) : const Color(0xFF1E293B),
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
            child: CircularProgressIndicator(strokeWidth: 3, valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary)),
          ),
          Gap(24),
          Text('Recherche en cours...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          Gap(8),
          Text('Nous récupérons vos ventes', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
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
            decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.search_off_rounded, size: 64, color: Color(0xFF94A3B8)),
          ),
          const Gap(24),
          const Text('Aucune vente trouvée', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
          const Gap(8),
          const Text('Essayez une autre période de temps.', style: TextStyle(fontSize: 14, color: Color(0xFF64748B))),
        ],
      ),
    );
  }

  // 🟢 UTILISATION DU MODEL HostessSaleModel
  Widget _buildHistoryItem(BuildContext context, HostessSaleModel sale) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
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
                      sale.ticketNo,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 0.5),
                    ),
                    _buildStatusBadge(sale.statut),
                  ],
                ),
                const Gap(8),
                Text(sale.passager, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A))),
                const Gap(6),
                Row(
                  children: [
                    const Icon(Icons.route_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const Gap(6),
                    Expanded(
                      child: Text(sale.trajet, style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500)),
                    ),
                  ],
                ),
                const Gap(4),
                Row(
                  children: [
                    const Icon(Icons.calendar_month_rounded, size: 14, color: Color(0xFF94A3B8)),
                    const Gap(6),
                    Text('${sale.date} • ${sale.heure}', style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
                  ],
                ),
                const Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(8)),
                      child: Text('Place ${sale.siege}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B))),
                    ),
                    Text(sale.prix, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1E293B))),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 🟢 UTILISATION DU MODEL HostessSaleModel ICI AUSSI
  void _showSaleDetails(BuildContext context, HostessSaleModel sale) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildSaleDetailsContent(context, sale),
    );
  }

  Widget _buildSaleDetailsContent(BuildContext context, HostessSaleModel sale) {
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
                decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Gap(24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Détails de la vente', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A))),
                _buildStatusBadge(sale.statut),
              ],
            ),
            const Gap(24),
            _buildDetailRow('N° Billet', sale.ticketNo, isHighlight: true),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            _buildDetailRow('Passager', sale.passager),
            const Gap(16),
            _buildDetailRow('Trajet', sale.trajet),
            const Gap(16),
            _buildDetailRow('Date', sale.date),
            const Gap(16),
            _buildDetailRow('Heure', sale.heure),
            const Gap(16),
            _buildDetailRow('Place', sale.siege),
            const Divider(height: 32, color: Color(0xFFEEEEEE)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Montant total', style: TextStyle(fontSize: 16, color: Color(0xFF757575), fontWeight: FontWeight.w600)),
                Text(sale.prix, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.primary)),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Fermer', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: Color(0xFF757575), fontWeight: FontWeight.w500)),
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
    final isConfirmed = status.toLowerCase() == 'confirmé';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isConfirmed ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isConfirmed ? const Color(0xFF2E7D32) : const Color(0xFFE65100),
        ),
      ),
    );
  }
}