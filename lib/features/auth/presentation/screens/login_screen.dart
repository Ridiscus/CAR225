
//ECRAN DE CONNEXION
/*import 'package:car225/features/auth/presentation/screens/signup_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

import '../../../booking/presentation/screens/search_results_screen.dart';
import '../../../onboarding/presentation/home_flow.dart';
import 'loading_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Gap(40),
              // LOGO SVG
              SvgPicture.asset( // <--- Changement ici
                  "assets/vectors/logo_complet.svg",
                  height: 80
              ),
              const Gap(30),

              // TITRE
              Text("Connectez vous",
                  style: TextStyle(color: kColorOrange, fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const Gap(30),

              // CHAMPS EMAIL
              _buildAuthInput("Email", Icons.email_outlined),
              const Gap(15),

              // CHAMPS MOT DE PASSE
              _buildAuthInput("Mot de passe", Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureText,
                  onToggleVisibility: () => setState(() => _obscureText = !_obscureText)
              ),

              // OPTIONS (Se souvenir / Oublié)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                          value: _rememberMe,
                          activeColor: kColorOrange,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _rememberMe = v!)
                      ),
                      const Text("se souvenir de moi", style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  TextButton(
                      onPressed: () {},
                      child: const Text("Mot de passe oublié", style: TextStyle(color: Colors.grey, fontSize: 12))
                  )
                ],
              ),
              const Gap(20),

              // BOUTON CONNEXION
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    // On lance l'écran de chargement "A"
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AuthLoadingScreen(
                          // Une fois chargé, on va vers l'écran principal (ou SearchResult)
                          nextScreen: const SearchResultsScreen(),
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kColorOrange,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Connexion", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const Gap(30),

              // DIVIDER "Ou continuez avec"
              const Row(
                children: [
                  Expanded(child: Divider()),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10),
                    child: Text("Ou continuez avec", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider()),
                ],
              ),
              const Gap(20),

              // SOCIAL BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialBtn("assets/images/google-logo.png"),
                  const Gap(20),
                  _buildSocialBtn("assets/images/apple.png"),
                ],
              ),
              const Gap(40),

              // LIEN INSCRIPTION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Vous n'avez pas de compte ? ", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                    child: const Text("Inscrivez vous", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  // WIDGET HELPER POUR LES CHAMPS DE SAISIE
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

  // WIDGET HELPER POUR LES BOUTONS SOCIAUX
  Widget _buildSocialBtn(String path) {
    return Container(
      padding: const EdgeInsets.all(10),
      height: 50, width: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Image.asset(path),
    );
  }
}*/




/*import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

// 1. IMPORTS CLEAN ARCHITECTURE
import '../../../../core/theme/app_colors.dart';
import '../../../../features/home/presentation/screens/main_wrapper_screen.dart';
import '../../../home/presentation/screens/forgot_password_flow.dart';
import 'loading_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _rememberMe = false;
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : AppColors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
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
                // ASTUCE : Si votre logo est noir, décommentez la ligne ci-dessous pour le rendre blanc en mode sombre
                // colorFilter: isDark ? const ColorFilter.mode(Colors.white, BlendMode.srcIn) : null,
              ),
              const Gap(30),

              // TITRE
              Text("Connectez-vous",
                  style: TextStyle(
                    // En mode sombre, le Primary color peut parfois être trop sombre,
                    // on peut choisir du blanc ou garder le primary selon votre charte.
                      color: isDark ? Colors.white : AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                  )
              ),
              const Gap(30),

              // CHAMPS EMAIL
              _buildAuthInput("Email", Icons.email_outlined),
              const Gap(15),

              // CHAMPS MOT DE PASSE
              _buildAuthInput("Mot de passe", Icons.lock_outline,
                  isPassword: true,
                  obscureText: _obscureText,
                  onToggleVisibility: () => setState(() => _obscureText = !_obscureText)
              ),

              // OPTIONS (Se souvenir / Oublié)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.primary,
                          // Bordure du checkbox adaptée au mode sombre
                          side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade400, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _rememberMe = v!)
                      ),
                      Text(
                          "se souvenir de moi",
                          style: TextStyle(color: secondaryTextColor, fontSize: 12)
                      ),
                    ],
                  ),
                  TextButton(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ForgotPasswordEmailScreen())
                        );
                      },
                      child: Text(
                          "Mot de passe oublié",
                          style: TextStyle(color: secondaryTextColor, fontSize: 12)
                      )
                  )
                ],
              ),
              const Gap(20),

              // BOUTON CONNEXION
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
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: const Text("Connexion", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const Gap(30),

              // DIVIDER
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[300])),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                        "Ou continuez avec",
                        style: TextStyle(color: secondaryTextColor, fontSize: 12)
                    ),
                  ),
                  Expanded(child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[300])),
                ],
              ),
              const Gap(20),

              // SOCIAL BUTTONS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSocialBtn("assets/images/google-logo.png"),
                  const Gap(20),
                  _buildSocialBtn("assets/images/apple.png"),
                ],
              ),
              const Gap(40),

              // LIEN INSCRIPTION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                      "Vous n'avez pas de compte ? ",
                      style: TextStyle(color: secondaryTextColor, fontSize: 12)
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                    child: const Text(
                        "Inscrivez vous",
                        style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)
                    ),
                  ),
                ],
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthInput(String hint, IconData icon, {bool isPassword = false, bool obscureText = false, VoidCallback? onToggleVisibility}) {
    // Récupération du thème dans la méthode
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? cardColor : AppColors.white, // Fond blanc ou gris foncé
        borderRadius: BorderRadius.circular(15),
        // Bordure plus subtile en mode sombre
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
      ),
      child: TextField(
        obscureText: obscureText,
        style: TextStyle(color: textColor), // Couleur du texte tapé (Important !)
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: isDark ? Colors.grey[400] : AppColors.grey),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: isDark ? Colors.grey[400] : AppColors.grey
            ),
            onPressed: onToggleVisibility,
          )
              : null,
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.grey[600] : AppColors.grey),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSocialBtn(String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(10),
      height: 50, width: 50,
      decoration: BoxDecoration(
        color: isDark ? cardColor : Colors.transparent, // Petit fond en mode sombre
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
      ),
      child: Image.asset(path),
    );
  }
}*/


