import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Variables de thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        title: Text(
            "FAQ & Aide",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
              "Questions fréquentes",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)
          ),
          const Gap(15),

          const FaqItem(
            question: "Comment recharger mon compte ?",
            answer: "Allez dans 'Mon Portefeuille', cliquez sur 'Recharger' et choisissez votre méthode de paiement (Orange Money, Wave, MTN).",
          ),
          const FaqItem(
            question: "Comment annuler un billet ?",
            answer: "Vous pouvez annuler un billet jusqu'à 2 heures avant le départ dans la section 'Mes Trajets'. Des frais peuvent s'appliquer.",
          ),
          const FaqItem(
            question: "J'ai oublié un objet dans le car",
            answer: "Contactez immédiatement le service client via la section 'Nous contacter' ou appelez le numéro d'urgence disponible sur votre billet.",
          ),
          const FaqItem(
            question: "Comment modifier mon profil ?",
            answer: "Rendez-vous dans l'onglet Profil > Informations personnelles pour mettre à jour votre nom, email ou photo.",
          ),
        ],
      ),
    );
  }
}

class FaqItem extends StatelessWidget {
  final String question;
  final String answer;

  const FaqItem({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
          color: cardColor, // <--- BLOC DYNAMIQUE
          borderRadius: BorderRadius.circular(15),
          // Optionnel : petite bordure subtile en mode sombre
          border: isDark ? Border.all(color: Colors.white10) : null
      ),
      child: ExpansionTile(
        title: Text(
            question,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        iconColor: Colors.green, // La flèche quand ouvert
        textColor: Colors.green, // Le titre quand ouvert
        collapsedIconColor: isDark ? Colors.grey : Colors.black54, // La flèche quand fermé
        children: [
          Text(
              answer,
              style: TextStyle(
                  color: isDark ? Colors.grey[300] : Colors.black87, // <--- TEXTE CONTENU DYNAMIQUE
                  height: 1.5
              )
          ),
        ],
      ),
    );
  }
}