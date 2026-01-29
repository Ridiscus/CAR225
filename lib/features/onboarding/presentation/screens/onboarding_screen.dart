/*import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../home_flow.dart';






class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // CONTENU : On utilise maintenant AppColors
  final List<Map<String, dynamic>> _content = [
    {
      "image": "assets/images/onboarding_map.jpg",
      "title": "Le voyage simplifié\npartout en Côte d'Ivoire",
      "desc": "Réservez vos trajets en car en un clic.\nProfitez d'un réseau national complet,\ndu confort moderne et du Wi-Fi à bord.",
      "color": AppColors.primary,        // Orange
      "bgColor": AppColors.primaryLight  // Orange clair
    },
    {
      "image": "assets/images/onboarding_process.jpg",
      "title": "Réservez en quelques\nclics",
      "desc": "Trouvez et réservez vos billets de bus pour\ntoute la Côte d'Ivoire avec des compagnies\npartenaires.",
      "color": AppColors.secondary,       // Vert
      "bgColor": AppColors.secondaryLight // Vert clair
    },
    {
      "image": "assets/images/onboarding_seat.jpg",
      "title": "Votre place, votre\nconfort",
      "desc": "Choisissez et réservez facilement votre\nsiège. Profitez d'un espace dédié pour\nun voyage paisible.",
      "color": AppColors.primary,
      "bgColor": AppColors.primaryLight
    },
    {
      "image": "assets/images/onboarding_relax.jpg",
      "title": "Gagnez en temps\nSoyez Smart",
      "desc": "Votre temps est précieux, ne le passez\npas dans une file d'attente.",
      "color": AppColors.secondary,
      "bgColor": AppColors.secondaryLight
    },
  ];

  void _finishOnboarding() {
    // Navigation propre vers le Login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // Récupération dynamique des couleurs selon la page
    final currentColor = _content[_currentPage]["color"] as Color;
    final currentBgColor = _content[_currentPage]["bgColor"] as Color;

    return Scaffold(
      backgroundColor: AppColors.white, // Utilisation du thème
      body: Stack(
        children: [
          // --- 1. LES CERCLES D'AMBIANCE (ANIMÉS) ---

          // Cercle Haut-Droit
          Positioned(
            top: -50,
            right: -50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentBgColor.withOpacity(0.5),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: 2000.ms, curve: Curves.easeInOut),
          ),

          // Cercle Bas-Gauche
          Positioned(
            bottom: -50,
            left: -50,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: currentBgColor.withOpacity(0.5),

              ),
            )
                .animate(onPlay: (controller) => controller.repeat(reverse: true))
                .moveY(begin: 0, end: -20, duration: 3000.ms, curve: Curves.easeInOut)
                .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 3000.ms),
          ),

          // --- 2. LE LOGO FIXE ---
          Positioned(
            top: size.height * 0.12,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SvgPicture.asset('assets/vectors/logo_text_top.svg', height: 22),
                  SvgPicture.asset('assets/vectors/logo_text_bottom.svg', height: 60),
                ],
              ),
            ),
          ),

          // --- 3. BOUTON PASSER ---
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _finishOnboarding,
              child: const Text(
                "Passer",
                style: TextStyle(color: AppColors.grey, fontSize: 16),
              ),
            ),
          ),

          // --- 4. CONTENU (PageView) ---
          Positioned.fill(
            top: size.height * 0.25,
            child: Column(
              children: [
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) => setState(() => _currentPage = index),
                    itemCount: _content.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              _content[index]["image"]!,
                              height: 280,
                              fit: BoxFit.contain,
                            )
                                .animate(target: _currentPage == index ? 1 : 0)
                                .fadeIn(duration: 400.ms)
                                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

                            const Gap(30),

                            Text(
                              _content[index]["title"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.black,
                              ),
                            ),
                            const Gap(15),

                            Text(
                              _content[index]["desc"]!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.grey,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // --- 5. BAS DE PAGE (Indicateurs + Bouton) ---
                Padding(
                  padding: EdgeInsets.only(bottom: 40 + bottomPadding, left: 20, right: 20),
                  child: Column(
                    children: [
                      // Indicateurs
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(

                          _content.length,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 5),
                            height: 6,
                            width: _currentPage == index ? 25 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index ? currentColor : AppColors.greyLight,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                        ),
                      ),

                      const Gap(30),

                      // Bouton Principal
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 55,
                        decoration: BoxDecoration(
                          color: currentColor,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_currentPage < _content.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            } else {
                              _finishOnboarding();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          child: Text(
                            _currentPage == _content.length - 1 ? "Commencez ✓" : "Suivant >",
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/


import 'package:car225/features/onboarding/presentation/home_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Imports
import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _content = [
    {
      "image": "assets/images/onboarding_maps.png",
      "title": "Le voyage simplifié\npartout en Côte d'Ivoire",
      "desc": "Profitez d'un réseau national complet, du confort moderne et du Wi-Fi à bord.",
    },
    {
      "image": "assets/images/onboarding_processs.png",
      "title": "Réservez en\nquelques clics",
      "desc": "Trouvez et réservez vos billets de bus avec nos compagnies partenaires fiables.",
    },
    {
      "image": "assets/images/onboarding_seat.png",
      "title": "Votre place,\nvotre confort",
      "desc": "Choisissez votre siège. Profitez d'un espace dédié pour un voyage paisible.",
    },
    {
      "image": "assets/images/onboarding_relax.png",
      "title": "Gagnez du temps,\nSoyez Smart",
      "desc": "Votre temps est précieux. Ne le perdez plus jamais dans une file d'attente.",
    },
  ];

  void _nextPage() {
    if (_currentPage < _content.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Couleur du fond de la carte du bas (Blanc vs Gris Foncé)
    final sheetColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    // Couleurs de texte
    final titleColor = isDark ? Colors.white : Colors.black;
    final descColor = isDark ? Colors.grey[400] : AppColors.grey;

    // Couleurs éléments graphiques
    final inactiveIndicatorColor = isDark ? Colors.grey[800] : AppColors.greyLight;
    final shadowColor = isDark ? Colors.black.withOpacity(0.5) : Colors.black12;

    // Calcul de la progression
    double progress = (_currentPage + 1) / _content.length;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.background,
      body: Stack(
        children: [
          // --- 1. IMAGE IMMERSIVE ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.65,
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentPage = index),
              itemCount: _content.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  _content[index]["image"]!,
                  fit: BoxFit.cover,
                );
              },
            ),
          ),

          // Ombre légère pour l'image
          Positioned(
            top: 0, left: 0, right: 0, height: size.height * 0.65,
            child: Container(color: Colors.black.withOpacity(0.1)),
          ),

          // --- 2. BOUTON "PASSER" ---
          Positioned(
            top: 50,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextButton(
                onPressed: _finishOnboarding,
                child: const Text(
                  "Passer",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),

          // --- 3. LA CARTE (CONTENU) ---
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: size.height * 0.45,
              width: double.infinity,
              decoration: BoxDecoration(
                color: sheetColor, // <--- COULEUR DYNAMIQUE ICI
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
                    color: shadowColor,
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  )
                ],
              ),
              padding: EdgeInsets.fromLTRB(
                  30,
                  40,
                  30,
                  20 + MediaQuery.of(context).padding.bottom
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // LOGO DISCRET
                  SvgPicture.asset(
                      'assets/vectors/logo_text_top.svg',
                      height: 16,
                      // Si le logo est noir de base, on le force en blanc ou orange en mode sombre
                      // Ici on garde Primary (Orange) ça marche souvent sur les deux fonds
                      color: AppColors.primary
                  ),
                  const Gap(20),

                  // TITRE ANIMÉ
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      );
                    },
                    child: Text(
                      _content[_currentPage]["title"]!,
                      key: ValueKey<String>(_content[_currentPage]["title"]!),
                      style: TextStyle(
                        fontSize: 32,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: titleColor, // <--- COULEUR DYNAMIQUE
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ),

                  const Gap(20),

                  // DESCRIPTION ANIMÉE
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _content[_currentPage]["desc"]!,
                      key: ValueKey<String>(_content[_currentPage]["desc"]!),
                      style: TextStyle(
                        fontSize: 15,
                        color: descColor, // <--- COULEUR DYNAMIQUE
                        height: 1.6,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // --- 4. NAVIGATION BAS DE PAGE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Indicateurs
                      Row(
                        children: List.generate(
                          _content.length,
                              (index) => AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.only(right: 8),
                            height: 8,
                            width: _currentPage == index ? 30 : 8,
                            decoration: BoxDecoration(
                              // Inactif = Gris foncé en Dark Mode, Gris clair en Light Mode
                              color: _currentPage == index ? AppColors.primary : inactiveIndicatorColor,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      // BOUTON CIRCULAIRE PROGRESSIF
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              value: progress,
                              strokeWidth: 4,
                              // Fond du cercle : plus sombre en mode sombre
                              backgroundColor: inactiveIndicatorColor,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          FloatingActionButton(
                            onPressed: _nextPage,
                            backgroundColor: AppColors.primary,
                            elevation: 0,
                            shape: const CircleBorder(),
                            child: Icon(
                              _currentPage == _content.length - 1 ? Icons.check : Icons.arrow_forward_ios,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      )
                    ],
                  )
                ],
              ),
            )
                .animate()
                .moveY(
                begin: 100,
                end: 0,
                duration: 800.ms,
                curve: Curves.easeOutCubic,
                delay: 200.ms
            ),
          ),
        ],
      ),
    );
  }
}
