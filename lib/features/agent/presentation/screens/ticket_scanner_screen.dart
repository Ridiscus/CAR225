import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/repositories/agent_repository_impl.dart';
import 'scan_result_screen.dart';

import '../../data/models/programme_model.dart';

class TicketScannerScreen extends StatefulWidget {
  const TicketScannerScreen({super.key});
  @override
  State<TicketScannerScreen> createState() => _TicketScannerScreenState();
}

class _TicketScannerScreenState extends State<TicketScannerScreen>
    with SingleTickerProviderStateMixin {
  bool _isScanning = false;
  bool _hasDetected = false;

  // 🟢 NOUVELLES VARIABLES POUR LA SÉLECTION
  int? _selectedVehiculeId;
  int? _selectedProgrammeId;

  // Pour l'interface, on s'assure que le scanner ne démarre pas sans ces infos
  bool get _isReadyToScan => _selectedVehiculeId != null && _selectedProgrammeId != null;

  late AnimationController _animationController;
  late Animation<double> _animation;
  final MobileScannerController _scannerController = MobileScannerController(
    detectionSpeed: DetectionSpeed.normal,
    facing: CameraFacing.back,
  );
  final AudioPlayer _audioPlayer = AudioPlayer();
  final TextEditingController _referenceController = TextEditingController(); // Nouveau controller

  late final AgentRepositoryImpl _repository;

  // Variables pour l'état
  List<ProgrammeModel> _programmesList = [];
  bool _isLoadingProgrammes = true;
  ProgrammeModel? _selectedProgramme; // On stocke tout l'objet sélectionné !


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

    // 🟢 ON INITIALISE LE REPOSITORY ICI !
    _repository = AgentRepositoryImpl(remoteDataSource: AgentRemoteDataSourceImpl());

    // 🟢 On charge les programmes puis on affiche la modale
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _fetchProgrammes();
      if (mounted) _showConfigurationSheet();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _scannerController.dispose();
    _audioPlayer.dispose();
    _referenceController.dispose();
    super.dispose();
  }

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
      _navigateToResult(code, isManual: false);
    }
  }

  void _navigateToResult(String code, {required bool isManual}) async {
    if (!isManual) {
      HapticFeedback.heavyImpact();
      try {
        await _audioPlayer.play(AssetSource('sounds/beep.wav'));
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (_) {}
    }

    if (!mounted) return;

    await Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => ScanResultScreen(
          ticketReference: code,
          isManual: isManual,
          // 🟢 UTILISE L'OBJET SÉLECTIONNÉ ICI
          vehiculeId: _selectedProgramme?.vehiculeId ?? 0,
          programmeId: _selectedProgramme?.id ?? 0,
        ),
      ),
    );

    if (mounted) {
      setState(() {
        _hasDetected = false;
        _isScanning = false;
      });
    }
  }



  Future<void> _fetchProgrammes() async {
    try {
      // Appel à ton API via le repository !
      final programmes = await _repository.getTodayProgrammes();

      if (mounted) {
        setState(() {
          _programmesList = programmes;
          _isLoadingProgrammes = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingProgrammes = false);
        // On affiche un petit message d'erreur si ça échoue
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  // 🟢 NOUVELLE MÉTHODE : BOTTOM SHEET POUR LA SAISIE MANUELLE
  void _showManualEntrySheet() {
    _stopScanAnimation(); // On met le scan en pause
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Saisir la référence",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const Gap(16),
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                hintText: "Ex: RES-XXXXXXXX",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (value) {
                if (value.isNotEmpty) {
                  Navigator.pop(context);
                  _navigateToResult(value, isManual: true);
                  _referenceController.clear();
                }
              },
            ),
            const Gap(24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (_referenceController.text.isNotEmpty) {
                    Navigator.pop(context);
                    _navigateToResult(_referenceController.text, isManual: true);
                    _referenceController.clear();
                  }
                },
                child: const Text("RECHERCHER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(30),
          ],
        ),
      ),
    );
  }

  void _showConfigurationSheet() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext context) {
        ProgrammeModel? tempSelectedProgramme = _selectedProgramme;

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 30,
                left: 24, right: 24, top: 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Configuration du départ", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const Gap(8),
                  const Text("Sélectionnez le trajet pour commencer l'embarquement.", style: TextStyle(color: Colors.grey)),
                  const Gap(24),

                  const Text("Trajet Prévu", style: TextStyle(fontWeight: FontWeight.w600)),
                  const Gap(8),

                  if (_isLoadingProgrammes)
                    const Center(child: CircularProgressIndicator())
                  else if (_programmesList.isEmpty)
                    const Text("Aucun départ prévu pour aujourd'hui.", style: TextStyle(color: Colors.redAccent))
                  else
                    DropdownButtonFormField<ProgrammeModel>(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      hint: const Text("Sélectionnez le trajet"),
                      value: tempSelectedProgramme,
                      items: _programmesList.map((prog) {
                        return DropdownMenuItem<ProgrammeModel>(
                          value: prog,
                          // Affichage clair : Départ -> Arrivée (Heure) [Plaque]
                          child: Text(
                            "${prog.pointDepart.split(',').first} -> ${prog.pointArrive.split(',').first}  (${prog.heureDepart}) [Car: ${prog.immatriculation}]",
                            style: const TextStyle(fontSize: 14),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) => setModalState(() => tempSelectedProgramme = value),
                    ),

                  const Gap(30),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: tempSelectedProgramme != null ? AppColors.primary : Colors.grey,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: tempSelectedProgramme != null
                          ? () {
                        setState(() {
                          _selectedProgramme = tempSelectedProgramme;
                        });
                        Navigator.pop(context);
                        _startScanAnimation();
                      }
                          : null,
                      child: const Text("DÉMARRER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLogo() {
    return SvgPicture.asset(
      "assets/vectors/logo_A.svg",
      height: 35,
      colorFilter: const ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
    );
  }


  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
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

              // 🟢 NOUVEAU BOUTON : SAISIE MANUELLE
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: TextButton.icon(
                  onPressed: _showManualEntrySheet,
                  icon: const Icon(Icons.keyboard, color: Colors.grey),
                  label: const Text(
                    "Saisir manuellement la référence",
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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
                  color: Colors.white.withOpacity(0.4),
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
                                color: AppColors.primary.withOpacity(0.6),
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
                        color: Colors.black.withOpacity(0.7),
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
                ? Colors.white.withOpacity(0.3)
                : Colors.redAccent.withOpacity(0.2),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _isScanning
                  ? Colors.transparent
                  : Colors.redAccent.withOpacity(0.5),
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
        if (!_isReadyToScan) {
          // Si l'agent n'a pas choisi son bus, on le force !
          _showConfigurationSheet();
          return;
        }

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
            color: Colors.white.withOpacity(0.2),
            width: 5,
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
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

}