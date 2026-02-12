import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
// import '../../../../core/theme/app_colors.dart'; // Décommente si besoin

// Import des écrans
import 'home_tab_screen.dart';
import 'my_tickets_tab_screen.dart';
import 'companies_tab_screen.dart';
import 'alerts_tab_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  // Ta couleur de marque (Utilisée maintenant pour le bouton actif et les accents)
  final Color _navBarGreen = const Color(0xFF005C35);

  final List<Widget> _pages = [
    const HomeTabScreen(),
    const MyTicketsTabScreen(),
    const CompaniesTabScreen(),
    const AlertsTabScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }
  @override
  Widget build(BuildContext context) {
    // 1. Détection du thème
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. Couleurs
    final Color navBarBackgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    // Cette couleur doit être EXACTEMENT la même que celle du Scaffold
    final Color scaffoldBackgroundColor = isDark ? Colors.black : Colors.grey[100]!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // Force la barre système à être opaque et de la même couleur que ta navbar
        systemNavigationBarColor: navBarBackgroundColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        // ❌ CHANGE ICI : On passe à false pour arrêter le scroll derrière la barre
        extendBody: false,

        backgroundColor: scaffoldBackgroundColor,

        body: _pages[_currentIndex],

        bottomNavigationBar: SafeArea(
          top: false,
          child: CurvedNavigationBar(
            index: _currentIndex,
            height: 70.0,

            // La couleur de la barre elle-même
            color: navBarBackgroundColor,

            buttonBackgroundColor: _navBarGreen,

            // ✅ CHANGE ICI : Au lieu de transparent, on met la couleur du fond de l'écran.
            // Cela donne l'illusion que la courbe est transparente,
            // mais empêche le contenu de passer derrière.
            backgroundColor: scaffoldBackgroundColor,

            animationCurve: Curves.easeInOutCubic,
            animationDuration: const Duration(milliseconds: 500),

            items: <Widget>[
              _buildNavItem("assets/icons/home.png", 0, isDark),
              _buildNavItem("assets/icons/ticket.png", 1, isDark),
              _buildNavItem("assets/icons/buss.png", 2, isDark),
              _buildNavItem("assets/icons/warning.png", 3, isDark),
            ],
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
          ),
        ),
      ),
    );
  }

  // ✅ WIDGET ADAPTÉ : Couleurs inversées pour fond blanc
  Widget _buildNavItem(String iconPath, int index, bool isDark) {
    final bool isSelected = _currentIndex == index;

    if (isSelected) {
      // CAS SÉLECTIONNÉ (Bouton flottant)
      // Le bouton est vert (_navBarGreen défini dans buttonBackgroundColor),
      // donc l'icône doit être Blanche.
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          iconPath,
          width: 30, // Légèrement plus grand quand sélectionné
          height: 30,
          color: Colors.white, // Blanc sur fond Vert
          fit: BoxFit.contain,
        ),
      );
    } else {
      // CAS NON SÉLECTIONNÉ (Sur la barre blanche)
      // L'icône doit être Grise (ou blanche tamisée en dark mode)
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          iconPath,
          width: 26,
          height: 26,
          // Gris pour être visible sur le blanc
          color: isDark ? Colors.white54 : Colors.grey,
        ),
      );
    }
  }
}