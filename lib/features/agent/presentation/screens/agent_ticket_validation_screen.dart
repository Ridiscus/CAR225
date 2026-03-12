import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'scan_result_screen.dart';

class AgentTicketValidationScreen extends StatefulWidget {
  final String from;
  final String to;
  final String busId;

  const AgentTicketValidationScreen({
    super.key,
    required this.from,
    required this.to,
    required this.busId,
  });

  @override
  State<AgentTicketValidationScreen> createState() =>
      _AgentTicketValidationScreenState();
}

class _AgentTicketValidationScreenState
    extends State<AgentTicketValidationScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  bool _hasDetected = false;

  late AnimationController _animationController;
  late Animation<double> _animation;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );

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

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (_hasDetected || !_isScanning) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      _hasDetected = true;
      final String code = barcodes.first.rawValue ?? "ID-INCONNU";

      HapticFeedback.heavyImpact();
      _stopScan();
      _navigateToResult(code);
    }
  }

  void _stopScan() {
    setState(() => _isScanning = false);
    _animationController.stop();
    _scannerController.stop();
  }

  void _startScan() {
    setState(() {
      _isScanning = true;
      _hasDetected = false;
    });
    _animationController.repeat(reverse: true);
    _scannerController.start();
  }

  void _navigateToResult(String code) async {
    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ScanResultScreen(ticketReference: code),
      ),
    );

    if (mounted) {
      _startScan();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Scanner
            MobileScanner(
              controller: _scannerController,
              onDetect: _handleBarcodeDetection,
            ),

            // Top Info Bar
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Validation des Billets",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            "${widget.from} ➔ ${widget.to}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        widget.busId,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scanner Frame
            Center(
              child: Column(
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

                      // Scanning Line
                      if (_isScanning)
                        Positioned(
                          top: _animation.value + 15,
                          left: 30,
                          right: 30,
                          child: Container(
                            height: 3,
                            decoration: BoxDecoration(
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.6,
                                  ),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const Gap(40),
                  const Text(
                    "Scanner le code QR du billet",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    "Maintenez le billet dans le cadre",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Flash & Controls
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildActionButton(
                    icon: Icons.flashlight_on_rounded,
                    onTap: () => _scannerController.toggleTorch(),
                  ),
                  const Gap(30),
                  _buildCaptureCircle(),
                  const Gap(30),
                  _buildActionButton(
                    icon: Icons.flip_camera_ios_rounded,
                    onTap: () => _scannerController.switchCamera(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildCaptureCircle() {
    return Container(
      height: 80,
      width: 80,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Icon(
            Icons.qr_code_2_rounded,
            color: AppColors.primary,
            size: 35,
          ),
        ),
      ),
    );
  }
}
