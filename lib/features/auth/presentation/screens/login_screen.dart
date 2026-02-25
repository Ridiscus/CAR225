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
  // 1. VARIABLES D'ÉTAT & CONTROLLERS
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _obscureText = true;
  bool _isLoading = false;

  // Variable pour gérer l'overlay de notification
  OverlayEntry? _currentOverlayEntry;

  // 2. CYCLE DE VIE (Lifecycle)
  @override
  void dispose() {
    _removeOverlay();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // 3. LOGIQUE & ACTIONS
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
        _passwordController.text,
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
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      String errorMsg = e.toString().replaceAll("Exception:", "").trim();
      _showTopNotification(errorMsg, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTopNotification(String message, {bool isError = false}) {
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
              color: isError
                  ? const Color(0xFFD32F2F).withOpacity(0.95)
                  : const Color(0xFF222222).withOpacity(0.95),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isError
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_outline,
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
                  ),
                ),
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

  void _removeOverlay() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildAuthInput(
    String hint,
    IconData icon, {
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleVisibility,
    TextEditingController? controller,
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
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey.shade300,
        ),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: iconColor),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    obscureText ? Icons.visibility_off : Icons.visibility,
                    color: iconColor,
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

  Widget _buildSocialBtn(String path) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      padding: const EdgeInsets.all(10),
      height: 50,
      width: 50,
      decoration: BoxDecoration(
        color: isDark ? cardColor : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey.shade300,
        ),
      ),
      child: Image.asset(path),
    );
  }

  // 5. MÉTHODE BUILD (Assemblage Final)
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final secondaryTextColor = isDark ? Colors.grey[400] : AppColors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              children: [
                const Gap(40),
                SvgPicture.asset("assets/vectors/logo_complet.svg", height: 80),
                const Gap(30),
                Text(
                  "Connectez-vous",
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(30),

                // --- CHAMPS ---
                _buildAuthInput(
                  "Email",
                  Icons.email_outlined,
                  controller: _emailController,
                ),
                const Gap(15),

                _buildAuthInput(
                  "Mot de passe",
                  Icons.lock_outline,
                  controller: _passwordController,
                  isPassword: true,
                  obscureText: _obscureText,
                  onToggleVisibility: () =>
                      setState(() => _obscureText = !_obscureText),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          activeColor: AppColors.primary,
                          side: BorderSide(
                            color: isDark ? Colors.grey : Colors.grey.shade400,
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (v) => setState(() => _rememberMe = v!),
                        ),
                        Text(
                          "Se souvenir de moi",
                          style: TextStyle(
                            color: secondaryTextColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const ForgotPasswordEmailScreen(),
                        ),
                      ),
                      child: Text(
                        "Mot de passe oublié",
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Connexion",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const Gap(30),

                // --- FOOTER ---
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Ou continuez avec",
                        style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: isDark ? Colors.grey[800] : Colors.grey[300],
                      ),
                    ),
                  ],
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildSocialBtn("assets/images/google-logo.png"),
                    const Gap(20),
                    _buildSocialBtn("assets/images/apple.png"),
                  ],
                ),
                const Gap(40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Vous n'avez pas de compte ? ",
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignupScreen(),
                        ),
                      ),
                      child: const Text(
                        "Inscrivez-vous",
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
