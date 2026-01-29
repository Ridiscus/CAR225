import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AuthLoadingScreen extends StatefulWidget {
  final Widget nextScreen;

  const AuthLoadingScreen({super.key, required this.nextScreen});

  @override
  State<AuthLoadingScreen> createState() => _AuthLoadingScreenState();
}

class _AuthLoadingScreenState extends State<AuthLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // --- CONFIGURATION DE L'ANIMATION (Inchangée) ---
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // --- NAVIGATION ---
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        // PushReplacement pour qu'on ne puisse pas revenir au chargement avec "Retour"
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => widget.nextScreen)
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE (Blanc ou Noir/Gris)
      body: Center(
        child: ScaleTransition(
          scale: _animation,
          child: SvgPicture.asset(
            "assets/vectors/logo_A.svg",
            width: 100,
            height: 100,
            // --- GESTION COULEUR LOGO ---
            // Si votre logo "A" est noir par défaut, il disparaitra sur fond noir.
            // Cette ligne le force à devenir Blanc en mode sombre.
            colorFilter: isDark
                ? const ColorFilter.mode(Colors.white, BlendMode.srcIn)
                : null, // En mode clair, on garde les couleurs d'origine
          ),
        ),
      ),
    );
  }
}