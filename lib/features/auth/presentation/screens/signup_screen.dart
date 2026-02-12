/*import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

import '../../../booking/presentation/screens/search_results_screen.dart';
import '../../../onboarding/presentation/home_flow.dart';

import 'loading_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
         elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.green), // Flèche verte comme sur le design
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Gap(40), // Ajoute un peu d'espace en haut si nécessaire

              // LOGO SVG
              SvgPicture.asset( // <--- Changement ici
                  "assets/vectors/logo_complet.svg", // Assure-toi que c'est le bon chemin
                  height: 80
              ),
              const Gap(20),

              Text("Créez votre compte",
                  style: TextStyle(color: kColorOrange, fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const Gap(30),

              // Inputs
              _buildAuthInput("Email", Icons.email_outlined),
              const Gap(15),
              _buildAuthInput("Mot de passe", Icons.lock_outline, isPassword: true, obscureText: _obscureText,
                  onToggleVisibility: () => setState(() => _obscureText = !_obscureText)),
              const Gap(15),
              _buildAuthInput("Confirmer mot de passe", Icons.lock_outline, isPassword: true, obscureText: _obscureText),

              const Gap(40),

              // Bouton Suivant
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // Pareil ici : on affiche le loader "A" avant d'aller à la suite
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthLoadingScreen(
                          // Peut-être qu'après l'inscription, on va vers un écran de validation OTP ?
                          // Pour l'instant, disons qu'on va à l'accueil :
                          nextScreen: const SearchResultsScreen(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kColorOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Suivant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const Gap(40),
              // LIEN LOGIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Vous avez déjà un compte ? ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Connectez-vous", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // (Réutiliser le même helper _buildAuthInput ici ou le mettre en global)
  Widget _buildAuthInput(String hint, IconData icon, {bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: TextField(
        obscureText: obscureText,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
            onPressed: onToggleVisibility,
          )
              : null,
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}*/



/*import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

// 1. IMPORTS CLEAN ARCHITECTURE
import '../../../../core/theme/app_colors.dart';
import '../../../../features/home/presentation/screens/main_wrapper_screen.dart';
import 'loading_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  bool _obscureText = true;
  bool _obscureTextConfirm = true; // Ajout d'un booléen distinct pour le 2ème champ

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : AppColors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        backgroundColor: scaffoldColor, // S'adapte au fond
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary), // Vert (Reste visible en sombre)
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Gap(40),

              // LOGO SVG
              SvgPicture.asset(
                "assets/vectors/logo_complet.svg",
                height: 80,
                // Optionnel : Si le logo est noir, on le passe en blanc en mode sombre
                // colorFilter: isDark ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null,
              ),
              const Gap(20),

              Text("Créez votre compte",
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.primary, // Blanc ou Couleur primaire
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                  )
              ),
              const Gap(30),

              // Inputs
              _buildAuthInput("Email", Icons.email_outlined),
              const Gap(15),

              _buildAuthInput("Mot de passe", Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureText,
                  onToggleVisibility: () => setState(() => _obscureText = !_obscureText)
              ),
              const Gap(15),

              _buildAuthInput("Confirmer mot de passe", Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureTextConfirm, // Utilisation de la var distincte
                  onToggleVisibility: () => setState(() => _obscureTextConfirm = !_obscureTextConfirm)
              ),

              const Gap(40),

              // BOUTON SUIVANT
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AuthLoadingScreen(
                          nextScreen: MainScreen(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary, // Branding
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Suivant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const Gap(40),

              // LIEN RETOUR LOGIN
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      "Vous avez déjà un compte ? ",
                      style: TextStyle(color: secondaryTextColor, fontSize: 12)
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                        "Connectez-vous",
                        style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget Helper Adapté Dark Mode
  Widget _buildAuthInput(String hint, IconData icon, {bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility}) {
    // Récup context pour thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final hintColor = isDark ? Colors.grey[600] : AppColors.grey;
    final iconColor = isDark ? Colors.grey[400] : AppColors.grey;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cardColor : AppColors.white, // Fond Gris foncé ou Blanc
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
      ),
      child: TextField(
        obscureText: obscureText,
        style: TextStyle(color: textColor), // <--- Important : Couleur du texte saisi
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: iconColor
            ),
            onPressed: onToggleVisibility,
          )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: hintColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}*/



