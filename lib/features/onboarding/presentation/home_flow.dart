import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

// Tes imports (Assure-toi que AppColors.primary est une couleur qui passe bien sur le noir, comme un vert ou bleu vif)
import '../../../../core/theme/app_colors.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../booking/presentation/screens/search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables
  String depart = "Abidjan";
  String destination = "Bouaké";
  bool isAllerRetour = false;


    @override
    Widget build(BuildContext context) {
      // -----------------------------------------------------------
      // 🌗 LOGIQUE DARK MODE / LIGHT MODE
      // -----------------------------------------------------------
      final isDark = Theme.of(context).brightness == Brightness.dark;

      // Couleurs dynamiques
      final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

      final mainTextColor = isDark ? Colors.white : Colors.black;

      // CORRECTION ICI : Ajout du '!' après [400]
      final subTextColor = isDark ? Colors.grey[400]! : AppColors.grey;

      // CORRECTION ICI : Ajout du '!' après [700]
      final borderColor = isDark ? Colors.grey[700]! : Colors.grey.shade300;

      // CORRECTION ICI : Ajout du '!' après [800]
      final circleBtnColor = isDark ? Colors.grey[800]! : Colors.white;
      // -----------------------------------------------------------


    return Scaffold(
      // MODIFICATION : On utilise la couleur du thème (défini dans ton main.dart)
      // Si ton main.dart est bien configuré, ça sera noir/gris foncé auto.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. LE HEADER (IMAGE + BOUTONS) ---
            Stack(
              children: [
                // Image de fond
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black, // Le fond derrière l'image reste noir, c'est mieux pour l'image
                    image: DecorationImage(
                      image: AssetImage("assets/images/bus_header.jpg"),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    ),
                  ),
                ),
                // Boutons du haut
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // PROFIL -> Login
                        _buildCircleBtn(
                            "assets/images/user.png",
                                () => _goToLogin(context),
                            circleBtnColor // On passe la couleur dynamique
                        ),

                        // TICKET -> SearchResultsScreen
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchResultsScreen(
                                  isGuestMode: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 40, width: 40,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: circleBtnColor, // Couleur dynamique
                                shape: BoxShape.circle
                            ),
                            child: Image.asset(
                              "assets/images/paper.png",
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- 2. LA CARTE DE RECHERCHE ---
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor, // <--- APPLICATION DE LA COULEUR DYNAMIQUE
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), // Ombre plus forte en dark pour le contraste
                          blurRadius: 10,
                          offset: const Offset(0, 5)
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Où souhaitez-vous voyager ?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainTextColor)), // Couleur texte dynamique

                      Text("Réservez votre billet en quelques clics",
                          style: TextStyle(color: subTextColor, fontSize: 12)), // Couleur sous-titre dynamique

                      const Gap(20),

                      // Champs Départ / Arrivée
                      Row(
                        children: [
                          Expanded(
                              child: _buildInputBox(
                                  "assets/images/map.png", "Départ", "Abidjan",
                                  mainTextColor, subTextColor, borderColor) // On passe les couleurs
                          ),
                          const Gap(10),
                          Expanded(
                              child: _buildInputBox(
                                  "assets/images/map.png", "Arrivée", "Yamoussoukro",
                                  mainTextColor, subTextColor, borderColor, isGreen: true)
                          ),
                        ],
                      ),
                      const Gap(15),

                      // Date + Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildInputBox(
                                "assets/images/agenda.png", "Date départ", "Ven. 30 Jan",
                                mainTextColor, subTextColor, borderColor),
                          ),

                          const Gap(10),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isAllerRetour,
                                activeColor: AppColors.primary,
                                // En dark mode, le checkColor (la coche) est blanc par défaut, c'est ok.
                                side: BorderSide(color: isDark ? Colors.grey : Colors.black54), // Bordure checkbox visible en dark
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onChanged: (bool? value) {
                                  setState(() {
                                    isAllerRetour = value ?? false;
                                  });
                                },
                              ),
                              const Gap(4),
                              Text("Aller-retour",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mainTextColor)),
                            ],
                          ),
                        ],
                      ),

                      const Gap(20),

                      // BOUTON RECHERCHER
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchResultsScreen(
                                  isGuestMode: true,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Rechercher des trajets", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // --- 3. BANNIÈRE PRÊT À RÉSERVER ---
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // En dark mode, 0xFF37474F est déjà sombre, mais on peut le garder
                  // ou le rendre un tout petit peu plus clair que le fond noir pour ressortir.
                  // Ici je le garde tel quel car c'est une couleur "Identité" gris/bleuté qui marche sur le noir.
                  color: const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(15),
                  border: isDark ? Border.all(color: Colors.grey[800]!) : null, // Petite bordure subtile en dark mode
                ),
                child: Column(
                  children: [
                    const Text("Prêt à réserver ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("Trouvez votre voyage parfait.", style: TextStyle(color: Colors.white70)), // AppColors.grey risque d'être trop sombre ici
                    const Gap(15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _goToLogin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                        ),
                        child: const Text("Réserver maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const Gap(20),
          ],
        ),
      ),
    );
  }

  // Helper : Bouton Rond Header (Modifié pour accepter la couleur)
  Widget _buildCircleBtn(String imagePath, VoidCallback onTap, Color bgColor) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        height: 40, width: 40,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Image.asset(
          imagePath,
          color: AppColors.primary,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Helper : Champ de saisie (Modifié pour accepter les couleurs dynamiques)
  Widget _buildInputBox(
      String imagePath,
      String label,
      String value,
      Color textColor,
      Color labelColor,
      Color borderColor,
      {bool isGreen = false}) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor), // Bordure dynamique
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 20,
            height: 20,
            color: isGreen ? AppColors.secondary : AppColors.primary,
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: labelColor)), // Label dynamique
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)), // Valeur dynamique
            ],
          )
        ],
      ),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
}



