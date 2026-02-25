import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart'; // <--- IMPORT CRUCIAL

// Tes imports d'écrans
import '../../../home/presentation/screens/main_wrapper_screen.dart';
// <--- Import de ton MainScreen (Dashboard)
import '../../../agent/presentation/screens/agent_main_wrapper.dart'; // <--- Import du wrapper Agent
import 'package:car225/features/hostess/presentation/screens/hostess_main_wrapper.dart';
import '../../../driver/presentation/screens/driver_main_wrapper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Variable pour stocker l'état de connexion
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();

    // 1. On lance la vérification du token immédiatement
    _checkLoginStatus();

    // 2. On lance le timer de l'animation (4500ms comme ton code original)
    Future.delayed(const Duration(milliseconds: 4500), () {
      _handleNavigation();
    });
  }

  // Vérifie si le token existe dans le téléphone
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    // Si le token n'est pas null et pas vide, on considère que c'est connecté
    setState(() {
      _isConnected = token != null && token.isNotEmpty;
    });

    // debugPrint("Statut connexion Splash: $_isConnected");
  }

  // Gère la redirection finale
  void _handleNavigation() {
    // Si l'utilisateur a quitté l'appli pendant le splash, on arrête
    if (!mounted) return;

    // CHOIX DE LA PAGE DE DESTINATION
    // TEMPORAIRE : On redirige vers l'écran Driver pour le développement
    const String userType = "driver";

    final Widget destination = _isConnected
        ? const MainScreen() // Si connecté -> Dashboard
        : userType == "hostess"
        ? const HostessMainWrapper()
        : userType == "driver"
        ? const DriverMainWrapper()
        : const AgentMainWrapper();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionDuration: const Duration(milliseconds: 800),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const curve = Curves.easeInOut;
          return FadeTransition(
            opacity: animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ta logique UI reste EXACTEMENT la même, je l'ai gardée telle quelle
    final size = MediaQuery.of(context).size;
    const int startTextDelay = 2000;
    const int moveDuration = 800;
    const int pauseAuCentre = 600;
    const int ascensionDuration = 1000;
    final double ascensionDistance = -size.height * 0.35;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFFF4500),
        body: SafeArea(
          top: false,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // --- 0. L'ANNEAU FIN ---
              Center(
                child:
                    Container(
                          width: 115,
                          height: 115,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.yellowAccent.withValues(alpha: 0.7),
                              width: 2,
                            ),
                          ),
                        )
                        .animate()
                        .scale(
                          duration: 1000.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.15, 1.15),
                          curve: Curves.easeInOut,
                        )
                        .tint(color: Colors.white, duration: 1000.ms)
                        .then(delay: 500.ms)
                        .fadeOut(duration: 300.ms),
              ),

              // --- 1. LE CERCLE BLANC ---
              Center(
                child:
                    Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate()
                        .scale(
                          duration: 1000.ms,
                          begin: const Offset(1, 1),
                          end: const Offset(1.1, 1.1),
                          curve: Curves.easeInOut,
                        )
                        .then()
                        .scale(
                          delay: 500.ms,
                          duration: 800.ms,
                          end: const Offset(30, 30),
                          curve: Curves.easeInExpo,
                        ),
              ),

              // --- 2. LE LOGO "A" ---
              Center(
                child: SvgPicture.asset('assets/vectors/logo_A.svg', height: 60)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .then(delay: 1000.ms)
                    .fadeOut(duration: 300.ms, curve: Curves.easeOut),
              ),

              // --- 3. LA PARENTHÈSE / ARCHE (Partie HAUTE) ---
              Positioned(
                    top: size.height * 0.50 - 35,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/vectors/logo_text_top.svg',
                        height: 30,
                      ),
                    ),
                  )
                  .animate(delay: startTextDelay.ms)
                  .moveY(
                    begin: -250,
                    end: 0,
                    duration: moveDuration.ms,
                    curve: Curves.easeOutQuart,
                  )
                  .fadeIn(duration: 200.ms)
                  .then(delay: pauseAuCentre.ms)
                  .moveY(
                    begin: 0,
                    end: ascensionDistance,
                    duration: ascensionDuration.ms,
                    curve: Curves.easeInOutCubic,
                  ),

              // --- 4. LE TEXTE "CAR 225" (Partie BASSE) ---
              Positioned(
                    top: size.height * 0.50 - 5,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SvgPicture.asset(
                        'assets/vectors/logo_text_bottom.svg',
                        height: 70,
                      ),
                    ),
                  )
                  .animate(delay: startTextDelay.ms)
                  .moveY(
                    begin: 250,
                    end: 0,
                    duration: moveDuration.ms,
                    curve: Curves.easeOutQuart,
                  )
                  .fadeIn(duration: 200.ms)
                  .then(delay: pauseAuCentre.ms)
                  .moveY(
                    begin: 0,
                    end: ascensionDistance,
                    duration: ascensionDuration.ms,
                    curve: Curves.easeInOutCubic,
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
