import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'TopUpScreen.dart';
import 'WithdrawScreen.dart';

// Assure-toi d'avoir importé tes couleurs si besoin, sinon on utilise le Theme
// import '../../../../core/theme/app_colors.dart';

class WalletScreen extends StatelessWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. THEME VARIABLES ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color; // Noir ou Blanc

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        title: Text(
            "Portefeuille",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), // <--- Icone dynamique
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CARTE PRINCIPALE ORANGE ---
            // Note : On garde le design orange intact même en mode sombre
            // car c'est une "carte physique" (branding fort).
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF5722),
                    Color(0xFFE64A19),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    // En mode sombre, l'ombre est un peu plus subtile ou agit comme une lueur
                    color: const Color(0xFFE64A19).withOpacity(isDark ? 0.2 : 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partie Haute : Texte + Icône
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SOLDE DISPONIBLE",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                          const Gap(8),
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                    text: "45 000 ",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Montserrat'
                                    )
                                ),
                                TextSpan(
                                    text: "FCFA",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600
                                    )
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                      )
                    ],
                  ),

                  const Gap(30),

                  // Partie Basse : Les boutons
                  Row(
                    children: [
                      // ... dans WalletScreen ...

// Bouton Recharger
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // NAVIGATION VERS RECHARGER
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const TopUpScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.25),
                              // ... reste du style
                            ),
                            child: const Text("Recharger", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),

                      const Gap(15),

                      // Bouton Retirer
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: () {
                              // NAVIGATION VERS RETRAIT
                              Navigator.push(context, MaterialPageRoute(builder: (context) => const WithdrawScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              // ... reste du style
                            ),
                            child: const Text("Retirer", style: TextStyle(color: Color(0xFFE64A19), fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),

            const Gap(30),

            // --- LISTE DES TRANSACTIONS ---
            Text("Dernières transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const Gap(15),

            // On passe le context pour récupérer le thème à l'intérieur
            _buildTransactionTile(context, "Rechargement Orange Money", "+ 5 000 F", DateTime.now(), true),
            _buildTransactionTile(context, "Ticket Abidjan - Bouaké", "- 6 000 F", DateTime.now().subtract(const Duration(days: 1)), false),
            _buildTransactionTile(context, "Rechargement Wave", "+ 10 000 F", DateTime.now().subtract(const Duration(days: 2)), true),

            const Gap(20),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, String title, String amount, DateTime date, bool isCredit) {
    // Variables locales
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black12 : Colors.black.withOpacity(0.03);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: cardColor, // <--- FOND DYNAMIQUE
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 2)
            )
          ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              // On garde les couleurs pastels mais en mode sombre on peut les rendre un peu plus transparentes si on veut
                color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle
            ),
            child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
                size: 20
            ),
          ),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                const Gap(4),
                Text(
                    "${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}",
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 12)
                ),
              ],
            ),
          ),
          Text(
              amount,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  // Si c'est du débit (négatif), ça prend la couleur du texte (Noir/Blanc), sinon Vert
                  color: isCredit ? Colors.green : textColor
              )
          ),
        ],
      ),
    );
  }
}