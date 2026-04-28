import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/voyage_model.dart';
import '../../data/models/convoi_model.dart';

const _kNavy = Color(0xFF0f172a);

class DriverReportsScreen extends StatefulWidget {
  const DriverReportsScreen({super.key});

  @override
  State<DriverReportsScreen> createState() => _DriverReportsScreenState();
}

class _DriverReportsScreenState extends State<DriverReportsScreen> {
  String? _selectedType;
  VoyageModel? _selectedVoyage;
  ConvoiModel? _selectedConvoi;
  bool _consumedTarget = false;
  final TextEditingController _descCtrl = TextEditingController();
  bool _isSubmitting = false;
  File? _photoFile;

  static const List<_ReportType> _reportTypes = [
    _ReportType('Panne mécanique', Icons.build_rounded, Color(0xFFEF4444)),
    _ReportType('Accident', Icons.car_crash_rounded, Color(0xFFDC2626)),
    _ReportType('Incident passager', Icons.person_off_rounded, Color(0xFFF59E0B)),
    _ReportType('Problème de route', Icons.alt_route_rounded, Color(0xFF8B5CF6)),
    _ReportType('Autre', Icons.more_horiz_rounded, Color(0xFF6B7280)),
  ];

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _isAccident => _selectedType == 'Accident';

