/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import 'main_wrapper_screen.dart'; // ⚠️ Vérifie que le chemin vers ton MainScreen est bon

class AlertSuccessScreen extends StatelessWidget {
  const AlertSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    // Fond du résumé : très léger en light, transparent en dark
    final summaryBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // --- CERCLE DE SUCCÈS ---
            Container(
              height: 100, width: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 50, color: Colors.green),
            ),
            const Gap(30),

            // --- TEXTES ---
            Text(
                "Rapport envoyé",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            const Text(
              "Merci de nous avoir signalé ce problème. Nos équipes examineront votre rapport dans les plus brefs délais.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Gap(40),

            // --- RÉSUMÉ (STATIQUE POUR L'INSTANT) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: summaryBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(context, "Type de problème", "Accident"),
                  const Gap(15),
                  _buildSummaryRow(context, "Statut", "En attente"),
                  const Gap(15),
                  _buildSummaryRow(context, "Numéro de dossier", "#${DateTime.now().millisecondsSinceEpoch}"),
                ],
              ),
            ),

            const Spacer(),

            // --- BOUTON RETOUR ACCUEIL ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  // On vide toute la navigation et on relance MainScreen
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      // ⚠️ Assure-toi que 'MainWrapperScreen' ou 'MainScreen' est bien le nom de ta page d'accueil principale
                      builder: (context) => const MainScreen(initialIndex: 0),
                    ),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Text(
                    "Retour à l'accueil",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const Gap(15),

            // --- BOUTON SECONDAIRE ---
            TextButton(
              onPressed: () {
                // Revient juste en arrière (ferme l'écran de succès)
                Navigator.pop(context);
              },
              child: Text("Fermer", style: TextStyle(color: textColor)),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
      ],
    );
  }
}*/



import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import 'main_wrapper_screen.dart'; // ⚠️ Vérifie le chemin

class AlertSuccessScreen extends StatelessWidget {
  // 🟢 1. AJOUT DES VARIABLES DYNAMIQUES
  final String alertType;
  final String status;
  final String reference;

  const AlertSuccessScreen({
    super.key,
    required this.alertType,
    this.status = "En attente", // Valeur par défaut logique après un envoi
    required this.reference,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final summaryBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // --- CERCLE DE SUCCÈS ---
            Container(
              height: 100, width: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 50, color: Colors.green),
            ),
            const Gap(30),

            // --- TEXTES ---
            Text(
                "Rapport envoyé",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            const Text(
              "Merci de nous avoir signalé ce problème. Nos équipes examineront votre rapport dans les plus brefs délais.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Gap(40),

            // --- 🟢 2. INJECTION DES VARIABLES DANS LE RÉSUMÉ ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: summaryBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(context, "Type de problème", alertType),
                  const Gap(15),
                  _buildSummaryRow(context, "Statut", status),
                  const Gap(15),
                  _buildSummaryRow(context, "Numéro de dossier", reference),
                ],
              ),
            ),

            const Spacer(),

            // --- BOUTON RETOUR ACCUEIL ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MainScreen(initialIndex: 0),
                    ),
                        (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                ),
                child: const Text(
                    "Retour à l'accueil",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                ),
              ),
            ),
            const Gap(15),

            // --- BOUTON SECONDAIRE ---
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Fermer", style: TextStyle(color: textColor)),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(BuildContext context, String label, String value) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        // Ajout d'un Expanded ou d'un style pour éviter les dépassements de texte si le type est long
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}