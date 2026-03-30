import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/services/networking/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/data/models/active_reservation_model.dart';
import '../../../booking/domain/repositories/alert_repository.dart';
import 'alert_success_screen.dart';

class AlertDetailScreen extends StatefulWidget {
  final String alertType;
  final Color alertColor;
  final String iconPath;
  final ActiveReservationModel reservation;

  const AlertDetailScreen({
    super.key,
    required this.alertType,
    required this.alertColor,
    required this.iconPath,
    required this.reservation,
  });

  @override
  State<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends State<AlertDetailScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  File? _selectedImage;
  Position? _currentPosition;
  bool _isLocating = false;
  bool _isSending = false;

  final ImagePicker _picker = ImagePicker();

  // 🟢 1. On garde une référence à l'OverlayEntry actif
  OverlayEntry? _currentNotification;


  // ✅ 1. LOGIQUE INTELLIGENTE
  // Vérifie si les champs doivent être obligatoires (seulement si Accident)
  bool get _isMandatory {
    return _getApiType(widget.alertType) == 'accident';
  }

  // Convertit le texte affiché en valeur acceptée par l'API
  // Convertit le texte affiché en valeur acceptée par l'API
  /*String _getApiType(String displayType) {
    // 🟢 1. Le .trim() EST VITAL ICI pour enlever les espaces avant/après
    final String cleanType = displayType.trim().toLowerCase();

    // 🟢 2. Des logs précis avec des guillemets pour détecter les espaces invisibles
    print("🔍 [DEBUG TYPE] Entrée UI brute  : '$displayType'");
    print("🔍 [DEBUG TYPE] Après nettoyage  : '$cleanType'");

    switch (cleanType) {
      case 'accident':
        return 'accident';
      case 'panne':
        return 'panne';
      case 'embouteillage':
        return 'embouteillage';
      case 'retard':
        return 'retard';
      default:
        print("⚠️ [WARNING TYPE] Type non reconnu par le switch ! On envoie : '$cleanType'");
        return cleanType;
    }
  }*/

  // Convertit le texte affiché en valeur acceptée par l'API
  String _getApiType(String displayType) {
    final String cleanType = displayType.trim().toLowerCase();

    print("🔍 [DEBUG TYPE] Entrée UI brute  : '$displayType'");
    print("🔍 [DEBUG TYPE] Après nettoyage  : '$cleanType'");

    switch (cleanType) {
      case 'accident':
        return 'accident';

    // 🟢 ON AJOUTE TON TEXTE EXACT DE L'UI ICI
      case 'panne véhicule':
      case 'panne': // (On garde 'panne' au cas où ça change plus tard)
        return 'panne'; // On envoie juste 'panne' à l'API

      case 'embouteillage':
        return 'embouteillage';

      case 'retard':
        return 'retard';

      default:
        print("⚠️ [WARNING TYPE] Type non reconnu par le switch ! On envoie : '$cleanType'");
        return cleanType;
    }
  }




  // --- NOTIFICATION TOP OVERLAY ---
  void _showTopNotification(String message, {bool isError = true}) {
    // 🟢 Si une notification existe déjà, on la supprime pour éviter de les empiler
    _removeCurrentNotification();

    final overlay = Overlay.of(context);
    _currentNotification = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFF222222) : Colors.green.shade700,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isError ? Icons.info_outline : Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(_currentNotification!);

