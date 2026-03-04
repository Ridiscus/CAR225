import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'hostess_main_wrapper.dart';
import '../widgets/hostess_header.dart';

class HostessHomeScreen extends StatefulWidget {
  const HostessHomeScreen({super.key});
  @override
  State<HostessHomeScreen> createState() => _HostessHomeScreenState();
}

class _HostessHomeScreenState extends State<HostessHomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // 1. HEADER FIXE
          const HostessHeader(),
          // 2. CONTENU SCROLLABLE
          Expanded(
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDashboardHeader(),
                  const Gap(10),
                  _buildMetricsGrid(),
                  const Gap(20),
                  _buildActionButton(),
                  const Gap(30),
                  _buildSalesTableHeader(),
                  const Gap(12),
                  _buildSalesTable(),
                  const Gap(
                    120,
                  ), // Espace pour ne pas être caché par le CurvedNavigationBar
                ],
              ),
            ),
          ),
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
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            title: 'Tickets vendus',
            value: '28',
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
            value: '450,000',
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
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A1A1A),
                  letterSpacing: -1,
                ),
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
          final state = context
              .findAncestorStateOfType<HostessMainWrapperState>();
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
            final state = context
                .findAncestorStateOfType<HostessMainWrapperState>();
            if (state != null) state.setIndex(3);
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

  Widget _buildSalesTable() {
    final List<Map<String, dynamic>> mockSales = [
      {
        'id': 'TK-001',
        'passenger': 'Jean-Pierre Mbarga',
        'route': 'Douala → Yaoundé',
        'seat': 'A12',
        'amount': '5,000',
        'status': 'confirmed',
      },
      {
        'id': 'TK-002',
        'passenger': 'Marie-Claire Fotso',
        'route': 'Yaoundé → Bafoussam',
        'seat': 'B05',
        'amount': '4,500',
        'status': 'confirmed',
      },
      {
        'id': 'TK-003',
        'passenger': 'Paul Ndjock',
        'route': 'Douala → Kribi',
        'seat': 'C08',
        'amount': '3,500',
        'status': 'pending',
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
      ),
      child: Column(
        children: mockSales.asMap().entries.map((entry) {
          final index = entry.key;
          final sale = entry.value;
          final isLast = index == mockSales.length - 1;

          return _buildSaleRow(
            id: sale['id'],
            passenger: sale['passenger'],
            route: sale['route'],
            seat: sale['seat'],
            amount: sale['amount'],
            status: sale['status'],
            isLast: isLast,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSaleRow({
    required String id,
    required String passenger,
    required String route,
    required String seat,
    required String amount,
    required String status,
    required bool isLast,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showSaleDetails(context, {
          'id': id,
          'passenger': passenger,
          'route': route,
          'seat': seat,
          'amount': amount,
          'status': status,
        }),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFFF0F0F0), width: 1),
                  ),
          ),
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
                    color: Color(0xFF9E9E9E),
                  ),
                  const Gap(6),
                  Expanded(
                    child: Text(
                      route,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Place $seat',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF666666),
                      ),
                    ),
                  ),
                  Text(
                    '$amount FCFA',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ],
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
                  backgroundColor: const Color(0xFF1A1A1A),
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
      if (mounted) {
        setState(() {
          _updateDateTime();
        });
      }
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
      width: 105, // Taille fixe pour éviter les micro-vibrations du layout
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