  bool get _canSubmit {
    if (_selectedType == null || _descCtrl.text.trim().isEmpty) return false;
    if (_isAccident && _photoFile == null) return false;
    return true;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1280,
    );
    if (picked != null) {
      setState(() => _photoFile = File(picked.path));
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Gap(12),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded,
                      color: Colors.blue, size: 22),
                ),
                title: const Text('Prendre une photo',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded,
                      color: AppColors.primary, size: 22),
                ),
                title: const Text('Choisir depuis la galerie',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              const Gap(8),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();

    // Consomme une éventuelle cible pré-sélectionnée (depuis l'écran Convois
    // ou Voyages — bouton « Faire un signalement »).
    if (!_consumedTarget) {
      final targetConvoi = provider.signalementConvoi;
      final targetVoyage = provider.signalementVoyage;
      if (targetConvoi != null || targetVoyage != null) {
        _consumedTarget = true;
        _selectedConvoi = targetConvoi;
        _selectedVoyage = targetVoyage;
        // On efface après usage pour éviter de re-pré-sélectionner au prochain rebuild.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          provider.clearSignalementTarget();
        });
      }
    }

    final activeVoyages = [
      if (provider.currentVoyage != null) provider.currentVoyage!,
      ...provider.todayVoyages.where((v) =>
          v.statut == 'en_cours' && v.id != provider.currentVoyage?.id),
    ];

    // Convois actifs (en_cours) — utilisés pour la pré-sélection ET le sélecteur.
    final activeConvois = provider.todayConvois
        .where((c) => c.statut == 'en_cours')
        .toList();

    // Si un convoi a été pré-sélectionné mais ne figure pas dans la liste
    // (par ex. convoi du jour sans en_cours), on l'injecte pour qu'il reste visible.
    if (_selectedConvoi != null &&
        !activeConvois.any((c) => c.id == _selectedConvoi!.id)) {
      activeConvois.insert(0, _selectedConvoi!);
    }

    final hasConvoiContext = _selectedConvoi != null || activeConvois.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          // ── En-tête ──
          Container(
            color: _kNavy,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.primary, size: 22),
                Gap(10),
                Text(
                  'Signalements',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Bannière contexte (convoi / voyage / aucun) ──
                  if (_selectedConvoi != null)
                    _InfoBanner(
                      icon: Icons.airport_shuttle_rounded,
                      message: hasConvoiContext
                          ? 'Convoi en cours détecté. Le signalement sera automatiquement associé à ce convoi.'
                          : 'Convoi pré-sélectionné. Le signalement sera associé.',
                      color: AppColors.secondary,
                    )
                  else if (activeConvois.isNotEmpty)
                    _InfoBanner(
                      icon: Icons.airport_shuttle_rounded,
                      message:
                          'Convoi en cours détecté. Sélectionnez le convoi concerné ci-dessous.',
                      color: AppColors.secondary,
                    )
                  else if (activeVoyages.isEmpty)
                    _InfoBanner(
                      icon: Icons.info_outline_rounded,
                      message:
                          'Aucun voyage ni convoi en cours. Vous pouvez quand même soumettre un signalement.',
                      color: Colors.blue,
                    )
                  else
                    _InfoBanner(
                      icon: Icons.check_circle_outline_rounded,
                      message:
                          'Voyage en cours détecté. Le signalement sera automatiquement associé.',
                      color: AppColors.secondary,
                    ),

                  const Gap(20),

                  // Sélecteur convoi (s'il y a un contexte convoi)
                  if (hasConvoiContext) ...[
                    _SectionLabel(label: 'CONVOI CONCERNÉ'),
                    const Gap(10),
                    _ConvoiSelector(
                      convois: activeConvois,
                      selected: _selectedConvoi,
                      onChanged: (c) => setState(() {
                        _selectedConvoi = c;
                        if (c != null) _selectedVoyage = null;
                      }),
                    ),
                    const Gap(20),
                  ] else if (activeVoyages.length > 1) ...[
                    _SectionLabel(label: 'VOYAGE CONCERNÉ'),
                    const Gap(10),
                    _VoyageSelector(
                      voyages: activeVoyages,
                      selected: _selectedVoyage,
                      onChanged: (v) => setState(() => _selectedVoyage = v),
                    ),
                    const Gap(20),
                  ],

                  // ── Type ──
                  _SectionLabel(label: 'TYPE DE PROBLÈME'),
                  const Gap(12),
                  ...List.generate(
                    _reportTypes.length,
                    (i) => _TypeTile(
                      type: _reportTypes[i],
                      isSelected: _selectedType == _reportTypes[i].label,
                      onTap: () =>
                          setState(() => _selectedType = _reportTypes[i].label),
                    ),
                  ),

                  const Gap(20),

                  // ── Description ──
                  _SectionLabel(label: 'DESCRIPTION DÉTAILLÉE'),
                  const Gap(10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: TextField(
                      controller: _descCtrl,
                      maxLines: 5,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Décrivez ce qu\'il se passe en détail...',
                        hintStyle:
                            TextStyle(color: Colors.grey[400], fontSize: 13),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(14),
                      ),
                    ),
                  ),

                  const Gap(20),

                  // ── Photo ──
                  Row(
                    children: [
                      _SectionLabel(
                          label: _isAccident
                              ? 'PHOTO (REQUISE POUR ACCIDENT)'
                              : 'PHOTO (OPTIONNELLE)'),
                      if (_isAccident && _photoFile == null) ...[
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REQUISE',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const Gap(10),
                  // Warning when accident selected but no photo
                  if (_isAccident && _photoFile == null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red.withOpacity(0.25)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_rounded,
                              color: Colors.red, size: 16),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              'Une photo est requise pour les signalements de type Accident.',
                              style: TextStyle(
                                  color: Colors.red[700],
                                  fontSize: 12,
                                  height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  _PhotoPicker(
                    photo: _photoFile,
                    required: _isAccident,
                    onTap: _showPhotoOptions,
                    onRemove: () => setState(() => _photoFile = null),
                  ),

                  const Gap(24),

                  // ── Soumettre ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _canSubmit && !_isSubmitting
                          ? () {
                              // Priorité au convoi sélectionné, sinon convoi
                              // unique dispo, sinon voyage sélectionné/par défaut.
                              final convoi = _selectedConvoi ??
                                  (hasConvoiContext && activeConvois.length == 1
                                      ? activeConvois.first
                                      : null);
                              final voyage = convoi != null
                                  ? null
                                  : (activeVoyages.isNotEmpty
                                      ? (_selectedVoyage ?? activeVoyages.first)
                                      : null);
                              _submit(context, provider,
                                  voyage: voyage, convoi: convoi);
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.send_rounded,
                              color: Colors.white, size: 20),
                      label: Text(
                        _isSubmitting ? 'Envoi...' : 'ENVOYER LE RAPPORT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Récupère la position GPS courante (best-effort) pour que le backend
  /// puisse :
  /// - dispatcher le signalement « accident » au sapeur-pompier le plus proche
  /// - géolocaliser le rapport pour la compagnie
  Future<({double? lat, double? lng})> _captureCurrentLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return (lat: null, lng: null);
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return (lat: null, lng: null);
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 8));
      return (lat: pos.latitude, lng: pos.longitude);
    } catch (_) {
      return (lat: null, lng: null);
    }
  }

  Future<void> _submit(
    BuildContext context,
    DriverProvider provider, {
    VoyageModel? voyage,
    ConvoiModel? convoi,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      // GPS optionnel mais essentiel pour le sapeur-pompier (accidents).
      final loc = await _captureCurrentLocation();

      await provider.submitReport(
        type: _selectedType!,
        description: _descCtrl.text.trim(),
        voyageId: voyage?.id,
        convoiId: convoi?.id,
        latitude: loc.lat,
        longitude: loc.lng,
        photo: _photoFile,
      );
      if (!mounted) return;
      _showSuccess(context);
      setState(() {
        _selectedType = null;
        _selectedVoyage = null;
        _selectedConvoi = null;
        _photoFile = null;
        _descCtrl.clear();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppColors.secondary, size: 48),
            ),
            const Gap(16),
            const Text('Rapport envoyé',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Gap(8),
            Text(
              'Votre signalement a bien été transmis aux équipes concernées.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], fontSize: 13),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('OK',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PHOTO PICKER WIDGET
// ─────────────────────────────────────────────────────────────────────────────
class _PhotoPicker extends StatelessWidget {
  final File? photo;
  final bool required;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _PhotoPicker({
    required this.photo,
    required this.onTap,
    required this.onRemove,
    this.required = false,
  });

  @override
  Widget build(BuildContext context) {
    if (photo != null) {
      return Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.file(
              photo!,
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
          ),
          Positioned(
            bottom: 8,
            right: 8,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.edit_rounded, color: Colors.white, size: 13),
                    SizedBox(width: 4),
                    Text('Changer',
                        style:
                            TextStyle(color: Colors.white, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: required ? Colors.red.withOpacity(0.03) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: required ? Colors.red.withOpacity(0.4) : const Color(0xFFE2E8F0),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_a_photo_rounded,
                  color: AppColors.primary, size: 26),
            ),
            const Gap(8),
            const Text('Ajouter une photo',
                style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
            Text('Appareil photo ou galerie',
                style:
                    TextStyle(color: Colors.grey[400], fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOUS-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _ReportType {
  final String label;
  final IconData icon;
  final Color color;
  const _ReportType(this.label, this.icon, this.color);
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B),
          letterSpacing: 0.8,
        ));
  }
}

class _TypeTile extends StatelessWidget {
  final _ReportType type;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeTile(
      {required this.type,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: isSelected ? type.color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? type.color : const Color(0xFFE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: type.color.withOpacity(isSelected ? 0.15 : 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(type.icon, color: type.color, size: 18),
            ),
            const Gap(12),
            Expanded(
              child: Text(
                type.label,
                style: TextStyle(
                  fontWeight:
                      isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 14,
                  color: isSelected
                      ? type.color
                      : const Color(0xFF1E293B),
                ),
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle_rounded,
                  color: type.color, size: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _InfoBanner(
      {required this.icon,
      required this.message,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const Gap(10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                  color: color.withOpacity(0.9),
                  fontSize: 12,
                  height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoyageSelector extends StatelessWidget {
  final List<VoyageModel> voyages;
  final VoyageModel? selected;
  final ValueChanged<VoyageModel?> onChanged;

  const _VoyageSelector(
      {required this.voyages,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<VoyageModel>(
          value: selected,
          isExpanded: true,
          hint: const Text('Sélectionner un voyage'),
          items: voyages.map((v) {
            final depart = v.programme?.gareDepart ??
                v.programme?.pointDepart ??
                '—';
            final arrivee = v.programme?.gareArrivee ??
                v.programme?.pointArrive ??
                '—';
            return DropdownMenuItem(
              value: v,
              child:
                  Text('$depart → $arrivee', overflow: TextOverflow.ellipsis),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _ConvoiSelector extends StatelessWidget {
  final List<ConvoiModel> convois;
  final ConvoiModel? selected;
  final ValueChanged<ConvoiModel?> onChanged;

  const _ConvoiSelector(
      {required this.convois,
      required this.selected,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    // Si un seul convoi est dispo et sélectionné, afficher une carte
    // statique (plus lisible qu'un dropdown).
    if (convois.length <= 1 && selected != null) {
      final c = selected!;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.airport_shuttle_rounded,
                  color: AppColors.primary, size: 18),
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${c.trajet.depart} → ${c.trajet.arrivee}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E293B)),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    [
                      if (c.reference != null && c.reference!.isNotEmpty)
                        c.reference!,
                      if (c.vehicule != null) c.vehicule!.immatriculation,
                    ].join(' · '),
                    style: const TextStyle(
                        fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.check_circle_rounded,
                color: AppColors.secondary, size: 20),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ConvoiModel>(
          value: selected,
          isExpanded: true,
          hint: const Text('Sélectionner un convoi'),
          items: convois.map((c) {
            return DropdownMenuItem(
              value: c,
              child: Text(
                '${c.trajet.depart} → ${c.trajet.arrivee}',
                overflow: TextOverflow.ellipsis,
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
