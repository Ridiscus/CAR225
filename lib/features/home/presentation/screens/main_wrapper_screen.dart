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
  final Color _navBarGreen = const Color(0xFFE34001);

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



/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Tes imports d'écrans...
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

  // --- COULEURS CONFIGURÉES ---
  // La couleur du bouton actif (Orange selon ton code hex FF7900)
  final Color _activeColor = const Color(0xFFFF7900);
  // La couleur des icônes inactives (Vert foncé, comme demandé)
  final Color _inactiveColor = const Color(0xFF005C35);

  late PageController _pageController;

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
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    // Glissement fluide de la page
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart, // Courbe très fluide pour le slide de page
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          height: 65,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(35), // Encore plus arrondi
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildFloatingItem(0, "assets/icons/home.png", isDark),
              _buildFloatingItem(1, "assets/icons/ticket.png", isDark),
              _buildFloatingItem(2, "assets/icons/buss.png", isDark),
              _buildFloatingItem(3, "assets/icons/warning.png", isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingItem(int index, String iconPath, bool isDark) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: AnimatedContainer(
        // Animation du conteneur (la pilule orange)
        duration: const Duration(milliseconds: 400),
        // easeOutBack donne un effet de "pop" ou de glissement élastique
        curve: Curves.easeOutBack,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 22, vertical: 12)
            : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        // TweenAnimationBuilder permet d'animer la couleur de l'image PNG !
        child: TweenAnimationBuilder<Color?>(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          // Si sélectionné : Blanc. Sinon : Vert (ou blanc foncé en mode sombre)
          tween: ColorTween(
            begin: isSelected ? Colors.white : (isDark ? Colors.white54 : _inactiveColor),
            end: isSelected ? Colors.white : (isDark ? Colors.white54 : _inactiveColor),
          ),
          builder: (context, color, child) {
            return Image.asset(
              iconPath,
              width: 24,
              height: 24,
              color: color, // La couleur animée s'applique ici
              fit: BoxFit.contain,
            );
          },
        ),
      ),
    );
  }
}*/


/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Tes imports d'écrans...
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

  // --- COULEURS ---
  final Color _activeColor = const Color(0xFFFF7900); // Ton Orange
  final Color _inactiveColor = const Color(0xFF005C35); // Ton Vert

  late PageController _pageController;

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
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          height: 85, // On garde une bonne hauteur
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(35),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVerticalItem(0, "Accueil", "assets/icons/home.png", isDark),
              _buildVerticalItem(1, "Billets", "assets/icons/ticket.png", isDark),
              _buildVerticalItem(2, "Bus", "assets/icons/buss.png", isDark),
              _buildVerticalItem(3, "Alertes", "assets/icons/warning.png", isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalItem(int index, String label, String iconPath, bool isDark) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        // Le conteneur global est transparent, il sert juste à définir la zone cliquable
        color: Colors.transparent,
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // C'EST ICI QUE TOUT SE JOUE : LE CERCLE ANIMÉ
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack, // Petit effet de rebond
              padding: const EdgeInsets.all(10), // Espace entre l'icône et le bord du cercle
              decoration: BoxDecoration(
                // ✅ LE FOND : Forme CERCLE parfait
                // Couleur : Orange transparent (0.15) si actif, sinon transparent
                color: isSelected
                    ? _activeColor.withOpacity(0.15)
                    : Colors.transparent,
                shape: BoxShape.circle, // Force la forme ronde
              ),
              child: TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 300),
                tween: ColorTween(
                  begin: isSelected ? _activeColor : (isDark ? Colors.white54 : _inactiveColor),
                  end: isSelected ? _activeColor : (isDark ? Colors.white54 : _inactiveColor),
                ),
                builder: (context, color, child) {
                  return Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: color,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),

            const SizedBox(height: 4), // Espace sous le cercle

            // LE TEXTE EN DESSOUS
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _activeColor : (isDark ? Colors.white54 : _inactiveColor),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/



