import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';
import 'package:car225/features/hostess/models/passenger_info.dart';
import 'package:car225/features/hostess/utils/ticket_pdf_generator.dart';

class HostessTicketResultScreen extends StatelessWidget {
  final bool isRoundTrip;
  final List<PassengerInfo> passengers;
  final String departure;
  final String arrival;
  final String travelDate;
  final String travelTime;
  final int totalPrice;

  const HostessTicketResultScreen({
    super.key,
    required this.isRoundTrip,
    required this.passengers,
    required this.departure,
    required this.arrival,
    required this.travelDate,
    required this.travelTime,
    required this.totalPrice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(
        title: 'Billets Générés',
        showLeading: false,
        leadingIcon: null,
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSummaryCard(),
                    const Gap(24),
                    _buildTicketsList(),
                    const Gap(20),
                  ],
                ),
              ),
            ),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.confirmation_number_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Vente confirmée',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(4),
                    Text(
                      '${passengers.length} billet(s) ${isRoundTrip ? "aller-retour" : "aller simple"}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total payé',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '$totalPrice FCFA',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Liste des billets',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.grey[800],
          ),
        ),
        const Gap(16),
        ...List.generate(
          passengers.length,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildTicketListItem(index + 1),
          ),
        ),
      ],
    );
  }

  Widget _buildTicketListItem(int ticketNumber) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header (Badge # + Type) ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$ticketNumber',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const Gap(12),
                Text(
                  'Billet ${isRoundTrip ? "Aller-Retour" : "Aller Simple"}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
              ],
            ),
          ),

          // ── Trajet (Mise en avant Départ/Arrivée) ──
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DÉPART',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        departure,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F5F7),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'ARRIVÉE',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        arrival,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A1A),
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xFFF0F0F0)),

          // ── Bouton Aperçu (En bas) ──
          Padding(
            padding: const EdgeInsets.all(12),
            child: Builder(
              builder: (context) => SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _showTicketDetails(context, ticketNumber),
                  icon: const Icon(Icons.remove_red_eye_outlined, size: 18),
                  label: const Text(
                    'VOIR L\'APERÇU DU BILLET',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTicketDetails(BuildContext context, int ticketNumber) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.95,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 15),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Gap(15),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Billet #$ticketNumber',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.grey[100],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(20),
              // Ticket content
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      _buildTicketCard(context, 'ALLER', ticketNumber),
                      if (isRoundTrip) ...[
                        const Gap(24),
                        _buildTicketCard(
                          context,
                          'RETOUR',
                          ticketNumber,
                          isReturn: true,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              // Bottom actions
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final pricePerTicket = totalPrice ~/ passengers.length;
                      final passengerIndex =
                          (ticketNumber - 1) % passengers.length;
                      await TicketPdfGenerator.printSingleTicket(
                        ticketNumber: ticketNumber,
                        passengerName: passengers[passengerIndex].fullName,
                        departure: departure,
                        arrival: arrival,
                        travelDate: travelDate,
                        travelTime: travelTime,
                        isRoundTrip: isRoundTrip,
                        price: pricePerTicket,
                      );
                    },
                    icon: const Icon(Icons.print_rounded, color: Colors.white),
                    label: const Text(
                      'Imprimer ce billet',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
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

  Widget _buildTicketCard(
    BuildContext context,
    String title,
    int ticketNumber, {
    bool isReturn = false,
  }) {
    final fromCity = isReturn ? arrival : departure;
    final toCity = isReturn ? departure : arrival;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE0E0E0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // QR CODE SECTION
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                ),
                const Gap(20),
                QrImageView(
                  data:
                      'TICKET-$ticketNumber-${isReturn ? "RET" : "GO"}-${DateTime.now().millisecondsSinceEpoch}',
                  version: QrVersions.auto,
                  size: 160.0,
                  eyeStyle: const QrEyeStyle(color: Color(0xFF263238)),
                ),
                const Gap(12),
                Text(
                  'ID: #225-$ticketNumber-${isReturn ? "R" : "A"}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // DOTTED LINE
          Row(
            children: List.generate(
              30,
              (index) => Expanded(
                child: Container(
                  height: 1,
                  color: index % 2 == 0
                      ? Colors.transparent
                      : Colors.grey.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),

          // INFO SECTION
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _buildInfoRow(
                  'PASSAGER',
                  passengers[(ticketNumber - 1) % passengers.length].fullName,
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: _buildInfoItem('DE', fromCity)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    Expanded(child: _buildInfoItem('VERS', toCity)),
                  ],
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoItem('DATE', travelDate),
                    _buildInfoItem('HEURE', travelTime),
                  ],
                ),
                const Gap(20),
                // Prix du billet
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'PRIX',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF666666),
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '${totalPrice ~/ passengers.length} FCFA',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
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

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const Gap(6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF1A1A1A),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1,
          ),
        ),
        const Gap(6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1A1A),
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                await TicketPdfGenerator.printAllTickets(
                  passengerCount: passengers.length,
                  passengerName: passengers.map((p) => p.fullName).join(', '),
                  departure: departure,
                  arrival: arrival,
                  travelDate: travelDate,
                  travelTime: travelTime,
                  isRoundTrip: isRoundTrip,
                  totalPrice: totalPrice,
                );
              },
              icon: const Icon(Icons.print_rounded, color: Colors.white),
              label: const Text(
                'IMPRIMER TOUS LES BILLETS',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF263238),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
          const Gap(12),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () {
                // Retourne à la racine (Accueil) pour commencer une nouvelle vente
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: const Icon(
                Icons.add_shopping_cart_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'NOUVELLE VENTE',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
