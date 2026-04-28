import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../../data/models/driver_reservation_model.dart';
import '../providers/driver_provider.dart';
import '../widgets/success_modal.dart';

const _kNavy = Color(0xFF0f172a);
const _kNavyCard = Color(0xFF1e293b);
const _kNavyMid = Color(0xFF1e3a5f);

class DriverScannerScreen extends StatefulWidget {
  const DriverScannerScreen({super.key});

  @override
  State<DriverScannerScreen> createState() => _DriverScannerScreenState();
}

class _DriverScannerScreenState extends State<DriverScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _hasDetected = false;

  late AnimationController _lineController;
  late Animation<double> _lineAnimation;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _lineAnimation =
        Tween<double>(begin: 0, end: 245).animate(_lineController)
          ..addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  @override
  void dispose() {
    _lineController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    _lineController.repeat(reverse: true);
    setState(() => _isScanning = true);
    await _scannerController.start();
  }

  Future<void> _stopScan() async {
    _lineController.stop();
    await _scannerController.stop();
    setState(() => _isScanning = false);
  }

  void _handleDetection(BarcodeCapture capture) {
    if (_hasDetected || !_isScanning) return;
    final barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        _hasDetected = true;
        _stopScan();
        HapticFeedback.heavyImpact();
        _searchTicket(code);
      }
    }
  }

  // ── Step 1: Search reservation ─────────────────────────────────────────────

  Future<void> _searchTicket(String reference) async {
    final provider = context.read<DriverProvider>();

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final res = await provider.searchReservation(reference);

    if (!mounted) return;
    Navigator.pop(context); // close loading

    if (res['success'] == true) {
      // Parse reservation from response
      final reservationJson = res['reservation'] ?? res['data'] ?? res;
      DriverReservationModel reservation;
      try {
        reservation = DriverReservationModel.fromJson(
            reservationJson is Map<String, dynamic>
                ? reservationJson
                : Map<String, dynamic>.from(reservationJson));
      } catch (_) {
        _showError('Impossible de lire les données de la réservation.');
        return;
      }
      _showConfirmationPopup(reference, reservation);
    } else {
      _showError(res['message'] ?? 'Billet introuvable.');
    }
  }

  // ── Step 2: Show confirmation popup ────────────────────────────────────────

  void _showConfirmationPopup(
      String reference, DriverReservationModel reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ReservationConfirmSheet(
        reservation: reservation,
        onConfirm: () {
          Navigator.pop(context);
          _confirmEmbarquement(reference);
        },
        onCancel: () {
          Navigator.pop(context);
          setState(() => _hasDetected = false);
          _startScan();
        },
      ),
    );
  }

  // ── Step 3: Confirm boarding ───────────────────────────────────────────────

  Future<void> _confirmEmbarquement(String reference) async {
    final provider = context.read<DriverProvider>();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );

    final res = await provider.confirmEmbarquement(reference);

    if (!mounted) return;
    Navigator.pop(context);

    if (res['success'] == true) {
      _showSuccess(res['message'] ?? 'Embarquement confirmé !');
    } else {
      _showError(res['message'] ?? 'Erreur lors de la confirmation.');
    }
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _showSuccess(String message) {
    showGeneralDialog(
      context: context,
      pageBuilder: (_, __, ___) => SuccessModal(
        message: message,
        onPressed: () {
          setState(() => _hasDetected = false);
          _startScan();
        },
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Icon(Icons.error_outline_rounded,
            color: Colors.redAccent, size: 60),
        content: Text(message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 15)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _hasDetected = false);
                _startScan();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('RÉESSAYER',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showManualEntry() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Saisir la référence',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Ex: REF-123456',
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.confirmation_number_outlined,
                color: AppColors.primary),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final ref = controller.text.trim();
              if (ref.isNotEmpty) {
                Navigator.pop(context);
                _hasDetected = true;
                _stopScan();
                _searchTicket(ref);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('RECHERCHER',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Caméra ──
            MobileScanner(
              controller: _scannerController,
              onDetect: _handleDetection,
            ),

            // ── Overlay sombre avec cadre ──
            _buildOverlay(),

            // ── Titre en haut ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.transparent,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SCANNER DE BILLETS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            'Scannez le QR code du passager',
                            style: TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Saisie manuelle
                    GestureDetector(
                      onTap: _showManualEntry,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.keyboard_rounded,
                                color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Manuel',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
            ),

            // ── Instructions en bas ──
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(30),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isScanning
                            ? Icons.wifi_tethering_rounded
                            : Icons.wifi_tethering_off_rounded,
                        color:
                            _isScanning ? AppColors.primary : Colors.grey,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isScanning
                            ? 'SCAN ACTIF — Alignez le code dans le cadre'
                            : 'SCAN INACTIF',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.72),
        BlendMode.srcOut,
      ),
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              color: Colors.black,
              backgroundBlendMode: BlendMode.dstOut,
            ),
          ),
          Center(
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Center(
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                children: [
                  if (_isScanning)
                    Positioned(
                      top: _lineAnimation.value,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 3,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.primary,
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ..._buildCorners(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCorners() {
    const size = 24.0;
    const thickness = 4.0;
    const color = AppColors.primary;

    Widget corner(
        {required double? top,
        required double? left,
        double? bottom,
        double? right}) {
      return Positioned(
        top: top,
        left: left,
        bottom: bottom,
        right: right,
        child: CustomPaint(
          size: const Size(size, size),
          painter: _CornerPainter(
            isTopLeft: top == 0 && left == 0,
            isTopRight: top == 0 && right == 0,
            isBottomLeft: bottom == 0 && left == 0,
            isBottomRight: bottom == 0 && right == 0,
            color: color,
            thickness: thickness,
          ),
        ),
      );
    }

    return [
      corner(top: 0, left: 0),
      corner(top: 0, left: null, right: 0),
      corner(top: null, left: 0, bottom: 0),
      corner(top: null, left: null, bottom: 0, right: 0),
    ];
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POPUP DE CONFIRMATION AVEC INFO PASSAGER
// ─────────────────────────────────────────────────────────────────────────────

class _ReservationConfirmSheet extends StatelessWidget {
  final DriverReservationModel reservation;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const _ReservationConfirmSheet({
    required this.reservation,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kNavy,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Poignée ──
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // ── En-tête statut ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('BILLET VALIDE',
                            style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.w800,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    reservation.reference,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 0.5),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Carte passager ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kNavyCard,
                  borderRadius: BorderRadius.circular(18),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Row(
                  children: [
                    // Photo passager
                    _PassagerAvatar(
                      photoUrl: reservation.fullPassagerPhotoUrl,
                      nom: reservation.passagerNomComplet,
                    ),
                    const SizedBox(width: 14),
                    // Infos passager
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reservation.passagerNomComplet ?? 'Passager',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (reservation.passagerTelephone != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_outlined,
                                    color: Colors.white38, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  reservation.passagerTelephone!,
                                  style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ],
                          if (reservation.passagerEmail != null) ...[
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(Icons.email_outlined,
                                    color: Colors.white38, size: 13),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    reservation.passagerEmail!,
                                    style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 12),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Siège
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.airline_seat_recline_normal_rounded,
                              color: AppColors.primary, size: 18),
                          const SizedBox(height: 3),
                          Text(
                            reservation.seatNumber.isNotEmpty
                                ? reservation.seatNumber
                                : '—',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w900,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Infos voyage ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _kNavyCard,
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.07)),
                ),
                child: Column(
                  children: [
                    // Trajet
                    Row(
                      children: [
                        const Icon(Icons.circle,
                            color: Colors.green, size: 9),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reservation.gareDepart ?? '—',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ),
                        if (reservation.heureDepart != null)
                          Text(
                            reservation.heureDepart!,
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 14),
                          ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4, top: 2, bottom: 2),
                      child: Row(
                        children: [
                          Container(width: 1, height: 16,
                              color: Colors.white24),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded,
                            color: Colors.redAccent, size: 9),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reservation.gareArrivee ?? '—',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14),
                          ),
                        ),
                      ],
                    ),

                    const Divider(color: Color(0xFF334155), height: 20),

                    // Stats : montant, aller/retour
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _InfoPill(
                          icon: Icons.payments_outlined,
                          label: 'Tarif',
                          value: reservation.montant != null
                              ? '${reservation.montant} F'
                              : '—',
                        ),
                        _InfoPill(
                          icon: reservation.isAllerRetour == true
                              ? Icons.swap_horiz_rounded
                              : Icons.arrow_forward_rounded,
                          label: 'Type',
                          value: reservation.isAllerRetour == true
                              ? 'Aller-Retour'
                              : 'Aller Simple',
                        ),
                        _InfoPill(
                          icon: Icons.confirmation_number_outlined,
                          label: 'Statut',
                          value: _statutLabel(reservation.statut),
                          valueColor: _statutColor(reservation.statut),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Boutons ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Row(
                children: [
                  // Annuler
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white24),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text('ANNULER',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Confirmer
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: onConfirm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.check_circle_rounded, size: 20),
                      label: const Text('CONFIRMER EMBARQUEMENT',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
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

  String _statutLabel(String? s) {
    switch (s) {
      case 'confirme':
      case 'confirmé':
        return 'Confirmé';
      case 'scanned':
      case 'scanné':
        return 'Scanné';
      case 'pending':
      case 'en_attente':
        return 'En attente';
      default:
        return s ?? '—';
    }
  }

  Color _statutColor(String? s) {
    switch (s) {
      case 'confirme':
      case 'confirmé':
        return Colors.green;
      case 'scanned':
      case 'scanné':
        return Colors.orange;
      default:
        return Colors.white60;
    }
  }
}

// ── Avatar passager ───────────────────────────────────────────────────────────

class _PassagerAvatar extends StatelessWidget {
  final String? photoUrl;
  final String? nom;

  const _PassagerAvatar({this.photoUrl, this.nom});

  @override
  Widget build(BuildContext context) {
    final initials = _initials();

    final initialsWidget = Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
    );

    return Container(
      width: 60,
      height: 60,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _kNavyMid,
        border: Border.all(color: AppColors.primary, width: 2.5),
      ),
      child: photoUrl != null && photoUrl!.isNotEmpty
          ? Image.network(
              photoUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => initialsWidget,
            )
          : initialsWidget,
    );
  }

  String _initials() {
    if (nom == null || nom!.isEmpty) return '?';
    final parts = nom!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return nom![0].toUpperCase();
  }
}

// ── Info pill ─────────────────────────────────────────────────────────────────

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white38, size: 16),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
              color: Colors.white38, fontSize: 10),
        ),
      ],
    );
  }
}

// ── Corner Painter ────────────────────────────────────────────────────────────

class _CornerPainter extends CustomPainter {
  final bool isTopLeft;
  final bool isTopRight;
  final bool isBottomLeft;
  final bool isBottomRight;
  final Color color;
  final double thickness;

  _CornerPainter({
    this.isTopLeft = false,
    this.isTopRight = false,
    this.isBottomLeft = false,
    this.isBottomRight = false,
    required this.color,
    required this.thickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    if (isTopLeft) {
      path.moveTo(0, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else if (isTopRight) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(size.width, size.height);
    } else if (isBottomLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.lineTo(size.width, size.height);
    } else if (isBottomRight) {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
