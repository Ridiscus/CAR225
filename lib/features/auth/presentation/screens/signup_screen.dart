import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  /*Future<void> _handleRegister() async {
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
  }*/


  Future<void> _handleRegister() async {
    // 1. Validation : Champs vides
    if (_nomController.text.isEmpty || _prenomController.text.isEmpty ||
        _emailController.text.isEmpty || _contactController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showTopNotification("Tous les champs sont obligatoires", isError: true);
      return;
    }

    // 🟢 2. NOUVELLE VALIDATION : 10 chiffres obligatoires
    if (_contactController.text.length != 10) {
      _showTopNotification("Le numéro de téléphone doit contenir exactement 10 chiffres", isError: true);
      return;
    }

    // 3. Validation : Mot de passe
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
                  isPhone: true,
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

              // 4. BOUTON S'INSCRIRE
              Container(
                width: double.infinity,
                height: 56,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/tabaa.jpg"),
                    fit: BoxFit.cover,
                  ),
                  // On garde l'ombre portée pour le style "Elevation 5"
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent, // Important pour voir l'image quand _isLoading est true
                    shadowColor: Colors.transparent,
                    elevation: 0,
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
  /*Widget _buildModernInput(BuildContext context, {
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
  }*/


  // --- WIDGET HELPER ADAPTÉ POUR IMAGES ET TELEPHONE ---
  Widget _buildModernInput(BuildContext context, {
    required String hint,
    required String imagePath,
    required TextEditingController controller,
    TextInputType inputType = TextInputType.text,
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggle,
    bool isPhone = false, // 🟢 NOUVEAU PARAMÈTRE
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.grey[800] : const Color(0xFFF5F5F5);
    final iconColor = Colors.grey[500];

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.transparent),
      ),
      child: TextField(
        controller: controller,
        // 💡 Force le clavier numérique si isPhone est vrai
        keyboardType: isPhone ? TextInputType.phone : inputType,
        obscureText: obscureText,
        style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87),

        // 🛡️ BLOQUER LA SAISIE PHYSIQUEMENT (Chiffres uniquement et 10 max)
        inputFormatters: isPhone
            ? [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(10),
        ]
            : null,

        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset(
                imagePath,
                width: 20,
                height: 20,
                color: iconColor
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