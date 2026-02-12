import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import 'claim_history_screen.dart';
import 'claim_screen.dart';

// --- ÉCRAN PRINCIPAL FAQ ---
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text("FAQ & Aide", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text("Questions fréquentes", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
          const Gap(15),

          const FaqItem(
            question: "Comment recharger mon compte ?",
            answer: "Allez dans 'Mon Portefeuille', cliquez sur 'Recharger' et choisissez votre méthode de paiement.",
          ),

          // --- ITEM MODIFIÉ POUR L'OBJET PERDU ---
          FaqItem(
            question: "J'ai oublié un objet dans le car",
            // Au lieu d'un texte simple, on passe un contenu personnalisé
            customContent: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Vous avez 24h après la fin du trajet pour signaler un objet perdu. Passé ce délai, veuillez nous contacter directement.",
                  style: TextStyle(color: textColor?.withOpacity(0.8), fontSize: 13),
                ),
                const Gap(15),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateClaimScreen())),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: const Text("Faire une réclamation", textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ClaimsHistoryScreen())),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: BorderSide(color: textColor ?? Colors.black),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                        ),
                        child: Text("Mes réclamations", style: TextStyle(color: textColor, fontSize: 12)),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          // ---------------------------------------

          const FaqItem(
            question: "Comment annuler un billet ?",
            answer: "Vous pouvez annuler un billet jusqu'à 2 heures avant le départ.",
          ),
        ],
      ),
    );
  }
}

// --- WIDGET FAQ ITEM AMÉLIORÉ ---
class FaqItem extends StatelessWidget {
  final String question;
  final String? answer; // Devient optionnel
  final Widget? customContent; // Nouveau paramètre

  const FaqItem({super.key, required this.question, this.answer, this.customContent});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: isDark ? Border.all(color: Colors.white10) : Border.all(color: Colors.grey.shade200)
      ),
      child: ExpansionTile(
        title: Text(question, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: Colors.green,
        children: [
          // Si customContent existe, on l'affiche, sinon on affiche le texte standard
          customContent ?? Text(
              answer ?? "",
              style: TextStyle(color: isDark ? Colors.grey[300] : Colors.black87, height: 1.5)
          ),
        ],
      ),
    );
  }
}