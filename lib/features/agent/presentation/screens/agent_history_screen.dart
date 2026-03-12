import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';

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
    final DateTime? pickedDate = await showDatePicker(
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
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(
        title: 'Historique des Scans',
        showLeading: false,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // --- HEADER: TOTAL & FILTER ---
            _buildCompactHeader(filteredScans.length),
            // --- SCANS LIST ---
            Expanded(
              child: filteredScans.isEmpty
                  ? _buildEmptyState(isFiltered: _selectedDate != null)
                  : _buildScansList(filteredScans),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactHeader(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          _buildDateTimePickerButton(),
          const Gap(16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'RÉSULTATS DES SCANS',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF90A4AE),
                  letterSpacing: 1,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF263238),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF263238).withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                    const Gap(10),
                    Text(
                      '$count SCAN${count > 1 ? 'S' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePickerButton() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.primary,
              size: 22,
            ),
            const Gap(14),
            Expanded(
              child: Text(
                _selectedDate == null
                    ? 'Rechercher par date...'
                    : DateFormat(
                        'EEEE dd MMMM yyyy',
                        'fr_FR',
                      ).format(_selectedDate!),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _selectedDate == null
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (_selectedDate != null)
              GestureDetector(
                onTap: () {
                  setState(() => _selectedDate = null);
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Color(0xFF64748B),
                    size: 16,
                  ),
                ),
              )
            else
              const Icon(
                Icons.calendar_month_rounded,
                color: Color(0xFFCBD5E1),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildScansList(List<TicketScan> scans) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      itemCount: scans.length,
      itemBuilder: (context, index) {
        return _buildScanCard(scans[index]);
      },
    );
  }

  Widget _buildScanCard(TicketScan scan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            HapticFeedback.lightImpact();
            _showScanDetails(scan);
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Ticket Icon instead of Person avatar
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.confirmation_number_rounded,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                ),
                const Gap(16),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              scan.passengerName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF263238),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm').format(scan.scanTime),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          Text(
                            'REF: ${scan.ticketId}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const Gap(8),
                          const CircleAvatar(
                            radius: 2,
                            backgroundColor: Color(0xFFB0BEC5),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'SIEGE #${scan.seatNumber}',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF64748B),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(6),
                      Text(
                        '${scan.startLocation} ➔ ${scan.location}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF78909C),
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
          bottom: true,
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
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
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
                    backgroundColor: const Color.fromARGB(255, 231, 62, 36),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'FERMER',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
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
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Color(0xFF263238),
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
