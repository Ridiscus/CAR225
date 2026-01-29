import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScrollingSubtitle extends StatefulWidget {
  final List<String> texts;
  const ScrollingSubtitle({super.key, required this.texts});

  @override
  State<ScrollingSubtitle> createState() => _ScrollingSubtitleState();
}

class _ScrollingSubtitleState extends State<ScrollingSubtitle> {
  int _currentIndex = 0;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Change le texte toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.texts.length;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Très important pour éviter les fuites de mémoire
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      // Animation : glissement du bas vers le haut + fondu
      transitionBuilder: (Widget child, Animation<double> animation) {
        final offsetAnimation = Tween<Offset>(
          begin: const Offset(0.0, 1.0), // Arrive du bas
          end: Offset.zero,
        ).animate(animation);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
      child: Text(
        widget.texts[_currentIndex],
        // La clé est cruciale pour que Flutter sache que le texte a changé
        key: ValueKey<String>(widget.texts[_currentIndex]),
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
    );
  }
}