import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

// --- IMPORTS ---
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/services/device/device_service.dart';


class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // --- CONTROLLERS ---
  // Infos Perso
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();

  // Infos Urgence
  final _nomUrgenceController = TextEditingController();
  final _prenomUrgenceController = TextEditingController();
  final _contactUrgenceController = TextEditingController();

  // État
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage;
  String? _currentPhotoUrl;

  late AuthRepositoryImpl _repo;

  @override
  void initState() {
    super.initState();
    _repo = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
      fcmService: FcmService(),
      deviceService: DeviceService(),
    );
    _loadUserData();
  }

  // 1. CHARGEMENT
  /*Future<void> _loadUserData() async {
    try {
      final user = await _repo.getUserProfile();

      setState(() {
        _nomController.text = user.name;
        _prenomController.text = user.prenom;
        _emailController.text = user.email;
        _contactController.text = user.contact;

        _nomUrgenceController.text = user.nomUrgence ?? "";
        _prenomUrgenceController.text = user.prenomUrgence ?? "";
        _contactUrgenceController.text = user.contactUrgence ?? "";

        _currentPhotoUrl = user.photoUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // 🔔 Erreur de chargement
      _showTopNotification("Impossible de charger les infos : $e", isError: true);
    }
  }*/

  // 1. CHARGEMENT
  Future<void> _loadUserData() async {
    try {
      final user = await _repo.getUserProfile();

      setState(() {
        _nomController.text = user.name;
        _prenomController.text = user.prenom;
        _emailController.text = user.email;
        _contactController.text = user.contact;

        _nomUrgenceController.text = user.nomUrgence ?? "";
        _prenomUrgenceController.text = user.prenomUrgence ?? "";
        _contactUrgenceController.text = user.contactUrgence ?? "";

        // 🔴 AVANT (C'est ça qui plante, ça prend l'URL brute "storage/...") :
        // _currentPhotoUrl = user.photoUrl;

        // 🟢 APRÈS (Utilise ton getter magique qui ajoute https://...) :
        _currentPhotoUrl = user.fullPhotoUrl;

        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showTopNotification("Impossible de charger les infos : $e", isError: true);
    }
  }

  // 2. IMAGE
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _selectedImage = File(image.path));
    }
  }

  // 3. UPDATE (Avec Validation)
  Future<void> _updateProfile() async {
    // 🛡️ VALIDATION DES CHAMPS AVANT ENVOI
    if (_nomController.text.trim().isEmpty || _prenomController.text.trim().isEmpty) {
      _showTopNotification("Le nom et le prénom sont obligatoires", isError: true);
      return;
    }
    if (_contactController.text.trim().isEmpty) {
      _showTopNotification("Le numéro de contact est obligatoire", isError: true);
      return;
    }
    // Validation Urgence (Si tu veux les rendre obligatoires)
    // Validation Urgence
    if (_contactUrgenceController.text.trim().isEmpty) {
      _showTopNotification("Le numéro d'urgence est obligatoire", isError: true);
      return; // <--- 🛑 IL MANQUAIT CECI ! Sans ça, le code continue.
    }

    setState(() => _isSaving = true);

    try {
      await _repo.updateUserProfile(
        name: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim(),
        nomUrgence: _nomUrgenceController.text.trim(),
        prenomUrgence: _prenomUrgenceController.text.trim(),
        contactUrgence: _contactUrgenceController.text.trim(),
        photoPath: _selectedImage?.path,
      );

      if (mounted) {
        await context.read<UserProvider>().loadUser();
      }

      if (!mounted) return;

      // ✅ SUCCÈS
      _showTopNotification("Profil mis à jour avec succès !", isError: false);

      // Petit délai pour laisser l'utilisateur voir la notif avant de fermer
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      // ❌ ERREUR API
      // On nettoie le message d'erreur pour qu'il soit lisible (retire "Exception:")
      final message = e.toString().replaceAll("Exception: ", "");
      _showTopNotification(message, isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- 🔔 TON SYSTÈME DE NOTIFICATION CUSTOM ---
  void _showTopNotification(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              // Noir pour erreur, Vert pour succès
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
                Icon(
                  isError ? Icons.info_outline : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Suppression automatique après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = AppColors.primary;
    final textColor = isDark ? Colors.white : Colors.black87;

    if (_isLoading) {
      return Scaffold(backgroundColor: bgColor, body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text("Modifier le profil", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- PHOTO DE PROFIL ---
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      height: 120, width: 120,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: primaryColor, width: 3),
                        image: DecorationImage(
                          image: _getProfileImage(),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0, right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle, border: Border.all(color: bgColor, width: 2)),
                        child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(30),

            // --- SECTION 1 : INFOS PERSO ---
            _buildSectionTitle("Informations Personnelles"),
            const Gap(15),

            Row(
              children: [
                Expanded(child: _buildModernInput(context, "Nom", _nomController, "assets/images/user.png")),
                const Gap(10),
                Expanded(child: _buildModernInput(context, "Prénom", _prenomController, "assets/images/user.png")),
              ],
            ),
            const Gap(15),
            _buildModernInput(context, "Email", _emailController, "assets/images/email.png", isEmail: true), // Souvent read-only
            const Gap(15),
            _buildModernInput(context, "Contact", _contactController, "assets/images/phone-call.png", isPhone: true),

            const Gap(30),

            // --- SECTION 2 : CONTACT URGENCE ---
            _buildSectionTitle("Contact d'Urgence (SOS)"),
            const Gap(15),

            Row(
              children: [
                Expanded(child: _buildModernInput(context, "Nom Contact", _nomUrgenceController, "assets/images/health-insurance.png")), // ou user.png
                const Gap(10),
                Expanded(child: _buildModernInput(context, "Prénom Contact", _prenomUrgenceController, "assets/images/health-insurance.png")),
              ],
            ),
            const Gap(15),
            _buildModernInput(context, "Numéro d'Urgence", _contactUrgenceController, "assets/images/phone-call.png", isPhone: true),

            const Gap(40),

            // --- BOUTON SAVE ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _updateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 5,
                  shadowColor: primaryColor.withOpacity(0.3),
                ),
                child: _isSaving
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Enregistrer les modifications", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(30),
          ],
        ),
      ),
    );
  }

  // Helper Image
  ImageProvider _getProfileImage() {
    if (_selectedImage != null) return FileImage(_selectedImage!);
    if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) return NetworkImage(_currentPhotoUrl!);
    return const AssetImage("assets/images/user.png"); // Placeholder
  }

  // Helper Titre Section
  Widget _buildSectionTitle(String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title.toUpperCase(),
      style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 1.0
      ),
    );
  }

  // Widget Input Moderne (Style Inscription)
  Widget _buildModernInput(BuildContext context, String hint, TextEditingController controller, String imagePath, {bool isPhone = false, bool isEmail = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.grey[800] : const Color(0xFFF5F5F5);
    final iconColor = Colors.grey[500];

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        keyboardType: isPhone ? TextInputType.phone : (isEmail ? TextInputType.emailAddress : TextInputType.text),
        style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(imagePath, width: 20, height: 20, color: iconColor),
          ),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 15),
        ),
      ),
    );
  }
}

