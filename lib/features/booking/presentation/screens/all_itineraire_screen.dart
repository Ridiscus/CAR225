import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';

class AllItinerariesScreen extends StatelessWidget {
  const AllItinerariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. RÉCUPÉRATION DU THÈME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);

    // Liste des données (Mock Data)
    final List<Map<String, dynamic>> itineraries = [
      {
        "company": "Maless Travel",
        "color": const Color(0xFFA855F7), // Violet
        "price": "15 000 F",
        "type": "Standard",
        "rating": "4.7",
        "route": "Korhogo ➝ Abidjan"
      },
      {
        "company": "UTB",
        "color": const Color(0xFFCA8A04), // Or/Moutarde
        "price": "8 000 F",
        "type": "Express",
        "rating": "4.8",
        "route": "Bouaké ➝ Abidjan"
      },
      {
        "company": "Fabiola",
        "color": const Color(0xFF15803D), // Vert foncé
        "price": "12 000 F",
        "type": "Standard",
        "rating": "4.5",
        "route": "Man ➝ Abidjan"
      },
      {
        "company": "A.V.S",
        "color": const Color(0xFFDC2626), // Rouge
        "price": "6 500 F",
        "type": "VIP",
        "rating": "4.9",
        "route": "Yakro ➝ Abidjan"
      },
      {
        "company": "SBTA",
        "color": const Color(0xFF2563EB), // Bleu roi
        "price": "7 000 F",
        "type": "Standard",
        "rating": "4.2",
        "route": "San Pedro ➝ Abidjan"
      },
      {
        "company": "ST Transport",
        "color": const Color(0xFF0D9488), // Sarcelle (Teal)
        "price": "5 000 F",
        "type": "Eco",
        "rating": "4.0",
        "route": "Daloa ➝ Abidjan"
      },
    ];

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), // <--- ICONE DYNAMIQUE
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Tous les itinéraires",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list, color: textColor), // <--- ICONE DYNAMIQUE
            onPressed: () {},
          )
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                  color: cardColor, // <--- FOND BARRE RECHERCHE
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4))
                  ]
              ),
              child: TextField(
                style: TextStyle(color: textColor), // Couleur du texte tapé
                decoration: InputDecoration(
                  icon: const Icon(Icons.search, color: Colors.grey),
                  hintText: "Rechercher une compagnie ou ville...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Grille des résultats
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: itineraries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, // 2 colonnes
                childAspectRatio: 0.72, // Ratio hauteur/largeur
                crossAxisSpacing: 15, // Espace horizontal
                mainAxisSpacing: 15, // Espace vertical
              ),
              itemBuilder: (context, index) {
                final item = itineraries[index];
                return _buildCompanyCard(
                  context: context, // <--- On passe le context
                  companyName: item['company'],
                  color: item['color'],
                  price: item['price'],
                  type: item['type'],
                  rating: item['rating'],
                  route: item['route'],
                );
              },
            ),
          ),
          const Gap(55),
        ],
      ),
    );
  }

  // TA CARTE PERSONNALISÉE (Adaptée)
  Widget _buildCompanyCard({
    required BuildContext context, // Ajout du context
    required String companyName,
    required Color color,
    required String price,
    required String type,
    required String rating,
    required String route,
  }) {
    // Variables locales au widget
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.grey.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: cardColor, // <--- FOND CARTE DYNAMIQUE
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partie haute colorée (Reste identique car le texte est blanc sur fond couleur)
          Container(
            height: 90,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(8)),
                      child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 9),
                          const Gap(2),
                          // Le texte rating reste noir car le fond est blanc (Container au dessus)
                          Text(rating, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    )
                  ],
                ),
                const Icon(Icons.directions_bus, color: Colors.white, size: 28),
                Text(companyName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1, overflow: TextOverflow.ellipsis
                ),
              ],
            ),
          ),

          // Partie basse infos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(companyName, style: const TextStyle(fontSize: 9, color: Colors.grey)),
                      const Gap(2),
                      // Route en couleur dynamique
                      Text(route, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),

                      const Gap(5),
                      Row(
                        children: const [
                          Icon(Icons.wifi, size: 12, color: AppColors.primary),
                          Gap(5),
                          Icon(Icons.flash_on, size: 12, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Divider(height: 10, color: isDark ? Colors.grey[800] : Colors.grey[300]),
                      // Prix en couleur dynamique
                      Text(price, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor)),
                      const Text("Dispo", style: TextStyle(fontSize: 9, color: AppColors.secondary, fontWeight: FontWeight.bold)),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}