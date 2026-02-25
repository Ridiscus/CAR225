import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  // -1 signifie qu'aucun n'est sélectionné au départ (tous grisés).
  int _selectedOperator = -1;

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(
      context,
    ).cardColor; // Blanc (Light) ou Gris Foncé (Dark)

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
          "RECHARGER",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LABEL
            Text(
              "MONTANT A AJOUTER",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.blueGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(10),

            // --- 1. ZONE ORANGE (Sélecteur Montant) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(
                  0xFFE64A19,
                ), // Reste orange même en dark mode
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE64A19).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Compteur
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "5000",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Gap(15),
                      Column(
                        children: [
                          Icon(
                            Icons.keyboard_arrow_up,
                            color: Colors.white,
                            size: 30,
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.white,
                            size: 30,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Gap(25),

                  // Chips Rapides
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAmountChip(context, "+2000"),
                      const Gap(10),
                      _buildAmountChip(context, "+5000"),
                      const Gap(10),
                      _buildAmountChip(context, "+10000"),
                    ],
                  ),
                ],
              ),
            ),
            const Gap(30),

            // --- 2. GRILLE OPERATEURS (SÉLECTIONNABLE) ---
            Text(
              "CHOISIR L'OPERATEUR",
              style: TextStyle(
                color: isDark ? Colors.grey[400] : Colors.blueGrey,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.6,
              children: [
                // --- 1. ORANGE MONEY ---
                _buildSelectableOperator(
                  index: 0,
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Image.asset(
                      "assets/images/om.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // --- 2. MTN ---
                _buildSelectableOperator(
                  index: 1,
                  color: const Color(0xFFFFCC00), // Jaune MTN
                  isBrandColor: true,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Image.asset(
                      "assets/images/MTNmoney.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // --- 3. WAVE ---
                _buildSelectableOperator(
                  index: 2,
                  color: const Color(0xFF5EC2F2), // Bleu Wave (Corrigé)
                  isBrandColor: true,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset(
                      "assets/images/wavee.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // --- 4. MOOV MONEY ---
                _buildSelectableOperator(
                  index: 3,
                  color: cardColor, // Fond neutre (Blanc/Noir) pour Moov
                  isBrandColor: false,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset(
                      "assets/images/moov.png",
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER : CHIP MONTANT ---
  Widget _buildAmountChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  // --- WIDGET HELPER : CARTE OPÉRATEUR SÉLECTIONNABLE ---
  // Gère l'effet de gris, la bordure orange et le clic
  Widget _buildSelectableOperator({
    required int index,
    required Color color,
    required Widget child,
    bool isBrandColor = false,
  }) {
    final isSelected = _selectedOperator == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedOperator = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // Zoom léger si sélectionné
        transform: isSelected
            ? Matrix4.identity().scaled(1.02)
            : Matrix4.identity(),

        child: ColorFiltered(
          // Si sélectionné : Pas de filtre (Couleurs réelles)
          // Si pas sélectionné : Filtre noir et blanc (Saturation matrix)
          colorFilter: isSelected
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.matrix(<double>[
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0.2126,
                  0.7152,
                  0.0722,
                  0,
                  0,
                  0,
                  0,
                  0,
                  1,
                  0,
                ]),
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(15),
              // Bordure Orange si sélectionné, sinon bordure discrète
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : (isBrandColor
                          ? Colors.transparent
                          : (isDark
                                ? Colors.grey[800]!
                                : Colors.grey.shade200)),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                  blurRadius: isSelected ? 12 : 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
