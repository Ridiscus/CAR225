import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart'; // <--- N'oublie pas l'import
// AJOUTE TES IMPORTS (Repo, Model, Colors, etc.)
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import 'package:provider/provider.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/services/device/device_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  // Contrôleurs
  final _nameController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // État
  bool _isLoading = true;
  bool _isSaving = false;
  File? _selectedImage; // Image locale (si modifiée)
  String? _currentPhotoUrl; // Image distante (actuelle)

  // Repo (Tu peux utiliser GetIt ou Provider ici si tu l'as mis en place)
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

  @override
  void dispose() {
    _nameController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // 1. CHARGEMENT DES DONNÉES (GET)
  Future<void> _loadUserData() async {
    try {
      final user = await _repo.remoteDataSource.getUserProfile();

      setState(() {
        _nameController.text = user.name;
        _prenomController.text = user.prenom;
        _emailController.text = user.email;
        _phoneController.text = user.contact;
        _addressController.text = user.adresse;
        _currentPhotoUrl = user.photoUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnack("Erreur chargement: $e", isError: true);
    }
  }

  // 2. SÉLECTION D'IMAGE (Image Picker)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    // On ouvre la galerie
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  // 3. MISE À JOUR (PUT)
  /* Future<void> _updateProfile() async {
    setState(() => _isSaving = true);

    try {
      // Appel Repository
      await _repo.remoteDataSource.updateUserProfile(
        name: _nameController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        contact: _phoneController.text.trim(),
        adresse: _addressController.text.trim(),
        photoPath: _selectedImage?.path, // Null si pas changée
      );

      if (!mounted) return;
      _showSnack("Profil mis à jour avec succès !");

      // Optionnel : Recharger pour être sûr ou juste rester comme ça
      // _loadUserData();

    } catch (e) {
      if (!mounted) return;
      _showSnack("Erreur update: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }*/

  Future<void> _updateProfile() async {
    setState(() => _isSaving = true);
    try {
      // 1. Appel Repository (Mise à jour serveur)
      await _repo.remoteDataSource.updateUserProfile(
        name: _nameController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        contact: _phoneController.text.trim(),
        adresse: _addressController.text.trim(),
        photoPath: _selectedImage?.path,
      );

      // 2. ✅ CORRECTION ICI : MAGIE DU PROVIDER
      // On force le rechargement global sans écouter les changements (listen: false est implicite avec read)
      if (mounted) {
        await context.read<UserProvider>().loadUser();
      }

      if (!mounted) return;
      _showSnack("Profil mis à jour !");
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showSnack("Erreur update: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    const primaryColor = AppColors.primary;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: scaffoldColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
          "Infos Personnelles",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- AVATAR ---
          Center(
            child: Stack(
              children: [
                GestureDetector(
                  onTap:
                      _pickImage, // Cliquer sur l'image ouvre aussi la galerie
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    // Logique d'affichage de l'image (Locale > Réseau > Asset)
                    backgroundImage: _getProfileImage(),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: scaffoldColor,
                      child: CircleAvatar(
                        radius: 15,
                        backgroundColor: primaryColor,
                        child: const Icon(
                          Icons.camera_alt,
                          size: 15,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(30),

          // --- FORMULAIRE ---
          // J'ai renommé label et passé le controller
          _buildInfoField(context, "Nom", _nameController),
          const Gap(15),
          _buildInfoField(context, "Prénom", _prenomController),
          const Gap(15),
          _buildInfoField(
            context,
            "Email",
            _emailController,
            isEmail: true,
          ), // Souvent readOnly
          const Gap(15),
          _buildInfoField(
            context,
            "Téléphone",
            _phoneController,
            isNumber: true,
          ),
          const Gap(15),
          _buildInfoField(context, "Adresse / Ville", _addressController),

          const Gap(40),

          // --- BOUTON SAVE ---
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _updateProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      "Enregistrer les modifications",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour l'image provider
  ImageProvider _getProfileImage() {
    if (_selectedImage != null) {
      return FileImage(_selectedImage!);
    } else if (_currentPhotoUrl != null && _currentPhotoUrl!.isNotEmpty) {
      return NetworkImage(_currentPhotoUrl!);
    } else {
      return const AssetImage("assets/images/profile_placeholder.png");
    }
  }

  // Widget Champ mis à jour pour accepter un Controller
  Widget _buildInfoField(
    BuildContext context,
    String label,
    TextEditingController controller, {
    bool isNumber = false,
    bool isEmail = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade300;
    final labelColor = isDark ? Colors.grey[400] : Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: FontWeight.bold, color: labelColor),
        ),
        const Gap(8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: TextFormField(
            controller: controller, // Utilisation du controller
            keyboardType: isNumber
                ? TextInputType.phone
                : (isEmail ? TextInputType.emailAddress : TextInputType.text),
            style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
