import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/agent_header.dart';

class AgentHistoryScreen extends StatefulWidget {
  const AgentHistoryScreen({super.key});

  @override
  State<AgentHistoryScreen> createState() => _AgentHistoryScreenState();
}

class TicketScan {
  final String ticketId;
  final String passengerName;
  final String startLocation;
  final String location;
  final String busNumber;
  final String seatNumber;
  final DateTime scanTime;
  final ScanStatus status;

  TicketScan({
    required this.ticketId,
    required this.passengerName,
    required this.startLocation,
    required this.location,
    required this.busNumber,
    required this.seatNumber,
    required this.scanTime,
    required this.status,
  });
}

enum ScanStatus { valid, invalid }

class _AgentHistoryScreenState extends State<AgentHistoryScreen> {
  DateTime? _selectedDate;

  // Données simulées d'historique basées sur le mockup
  final List<TicketScan> _scans = [
    TicketScan(
      ticketId: 'TKT-2026-012',
      passengerName: 'Kouadio Foffi Jean',
      startLocation: 'ABIDJAN',
      location: 'BOUAKE',
      busNumber: '#225',
      seatNumber: '12',
      scanTime: DateTime.now().subtract(const Duration(minutes: 15)),
      status: ScanStatus.valid,
    ),
    TicketScan(
      ticketId: 'TKT-2026-013',
      passengerName: 'Traoré Mariam',
      startLocation: 'ABIDJAN',
      location: 'YAMOUSSOUKRO',
      busNumber: '#225',
      seatNumber: '13',
      scanTime: DateTime.now().subtract(const Duration(minutes: 10)),
      status: ScanStatus.valid,
    ),
    TicketScan(
      ticketId: 'TKT-2026-014',
      passengerName: 'Kouadio Foffi Jean',
      startLocation: 'ABIDJAN',
      location: 'KORHOGO',
      busNumber: '#228',
      seatNumber: '14',
      scanTime: DateTime.now().subtract(const Duration(minutes: 5)),
      status: ScanStatus.valid,
    ),
    TicketScan(
      ticketId: 'TKT-2026-015',
      passengerName: 'Diomandé Bakary',
      startLocation: 'ABIDJAN',
      location: 'ABENGOUROU',
      busNumber: '#228',
      seatNumber: '15',
      scanTime: DateTime.now(),
      status: ScanStatus.valid,
    ),
  ];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Color(0xFF263238),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredScans = _selectedDate == null
        ? _scans
        : _scans.where((scan) {
            return scan.scanTime.year == _selectedDate!.year &&
                scan.scanTime.month == _selectedDate!.month &&
                scan.scanTime.day == _selectedDate!.day;
          }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER AGENT ---
            const AgentHeader(),
            const Divider(height: 1, color: Color(0xFFF5F5F5)),
            const Gap(20),
            // --- DATE FILTER BAR ---
            _buildDateFilterBar(),
            // --- SECTION TITLE & DATE BADGE ---
            _buildTitleSection(),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const Gap(5),
                    // --- SCANS LIST ---
                    filteredScans.isEmpty
                        ? _buildEmptyState(isFiltered: _selectedDate != null)
                        : _buildScansList(filteredScans),
                    const Gap(100), // Espace pour la barre de nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Historique des scans',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF212121),
            ),
          ),
          if (_selectedDate == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFECEFF1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'AUJOURD\'HUI',
                style: TextStyle(
                  fontSize: 11,
                  color: Color(0xFF607D8B),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDateFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "PÉRIODE DES SCANS",
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB0BEC5),
              letterSpacing: 1.5,
            ),
          ),
          const Gap(12),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _selectedDate == null
                    ? const Color(0xFFF8F9FA)
                    : AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _selectedDate == null
                      ? const Color(0xFFECEFF1)
                      : AppColors.primary.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _selectedDate == null
                          ? Colors.white
                          : AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        if (_selectedDate != null)
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                      ],
                    ),
                    child: Icon(
                      Icons.calendar_month_rounded,
                      size: 20,
                      color: _selectedDate == null
                          ? const Color(0xFF90A4AE)
                          : Colors.white,
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'SÉLECTIONNER UNE DATE'
                              : 'FILTRE APPLIQUÉ',
                          style: TextStyle(
                            fontSize: 11,
                            color: _selectedDate == null
                                ? const Color(0xFF90A4AE)
                                : AppColors.primary,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          _selectedDate == null
                              ? 'Historique complet'
                              : DateFormat(
                                  'EEEE dd MMMM yyyy',
                                  'fr_FR',
                                ).format(_selectedDate!),
                          style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF263238),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedDate != null)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedDate = null;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEFF1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: Color(0xFF90A4AE),
                        ),
                      ),
                    )
                  else
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Color(0xFFB0BEC5),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScansList(List<TicketScan> scans) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scans.length,
      itemBuilder: (context, index) {
        return _buildScanCard(scans[index]);
      },
    );
  }

  Widget _buildScanCard(TicketScan scan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      height: 95,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.06),
          width: 1.5,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showScanDetails(scan);
            },
            child: Stack(
              children: [
                // Liseré Orange flottant/courbé à gauche
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 6,
                    decoration: const BoxDecoration(color: AppColors.primary),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      const Gap(4), // Espace pour compenser le liseré
                      // Bloc Numéro de Siège (Noir)
                      _buildSeatIndicator(scan.seatNumber),
                      const Gap(16),
                      // Infos Passager
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    scan.passengerName,
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF263238),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const Gap(10),
                                // Badge de validation (Checkmark vert)
                                Container(
                                  height: 24,
                                  width: 24,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE8F5E9),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Color(0xFF2E7D32),
                                    size: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Gap(8),
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    scan.startLocation,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB0BEC5),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 18,
                                    color: Color(0xFFB0BEC5),
                                  ),
                                ),
                                Flexible(
                                  child: Text(
                                    scan.location,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB0BEC5),
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                                const Gap(10),
                                const CircleAvatar(
                                  radius: 2.5,
                                  backgroundColor: Color(0xFFCFD8DC),
                                ),
                                const Gap(8),
                                Text(
                                  DateFormat('HH:mm').format(scan.scanTime),
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showScanDetails(TicketScan scan) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Détails du Scan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      // fontStyle: FontStyle.italic,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
              const Gap(30),
              _buildDetailItem('PASSAGER', scan.passengerName),
              _buildDetailItem('RÉFÉRENCE', scan.ticketId),
              _buildDetailItem('NUMÉRO DU CAR', scan.busNumber),
              _buildDetailItem('DEPART', scan.startLocation),
              _buildDetailItem('DESTINATION', scan.location),
              _buildDetailItem('SIÈGE', 'Case #${scan.seatNumber}'),
              _buildDetailItem(
                'HEURE DU SCAN',
                DateFormat('dd MMM yyyy à HH:mm').format(scan.scanTime),
              ),
              const Gap(40),
              SizedBox(
                height: 55,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'FERMER',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFFB0BEC5),
              letterSpacing: 1,
            ),
          ),
          const Gap(6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeatIndicator(String seat) {
    return Container(
      height: 62,
      width: 62,
      decoration: BoxDecoration(
        color: const Color(0xFF000000),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'SIEGE',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
          const Gap(2),
          Text(
            '#$seat',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Gap(30),
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary, width: 1),
            ),
            child: Icon(
              isFiltered ? Icons.search_off_rounded : Icons.history_rounded,
              size: 80,
              color: AppColors.primary,
            ),
          ),
          const Gap(24),
          Text(
            isFiltered ? 'Aucun résultat trouvé' : 'Aucun scan enregistré',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          if (isFiltered) ...[
            const Gap(10),
            const Text(
              'Essayez une autre date ou réinitialisez le filtre',
              style: TextStyle(
                fontSize: 15,
                color: Color.fromARGB(255, 169, 184, 190),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