    // 🟢 2. On passe la référence locale au Future.delayed
    // On retire le check "if (mounted)" car on veut que la notification disparaisse
    // même si on a changé d'écran entre-temps.
    final notificationToRemove = _currentNotification;
    Future.delayed(const Duration(seconds: 3), () {
      try {
        if (notificationToRemove != null && notificationToRemove.mounted) {
          notificationToRemove.remove();
        }
      } catch (_) {}
    });
  }

  // 🟢 Nouvelle méthode pour nettoyer proprement
  void _removeCurrentNotification() {
    if (_currentNotification != null && _currentNotification!.mounted) {
      try {
        _currentNotification!.remove();
      } catch (_) {}
      _currentNotification = null;
    }
  }

  // 🟢 3. On nettoie si l'utilisateur appuie sur le bouton retour classique
  @override
  void dispose() {
    _removeCurrentNotification();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }



  // --- GESTION PHOTO ---
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source, imageQuality: 50);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      _showTopNotification("Impossible de charger la photo", isError: true);
    }
  }

  void _showImageSourceModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.blue),
                title: const Text('Prendre une photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.purple),
                title: const Text('Choisir dans la galerie'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- GESTION LOCALISATION ---
  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permission de localisation refusée');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Localisation définitivement refusée.');
      }

      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      // Essai de géocodage (nom de rue), mais on continue même si ça échoue
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (mounted) {
          setState(() {
            _currentPosition = position;
            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];
              _locationController.text = "${place.street ?? ''}, ${place.locality ?? ''}".trim();
              if (_locationController.text == ",") _locationController.text = "Position GPS détectée";
            } else {
              _locationController.text = "${position.latitude}, ${position.longitude}";
            }
            _isLocating = false;
          });
        }
      } catch (_) {
        if (mounted) {
          setState(() {
            _currentPosition = position;
            _locationController.text = "${position.latitude}, ${position.longitude}";
            _isLocating = false;
          });
        }
      }

    } catch (e) {
      setState(() => _isLocating = false);
      _showTopNotification("Erreur GPS : ${e.toString().replaceAll('Exception:', '')}", isError: true);
    }
  }


  // --- ENVOI DU SIGNALEMENT ---
  /*Future<void> _submitSignalement() async {

    // ✅ VALIDATION ACCIDENT
    if (_isMandatory) {
      if (_descriptionController.text.trim().isEmpty) {
        _showTopNotification("Veuillez décrire l'accident.", isError: true);
        return;
      }
      if (_selectedImage == null) {
        _showTopNotification("Une photo est obligatoire pour un accident.", isError: true);
        return;
      }
    }

    // 📍 Localisation obligatoire
    if (_currentPosition == null) {
      _showTopNotification("Récupération de la position en cours...", isError: false);
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    final int? vehiculeId = widget.reservation.vehiculeId;


    if (vehiculeId == null || vehiculeId <= 0) {
      _showTopNotification(
        "Aucun véhicule valide associé à cette réservation",
        isError: true,
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        //baseUrl: 'https://car225.com/api/',
        //baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
        /*headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },*/
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final repository = AlertRepository(dio: dio);

      await repository.createSignalement(
        programmeId: widget.reservation.programmeId,
        vehiculeId: widget.reservation.vehiculeId!, // sécurisé ici
        type: _getApiType(widget.alertType),
        description: _descriptionController.text,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photo: _selectedImage,
      );

      if (mounted) {
        _removeCurrentNotification(); // Si tu as gardé la correction d'avant

        // On génère un petit numéro de suivi factice basé sur l'heure
        // (à remplacer par l'ID de l'API si ton backend te le renvoie dans response.data)
        final reference = "#SIG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AlertSuccessScreen(
            alertType: widget.alertType, // Ex: "Panne véhicule"
            status: "En attente",        // Ou "Reçu"
            reference: reference,
          )),
        );
      }

    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll("Exception:", "").trim();
        _showTopNotification(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }*/


  // --- ENVOI DU SIGNALEMENT ---
  Future<void> _submitSignalement() async {
    // ✅ VALIDATION ACCIDENT
    if (_isMandatory) {
      if (_descriptionController.text.trim().isEmpty) {
        _showTopNotification("Veuillez décrire l'accident.", isError: true);
        return;
      }
      if (_selectedImage == null) {
        _showTopNotification("Une photo est obligatoire pour un accident.", isError: true);
        return;
      }
    }

    // 📍 Localisation obligatoire
    if (_currentPosition == null) {
      _showTopNotification("Récupération de la position en cours...", isError: false);
      await _getCurrentLocation();
      if (_currentPosition == null) return;
    }

    final int? vehiculeId = widget.reservation.vehiculeId;

    if (vehiculeId == null || vehiculeId <= 0) {
      _showTopNotification(
        "Aucun véhicule valide associé à cette réservation",
        isError: true,
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? prefs.getString('token');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
      ));

      final repository = AlertRepository(dio: dio);

      await repository.createSignalement(
        programmeId: widget.reservation.programmeId,
        vehiculeId: widget.reservation.vehiculeId!,
        type: _getApiType(widget.alertType),
        description: _descriptionController.text,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        photo: _selectedImage,
      );

      if (mounted) {
        _removeCurrentNotification();
        final reference = "#SIG-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}";
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => AlertSuccessScreen(
            alertType: widget.alertType,
            status: "En attente",
            reference: reference,
          )),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().replaceAll("Exception:", "").trim();
        _showTopNotification(msg, isError: true);
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final inputFillColor = isDark ? Colors.grey[900] : Colors.white;
    final borderColor = isDark ? Colors.grey[800] : Colors.transparent;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text("Détails du problème", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 20, 20, bottomPadding + 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // INFO VOYAGE
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[900] : Colors.grey[100],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.directions_bus, color: textColor),
                  const Gap(15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Voyage avec ${widget.reservation.compagnieName}", style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text("${widget.reservation.pointDepart} ➔ ${widget.reservation.pointArrive}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Gap(20),

            // TYPE ALERTE
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: widget.alertColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: widget.alertColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(widget.iconPath, width: 16, color: widget.alertColor),
                  const Gap(8),
                  Text(widget.alertType, style: TextStyle(color: widget.alertColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Gap(25),

            // ✅ 3. AFFICHAGE DYNAMIQUE (Description)
            Row(
              children: [
                Text("Description du problème", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                const Gap(5),
                Text(
                  _isMandatory ? "*" : "(Optionnel)",
                  style: TextStyle(
                      color: _isMandatory ? Colors.red : Colors.grey,
                      fontSize: 12,
                      fontWeight: _isMandatory ? FontWeight.bold : FontWeight.normal
                  ),
                ),
              ],
            ),
            const Gap(10),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: _isMandatory
                    ? "Décrivez en détails ce qui s'est passé..."
                    : "Ajoutez une note si nécessaire...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                enabledBorder: isDark
                    ? OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor!))
                    : null,
                contentPadding: const EdgeInsets.all(15),
              ),
            ),
            const Gap(20),

            // LOCALISATION (Toujours auto et visible)
            Text("Lieu du problème", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Gap(10),
            TextField(
              controller: _locationController,
              readOnly: true,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Cliquez sur l'icône GPS...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                suffixIcon: IconButton(
                  onPressed: _isLocating ? null : _getCurrentLocation,
                  icon: _isLocating
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.my_location, color: Colors.blue),
                ),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                enabledBorder: isDark
                    ? OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor!))
                    : null,
              ),
            ),
            const Gap(20),

            // ✅ 4. AFFICHAGE DYNAMIQUE (Photo)
            Row(
              children: [
                Text("Preuve photo", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                const Gap(5),
                Text(
                  _isMandatory ? "*" : "(Optionnel)",
                  style: TextStyle(
                      color: _isMandatory ? Colors.red : Colors.grey,
                      fontSize: 12,
                      fontWeight: _isMandatory ? FontWeight.bold : FontWeight.normal
                  ),
                ),
              ],
            ),
            const Gap(10),
            GestureDetector(
              onTap: _showImageSourceModal,
              child: Container(
                height: 150,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: inputFillColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      // Bordure rouge si obligatoire et manquant (optionnel pour UX poussée)
                        color: _selectedImage == null
                            ? Colors.grey.shade400
                            : AppColors.primary,
                        width: 1
                    ),
                    image: _selectedImage != null
                        ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                        : null
                ),
                child: _selectedImage == null
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_enhance_rounded, size: 40, color: Colors.grey.shade400),
                    const Gap(10),
                    Text(
                        _isMandatory ? "Appuyez pour ajouter une photo" : "Ajouter une photo (facultatif)",
                        style: TextStyle(color: Colors.grey.shade500)
                    ),
                  ],
                )
                    : Stack(
                  children: [
                    Positioned(
                      right: 10, top: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.black54,
                        radius: 15,
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const Gap(30),

            // BOUTON
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSending ? null : _submitSignalement,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: _isSending
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                    : const Text("Envoyer le signalement", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}