import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';

// IMPORTS CLEAN ARCHI
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../../../features/home/presentation/screens/main_wrapper_screen.dart';
import '../../../home/presentation/screens/forgot_password_flow.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- 1. CONTROLLERS ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscureText = true;
  bool _isLoading = false;

  // --- VARIABLE POUR GÉRER L'OVERLAY (Correction du bug "reste fixe") ---
  OverlayEntry? _currentOverlayEntry;

  // --- 2. NOTIFICATION TOP BAR (Design & Logique) ---
  void _showTopNotification(String message, {bool isError = false}) {
    // 1. Si une notif est déjà là, on l'enlève pour éviter la superposition
    _removeOverlay();

    final overlay = Overlay.of(context);
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
                Icon(isError ? Icons.warning_amber_rounded : Icons.check_circle_outline, color: Colors.white, size: 20),
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

    // 2. Affichage
    overlay.insert(_currentOverlayEntry!);

    // 3. Timer pour l'enlever automatiquement
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _removeOverlay();
    });
  }

  // Fonction utilitaire pour nettoyer l'overlay proprement
  void _removeOverlay() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  // --- 3. FONCTION DE CONNEXION ---
  Future<void> _handleLogin() async {
    // Validation
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      await authRepository.login(
          _emailController.text.trim(),
          _passwordController.text
      );

      if (!mounted) return;

      // Succès
      _showTopNotification("Connexion réussie !");

      // Petit délai esthétique avant de changer de page
      await Future.delayed(const Duration(milliseconds: 500));

      if (!mounted) return;

      // Navigation : On supprime tout l'historique précédent
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false, // <--- C'est cette condition qui supprime toutes les pages précédentes
      );

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
    // --- IMPORTANT : On nettoie la notification si on quitte l'écran ---
    _removeOverlay();

    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final secondaryTextColor = isDark ? Colors.grey[400] : AppColors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            children: [
              const Gap(40),
              SvgPicture.asset("assets/vectors/logo_complet.svg", height: 80),
              const Gap(30),
              Text("Connectez-vous",
                  style: TextStyle(
                      color: isDark ? Colors.white : AppColors.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold
                  )
              ),
              const Gap(30),

              // --- CHAMPS ---
              _buildAuthInput("Email", Icons.email_outlined, controller: _emailController),
              const Gap(15),

              _buildAuthInput("Mot de passe", Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscureText,
                  onToggleVisibility: () => setState(() => _obscureText = !_obscureText)
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.primary,
                          side: BorderSide(color: isDark ? Colors.grey : Colors.grey.shade400, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (v) => setState(() => _rememberMe = v!)
                      ),
                      Text("Se souvenir de moi", style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                    ],
                  ),
                  TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordEmailScreen())),
                      child: Text("Mot de passe oublié", style: TextStyle(color: secondaryTextColor, fontSize: 12))
                  )
                ],
              ),
              const Gap(20),

              // --- BOUTON ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Connexion", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const Gap(30),

              // --- FOOTER ---
              Row(
                children: [
                  Expanded(child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[300])),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("Ou continuez avec", style: TextStyle(color: secondaryTextColor, fontSize: 12))),
                  Expanded(child: Divider(color: isDark ? Colors.grey[800] : Colors.grey[300])),
                ],
              ),
              const Gap(20),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [_buildSocialBtn("assets/images/google-logo.png"), const Gap(20), _buildSocialBtn("assets/images/apple.png")]),
              const Gap(40),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text("Vous n'avez pas de compte ? ", style: TextStyle(color: secondaryTextColor, fontSize: 12)),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SignupScreen())),
                  child: const Text("Inscrivez-vous", style: TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
              ),
              const Gap(20),
            ],
          ),
        ),
      ),
    );
  }

  // --- HELPER INPUT ---
  Widget _buildAuthInput(String hint, IconData icon, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextEditingController? controller
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

  Widget _buildSocialBtn(String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(10),
      height: 50, width: 50,
      decoration: BoxDecoration(
        color: isDark ? cardColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
      ),
      child: Image.asset(path),
    );
  }
}