/*import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

// IMPORTS CLEAN ARCHI
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
// Note: J'importe les services même s'ils ne sont pas utilisés directement dans register,
// car AuthRepositoryImpl en a besoin pour s'instancier.
import '../../../../core/services/device/device_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // --- 1. CONTROLLERS (Un pour chaque champ du JSON) ---
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _adresseController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  bool _obscureText = true;
  bool _obscureTextConfirm = true;
  bool _isLoading = false;

  // --- 2. LOGIQUE D'INSCRIPTION ---
  Future<void> _handleRegister() async {
    // Validation basique
    if (_passwordController.text != _confirmPassController.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Les mots de passe ne correspondent pas"), backgroundColor: Colors.red));
      return;
    }
    if (_nomController.text.isEmpty || _emailController.text.isEmpty || _contactController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs obligatoires"), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Instanciation du Repo (Injection manuelle)
      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      await authRepository.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim(),
        adresse: _adresseController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      // SUCCÈS : On affiche un message et on retourne au login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Compte créé avec succès ! Connectez-vous."), backgroundColor: Colors.green),
      );

      // On ferme l'écran d'inscription pour revenir au Login
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${e.toString()}"), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _adresseController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final secondaryTextColor = isDark ? Colors.grey[400] : AppColors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Gap(20),
              SvgPicture.asset("assets/vectors/logo_complet.svg", height: 80),
              const Gap(20),

              Text("Créez votre compte",
                  style: TextStyle(color: isDark ? Colors.white : AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const Gap(30),

              // --- FORMULAIRE ---
              // Nom & Prénom
              _buildAuthInput("Nom", Icons.person_outline, controller: _nomController),
              const Gap(15),
              _buildAuthInput("Prénom", Icons.person, controller: _prenomController),
              const Gap(15),

              // Contact & Adresse
              _buildAuthInput("Contact (ex: 0708...)", Icons.phone_android, controller: _contactController, inputType: TextInputType.phone),
              const Gap(15),
              _buildAuthInput("Adresse (ex: Cocody)", Icons.location_on_outlined, controller: _adresseController),
              const Gap(15),

              // Email
              _buildAuthInput("Email", Icons.email_outlined, controller: _emailController, inputType: TextInputType.emailAddress),
              const Gap(15),

              // Mots de passe
              _buildAuthInput("Mot de passe", Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscureText,
                  onToggleVisibility: () => setState(() => _obscureText = !_obscureText)
              ),
              const Gap(15),
              _buildAuthInput("Confirmer mot de passe", Icons.lock_outline,
                  controller: _confirmPassController,
                  isPassword: true,
                  obscureText: _obscureTextConfirm,
                  onToggleVisibility: () => setState(() => _obscureTextConfirm = !_obscureTextConfirm)
              ),

              const Gap(40),

              // BOUTON D'ACTION
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("S'inscrire", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const Gap(30),

              // FOOTER
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Vous avez déjà un compte ? ", style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text("Connectez-vous", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Gap(30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper Widget mis à jour avec Controller et InputType
  Widget _buildAuthInput(String hint, IconData icon, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextEditingController? controller,
    TextInputType inputType = TextInputType.text, // Pour afficher le clavier numérique pour le contact
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final hintColor = isDark ? Colors.grey[600] : AppColors.grey;
    final iconColor = isDark ? Colors.grey[400] : AppColors.grey;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cardColor : AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: isPassword
              ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: iconColor), onPressed: onToggleVisibility)
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: hintColor),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}*/





