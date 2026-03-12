/*/*import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

// IMPORTS CLEAN ARCHI
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../home/presentation/screens/VerifOtpScreen.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/login_request_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../../../features/home/presentation/screens/main_wrapper_screen.dart';
import '../../../home/presentation/screens/forgot_password_flow.dart';
import 'signup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // Assure-toi d'avoir cet import




class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- 1. CONTROLLERS ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = true;
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


  Future<void> _handleLogin() async {
    final emailClean = _emailController.text.trim();
    final passwordClean = _passwordController.text;

    if (emailClean.isEmpty || passwordClean.isEmpty) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fcmService = FcmService();
      final deviceService = DeviceService();

      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: fcmService,
        deviceService: deviceService,
      );

      // 1. Préparation des données techniques
      String fcmToken = await fcmService.getToken() ?? "no_token";
      String deviceName = await deviceService.getDeviceName();

      // 📦 CRÉATION DU MODÈLE (C'est ici que l'erreur se règle)
      final loginParams = LoginRequestModel(
        email: emailClean,
        password: passwordClean,
        fcmToken: fcmToken,
        deviceName: deviceName,
      );

      print("⏳ [STEP 1] Appel API login()...");

      // 2. Appel API (On récupère maintenant AuthResponseModel)
      final response = await authRepository.login(loginParams);

      if (!mounted) return;

      // 3. GESTION DU FLUX (Succès vs OTP)
      if (response.success) {
        if (response.requiresOtp) {
          // 🚨 CAS OTP : On redirige vers l'écran de vérification
          print("📲 [OTP] Redirection vers l'écran de vérification...");
          _showTopNotification(response.message); // Affiche "Code envoyé au..."

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifOtpScreen(
                email: emailClean,
                contact: response.contact ?? "",
              ),
            ),
          );
        } else {
          // ✅ CAS CONNEXION DIRECTE
          print("✅ [STEP 1] Connexion réussie, chargement du profil...");

          await context.read<UserProvider>().loadUser();

          _showTopNotification("Connexion réussie !");
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
          );
        }
      }

    } catch (e, stackTrace) {
      print("🔴 [ERREUR] $e");
      // ... ton code de gestion d'erreur reste identique
      _showTopNotification(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }


  // --- 4. GESTION CONNEXION GOOGLE ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      print("🔵 [GOOGLE LOGIN] Démarrage...");
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        print("⚠️ [GOOGLE LOGIN] Annulé par l'utilisateur");
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception("Impossible de récupérer l'ID Token Google.");
      }

      String? fcmToken = await FirebaseMessaging.instance.getToken();

      // E. Appel API via la méthode intermédiaire
      await _processBackendGoogleLogin(
          googleId: googleUser.id,      // <--- AJOUTÉ : L'ID UNIQUE GOOGLE
          idToken: idToken,
          accessToken: accessToken,
          fcmToken: fcmToken,
          email: googleUser.email,
          displayName: googleUser.displayName,
          photoUrl: googleUser.photoUrl
      );

    } catch (e) {
      print("❌ [GOOGLE ERROR] $e");
      _showTopNotification("Erreur connexion Google: ${e.toString()}", isError: true);
      setState(() => _isLoading = false);
    }
  }


  Future<void> _processBackendGoogleLogin({
    required String googleId,   // <--- AJOUTÉ
    required String idToken,
    String? accessToken,
    String? fcmToken,
    String? email,
    String? displayName,
    String? photoUrl
  }) async {
    try {
      await AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      ).loginWithGoogle(
          googleId: googleId,           // <--- TRANSMIS AU REPO
          idToken: idToken,
          accessToken: accessToken,
          fcmToken: fcmToken ?? "no_fcm",
          email: email,
          fullName: displayName,        // Renommé pour correspondre au repo
          photoUrl: photoUrl
      );

      // ... La suite (Load User et Navigation) reste pareil ...
      if (!mounted) return;
      await context.read<UserProvider>().loadUser();

      _showTopNotification("Connexion Google réussie !");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
      );

    } catch (e) {
      throw e;
    }
  }



  @override
  void dispose() {
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

              // --- BOUTON CONNEXION ---
              Container(
                width: double.infinity,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/tabaa.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent, // Garde l'image visible pendant le chargement
                    shadowColor: Colors.transparent,
                    elevation: 0,
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
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // BOUTON GOOGLE AVEC ACTION
                    _buildSocialBtn(
                      "assets/images/google-logo.png",
                      onTap: _handleGoogleLogin, // <--- C'est ici que ça se passe !
                    ),

                    const Gap(20),

                    // BOUTON APPLE (Placeholder pour l'instant)
                    _buildSocialBtn(
                      "assets/images/apple.png",
                      onTap: () {
                        _showTopNotification("Connexion Apple bientôt disponible");
                      },
                    )
                  ]
              ),
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


  // --- HELPER BOUTON SOCIAL (CORRIGÉ) ---
  Widget _buildSocialBtn(String path, {VoidCallback? onTap}) { // 1. Ajout du paramètre onTap
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return GestureDetector( // 2. Ajout du détecteur de clic
      onTap: onTap, // 3. Liaison de l'action
      child: Container(
        padding: const EdgeInsets.all(10),
        height: 50, width: 50,
        decoration: BoxDecoration(
          color: isDark ? cardColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
        ),
        child: Image.asset(path),
      ),
    );
  }

}*/



