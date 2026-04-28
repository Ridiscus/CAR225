import 'dart:io'; // 🟢 NOUVEAU : Import nécessaire pour Platform.isIOS
import 'package:car225/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// IMPORTS CLEAN ARCHI
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../agent/presentation/screens/agent_main_wrapper.dart';
import '../../../driver/presentation/screens/driver_main_wrapper.dart';
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
  // Remplacer _emailController par _identifierController
  final TextEditingController _identifierController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe =
  true; // 🟢 MODIF : Activé par défaut (true au lieu de false)
  bool _obscureText = true;
  bool _isLoading = false;

  String _lastInputValue = "";

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

        /*if (response.success) {
          // 🟢 SAUVEGARDE DU RÔLE DANS LE TÉLÉPHONE
          final prefs = await SharedPreferences.getInstance();
          final String role = (response.role ?? '').toLowerCase();
          await prefs.setString('user_role', role); // <-- Ligne magique

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
        }*/

        if (response.success) {
          // 🟢 On force le rôle "user" pour le particulier
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_role', 'user');

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
          }  else {
            await context.read<UserProvider>().loadUser();
            _showTopNotification("Connexion réussie !");
            await Future.delayed(const Duration(milliseconds: 500));
            if (!mounted) return;

            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const MainScreen()), // ✅ Normal pour un particulier
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
          await context.read<UserProvider>().loadUser(); // À décommenter si besoin

          _showTopNotification("Connexion réussie !");
          await Future.delayed(const Duration(milliseconds: 500));

          if (!mounted) return;

          // 🟢 LOG POUR VOIR EXACTEMENT LE RÔLE ENVOYÉ PAR L'API
          print("👉 [DEBUG] Rôle reçu de l'API : '${response.role}'");

          // 🟢 ROUTAGE DYNAMIQUE SELON LE RÔLE (en minuscules pour éviter les erreurs de majuscules)
          Widget destination;
          final String role = (response.role ?? '').toLowerCase();

          if (role == 'hotesse' || role == 'hôtesse') {
            destination = const HostessMainWrapper();
          } else if (role == 'agent') {
            destination = const AgentMainWrapper();
          } else if (role == 'driver' || role == 'chauffeur') { // 🟢 ON ACCEPTE "driver" ET "chauffeur"
            destination = const DriverMainWrapper();
          } else {
            // Par défaut si le rôle n'est pas reconnu
            print("⚠️ [WARNING] Rôle non reconnu : '$role'. Redirection vers MainScreen.");
            destination = const MainScreen();
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => destination),
                (route) => false,
          );
        }*/


        if (response.success) {
          // 🟢 On sauvegarde le rôle renvoyé par l'API
          final prefs = await SharedPreferences.getInstance();
          final String role = (response.role ?? '').toLowerCase();
          await prefs.setString('user_role', role);

          await context.read<UserProvider>().loadUser();
          _showTopNotification("Connexion réussie !");
          await Future.delayed(const Duration(milliseconds: 500));
          if (!mounted) return;


          // ✅ REDIRECTION DYNAMIQUE OBLIGATOIRE ICI
          Widget destination;

          if (role == 'hotesse' || role == 'hôtesse') {
            destination = const HostessMainWrapper();
          } else if (role == 'agent') {
            destination = const AgentMainWrapper();
          } else if (role == 'driver' || role == 'chauffeur') {

            // 🟢 ON INTERCEPTE LE CHAUFFEUR POUR AFFICHER LE POP-UP GOOGLE
            bool accepted = await _showLocationDisclosureDialog();

            if (!mounted) return;

            if (!accepted) {
              _showTopNotification(
                  "Vous devez accepter la localisation pour vous connecter en tant que chauffeur.",
                  isError: true
              );
              // On arrête tout, il n'est pas redirigé
              return;
            }

            destination = const DriverMainWrapper();

          } else {
            destination = const MainScreen();
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => destination),
                (route) => false,
          );

          // ✅ REDIRECTION DYNAMIQUE OBLIGATOIRE ICI
          /*Widget destination;
          if (role == 'hotesse' || role == 'hôtesse') {
            destination = const HostessMainWrapper();
          } else if (role == 'agent') {
            destination = const AgentMainWrapper();
          } else if (role == 'driver' || role == 'chauffeur') {
            destination = const DriverMainWrapper();
          } else {
            destination = const MainScreen();
          }

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => destination),
                (route) => false,
          );*/
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


  // 🟢 NOUVEAU : Le Pop-up obligatoire de Google pour la localisation
  Future<bool> _showLocationDisclosureDialog() async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force l'utilisateur à choisir
      builder: (BuildContext context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return AlertDialog(
          backgroundColor: isDark ? Theme.of(context).cardColor : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary),
              const Gap(10),
              Expanded(
                child: Text(
                  "Utilisation de votre position",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            "CAR225 collecte des données de localisation pour permettre le suivi de vos courses en temps réel par les passagers et calculer le montant du trajet, même lorsque l'application est fermée ou en arrière-plan.",
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.black87,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Refuse
              child: const Text(
                "Refuser",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.of(context).pop(true), // Accepte
              child: const Text(
                "Accepter",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  void dispose() {
    _removeOverlay();
    //_emailController.dispose();
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }


  // 🟢 LOGIQUE D'AUTO-COMPLÉTION CORRIGÉE (Gère l'effacement)
  void _handleIdentifierInput(String value) {
    // Si l'utilisateur est en train d'effacer, on ne fait rien
    // et on met juste à jour notre variable de mémorisation.
    if (value.length < _lastInputValue.length) {
      _lastInputValue = value;
      return;
    }

    // On met à jour la valeur mémorisée
    _lastInputValue = value;

    // On ne déclenche l'auto-complétion que si c'est exactement la 1ère lettre tapée
    if (value.length == 1) {
      final firstChar = value.toUpperCase();
      String prefix = "";

      if (firstChar == 'U') {
        prefix = 'USR-';
      } else if (firstChar == 'A') {
        prefix = 'AGT-';
      } else if (firstChar == 'C') {
        prefix = 'CHF-';
      } else if (firstChar == 'H') {
        prefix = 'HTS-';
      }

      if (prefix.isNotEmpty) {
        // On remplace le texte par le préfixe
        _identifierController.value = TextEditingValue(
          text: prefix,
          selection: TextSelection.collapsed(offset: prefix.length),
        );

        // 🔴 TRÈS IMPORTANT : On dit à notre variable qu'on vient d'insérer 4 caractères
        // pour que la touche effacer fonctionne bien par la suite.
        _lastInputValue = prefix;
      }
    }
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
                "Tél ou Code ID",
                "assets/images/user.png", // 🟢 Ici, on met le chemin de ton Flaticon
                controller: _identifierController,
                onChanged: _handleIdentifierInput,
              ),
              const Gap(15),

              _buildAuthInput(
                "Mot de passe",
                "assets/images/padlock.png", // 🟢 Pareil ici
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
  /*Widget _buildAuthInput(
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
  }*/
// --- HELPER INPUT MODIFIÉ ---
  Widget _buildAuthInput(
      String hint,
      String iconPath, { // 🟢 MODIFICATION : On attend un String (chemin) au lieu d'un IconData
        bool isPassword = false,
        bool obscureText = false,
        VoidCallback? onToggleVisibility,
        TextEditingController? controller,
        Function(String)? onChanged,
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
        onChanged: onChanged,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          // 🟢 MODIFICATION : On utilise Image.asset avec un Padding
          prefixIcon: Padding(
            padding: const EdgeInsets.all(14.0), // Ajuste cette valeur pour modifier l'espacement
            child: Image.asset(
              iconPath,
              width: 22, // Ajuste la taille de ton Flaticon ici
              height: 22,
              color: iconColor, // Garde la couleur dynamique (clair/sombre) de ton thème
            ),
          ),

          // Note: L'icône "œil" pour le mot de passe reste un Icon Flutter classique
          // car c'est très standard, mais tu peux aussi le changer de la même manière si tu as un Flaticon pour ça !
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