/*import 'dart:io'; // Pour File
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart'; // <--- Import Image Picker

import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // --- CONTROLLERS ---
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _adresseController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // --- PHOTO ---
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  bool _obscureText = true;
  bool _obscureTextConfirm = true;
  bool _isLoading = false;


  // --- VARIABLE POUR GÉRER L'OVERLAY (Correction du bug "reste fixe") ---
  OverlayEntry? _currentOverlayEntry;

  // --- FONCTION CHOIX PHOTO ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }


  // Fonction utilitaire pour nettoyer l'overlay proprement
  void _removeOverlay() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }
// --- NOTIF TOP BAR ---
  void _showTopNotification(String message, {bool isError = false}) {
    // 1. On nettoie l'ancienne s'il y en a une
    _removeOverlay();

    final overlay = Overlay.of(context);

    // 2. CORRECTION : On assigne l'overlay à la variable DE LA CLASSE (_currentOverlayEntry)
    // Au lieu de créer une variable locale "final overlayEntry ="
    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFFD32F2F).withOpacity(0.95) : const Color(0xFF222222).withOpacity(0.95),
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
                    isError ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 20
                ),
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

    // 3. On insère la variable de classe
    overlay.insert(_currentOverlayEntry!);

    // 4. Timer de sécurité (Nettoyage automatique après 3s)
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _removeOverlay();
    });
  }

  // --- LOGIQUE INSCRIPTION ---
  Future<void> _handleRegister() async {
    if (_nomController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showTopNotification("Champs obligatoires manquants", isError: true);
      return;
    }
    if (_passwordController.text != _confirmPassController.text) {
      _showTopNotification("Mots de passe différents", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      await authRepository.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim(),
        adresse: _adresseController.text.trim(),
        password: _passwordController.text,
        photoPath: _selectedImage?.path, // <--- ENVOI DU CHEMIN PHOTO
      );

      if (!mounted) return;
      _showTopNotification("Compte créé avec succès !");
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceAll("Exception:", "").trim();
      _showTopNotification(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }




  @override
  void dispose() {
    // --- IMPORTANT : On nettoie la notification si on quitte l'écran ---
    _removeOverlay();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final secondaryTextColor = isDark ? Colors.grey[400] : AppColors.grey;
    final primaryColor = AppColors.primary;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: scaffoldColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              // --- 1. SÉLECTEUR DE PHOTO ---
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      height: 100,
                      width: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        border: Border.all(color: primaryColor.withOpacity(0.5), width: 2),
                        image: _selectedImage != null
                            ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                            : null,
                      ),
                      child: _selectedImage == null
                          ? Icon(Icons.person, size: 50, color: isDark ? Colors.grey[600] : Colors.grey[400])
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(10),
              Text("Ajouter une photo", style: TextStyle(color: secondaryTextColor, fontSize: 12)),
              const Gap(20),

              Text("Créez votre compte",
                  style: TextStyle(color: isDark ? Colors.white : AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const Gap(30),

              // --- FORMULAIRE ---
              _buildAuthInput("Nom", Icons.person_outline, controller: _nomController),
              const Gap(15),
              _buildAuthInput("Prénom", Icons.person, controller: _prenomController),
              const Gap(15),
              _buildAuthInput("Contact", Icons.phone_android, controller: _contactController, inputType: TextInputType.phone),
              const Gap(15),
              _buildAuthInput("Adresse", Icons.location_on_outlined, controller: _adresseController),
              const Gap(15),
              _buildAuthInput("Email", Icons.email_outlined, controller: _emailController, inputType: TextInputType.emailAddress),
              const Gap(15),
              _buildAuthInput("Mot de passe", Icons.lock_outline, controller: _passwordController, isPassword: true, obscureText: _obscureText, onToggleVisibility: () => setState(() => _obscureText = !_obscureText)),
              const Gap(15),
              _buildAuthInput("Confirmer mot de passe", Icons.lock_outline, controller: _confirmPassController, isPassword: true, obscureText: _obscureTextConfirm, onToggleVisibility: () => setState(() => _obscureTextConfirm = !_obscureTextConfirm)),

              const Gap(40),

              // BOUTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30))),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("S'inscrire", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const Gap(30),
              // FOOTER...
              // (Même code que précédemment pour le footer)
              const Gap(30),
            ],
          ),
        ),
      ),
    );
  }

  // Helper _buildAuthInput identique à avant
  Widget _buildAuthInput(String hint, IconData icon, {bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility, TextEditingController? controller, TextInputType inputType = TextInputType.text}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final hintColor = isDark ? Colors.grey[600] : AppColors.grey;
    final iconColor = isDark ? Colors.grey[400] : AppColors.grey;

    return Container(
      decoration: BoxDecoration(color: isDark ? cardColor : AppColors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300)),
      child: TextField(
        controller: controller, keyboardType: inputType, obscureText: obscureText, style: TextStyle(color: textColor),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: isPassword ? IconButton(icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: iconColor), onPressed: onToggleVisibility) : null,
          hintText: hint, hintStyle: TextStyle(color: hintColor), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }
}*/