import 'dart:io'; // 🟢 NOUVEAU : Import nécessaire pour Platform.isIOS
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

// IMPORTS CLEAN ARCHI
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../home/presentation/screens/VerifOtpScreen.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/login_request_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../../../features/home/presentation/screens/main_wrapper_screen.dart';
import '../../../home/presentation/screens/forgot_password_flow.dart';
import 'signup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- 1. CONTROLLERS ---
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = true; // 🟢 MODIF : Activé par défaut (true au lieu de false)
  bool _obscureText = true;
  bool _isLoading = false;

  // --- VARIABLE POUR GÉRER L'OVERLAY ---
  OverlayEntry? _currentOverlayEntry;

  // --- 2. NOTIFICATION TOP BAR ---
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

    overlay.insert(_currentOverlayEntry!);

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) _removeOverlay();
    });
  }

  void _removeOverlay() {
    _currentOverlayEntry?.remove();
    _currentOverlayEntry = null;
  }

  Future<void> _handleLogin() async {
    final emailClean = _emailController.text.trim();
    final passwordClean = _passwordController.text;

    if (emailClean.isEmpty || passwordClean.isEmpty) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fcmService = FcmService();
      final deviceService = DeviceService();

      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: fcmService,
        deviceService: deviceService,
      );

      String fcmToken = await fcmService.getToken() ?? "no_token";
      String deviceName = await deviceService.getDeviceName();

      final loginParams = LoginRequestModel(
        email: emailClean,
        password: passwordClean,
        fcmToken: fcmToken,
        deviceName: deviceName,
      );

      final response = await authRepository.login(loginParams);

      if (!mounted) return;

      if (response.success) {
        if (response.requiresOtp) {
          _showTopNotification(response.message);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifOtpScreen(
                email: emailClean,
                contact: response.contact ?? "",
              ),
            ),
          );
        } else {
          await context.read<UserProvider>().loadUser();

          _showTopNotification("Connexion réussie !");
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
          );
        }
      }

    } catch (e, stackTrace) {
      print("🔴 [ERREUR] $e");
      _showTopNotification(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 4. GESTION CONNEXION GOOGLE ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception("Impossible de récupérer l'ID Token Google.");
      }

      String? fcmToken = await FirebaseMessaging.instance.getToken();

      await _processBackendGoogleLogin(
          googleId: googleUser.id,
          idToken: idToken,
          accessToken: accessToken,
          fcmToken: fcmToken,
          email: googleUser.email,
          displayName: googleUser.displayName,
          photoUrl: googleUser.photoUrl
      );

    } catch (e) {
      _showTopNotification("Erreur connexion Google: ${e.toString()}", isError: true);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processBackendGoogleLogin({
    required String googleId,
    required String idToken,
    String? accessToken,
    String? fcmToken,
    String? email,
    String? displayName,
    String? photoUrl
  }) async {
    try {
      await AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      ).loginWithGoogle(
          googleId: googleId,
          idToken: idToken,
          accessToken: accessToken,
          fcmToken: fcmToken ?? "no_fcm",
          email: email,
          fullName: displayName,
          photoUrl: photoUrl
      );

      if (!mounted) return;
      await context.read<UserProvider>().loadUser();

      _showTopNotification("Connexion Google réussie !");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
      );

    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
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

              // --- BOUTON CONNEXION ---
              Container(
                width: double.infinity,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/tabaa.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
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

              // --- BOUTONS SOCIAUX ---
              Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // BOUTON GOOGLE TOUJOURS VISIBLE
                    _buildSocialBtn(
                      "assets/images/google-logo.png",
                      onTap: _handleGoogleLogin,
                    ),

                    // 🟢 MODIF : Le bouton Apple s'affiche UNIQUEMENT sur iOS
                    if (Platform.isIOS) ...[
                      const Gap(20),
                      _buildSocialBtn(
                        "assets/images/apple.png",
                        onTap: () {
                          _showTopNotification("Connexion Apple bientôt disponible");
                        },
                      ),
                    ]
                  ]
              ),

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

  // --- HELPER BOUTON SOCIAL ---
  Widget _buildSocialBtn(String path, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        height: 50, width: 50,
        decoration: BoxDecoration(
          color: isDark ? cardColor : Colors.transparent,
          shape: BoxShape.circle,
          border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300),
        ),
        child: Image.asset(path),
      ),
    );
  }
}*/


