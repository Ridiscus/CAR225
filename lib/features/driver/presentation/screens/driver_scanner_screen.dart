import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../widgets/success_modal.dart';

class DriverScannerScreen extends StatefulWidget {
  const DriverScannerScreen({super.key});

  @override
  State<DriverScannerScreen> createState() => _DriverScannerScreenState();
}

class _DriverScannerScreenState extends State<DriverScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
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
      ..addListener(() => setState(() {}));
    
    // Auto start scanning
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScan();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _startScan() async {
    _animationController.repeat(reverse: true);
    setState(() => _isScanning = true);
    await _scannerController.start();
  }

  Future<void> _stopScan() async {
    _animationController.stop();
    await _scannerController.stop();
    setState(() => _isScanning = false);
  }

  void _handleBarcodeDetection(BarcodeCapture capture) {
    if (_hasDetected || !_isScanning) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      _hasDetected = true;
      final String code = barcodes.first.rawValue ?? "";
      if (code.isNotEmpty) {
        _stopScan();
        _validateTicket(code);
      }
    }
  }

  void _validateTicket(String reference) async {
    HapticFeedback.heavyImpact();
    final provider = context.read<DriverProvider>();
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.white)),
    );

    final res = await provider.validateTicket(reference);
    Navigator.pop(context); // Close loading

    if (res['success'] == true) {
      _showSuccess(res['message'] ?? "Billet validé avec succès !");
    } else {
      _showError(res['message'] ?? "Billet invalide ou déjà utilisé.");
    }
  }

  void _showSuccess(String message) {
    showGeneralDialog(
      context: context,
      pageBuilder: (context, anim1, anim2) => SuccessModal(
        message: message,
        onPressed: () {
          setState(() {
            _hasDetected = false;
          });
          _startScan();
        },
      ),
    );
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Icon(Icons.error_outline, color: Colors.red, size: 60),
        content: Text(message, textAlign: TextAlign.center),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _hasDetected = false);
              _startScan();
            },
            child: const Text("RÉESSAYER"),
          ),
        ],
      ),
    );
  }
  void _showManualEntryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Saisir la référence"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "Ex: REF123456",
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.characters,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () {
              final ref = controller.text.trim();
              if (ref.isNotEmpty) {
                Navigator.pop(context);
                _validateTicket(ref);
              }
            },
            child: const Text("VALIDER"),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Caméra
          MobileScanner(
            controller: _scannerController,
            onDetect: _handleBarcodeDetection,
          ),
          
          // Overlay
          _buildOverlay(),
          
          Positioned(
            top: 50,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),

          // Bouton Saisie Manuelle
          Positioned(
            top: 50,
            right: 20,
            child: TextButton.icon(
              onPressed: () => _showManualEntryDialog(),
              icon: const Icon(Icons.keyboard, color: Colors.white),
              label: const Text("Saisir", style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
          
          // Instructions
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: const Text(
                  "ALIGNER LE CODE DANS LE CADRE",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay() {
    return ColorFiltered(
      colorFilter: ColorFilter.mode(
        Colors.black.withValues(alpha: 0.7),
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
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          // Ligne d'animation
          Center(
            child: SizedBox(
               width: 250,
               height: 250,
               child: Stack(
                 children: [
                    if (_isScanning)
                      Positioned(
                        top: _animation.value,
                        left: 0,
                        right: 0,
                        child: Container(
                          height: 2,
                          color: AppColors.primary,
                        ),
                      ),
                 ],
               ),
            ),
          )
        ],
      ),
    );
  }
}
