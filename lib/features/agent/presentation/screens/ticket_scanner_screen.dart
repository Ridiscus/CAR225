import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../core/theme/app_colors.dart';
import 'scan_result_screen.dart';

class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});

  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen>
    with SingleTickerProviderStateMixin {
  // 1. VARIABLES D'ÉTAT & CONTROLLERS
  bool _isScanning = false;
  bool _hasDetected = false;

  late AnimationController _animationController;
  late Animation<double> _animation;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed:
        DetectionSpeed.normal, // Fix: 'balanced' n'existe plus en v7
    facing: CameraFacing.back,
  );

  // 2. CYCLE DE VIE (Lifecycle)
  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 245).animate(_animationController)
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  // 3. LOGIQUE & ACTIONS
  Future<void> _startScanAnimation() async {
    _animationController.repeat(reverse: true);
    setState(() => _isScanning = true);
    await _scannerController.start();
  }

  Future<void> _stopScanAnimation() async {
    _animationController.stop();
    await _scannerController.stop();
    setState(() => _isScanning = false);
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (_hasDetected || !_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      _hasDetected = true;
      final String code = barcodes.first.rawValue ?? "ID-INCONNU";

      _stopScanAnimation();
      _navigateToResult(code);
    }
  }

  void _navigateToResult(String code) async {
    HapticFeedback.heavyImpact();

    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ScanResultScreen(ticketReference: code),
      ),
    );

    // Une fois revenu sur l'écran du scanner
    if (mounted) {
      setState(() {
        _hasDetected = false;
        _isScanning = false; // On reste en pause par sécurité
      });
    }
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildLogo() {
    return SvgPicture.asset(
      "assets/vectors/logo_A.svg",
      height: 35,
      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
    );
  }

  Widget _buildScannerFrame() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 280,
              height: 280,
              child: Stack(
                children: [
                  _buildFrameCorner(Alignment.topLeft),
                  _buildFrameCorner(Alignment.topRight),
                  _buildFrameCorner(Alignment.bottomLeft),
                  _buildFrameCorner(Alignment.bottomRight),
                ],
              ),
            ),
            Container(
              width: 220,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(35),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: Stack(
                  children: [
                    MobileScanner(
                      controller: _scannerController,
                      onDetect: _handleBarcodeDetection,
                      placeholderBuilder: (context) => Container(
                        // Fix: Correction de la signature
                        color: Colors.black,
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),

                    if (_isScanning)
                      Positioned(
                        top: _animation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 3,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.6),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                            color: AppColors.primary,
                          ),
                        ),
                      ),

                    // OVERLAY SI PAS EN TRAIN DE SCANNER
                    if (!_isScanning)
                      Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.qr_code_scanner,
                                color: Colors.white54,
                                size: 40,
                              ),
                              Gap(10),
                              Text(
                                "SCANNER EN PAUSE",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const Gap(20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            color: _isScanning
                ? Colors.white.withValues(alpha: 0.3)
                : Colors.redAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isScanning
                  ? Colors.transparent
                  : Colors.redAccent.withValues(alpha: 0.5),
            ),
          ),
          child: Text(
            _isScanning
                ? 'ALIGNER LE BILLET DANS LE CADRE'
                : 'SCANNER DÉSACTIVÉ',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFrameCorner(Alignment alignment) {
    bool isLeft =
        alignment == Alignment.topLeft || alignment == Alignment.bottomLeft;
    bool isTop =
        alignment == Alignment.topLeft || alignment == Alignment.topRight;

    return Align(
      alignment: alignment,
      child: Container(
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          border: Border(
            top: isTop
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            bottom: !isTop
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            left: isLeft
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
            right: !isLeft
                ? const BorderSide(color: AppColors.primary, width: 4)
                : BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCaptureButton() {
    return GestureDetector(
      onTap: () {
        if (_isScanning) {
          _stopScanAnimation();
        } else {
          _startScanAnimation();
        }
      },
      child: Container(
        height: 85,
        width: 85,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 5,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: _isScanning ? 25 : 35,
              height: _isScanning ? 25 : 35,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(_isScanning ? 5 : 35),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 5. MÉTHODE BUILD
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const Gap(10),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: Stack(
                      children: [
                        Center(child: _buildScannerFrame()),
                        Positioned(
                          top: 30,
                          left: 24,
                          right: 24,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [_buildLogo()],
                          ),
                        ),
                        Positioned(
                          bottom: 30,
                          left: 0,
                          right: 0,
                          child: _buildCaptureButton(),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Gap(80),
            ],
          ),
        ),
      ),
    );
  }
}