import 'dart:io'; // 🟢 NOUVEAU : Import nécessaire pour Platform.isIOS
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

// IMPORTS CLEAN ARCHI
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../agent/presentation/screens/agent_main_wrapper.dart';
import '../../../home/presentation/screens/VerifOtpScreen.dart';
import '../../../hostess/presentation/screens/hostess_main_wrapper.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/models/login_request_model.dart';
import '../../data/models/unified_login_request_model.dart';
import '../../data/repositories/auth_repository_impl.dart';

import '../../../../features/home/presentation/screens/main_wrapper_screen.dart';
import '../../../home/presentation/screens/forgot_password_flow.dart';
import 'signup_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';



class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // --- 1. CONTROLLERS ---
  /*final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();*/

  // --- 1. CONTROLLERS ---
  // Remplacer _emailController par _identifierController
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe =
  true; // 🟢 MODIF : Activé par défaut (true au lieu de false)
  bool _obscureText = true;
  bool _isLoading = false;

  // --- VARIABLE POUR GÉRER L'OVERLAY ---
  OverlayEntry? _currentOverlayEntry;

  // --- 2. NOTIFICATION TOP BAR ---
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

  /*Future<void> _handleLogin() async {
    final emailClean = _emailController.text.trim();
    final passwordClean = _passwordController.text;

    if (emailClean.isEmpty || passwordClean.isEmpty) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fcmService = FcmService();
      final deviceService = DeviceService();

      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: fcmService,
        deviceService: deviceService,
      );

      String fcmToken = await fcmService.getToken() ?? "no_token";
      String deviceName = await deviceService.getDeviceName();

      final loginParams = LoginRequestModel(
        email: emailClean,
        password: passwordClean,
        fcmToken: fcmToken,
        deviceName: deviceName,
      );

      final response = await authRepository.login(loginParams);

      if (!mounted) return;

      if (response.success) {
        if (response.requiresOtp) {
          _showTopNotification(response.message);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VerifOtpScreen(
                email: emailClean,
                contact: response.contact ?? "",
              ),
            ),
          );
        } else {
          await context.read<UserProvider>().loadUser();

          _showTopNotification("Connexion réussie !");
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
          );
        }
      }
    } catch (e, stackTrace) {
      print("🔴 [ERREUR] $e");
      _showTopNotification(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }*/


  Future<void> _handleLogin() async {
    final identifierClean = _identifierController.text.trim(); // <-- Modifié
    final passwordClean = _passwordController.text;

    if (identifierClean.isEmpty || passwordClean.isEmpty) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final fcmService = FcmService();
      final deviceService = DeviceService();

      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: fcmService,
        deviceService: deviceService,
      );

      String fcmToken = await fcmService.getToken() ?? "no_token";
      String deviceName = await deviceService.getDeviceName();

      // 🟢 LOGIQUE DE SÉPARATION (Email vs Code ID)
      bool isEmail = identifierClean.contains('@');

      if (isEmail) {
        // ---------------------------------------------------------
        // 1️⃣ C'EST UN PARTICULIER (Il a tapé un email avec @)
        // ---------------------------------------------------------
        final loginParams = LoginRequestModel(
          email: identifierClean,
          password: passwordClean,
          fcmToken: fcmToken,
          deviceName: deviceName,
        );

        final response = await authRepository.login(loginParams);

        if (!mounted) return;

        if (response.success) {
          if (response.requiresOtp) {
            _showTopNotification(response.message);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => VerifOtpScreen(
                  email: identifierClean,
                  contact: response.contact ?? "",
                ),
              ),
            );
          } else {
            await context.read<UserProvider>().loadUser();
            _showTopNotification("Connexion réussie !");
            await Future.delayed(const Duration(milliseconds: 500));
            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()), // Redirection Particulier
                  (route) => false,
            );
          }
        }
      } else {
        // ---------------------------------------------------------
        // 2️⃣ C'EST UNE HÔTESSE / AGENT (Il a tapé un Code, ex: ZEUS123)
        // ---------------------------------------------------------
        print("👉 [DEBUG] Tentative de connexion via Code ID : $identifierClean");

        final unifiedLoginParams = UnifiedLoginRequestModel(
          codeId: identifierClean,
          password: passwordClean,
          fcmToken: fcmToken,
          nomDevice: deviceName,
        );

        final response = await authRepository.unifiedLogin(unifiedLoginParams);

        if (!mounted) return;

        /*if (response.success) {
          // Si besoin, charger des infos utilisateurs spécifiques ici
          // await context.read<UserProvider>().loadUser();

          _showTopNotification("Connexion réussie !");
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          // Redirection vers l'espace Hôtesse !
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const HostessMainWrapper()),
                (route) => false,
          );
        }*/

        if (response.success) {
          await context.read<UserProvider>().loadUser(); // À décommenter si besoin

          _showTopNotification("Connexion réussie !");
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          // 🟢 ROUTAGE DYNAMIQUE SELON LE RÔLE
          Widget destination;
          if (response.role == 'hotesse') {
            destination = const HostessMainWrapper();
          } else if (response.role == 'agent') {
            destination = const AgentMainWrapper();
          } else {
            // Par défaut si le rôle n'est pas reconnu
            destination = const MainScreen();
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => destination),
                (route) => false,
          );
        }


      }

    } catch (e) {
      print("🔴 [ERREUR] $e");
      _showTopNotification(e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 4. GESTION CONNEXION GOOGLE ---
  Future<void> _handleGoogleLogin() async {
    setState(() => _isLoading = true);

    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      final String? accessToken = googleAuth.accessToken;

      if (idToken == null) {
        throw Exception("Impossible de récupérer l'ID Token Google.");
      }

      String? fcmToken = await FirebaseMessaging.instance.getToken();

      await _processBackendGoogleLogin(
        googleId: googleUser.id,
        idToken: idToken,
        accessToken: accessToken,
        fcmToken: fcmToken,
        email: googleUser.email,
        displayName: googleUser.displayName,
        photoUrl: googleUser.photoUrl,
      );
    } catch (e) {
      _showTopNotification(
        "Erreur connexion Google: ${e.toString()}",
        isError: true,
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _processBackendGoogleLogin({
    required String googleId,
    required String idToken,
    String? accessToken,
    String? fcmToken,
    String? email,
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      await AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      ).loginWithGoogle(
        googleId: googleId,
        idToken: idToken,
        accessToken: accessToken,
        fcmToken: fcmToken ?? "no_fcm",
        email: email,
        fullName: displayName,
        photoUrl: photoUrl,
      );

      if (!mounted) return;
      await context.read<UserProvider>().loadUser();

      _showTopNotification("Connexion Google réussie !");

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
            (route) => false,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    //_emailController.dispose();
    _identifierController.dispose();
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
              /*_buildAuthInput(
                "Email",
                Icons.email_outlined,
                controller: _emailController,
              ),
              const Gap(15),*/

              // --- CHAMPS ---
              _buildAuthInput(
                "Email ou Code ID", // 🟢 Le texte change pour être explicite
                Icons.person_outline, // 🟢 L'icône change pour être plus générique
                controller: _identifierController,
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
                        builder: (context) => const ForgotPasswordEmailScreen(),
                      ),
                    ),
                    child: Text(
                      "Mot de passe oublié",
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
                    ),
                  ),
                ],
              ),
              const Gap(20),

              // --- BOUTON CONNEXION ---
              Container(
                width: double.infinity,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/tabaa.jpg"),
                    fit: BoxFit.cover,
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    disabledBackgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    elevation: 0,
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
                      style: TextStyle(color: secondaryTextColor, fontSize: 12),
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

              // --- BOUTONS SOCIAUX ---
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // BOUTON GOOGLE TOUJOURS VISIBLE
                  _buildSocialBtn(
                    "assets/images/google-logo.png",
                    onTap: _handleGoogleLogin,
                  ),

                  // 🟢 MODIF : Le bouton Apple s'affiche UNIQUEMENT sur iOS
                  if (Platform.isIOS) ...[
                    const Gap(20),
                    _buildSocialBtn(
                      "assets/images/apple.png",
                      onTap: () {
                        _showTopNotification(
                          "Connexion Apple bientôt disponible",
                        );
                      },
                    ),
                  ],
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
    );
  }

  // --- HELPER INPUT ---
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

  // --- HELPER BOUTON SOCIAL ---
  Widget _buildSocialBtn(String path, {VoidCallback? onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}
