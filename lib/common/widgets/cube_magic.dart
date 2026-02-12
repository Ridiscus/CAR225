import 'dart:async';
import 'package:flutter/material.dart';

class SimpleHeaderBackground extends StatefulWidget {
  final List<String> images;
  final double height;

  const SimpleHeaderBackground({
    super.key,
    required this.images,
    required this.height,
  });

  @override
  State<SimpleHeaderBackground> createState() => _SimpleHeaderBackgroundState();
}

class _SimpleHeaderBackgroundState extends State<SimpleHeaderBackground> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startSlideShow();
  }

  void _startSlideShow() {
    // Change d'image toutes les 5 secondes
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        setState(() {
          _currentIndex = (_currentIndex + 1) % widget.images.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      // AnimatedSwitcher gère automatiquement le fondu entre les widgets
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1000), // Durée du fondu (1 seconde)
        switchInCurve: Curves.easeOut, // Courbe douce
        switchOutCurve: Curves.easeIn,

        // C'est ici qu'on définit l'animation (Fondu + Léger Zoom)
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              // Zoom très léger de 1.05x à 1.0x (effet d'atterrissage doux)
              scale: Tween<double>(begin: 1.05, end: 1.0).animate(animation),
              child: child,
            ),
          );
        },

        // L'image actuelle
        child: Container(
          // La clé est INDISPENSABLE pour que Flutter sache que l'image a changé
          key: ValueKey<String>(widget.images[_currentIndex]),
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(widget.images[_currentIndex]),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}





class SlidingHeaderBackground extends StatefulWidget {
  final List<String> images;
  final double height;

  const SlidingHeaderBackground({
    super.key,
    required this.images,
    required this.height,
  });

  @override
  State<SlidingHeaderBackground> createState() => _SlidingHeaderBackgroundState();
}

class _SlidingHeaderBackgroundState extends State<SlidingHeaderBackground> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // On commence à une page élevée pour permettre le scroll infini vers la gauche si besoin
    _pageController = PageController(initialPage: 1000);
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (mounted) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800), // Vitesse du glissement
          curve: Curves.fastOutSlowIn, // Effet de freinage naturel
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: PageView.builder(
        controller: _pageController,
        // On met un grand nombre pour simuler l'infini
        itemCount: 100000,
        physics: const NeverScrollableScrollPhysics(), // Empêche l'utilisateur de slider manuellement (optionnel)
        itemBuilder: (context, index) {
          // L'opérateur modulo % permet de boucler sur ta liste de 3 images indéfiniment
          final int actualIndex = index % widget.images.length;
          return Image.asset(
            widget.images[actualIndex],
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}