/*import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../../core/theme/app_colors.dart';

// Import des écrans
import 'home_tab_screen.dart';
import 'my_tickets_tab_screen.dart';
import 'companies_tab_screen.dart';
import 'alerts_tab_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;

  // Le constructeur accepte l'index initial (0 par défaut)
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Une seule variable pour gérer l'index
  int _currentIndex = 0;

  // Liste des écrans
  final List<Widget> _pages = [
    const HomeTabScreen(),      // Index 0: Accueil
    const MyTicketsTabScreen(), // Index 1: Billets
    const CompaniesTabScreen(), // Index 2: Compagnies
    const AlertsTabScreen(),    // Index 3: Alertes
  ];

  @override
  void initState() {
    super.initState();
    // Au démarrage, on applique l'index demandé (par exemple 0 quand on vient des alertes)
    _currentIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Affiche la page correspondante à l'index actuel
      body: _pages[_currentIndex],

      // Barre de navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5)
            )
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed, // Nécessaire car 4 éléments
          items: [
            _buildNavItem("assets/icons/home.png", "Accueil", 0),
            _buildNavItem("assets/icons/ticket.png", "Billets", 1),
            _buildNavItem("assets/icons/buss.png", "Compagnies", 2),
            _buildNavItem("assets/icons/warning.png", "Alertes", 3),
          ],
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(String iconPath, String label, int index) {
    return BottomNavigationBarItem(
      icon: Image.asset(
          iconPath,
          width: 24,
          // Change la couleur si l'onglet est actif
          color: _currentIndex == index ? AppColors.primary : Colors.grey
      ),
      label: label,
    );
  }
}*/

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Nécessaire pour contrôler la couleur de la barre système
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../../../core/theme/app_colors.dart';

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

  // Ta couleur
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
    // 1. On détecte le mode (Clair ou Sombre)
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // 2. On récupère la couleur de fond de l'app (Celle qui est derrière la courbe)
    // Si tu utilises Colors.grey[100] en dur dans le Scaffold, utilise-le ici aussi.
    // Sinon, utilise Theme.of(context).scaffoldBackgroundColor
    final backgroundColor = isDark ? Colors.black : Colors.grey[100]!;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        // --- LE SECRET EST ICI ---

        // Au lieu de transparent, on met la MEME couleur que le fond de l'écran.
        // Comme la CurvedNavBar flotte un peu, le bas doit être de la couleur du fond.
        systemNavigationBarColor: backgroundColor,

        // On inverse la couleur des icônes (Carré, Rond, Retour) selon le mode
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,

        // (Optionnel) Pour la barre de statut en haut (Heure, Batterie)
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
      child: Scaffold(
        extendBody: true,
        backgroundColor: backgroundColor, // On utilise la variable définie plus haut

        body: _pages[_currentIndex],

        bottomNavigationBar: SafeArea(
          top: false,
          // bottom: true est la valeur par défaut.
          // C'est ce qui empêche la barre verte de passer SOUS les boutons Android.
          // L'espace créé en bas sera rempli par la couleur définie dans systemNavigationBarColor.
          child: CurvedNavigationBar(
            index: _currentIndex,
            height: 70.0,
            color: _navBarGreen,
            buttonBackgroundColor: _navBarGreen,
            backgroundColor: Colors.transparent, // Transparence pour voir le fond derrière la courbe
            animationCurve: Curves.easeInOutCubic,
            animationDuration: const Duration(milliseconds: 500),
            items: <Widget>[
              _buildNavItem("assets/icons/home.png", 0),
              _buildNavItem("assets/icons/ticket.png", 1),
              _buildNavItem("assets/icons/buss.png", 2),
              _buildNavItem("assets/icons/warning.png", 3),
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




  // Ton widget personnalisé intact
  Widget _buildNavItem(String iconPath, int index) {
    final bool isSelected = _currentIndex == index;

    if (isSelected) {
      return Container(
        width: 45,
        height: 45,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        padding: const EdgeInsets.all(10),
        child: Image.asset(
          iconPath,
          color: _navBarGreen,
          fit: BoxFit.contain,
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image.asset(
          iconPath,
          width: 26,
          height: 26,
          color: Colors.white,
        ),
      );
    }
  }
}



/*import 'package:flutter/material.dart';
import 'dart:math' as math; // Nécessaire pour le calcul de la parabole (Pi)
import 'dart:ui';
// Import des écrans (garde tes imports actuels)
import 'home_tab_screen.dart';
import 'my_tickets_tab_screen.dart';
import 'companies_tab_screen.dart';
import 'alerts_tab_screen.dart';
import '../../../../core/theme/app_colors.dart';

class MainScreen extends StatefulWidget {
  final int initialIndex;
  const MainScreen({super.key, this.initialIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Index actuel
  int _currentIndex = 0;

  // Liste des écrans
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

  // Méthode pour changer d'onglet
  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Important pour que le ballon puisse "voler" au-dessus du contenu
      backgroundColor: Colors.grey[100],

      body: _pages[_currentIndex],

      // On appelle notre barre personnalisée
      bottomNavigationBar: JumpingTabBar(
        currentIndex: _currentIndex,
        onTabChanged: _onTabSelected,
        items: [
          JumpingTabItem(iconPath: "assets/icons/home.png", label: "Accueil"),
          JumpingTabItem(iconPath: "assets/icons/ticket.png", label: "Billets"),
          JumpingTabItem(iconPath: "assets/icons/buss.png", label: "Cies"),
          JumpingTabItem(iconPath: "assets/icons/warning.png", label: "Alertes"),
        ],
      ),
    );
  }
}

// --- CLASSE MODÈLE POUR LES ITEMS ---
class JumpingTabItem {
  final String iconPath;
  final String label;

  JumpingTabItem({required this.iconPath, required this.label});
}

// --- LA BARRE DE NAVIGATION "BALLON DE BASKET" ---
class JumpingTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final List<JumpingTabItem> items;

  const JumpingTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.items,
  });

  @override
  State<JumpingTabBar> createState() => _JumpingTabBarState();
}

class _JumpingTabBarState extends State<JumpingTabBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  // Pour gérer les positions
  int _previousIndex = 0;

  // COULEURS
  final Color _navBarGreen = const Color(0xFF005C35); // Ton vert spécifique
  final Color _ballColor = Colors.white; // Intérieur du ballon
  final double _barHeight = 70.0;
  final double _ballSize = 48.0;

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;

    // Animation rapide et fluide (400ms)
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void didUpdateWidget(JumpingTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si l'index change depuis le parent, on lance l'animation
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Largeur d'un seul onglet
    final double itemWidth = size.width / widget.items.length;

    return SizedBox(
      height: _barHeight + 30, // On ajoute de la marge en haut pour le saut (le vol)

      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // 1. LA BARRE VERTE (Le fond)
          Container(
            height: _barHeight,
            width: double.infinity,
            decoration: BoxDecoration(
              color: _navBarGreen,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, -5))
              ],
            ),
            // Les icônes statiques (inactives)
            child: Row(
              children: List.generate(widget.items.length, (index) {
                final isSelected = widget.currentIndex == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTabChanged(index),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      child: isSelected
                          ? const SizedBox() // Si c'est sélectionné, l'icône est dans le ballon, donc on cache celle de la barre
                          : Image.asset(
                        widget.items[index].iconPath,
                        width: 24,
                        height: 24,
                        color: Colors.white.withOpacity(0.8), // Icônes inactives en blanc un peu transparent
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 2. LE BALLON QUI SAUTE (AnimatedBuilder)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // --- CALCUL DE LA TRAJECTOIRE (MATHS) ---

              // 1. Position X (Horizontale) : Interpolation linéaire
              // On va de l'ancien index vers le nouveau
              final double startX = (_previousIndex * itemWidth) + (itemWidth / 2);
              final double endX = (widget.currentIndex * itemWidth) + (itemWidth / 2);
              // Lerp (Linear Interpolation) nous donne la position actuelle selon l'avancement (0.0 à 1.0)
              // On utilise lerpDouble au lieu de double.lerp
              final double currentX = lerpDouble(startX, endX, _controller.value) ?? startX;

              // 2. Position Y (Verticale) : Parabole
              // sin(pi * value) donne une cloche : commence à 0, monte à 1 (au milieu), redescend à 0
              // On multiplie par 50 pour sauter à 50 pixels de hauteur
              final double jumpHeight = 50.0;
              final double verticalOffset = jumpHeight * math.sin(_controller.value * math.pi);

              // Position de base (posé sur la barre)
              // On le place un peu plus haut que le fond pour qu'il "chevauche" la barre (effet encastré)
              final double baseBottom = _barHeight - (_ballSize / 2) - 10;

              // Position finale Y = Base + Saut
              final double currentBottom = baseBottom + verticalOffset;

              return Positioned(
                left: currentX - (_ballSize / 2), // On centre horizontalement
                bottom: currentBottom,
                child: Container(
                  width: _ballSize,
                  height: _ballSize,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _ballColor, // Fond BLANC
                    shape: BoxShape.circle,
                    // BORDURE VERTE (Contours)
                    border: Border.all(
                      color: _navBarGreen,
                      width: 2.0, // Épaisseur du contour
                    ),
                    boxShadow: [
                      // Petite ombre pour donner du volume au ballon
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),

                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Image.asset(
                    widget.items[widget.currentIndex].iconPath, // Affiche l'icône active
                    color: _navBarGreen, // L'icône est verte sur fond blanc
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}*/






/*import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui'; // Indispensable pour lerpDouble

// --- TES IMPORTS ---
import '../../../../core/theme/app_colors.dart';
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

  void _onTabSelected(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Le contenu passe derrière la barre
      backgroundColor: Colors.grey[100],

      body: _pages[_currentIndex],

      bottomNavigationBar: JumpingTabBar(
        currentIndex: _currentIndex,
        onTabChanged: _onTabSelected,
        items: [
          JumpingTabItem(iconPath: "assets/icons/home.png", label: "Accueil"),
          JumpingTabItem(iconPath: "assets/icons/ticket.png", label: "Billets"),
          JumpingTabItem(iconPath: "assets/icons/buss.png", label: "Cies"),
          JumpingTabItem(iconPath: "assets/icons/warning.png", label: "Alertes"),
        ],
      ),
    );
  }
}

// --- MODÈLE ---
class JumpingTabItem {
  final String iconPath;
  final String label;
  JumpingTabItem({required this.iconPath, required this.label});
}

// --- WIDGET PRINCIPAL DE LA BARRE ---
class JumpingTabBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTabChanged;
  final List<JumpingTabItem> items;

  const JumpingTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabChanged,
    required this.items,
  });

  @override
  State<JumpingTabBar> createState() => _JumpingTabBarState();
}

class _JumpingTabBarState extends State<JumpingTabBar> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _previousIndex = 0;

  // COULEURS & DIMENSIONS
  final Color _navBarGreen = const Color(0xFF005C35);
  final Color _ballBorderColor = const Color(0xFF005C35);
  final double _barHeight = 75.0; // Hauteur de la barre verte
  final double _ballSize = 55.0;  // Taille du ballon

  @override
  void initState() {
    super.initState();
    _previousIndex = widget.currentIndex;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500), // Vitesse du saut
    );
  }

  @override
  void didUpdateWidget(JumpingTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentIndex != oldWidget.currentIndex) {
      _previousIndex = oldWidget.currentIndex;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final double itemWidth = size.width / widget.items.length;

    return SizedBox(
      height: _barHeight + 40, // Marge pour le saut aérien
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [

          // 1. LE FOND VERT SCULPTÉ (AnimatedBuilder pour bouger le creux)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // Calculer la position X actuelle du creux (doit suivre le ballon)

              final double startX = (_previousIndex * itemWidth) + (itemWidth / 2);
              final double endX = (widget.currentIndex * itemWidth) + (itemWidth / 2);
              final double currentX = lerpDouble(startX, endX, _controller.value) ?? startX;

              return CustomPaint(
                size: Size(size.width, _barHeight),
                painter: NavBarCurvePainter(
                  backgroundColor: _navBarGreen,
                  xOffset: currentX, // Le creux se déplace ici
                ),
              );
            },
          ),

          // 2. LES ICÔNES NON SÉLECTIONNÉES (Sur la barre)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: _barHeight,
            child: Row(
              children: List.generate(widget.items.length, (index) {
                return Expanded(
                  child: GestureDetector(
                    onTap: () => widget.onTabChanged(index),
                    behavior: HitTestBehavior.opaque,
                    child: Center(
                      // Si c'est l'index courant ou précédent pendant l'anim, on cache l'icône du fond
                      // car elle est dans le ballon qui vole.
                      child: (index == widget.currentIndex)
                          ? const SizedBox()
                          : Image.asset(
                        widget.items[index].iconPath,
                        width: 24,
                        height: 24,
                        color: Colors.white, // Blanc transparent pour le fond
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),

          // 3. LE BALLON QUI SAUTE (AnimatedBuilder pour la parabole)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              // --- POSITION X (Horizontale) ---
              final double startX = (_previousIndex * itemWidth) + (itemWidth / 2);
              final double endX = (widget.currentIndex * itemWidth) + (itemWidth / 2);
              final double currentX = lerpDouble(startX, endX, _controller.value) ?? startX;

              // --- POSITION Y (Verticale - Parabole) ---
              // On utilise le Sinus pour faire monter et descendre
              final double jumpHeight = 45.0; // Hauteur du saut
              // sin(pi * value) : 0 -> 1 -> 0
              final double yOffset = jumpHeight * math.sin(_controller.value * math.pi);

              // Position au repos (dans le creux)
              // Le ballon est un peu enfoncé dans la barre (d'où le creux)
              final double restingY = _barHeight * 0.55;

              final double currentBottom = restingY + yOffset;

              return Positioned(
                left: currentX - (_ballSize / 2),
                bottom: currentBottom,
                child: Container(
                  width: _ballSize,
                  height: _ballSize,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white, // Intérieur BLANC
                    shape: BoxShape.circle,
                    // CONTOUR VERT
                    border: Border.all(
                      color: _ballBorderColor,
                      width: 2.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    widget.items[widget.currentIndex].iconPath,
                    color: _navBarGreen, // L'icône active est VERTE
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- LE PEINTRE QUI DESSINE LA BARRE VERTE AVEC LE CREUX ---
class NavBarCurvePainter extends CustomPainter {
  final Color backgroundColor;
  final double xOffset; // Position horizontale du centre du creux

  NavBarCurvePainter({required this.backgroundColor, required this.xOffset});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    Path path = Path();

    // On commence en haut à gauche
    path.moveTo(0, 0);

    // --- DESSIN DU CREUX (BÉZIER) ---
    // C'est ici que la magie opère pour créer la courbe douce

    double curveWidth = 70.0; // Largeur de l'ouverture
    double curveDepth = 35.0; // Profondeur du creux

    // Ligne jusqu'au début du creux
    path.lineTo(xOffset - curveWidth / 2 - 20, 0);

    // Première courbe (Descente douce)
    path.cubicTo(
      xOffset - curveWidth / 4, 0,            // Point de contrôle 1
      xOffset - curveWidth / 4, curveDepth,   // Point de contrôle 2
      xOffset, curveDepth,                    // Point d'arrivée (milieu bas)
    );

    // Seconde courbe (Remontée douce)
    path.cubicTo(
      xOffset + curveWidth / 4, curveDepth,   // Point de contrôle 1
      xOffset + curveWidth / 4, 0,            // Point de contrôle 2
      xOffset + curveWidth / 2 + 20, 0,       // Point d'arrivée (fin du creux)
    );

    // Fin de la ligne en haut à droite
    path.lineTo(size.width, 0);

    // Bas et fermeture
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    // Ajout d'une ombre légère sur la barre pour le relief
    canvas.drawShadow(path, Colors.black.withOpacity(0.1), 4.0, true);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(NavBarCurvePainter oldDelegate) {
    return oldDelegate.xOffset != xOffset; // Redessiner si le creux bouge
  }
}*/