/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Tes imports d'écrans...
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

  // --- COULEURS ---
  final Color _activeColor = const Color(0xFFFFFFFF); // Ton Orange
  final Color _inactiveColor = const Color(0xFF005C35); // Ton Vert

  late PageController _pageController;

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
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),

      bottomNavigationBar: SafeArea(
        child: Container(
          height: 85,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          padding: const EdgeInsets.symmetric(horizontal: 10),

          // ✅ AJOUT 1 : Ceci coupe l'image pour qu'elle respecte les bords arrondis
          clipBehavior: Clip.hardEdge,

          decoration: BoxDecoration(
            // On garde la couleur en "fond de secours" si l'image ne charge pas
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(35),

            // ✅ AJOUT 2 : L'image de fond
            image: DecorationImage(
              // Remplace par ton chemin d'image (ex: une texture bois, un dégradé, un motif...)
              image: const AssetImage("assets/images/row.jpg"),
              fit: BoxFit.cover, // L'image remplit tout le conteneur
              // Optionnel : Assombrir un peu l'image pour que le texte reste lisible
              colorFilter: isDark
                  ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)
                  : null,
            ),

            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 25,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildVerticalItem(0, "Accueil", "assets/icons/home.png", isDark),
              _buildVerticalItem(1, "Billets", "assets/icons/ticket.png", isDark),
              _buildVerticalItem(2, "Bus", "assets/icons/buss.png", isDark),
              _buildVerticalItem(3, "Alertes", "assets/icons/warning.png", isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalItem(int index, String label, String iconPath, bool isDark) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: Colors.transparent,
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                // ✅ NOTE : Si ton image de fond est sombre ou complexe,
                // tu voudras peut-être augmenter l'opacité ici (ex: 0.3 ou 0.8)
                // pour que le cercle se voie bien par dessus l'image.
                color: isSelected
                    ? _activeColor.withOpacity(0.2) // J'ai mis 0.2 pour plus de contraste
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 300),
                tween: ColorTween(
                  // Attention aux contrastes avec ton image de fond !
                  // Si l'image est foncée, force le blanc pour les icônes inactives
                  begin: isSelected ? _activeColor : Colors.white,
                  end: isSelected ? _activeColor : Colors.white,
                ),
                builder: (context, color, child) {
                  return Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: color,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                // Même chose ici, attention à la lisibilité sur l'image
                color: isSelected ? _activeColor : Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/



/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Tes imports d'écrans...
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

// ✅ 1. Ajout du Mixin "SingleTickerProviderStateMixin"
class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  final Color _activeColor = const Color(0xFFFFFFFF);
  final Color _inactiveColor = const Color(0xFF005C35);

  late PageController _pageController;

  // ✅ 2. Déclaration des variables d'animation
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;


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
    _pageController = PageController(initialPage: widget.initialIndex);

    // ✅ 3. Initialisation de l'animation d'entrée
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1200), // Durée un peu plus longue pour la fluidité
      vsync: this,
    );

    // Configuration du mouvement
    // Offset(0, 1) = Vient du BAS (hors écran) vers sa place
    // Offset(-1, 0) = Vient de la GAUCHE
    // Offset(1, 0) = Vient de la DROITE
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0), // Commence 2x sa hauteur plus bas (caché)
      end: Offset.zero,            // Arrive à sa position normale (0,0)
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart, // Courbe fluide et élégante (effet freinage à la fin)
    ));

    // ✅ 4. Lancer l'animation (avec un petit délai pour laisser l'UI se dessiner)
    Future.delayed(const Duration(milliseconds: 100), () {
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose(); // ✅ Bien dispose le controller
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),

      // ✅ 5. On enveloppe le tout dans SlideTransition
      bottomNavigationBar: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Container(
            height: 85,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            clipBehavior: Clip.hardEdge,

            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(35),
              image: DecorationImage(
                image: const AssetImage("assets/images/row.jpg"),
                fit: BoxFit.cover,
                colorFilter: isDark
                    ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)
                    : null,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildVerticalItem(0, "Accueil", "assets/icons/home.png", isDark),
                _buildVerticalItem(1, "Billets", "assets/icons/ticket.png", isDark),
                _buildVerticalItem(2, "Bus", "assets/icons/buss.png", isDark),
                _buildVerticalItem(3, "Alertes", "assets/icons/warning.png", isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVerticalItem(int index, String label, String iconPath, bool isDark) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: Colors.transparent,
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? _activeColor.withOpacity(0.2)
                    : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: TweenAnimationBuilder<Color?>(
                duration: const Duration(milliseconds: 300),
                tween: ColorTween(
                  begin: isSelected ? _activeColor : Colors.white,
                  end: isSelected ? _activeColor : Colors.white,
                ),
                builder: (context, color, child) {
                  return Image.asset(
                    iconPath,
                    width: 24,
                    height: 24,
                    color: color,
                    fit: BoxFit.contain,
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            Text(
              label,
              style: TextStyle(
                color: isSelected ? _activeColor : Colors.white,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/




/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Tes imports d'écrans...
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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // COULEURS MODIFIÉES POUR LE CONTRASTE
  // Quand actif : Le fond de l'icône devient BLANC, l'icône devient VERTE (ou noire)
  final Color _activeIconColor = const Color(0xFF005C35); // Vert foncé (pour l'icône active)
  final Color _activeBgColor = Colors.white;              // Fond blanc (pour l'icône active)
  final Color _inactiveColor = Colors.white70;            // Blanc transparent (pour les inactifs)

  late PageController _pageController;
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;

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
    _pageController = PageController(initialPage: widget.initialIndex);

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 2.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    ));

    Future.delayed(const Duration(milliseconds: 100), () {
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),

      bottomNavigationBar: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Container(
            height: 85, // Hauteur un peu plus grande pour l'effet de flottement
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(35),
              image: DecorationImage(
                image: const AssetImage("assets/images/row.jpg"),
                fit: BoxFit.cover,
                colorFilter: isDark
                    ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)
                    : null,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 25, offset: const Offset(0, 10)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildVerticalItem(0, "Accueil", "assets/icons/home.png", isDark),
                _buildVerticalItem(1, "Billets", "assets/icons/ticket.png", isDark),
                _buildVerticalItem(2, "Bus", "assets/icons/buss.png", isDark),
                _buildVerticalItem(3, "Alertes", "assets/icons/warning.png", isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- C'EST ICI QUE LA MAGIE OPÈRE ---
  Widget _buildVerticalItem(int index, String label, String iconPath, bool isDark) {
    bool isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        color: Colors.transparent, // Zone de clic
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. L'ANIMATION DE L'ICÔNE ET DU CERCLE
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              curve: Curves.elasticOut, // L'effet "BOING" (Rebond)

              // Quand sélectionné, on le remonte de 8 pixels (margin bottom)
              // et on agrandit la taille (padding)
              margin: EdgeInsets.only(bottom: isSelected ? 8 : 0),
              padding: EdgeInsets.all(isSelected ? 12 : 8),

              decoration: BoxDecoration(
                // Fond Blanc quand actif, Transparent quand inactif
                color: isSelected ? _activeBgColor : Colors.transparent,
                shape: BoxShape.circle, // Ou BorderRadius.circular(15) pour un carré arrondi
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  )
                ]
                    : [],
              ),
              child: Image.asset(
                iconPath,
                width: 24,
                height: 24,
                // Si sélectionné : couleur du thème (vert). Sinon : Blanc.
                color: isSelected ? _activeIconColor : _inactiveColor,
                fit: BoxFit.contain,
              ),
            ),

            // 2. LE TEXTE QUI APPARAÎT/DISPARAÎT
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isSelected ? 16 : 0, // Cache le texte si non sélectionné (Optionnel, ou laisse le visible)
              child: isSelected
                  ? Text(
                label,
                style: TextStyle(
                  color: Colors.white, // Texte toujours blanc sur ton fond image
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              )
                  : const SizedBox(), // Vide si non sélectionné pour un look plus épuré
            ),
          ],
        ),
      ),
    );
  }
}*/



/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Tes imports d'écrans...
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

class _MainScreenState extends State<MainScreen> with SingleTickerProviderStateMixin {
  int _currentIndex = 0;

  // --- COULEURS ---
  // Vert Car225
  final Color _brandColor = const Color(0xFF005C35);

  late PageController _pageController;
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;

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
    _pageController = PageController(initialPage: widget.initialIndex);

    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(15, -55),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    ));

    Future.delayed(const Duration(milliseconds: 300), () {
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),

      /*bottomNavigationBar: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          child: Container(
            height: 100, // On augmente un peu la hauteur pour laisser la place au rebond
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            padding: const EdgeInsets.symmetric(horizontal: 15), // Un peu plus d'espace sur les côtés

            // ⚠️ NOTE IMPORTANTE : Si on veut que l'icône "sorte" vraiment du cadre,
            // il faudrait enlever le clipBehavior, mais ici on le garde pour l'arrondi de l'image de fond.
            clipBehavior: Clip.hardEdge,

            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(35),
              image: DecorationImage(
                image: const AssetImage("assets/images/yé1.jpg"),
                fit: BoxFit.cover,
                colorFilter: isDark
                    ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)
                    : null,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 30, offset: const Offset(0, 15)),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // On appelle juste la fonction, le Expanded est DEDANS maintenant
                _buildImpactItem(0, "Accueil", "assets/icons/home.png", isDark),
                _buildImpactItem(1, "Billets", "assets/icons/ticket.png", isDark),
                _buildImpactItem(2, "Bus", "assets/icons/buss.png", isDark),
                _buildImpactItem(3, "Alertes", "assets/icons/warning.png", isDark),
              ],
            ),
          ),
        ),
      ),*/

      bottomNavigationBar: SlideTransition(
        position: _slideAnimation,
        child: SafeArea(
          // On change le Container par un SizedBox transparent qui donne de la hauteur
          // C'est l'espace de "vol" pour tes icônes
          child: SizedBox(
            height: 120, // Hauteur totale (Barre + Espace de saut)
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [

                // COUCHE 1 : LE FOND VISUEL (L'image et les ombres)
                // On le positionne en bas, avec une hauteur fixe (ex: 90)
                Positioned(
                  bottom: 0,
                  left: 20,
                  right: 20,
                  height: 90, // La hauteur réelle de ta barre visible
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(35),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15)
                        ),
                      ],
                    ),
                    // On utilise ClipRRect ICI pour couper l'image proprement
                    // sans couper les icônes qui seront au-dessus
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          image: DecorationImage(
                            image: const AssetImage("assets/images/yé1.jpg"),
                            fit: BoxFit.cover,
                            colorFilter: isDark
                                ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // COUCHE 2 : LES ICÔNES (Les acrobates)
                // Elles prennent toute la hauteur (120) donc elles ont de la place pour sauter
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35), // Marges pour aligner avec le fond
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end, // On aligne en bas
                      children: [
                        _buildImpactItem(0, "Accueil", "assets/icons/home.png", isDark),
                        _buildImpactItem(1, "Billets", "assets/icons/ticket.png", isDark),
                        _buildImpactItem(2, "Bus", "assets/icons/buss.png", isDark),
                        _buildImpactItem(3, "Alertes", "assets/icons/warning.png", isDark),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),


    );
  }




  Widget _buildImpactItem(int index, String label, String iconPath, bool isDark) {
    bool isSelected = _currentIndex == index;

    // 1. On utilise Expanded ici pour être sûr que ça prend la largeur disponible (1/4 de l'écran)
    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          // 2. HAUTEUR FIXE : On impose une hauteur stricte (ex: 70).
          // C'est ça qui TUE l'erreur d'overflow définitivement.
          height: 70,
          child: Stack(
            clipBehavior: Clip.none, // Permet à l'élément de sortir un peu du cadre si besoin
            alignment: Alignment.center,
            children: [

              // COUCHE 1 : LE TEXTE (En bas)
              // Il reste sagement en bas et disparaît si sélectionné
              Positioned(
                bottom: 10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 0.0 : 1.0,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))
                      ],
                    ),
                  ),
                ),
              ),

              // COUCHE 2 : LE CERCLE + ICÔNE (Au dessus)
              // Au lieu de changer la layout, on change juste sa position "top"
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                // Si sélectionné, il monte vers le haut (-15), sinon il est centré (top: 10 environ)
                top: isSelected ? -20 : 8,

                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 50 : 24,
                  height: isSelected ? 50 : 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: const Color(0xFF005C35).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                      const BoxShadow(
                        color: Colors.white,
                        blurRadius: 0,
                        spreadRadius: 2,
                      ),
                    ]
                        : [],
                  ),
                  child: Center(
                    child: Image.asset(
                      iconPath,
                      width: isSelected ? 26 : 24,
                      height: isSelected ? 26 : 24,
                      color: isSelected ? const Color(0xFFE34001) : Colors.white.withOpacity(0.9),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),

              // COUCHE 3 : LE POINT (Tout en bas, apparaît si sélectionné)
              Positioned(
                bottom: 8,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5)
                        ]
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


}*/









