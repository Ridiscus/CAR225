import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import 'main_wrapper_screen.dart';

class AlertDetailScreen extends StatelessWidget {
  final String alertType;
  final Color alertColor;
  final String iconPath;

  const AlertDetailScreen({
    super.key,
    required this.alertType,
    required this.alertColor,
    required this.iconPath,
  });

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final inputFillColor = isDark ? Colors.grey[900] : Colors.white; // Fond des inputs
    final borderColor = isDark ? Colors.grey[800] : Colors.transparent;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), // Flèche dynamique
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Détails du problème", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alertType, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            const Gap(10),

            // Tag du type d'alerte (Reste similaire car utilise l'opacité)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: alertColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: alertColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(iconPath, width: 16, color: alertColor),
                  const Gap(8),
                  Text(alertType, style: TextStyle(color: alertColor, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const Gap(25),

            // --- Champ Description ---
            Text("Description du problème", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Gap(10),
            TextField(
              maxLines: 5,
              style: TextStyle(color: textColor), // Texte saisi
              decoration: InputDecoration(
                hintText: "Décrivez en détails ce qui s'est passé...",
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: inputFillColor, // Couleur fond input adaptée
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                enabledBorder: isDark
                    ? OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor!))
                    : null,
                contentPadding: const EdgeInsets.all(15),
              ),
            ),
            const Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: EdgeInsets.only(top: 5),
                child: Text("0/500 caractères", style: TextStyle(color: Colors.grey, fontSize: 11)),
              ),
            ),
            const Gap(20),

            // --- Champ Lieu ---
            Text("Lieu du problème (optionnel)", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Gap(10),
            TextField(
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                hintText: "Localisation actuelle...",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.location_on_outlined, color: Colors.grey),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                enabledBorder: isDark
                    ? OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor!))
                    : null,
              ),
            ),
            const Gap(20),

            // --- Champ Passagers ---
            Text("Nombre de passagers affectés", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            const Gap(10),
            TextField(
              style: TextStyle(color: textColor),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: "1",
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.people_outline, color: Colors.grey),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                enabledBorder: isDark
                    ? OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor!))
                    : null,
              ),
            ),
            const Gap(20),

            // --- Boite info urgence ---
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                // Dark: Bleu très sombre transparent / Light: Bleu pâle
                color: isDark ? Colors.blue.withOpacity(0.15) : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: isDark ? Colors.blue.withOpacity(0.3) : Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue),
                  const Gap(10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Urgence ?", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        Text(
                            "Si c'est une situation d'urgence vitale, contactez immédiatement les autorités locales.",
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.blueGrey[200] : Colors.blueGrey)
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            const Gap(30),

            // --- BOUTON ENVOYER ---
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const AlertSuccessScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  elevation: 5,
                  shadowColor: AppColors.primary.withOpacity(0.4),
                ),
                child: const Text("Envoyer le signalement", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// --- ALERT SUCCES SCREEN ---
// ---------------------------------------------------------

class AlertSuccessScreen extends StatelessWidget {
  const AlertSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Variables de thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final summaryBgColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(),

            // Cercle vert
            Container(
              height: 100, width: 100,
              decoration: BoxDecoration(
                color: isDark ? Colors.green.withOpacity(0.15) : Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 50, color: Colors.green),
            ),
            const Gap(30),

            Text("Rapport envoyé", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)),
            const Gap(10),
            const Text(
              "Merci de nous avoir signalé ce problème. Nos équipes examineront votre rapport dans les plus brefs délais.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const Gap(40),

            // Résumé
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: summaryBgColor, // Fond adapté gris/transparent
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  _buildSummaryRow(context, "Type de problème", "Accident"),
                  const Gap(15),
                  _buildSummaryRow(context, "Passagers affectés", "5"),
                  const Gap(15),
                  _buildSummaryRow(context, "Numéro de rapport", "#1768855343878"),
                ],
              ),
            ),

            const Spacer(),

            // Boutons d'action
            SizedBox(
              width: double.infinity,
              height: 50,
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
                  backgroundColor: const Color(0xFFE8501E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text("Retour à l'accueil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(15),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Signaler un autre problème", style: TextStyle(color: textColor)), // Texte dynamique
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
}