import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';

// IMPORTS CLEAN ARCHI (Ajuste selon ton arborescence réelle)
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // --- CONTROLLERS ---
  // ✅ Champs adaptés au JSON API : name, prenom, email, contact, password
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _emailController = TextEditingController();
  final _contactController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPassController = TextEditingController();

  // --- PHOTO & ETAT ---
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _obscureText = true;
  bool _obscureTextConfirm = true;
  bool _isLoading = false;
  OverlayEntry? _currentOverlayEntry;

  // --- ACTIONS ---

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _selectedImage = File(pickedFile.path));
    }
  }

  void _removeOverlay() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  void _showTopNotification(String message, {bool isError = false}) {
    _removeOverlay();
    final overlay = Overlay.of(context);
    _currentOverlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? Colors.redAccent : Colors.green,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white),
                const Gap(10),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(_currentOverlayEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _removeOverlay();
    });
  }

  Future<void> _handleRegister() async {
    // Validation
    if (_nomController.text.isEmpty || _prenomController.text.isEmpty ||
        _emailController.text.isEmpty || _contactController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showTopNotification("Tous les champs sont obligatoires", isError: true);
      return;
    }

    if (_passwordController.text != _confirmPassController.text) {
      _showTopNotification("Les mots de passe ne correspondent pas", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      // ⚠️ ADAPTATION API : Suppression du champ 'adresse'
      await authRepository.register(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        contact: _contactController.text.trim(),
        password: _passwordController.text, // Le repo gèrera le password_confirmation si besoin, ou l'API le déduira
        photoPath: _selectedImage?.path,
      );

      if (!mounted) return;
      _showTopNotification("Compte créé avec succès !");
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;
      // Nettoyage du message d'erreur
      String errorMsg = e.toString().replaceAll("Exception:", "").trim();
      _showTopNotification(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _contactController.dispose();
    _passwordController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- UI ---

  /*@override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = AppColors.primary;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Bouton retour + Titre)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Gap(20),

              Text("Inscription", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
              const Gap(5),
              Text("Créez votre compte pour commencer.", style: TextStyle(fontSize: 16, color: Colors.grey[600])),

              const Gap(30),

              // 2. PHOTO PICKER (Centré)
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          border: Border.all(color: primaryColor, width: 2),
                          image: _selectedImage != null
                              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _selectedImage == null
                            ? Icon(Icons.person_rounded, size: 60, color: Colors.grey[400])
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgColor, width: 3),
                          ),
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(30),

              // 3. FORMULAIRE

              // Ligne Nom & Prénom
              Row(
                children: [
                  Expanded(
                    child: _buildModernInput(
                        hint: "Nom",
                        controller: _nomController,
                        icon: Icons.person_outline
                    ),
                  ),
                  const Gap(15),
                  Expanded(
                    child: _buildModernInput(
                        hint: "Prénom",
                        controller: _prenomController,
                        icon: Icons.person_outline
                    ),
                  ),
                ],
              ),
              const Gap(15),

              _buildModernInput(
                  hint: "Email",
                  controller: _emailController,
                  icon: Icons.email_outlined,
                  inputType: TextInputType.emailAddress
              ),
              const Gap(15),

              _buildModernInput(
                  hint: "Contact",
                  controller: _contactController,
                  icon: Icons.phone_android_outlined,
                  inputType: TextInputType.phone
              ),
              const Gap(15),

              _buildModernInput(
                  hint: "Mot de passe",
                  controller: _passwordController,
                  icon: Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureText,
                  onToggle: () => setState(() => _obscureText = !_obscureText)
              ),
              const Gap(15),

              _buildModernInput(
                  hint: "Confirmer mot de passe",
                  controller: _confirmPassController,
                  icon: Icons.lock_check_outlined,
                  isPassword: true,
                  obscureText: _obscureTextConfirm,
                  onToggle: () => setState(() => _obscureTextConfirm = !_obscureTextConfirm)
              ),

              const Gap(40),

              // 4. BOUTON D'ACTION
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 5,
                    shadowColor: primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("S'inscrire", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const Gap(30),

              // 5. FOOTER
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déjà un compte ? ", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text("Se connecter", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER MODERNE ---
  Widget _buildModernInput({
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.grey[800] : const Color(0xFFF5F5F5); // Gris très clair pour le fond
    final iconColor = Colors.grey[500];

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
        // Petit contour subtil si besoin, sinon sans bordure
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor, size: 22),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: iconColor),
            onPressed: onToggle,
          )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        ),
      ),
    );
  }*/




  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final primaryColor = AppColors.primary;
    final textColor = isDark ? Colors.white : Colors.black87;
    // Couleur pour les icones flaticons (gris pour faire sérieux, ou null pour couleur d'origine)
    final iconColor = Colors.grey[500];

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                // On garde l'icône système pour la navigation, c'est plus standard
                icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Gap(20),

              Text("Inscription", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textColor)),
              const Gap(5),
              Text("Créez votre compte pour commencer.", style: TextStyle(fontSize: 16, color: Colors.grey[600])),

              const Gap(30),

              // 2. PHOTO PICKER
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      Container(
                        height: 110,
                        width: 110,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          border: Border.all(color: primaryColor, width: 2),
                          image: _selectedImage != null
                              ? DecorationImage(image: FileImage(_selectedImage!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: _selectedImage == null
                        // Ici on peut aussi mettre une image flaticon si tu veux
                            ? Padding(
                          padding: const EdgeInsets.all(25.0),
                          child: Image.asset("assets/images/user.png", color: Colors.grey[400]),
                        )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: bgColor, width: 3),
                          ),
                          // Petite icône camera, on peut laisser en Icon ou mettre une image
                          child: const Icon(Icons.camera_alt, size: 18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(30),

              // 3. FORMULAIRE AVEC IMAGES FLATICONS

              Row(
                children: [
                  Expanded(
                    child: _buildModernInput(
                        context,
                        hint: "Nom",
                        controller: _nomController,
                        imagePath: "assets/images/user.png" // 👤 Image
                    ),
                  ),
                  const Gap(15),
                  Expanded(
                    child: _buildModernInput(
                        context,
                        hint: "Prénom",
                        controller: _prenomController,
                        // On peut ne pas mettre d'icone pour le prénom pour alléger,
                        // ou remettre user.png
                        imagePath: "assets/images/user.png"
                    ),
                  ),
                ],
              ),
              const Gap(15),

              _buildModernInput(
                  context,
                  hint: "Email",
                  controller: _emailController,
                  imagePath: "assets/images/email.png", // 📧 Image
                  inputType: TextInputType.emailAddress
              ),
              const Gap(15),

              _buildModernInput(
                  context,
                  hint: "Contact",
                  controller: _contactController,
                  imagePath: "assets/images/phone-call.png", // 📞 Image
                  inputType: TextInputType.phone
              ),
              const Gap(15),

              _buildModernInput(
                  context,
                  hint: "Mot de passe",
                  controller: _passwordController,
                  imagePath: "assets/images/padlock.png", // 🔒 Image
                  isPassword: true,
                  obscureText: _obscureText,
                  onToggle: () => setState(() => _obscureText = !_obscureText)
              ),
              const Gap(15),

              _buildModernInput(
                  context,
                  hint: "Confirmer mdp",
                  controller: _confirmPassController,
                  imagePath: "assets/images/padlock.png", // 🔒 Image
                  isPassword: true,
                  obscureText: _obscureTextConfirm,
                  onToggle: () => setState(() => _obscureTextConfirm = !_obscureTextConfirm)
              ),

              const Gap(40),

              // 4. BOUTON
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    elevation: 5,
                    shadowColor: primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text("S'inscrire", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),

              const Gap(30),

              // 5. FOOTER
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Déjà un compte ? ", style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Text("Se connecter", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER ADAPTÉ POUR IMAGES ---
  Widget _buildModernInput(BuildContext context, {
    required String hint,
    required String imagePath, // ✅ String path au lieu de IconData
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.grey[800] : const Color(0xFFF5F5F5);
    final iconColor = Colors.grey[500]; // Couleur grise pour un look pro

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        keyboardType: inputType,
        obscureText: obscureText,
        style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),
        decoration: InputDecoration(
          // ✅ Image Flaticon avec Padding pour ajuster la taille
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
                imagePath,
                width: 20,
                height: 20,
                color: iconColor // Retire 'color' si tu veux les images en couleur originale
            ),
          ),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: iconColor),
            onPressed: onToggle,
          )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        ),
      ),
    );
  }


}