/*import 'dart:async'; // 🟢 NOUVEAU : Nécessaire pour le Timer
import 'package:flutter/material.dart';

// Tes imports d'écrans...
// Assure-toi que ces fichiers existent ou remplace par des Container() pour tester
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

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final Color _brandColor = const Color(0xFF005C35);

  late PageController _pageController;

  // Animation d'entrée (glissement initial)
  late AnimationController _entranceController;
  late Animation<Offset> _slideAnimation;

  // 🟢 NOUVEAU : Contrôleur pour le Pliage/Dépliage
  late AnimationController _foldController;
  late Animation<double> _foldAnimation;
  late Animation<double> _scaleTriangleAnimation;

  // 🟢 NOUVEAU : Timer pour l'auto-hide
  Timer? _hideTimer;
  bool _isMenuOpen = true; // Pour savoir si on est plié ou déplié

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
    _pageController = PageController(initialPage: widget.initialIndex);

    // 1. Animation d'entrée (Slide du bas vers le haut au lancement)
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(15, -55), // Commence plus bas
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutQuart,
    ));

    // 🟢 2. Animation de Pliage (Barre <-> Triangle)
    _foldController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
      value: 1.0, // On commence déplié (valeur 1.0)
    );

    // Animation de la barre (disparait quand on plie)
    _foldAnimation = CurvedAnimation(
      parent: _foldController,
      curve: Curves.easeInOutBack,
    );

    // Animation du triangle (apparait quand on plie)
    // Inverse de l'autre : quand controller = 0 (plié), triangle scale = 1
    _scaleTriangleAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _foldController, curve: Curves.elasticOut),
    );

    // Lancement
    Future.delayed(const Duration(milliseconds: 300), () {
      _entranceController.forward();
      _startHideTimer(); // On lance le chrono dès le début
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _entranceController.dispose();
    _foldController.dispose();
    _hideTimer?.cancel(); // 🟢 Important : couper le timer
    super.dispose();
  }

  // 🟢 NOUVEAU : Gestion du Timer
  void _startHideTimer() {
    _hideTimer?.cancel(); // Annule le précédent s'il existe
    _hideTimer = Timer(const Duration(seconds: 5), () {
      if (mounted && _isMenuOpen) {
        _foldMenu();
      }
    });
  }

  void _foldMenu() {
    setState(() {
      _isMenuOpen = false;
    });
    _foldController.reverse(); // Va vers 0.0 (Mode Triangle)
  }

  void _unfoldMenu() {
    setState(() {
      _isMenuOpen = true;
    });
    _foldController.forward(); // Va vers 1.0 (Mode Barre)
    _startHideTimer(); // Relance le timer
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutQuart,
    );

    // 🟢 Quand on clique, on relance le timer de 5s
    _startHideTimer();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      backgroundColor: isDark ? Colors.black : Colors.grey[100],

      // 🟢 GestureDetector global sur le body pour réinitialiser le timer si l'utilisateur scroll ou touche l'écran ?
      // Optionnel : si tu veux que le menu reste ouvert tant qu'on touche l'app, décommente le GestureDetector ci-dessous.
      // Pour l'instant, je le laisse réagir uniquement aux clics sur la barre.
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
        onPageChanged: (index) => setState(() => _currentIndex = index),
      ),

      bottomNavigationBar: SlideTransition(
        position: _slideAnimation,
        // 🔴 ON REMPLACE SafeArea PAR Padding
        // Cela permet de soulever tout le bloc (SizedBox 120) de la hauteur de la barre système
        child: Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewPadding.bottom),
          child: SizedBox(
            height: 120, // Espace total
            child: Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [

                // 🟢 1. LE TRIANGLE (Visible quand _isMenuOpen = false)
                Positioned(
                  // J'ai augmenté un peu le bottom (passé de 10 à 20) pour qu'il ne colle pas trop
                  // si la barre système est très fine (navigation par gestes)
                  bottom: 15,
                  child: ScaleTransition(
                    scale: _scaleTriangleAnimation,
                    child: GestureDetector(
                      onTap: _unfoldMenu,
                      child: Container(
                        width: 60,
                        height: 50,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 5)
                            )
                          ],
                        ),
                        child: ClipPath(
                          clipper: TriangleClipper(),
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              image: const DecorationImage(
                                image: AssetImage("assets/images/yé1.jpg"),
                                fit: BoxFit.cover,
                              ),
                              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                            ),
                            child: Stack(
                              children: [
                                if (isDark)
                                  Container(color: Colors.black.withOpacity(0.6)),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: const [
                                      SizedBox(height: 10),
                                      Icon(Icons.keyboard_arrow_up_rounded, color: Colors.white, size: 30),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // 🟢 2. LA BARRE DE NAVIGATION (Visible quand _isMenuOpen = true)
                FadeTransition(
                  opacity: _foldAnimation,
                  child: ScaleTransition(
                    scale: _foldAnimation,
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      height: 120, // Container global
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        clipBehavior: Clip.none,
                        children: [
                          // --- FOND ---
                          Positioned(
                            bottom: 0,
                            left: 20,
                            right: 20,
                            height: 90,
                            child: GestureDetector(
                              onTap: _startHideTimer,
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(35),
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15)
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(35),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                      image: DecorationImage(
                                        image: const AssetImage("assets/images/yé1.jpg"),
                                        fit: BoxFit.cover,
                                        colorFilter: isDark
                                            ? ColorFilter.mode(Colors.black.withOpacity(0.6), BlendMode.darken)
                                            : null,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          // --- ICÔNES ---
                          Positioned.fill(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 35),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  _buildImpactItem(0, "Accueil", "assets/icons/home.png", isDark),
                                  _buildImpactItem(1, "Billets", "assets/icons/ticket.png", isDark),
                                  _buildImpactItem(2, "Bus", "assets/icons/buss.png", isDark),
                                  _buildImpactItem(3, "Alertes", "assets/icons/warning.png", isDark),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),



    );
  }

  Widget _buildImpactItem(int index, String label, String iconPath, bool isDark) {
    bool isSelected = _currentIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _onItemTapped(index),
        behavior: HitTestBehavior.translucent,
        child: SizedBox(
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // TEXTE
              Positioned(
                bottom: 10,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isSelected ? 0.0 : 1.0,
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      shadows: [
                        Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(0, 1))
                      ],
                    ),
                  ),
                ),
              ),
              // CERCLE + ICÔNE
              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutBack,
                top: isSelected ? -20 : 8,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isSelected ? 50 : 24,
                  height: isSelected ? 50 : 24,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.white : Colors.transparent,
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                      BoxShadow(
                        color: const Color(0xFF005C35).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ]
                        : [],
                  ),
                  child: Center(
                    child: Image.asset(
                      iconPath,
                      width: isSelected ? 26 : 24,
                      height: isSelected ? 26 : 24,
                      color: isSelected ? const Color(0xFFE34001) : Colors.white.withOpacity(0.9),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              // POINT
              Positioned(
                bottom: 8,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 400),
                  opacity: isSelected ? 1.0 : 0.0,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.white.withOpacity(0.5), blurRadius: 5)
                        ]
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 🟢 NOUVEAU : La classe pour dessiner le triangle
class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // On dessine un triangle arrondi vers le haut
    path.moveTo(0, size.height); // Coin bas gauche
    path.lineTo(size.width, size.height); // Coin bas droite
    path.lineTo(size.width / 2, 0); // Pointe haut milieu
    path.close();

    // Si tu veux un triangle plus doux (arrondi), le code est plus complexe,
    // mais celui-ci fait un triangle parfait.
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}*/