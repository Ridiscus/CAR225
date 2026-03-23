import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:io';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';
import '../widgets/driver_header.dart';
import '../widgets/success_modal.dart';

class DriverReportsScreen extends StatefulWidget {
  const DriverReportsScreen({super.key});

  @override
  State<DriverReportsScreen> createState() => _DriverReportsScreenState();
}

class _DriverReportsScreenState extends State<DriverReportsScreen> {
  String? _selectedType;
  final TextEditingController _descriptionController = TextEditingController();
  File? _imageFile;
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoadingLocation = false;

  final List<Map<String, dynamic>> _reportTypes = [
    {"label": "Accident", "icon": Icons.car_crash_rounded},
    {"label": "Panne", "icon": Icons.build_rounded},
    {"label": "Retard", "icon": Icons.access_time_filled_rounded},
    {"label": "Autre", "icon": Icons.warning_rounded},
  ];

  Widget _buildSectionHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const Gap(12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 17,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        imageQuality: 70,
      );
      if (image != null) {
        setState(() => _imageFile = File(image.path));
      }
    } catch (e) {
      debugPrint("Erreur lors de la sélection de l'image: $e");
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        top: false,
        bottom: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const Gap(15),
              const Text(
                "Ajouter une photo",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Gap(10),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.camera_alt, color: AppColors.primary),
                ),
                title: const Text(
                  "Prendre une photo",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(
                    Icons.photo_library,
                    color: AppColors.primary,
                  ),
                ),
                title: const Text(
                  "Choisir depuis la galerie",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              const Gap(30),
            ],
          ),
        ),
      ),
    );
  }

  void _showImagePreviewDialog() {
    if (_imageFile == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(_imageFile!),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Veuillez activer la localisation")),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Permission de localisation refusée"),
              ),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "La permission est refusée de façon permanente. Veuillez l'activer dans les paramètres.",
              ),
            ),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );

      // Récupérer l'adresse lisible (Reverse Geocoding)
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String address = "Adresse inconnue";
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // Formatter l'adresse : Rue, Ville, Pays (ou selon besoin)
        address = [
          if (place.street != null && place.street!.isNotEmpty) place.street,
          if (place.locality != null && place.locality!.isNotEmpty)
            place.locality,
          if (place.country != null && place.country!.isNotEmpty) place.country,
        ].join(', ');
      }

      setState(() {
        _currentPosition = position;
        _currentAddress = address;
        _isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint("Erreur localisation: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Impossible de récupérer la position : $e")),
        );
      }
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadSignalements();
    });
  }

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              const DriverHeader(title: "Signalements", showProfile: false),
              Container(
                color: AppColors.primary,
                child: const TabBar(
                  indicatorColor: Colors.white,
                  indicatorWeight: 3,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: [
                    Tab(text: "NOUVEAU"),
                    Tab(text: "HISTORIQUE"),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _buildNewReportTab(driverProvider),
                    _buildHistoryTab(driverProvider),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewReportTab(DriverProvider driverProvider) {
    return SafeArea(
      top: false,
      bottom: true,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 25,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (driverProvider.selectedTripForReport != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 18),
                        const Gap(8),
                        Text(
                          "SIGNALER POUR LE VOYAGE #${driverProvider.selectedTripForReport!.id}",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: AppColors.primary,
                            letterSpacing: 1,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => driverProvider.setSelectedTripForReport(null),
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const Gap(10),
                    Text(
                      "${driverProvider.selectedTripForReport!.departureStation} → ${driverProvider.selectedTripForReport!.arrivalStation}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      "${driverProvider.selectedTripForReport!.carRegistration} • ${driverProvider.selectedTripForReport!.scheduledDepartureTime.day}/${driverProvider.selectedTripForReport!.scheduledDepartureTime.month}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
              const Gap(30),
            ],
            _buildSectionHeader("1", "Type d'incident"),
            const Gap(15),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: _reportTypes.map((typeObj) {
                  final type = typeObj["label"] as String;
                  final icon = typeObj["icon"] as IconData;
                  bool isSelected = _selectedType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: InkWell(
                      onTap: () => setState(() => _selectedType = type),
                      borderRadius: BorderRadius.circular(30),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary : Colors.grey[50],
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : Colors.grey[200]!,
                            width: 1.5,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(alpha: 0.2),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 18,
                              color: isSelected ? Colors.white : AppColors.primary,
                            ),
                            const Gap(8),
                            Text(
                              type,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const Gap(35),
            _buildSectionHeader("2", "Décrivez la situation"),
            const Gap(20),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                hintText: "Ex: Le véhicule a une crevaison sur l'autoroute du nord...",
                hintStyle: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.all(18),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 211, 210, 210),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const Gap(35),
            _buildSectionHeader("3", "Preuves & Localisation"),
            const Gap(20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color.fromARGB(255, 211, 210, 210),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Gap(20),
                  // Photo Section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "PHOTO DE L'INCIDENT",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.black54,
                              letterSpacing: 1,
                            ),
                          ),
                          if (_imageFile != null)
                            Row(
                              children: [
                                InkWell(
                                  onTap: _showImageSourceDialog,
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.blue,
                                    size: 20,
                                  ),
                                ),
                                const Gap(15),
                                InkWell(
                                  onTap: () => setState(
                                    () => _imageFile = null,
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.redAccent,
                                    size: 20,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      const Gap(15),
                      GestureDetector(
                        onTap: () => _imageFile == null ? _showImageSourceDialog() : _showImagePreviewDialog(),
                        child: Container(
                          width: double.infinity,
                          height: _imageFile == null ? 100 : 180,
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(
                              color: Colors.grey[200]!,
                              style: _imageFile == null ? BorderStyle.solid : BorderStyle.none,
                            ),
                          ),
                          child: _imageFile == null
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo_outlined,
                                      color: Colors.grey[400],
                                      size: 24,
                                    ),
                                    const Gap(12),
                                    Text(
                                      "Ajouter une preuve visuelle",
                                      style: TextStyle(
                                        color: Colors.grey[500],
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                )
                              : ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                    15,
                                  ),
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      Image.file(
                                        _imageFile!,
                                        fit: BoxFit.cover,
                                      ),
                                      Positioned(
                                        right: 10,
                                        bottom: 10,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                              alpha: 0.5,
                                            ),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.fullscreen_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),
                  Divider(color: Colors.grey[100], thickness: 1),
                  const Gap(10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: _currentAddress != null ? AppColors.secondary.withValues(alpha: 0.05) : Colors.grey[50],
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: _currentAddress != null ? AppColors.secondary.withValues(alpha: 0.1) : Colors.grey[200]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _currentAddress != null ? AppColors.secondary : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "POSITION ACTUELLE",
                                style: TextStyle(
                                  color: _currentAddress != null ? AppColors.secondary : Colors.grey[500],
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                _currentAddress ?? "Recherche de position...",
                                style: TextStyle(
                                  color: _currentAddress != null ? Colors.black87 : Colors.grey[400],
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _getLocation,
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(
                                    alpha: 0.05,
                                  ),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isLoadingLocation
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.primary,
                                    ),
                                  )
                                : const Icon(
                                    Icons.my_location_rounded,
                                    color: AppColors.primary,
                                    size: 18,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(30),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.amber.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.amber,
                    size: 20,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      "Ce signalement sera immédiatement visible par la compagnie et les secours si nécessaire.",
                      style: TextStyle(
                        color: Colors.amber[900],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Gap(30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _canSubmit() ? () => _submitReport(context, driverProvider) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 5,
                  shadowColor: AppColors.primary.withValues(
                    alpha: 0.3,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    Gap(10),
                    Text(
                      "Envoyer le Signalement",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(25),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(DriverProvider provider) {
    if (provider.isLoading && provider.signalements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.signalements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 60, color: Colors.grey[300]),
            const Gap(16),
            Text(
              "Aucun historique",
              style: TextStyle(color: Colors.grey[500], fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              "Vos signalements s'afficheront ici",
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => provider.loadSignalements(),
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: provider.signalements.length,
        itemBuilder: (context, index) {
          final signalement = provider.signalements[index];
          return _buildSignalementCard(signalement);
        },
      ),
    );
  }

  Widget _buildSignalementCard(dynamic s) {
    Color statusColor;
    String statusLabel;
    switch (s.statut.toLowerCase()) {
      case 'traité':
      case 'resolved':
        statusColor = Colors.green;
        statusLabel = "Traité";
        break;
      case 'en_cours':
        statusColor = Colors.blue;
        statusLabel = "En cours";
        break;
      case 'annulé':
        statusColor = Colors.red;
        statusLabel = "Annulé";
        break;
      default:
        statusColor = Colors.orange;
        statusLabel = "Transmis";
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showSignalementDetails(s),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    s.createdAt,
                    style: TextStyle(color: Colors.grey[400], fontSize: 11),
                  ),
                ],
              ),
              const Gap(12),
              Row(
                children: [
                  Icon(_getIconForType(s.type), color: AppColors.primary, size: 20),
                  const Gap(10),
                  Text(
                    s.type,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const Gap(8),
              Text(
                s.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[600], fontSize: 13),
              ),
              if (s.voyage != null) ...[
                const Gap(12),
                const Divider(height: 1),
                const Gap(8),
                Row(
                  children: [
                    Icon(Icons.directions_bus_filled_outlined, size: 14, color: Colors.grey[400]),
                    const Gap(6),
                    Text(
                      "Voyage #${s.voyage.id}",
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type.toLowerCase()) {
      case 'accident': return Icons.car_crash_rounded;
      case 'panne': return Icons.build_rounded;
      case 'retard': return Icons.access_time_filled_rounded;
      default: return Icons.warning_rounded;
    }
  }

  void _showSignalementDetails(dynamic s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            ),
            const Gap(24),
            Text(s.type.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary, fontSize: 12, letterSpacing: 1.5)),
            const Gap(8),
            Text("Détails du Signalement", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.blueGrey[900])),
            const Gap(20),
            Text(s.description, style: const TextStyle(fontSize: 15, height: 1.5, color: Colors.black87)),
            const Gap(24),
            if (s.photo != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  s.photo!.startsWith('http') ? s.photo! : "https://car225.com/storage/${s.photo}",
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    width: double.infinity,
                    color: Colors.grey[100],
                    child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                  ),
                ),
              ),
              const Gap(24),
            ],
            _buildDetailRow(Icons.calendar_today_outlined, "Date", s.createdAt),
            const Gap(12),
            if (s.vehicule != null) _buildDetailRow(Icons.directions_bus_rounded, "Véhicule", s.vehicule),
            const Gap(32),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("FERMER", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[400]),
        const Gap(12),
        Text("$label : ", style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  bool _canSubmit() {
    if (_selectedType == null || _descriptionController.text.trim().isEmpty) {
      return false;
    }
    if (_selectedType == "Accident") {
      return _imageFile != null && _currentAddress != null;
    }
    return true;
  }

  void _submitReport(BuildContext context, DriverProvider provider) async {
    // Déterminer le voyage à utiliser : selectedTripForReport en priorité, sinon currentTrip
    final trip = provider.selectedTripForReport ?? provider.currentTrip;
    if (trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Aucun voyage actif trouvé pour ce signalement."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    final success = await provider.submitReport(
      type: _selectedType!,
      description: _descriptionController.text,
      tripId: trip.id.toString(),
      image: _imageFile,
      latitude: _currentPosition?.latitude,
      longitude: _currentPosition?.longitude,
    );

    if (!mounted) return;

    Navigator.pop(context); // Fermer le dialog de chargement

    if (success) {
      SuccessModal.show(
        context: context,
        title: "Rapport envoyé",
        message:
            "Votre signalement a été transmis avec succès et sera traité dans les plus brefs délais.",
        onPressed: () {
          setState(() {
            _selectedType = null;
            _descriptionController.clear();
            _imageFile = null;
            _currentPosition = null;
            _currentAddress = null;
          });
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? "Erreur lors de l'envoi du signalement"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

