import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Variables de thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      // On retire le Colors.white forcé pour mettre la couleur du scaffold
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
            "Confidentialité",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Politique de Confidentialité",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            Text(
                "Dernière mise à jour : 25 Octobre 2023",
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)
            ),
            const Gap(30),

            const _SectionHeader("1. Collecte des données"),
            const _SectionText(
                "Nous collectons vos informations personnelles (Nom, Prénom, Téléphone) uniquement dans le but de faciliter vos réservations de billets et d'assurer la sécurité de vos transactions."
            ),

            const _SectionHeader("2. Utilisation de la localisation"),
            const _SectionText(
                "Votre position géographique est utilisée pour vous proposer les gares les plus proches et suivre votre trajet en temps réel. Ces données ne sont pas partagées avec des tiers publicitaires."
            ),

            const _SectionHeader("3. Sécurité des paiements"),
            const _SectionText(
                "Toutes les transactions effectuées via Mobile Money sont cryptées et sécurisées par nos partenaires financiers agréés."
            ),

            const _SectionHeader("4. Vos droits"),
            const _SectionText(
                "Conformément à la législation en vigueur, vous disposez d'un droit d'accès, de rectification et de suppression de vos données. Vous pouvez exercer ce droit depuis les paramètres de votre compte."
            ),

            const Gap(50),
          ],
        ),
      ),
    );
  }
}

// Widgets locaux adaptés
class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    // Récupération de la couleur du texte principale
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
          text,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)
      ),
    );
  }
}

class _SectionText extends StatelessWidget {
  final String text;
  const _SectionText(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Text(
      text,
      // Gris très clair en dark mode, gris foncé en light mode pour une lecture douce
      style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.grey[300] : Colors.black87,
          height: 1.6
      ),
      textAlign: TextAlign.justify,
    );
  }
}