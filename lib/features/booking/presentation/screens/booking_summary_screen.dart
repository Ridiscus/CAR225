import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';

class BookingSummaryScreen extends StatelessWidget {
  const BookingSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. DÉFINITION DES COULEURS DYNAMIQUES ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final dividerColor = isDark ? Colors.grey[800] : const Color(0xFFEEEEEE);
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // <--- APPBAR DYNAMIQUE
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), // <--- ICONE DYNAMIQUE
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Confirmation de réservation",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),

      // Barre du bas fixe avec le bouton Payer
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardColor, // <--- FOND DYNAMIQUE
            boxShadow: [
              BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, -5))
            ]
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () {
                // TODO: Intégration du paiement ici
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text(
                "Confirmer et payer",
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Vérifiez les détails de votre réservation",
              style: TextStyle(color: AppColors.grey, fontSize: 14),
            ),
            const Gap(20),

            // 1. DÉTAILS DU TRAJET
            _buildSectionCard(
              context, // <--- On passe le context
              title: "Détails du trajet",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Compagnie", style: TextStyle(color: AppColors.grey, fontSize: 12)),
                    const Text("Confort", style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  ],
                ),
                const Gap(5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Express Transport", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        // Fond du badge : gris clair le jour, gris foncé la nuit
                          color: isDark ? Colors.grey[800] : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(5)
                      ),
                      child: Text("Standard", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
                    ),
                  ],
                ),
                Divider(height: 30, color: dividerColor), // <--- DIVIDER DYNAMIQUE

                // Départ -> Arrivée
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Départ", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                        const Gap(5),
                        Text("Bouaké", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                        const Gap(5),
                        const Text("Durée 4h 30m", style: TextStyle(fontSize: 10, color: AppColors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Arrivée", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                        const Gap(5),
                        Text("Yamoussoukro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      ],
                    ),
                  ],
                )
              ],
            ),

            const Gap(15),

            // 2. ITINÉRAIRE (Visuel)
            _buildSectionCard(
              context,
              title: "Itinéraire",
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                        // Ligne verticale : ajustée pour être visible mais discrète en nuit
                        Container(width: 1, height: 25, color: isDark ? Colors.grey[700] : Colors.grey.shade300),
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                      ],
                    ),
                    const Gap(15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Départ", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                        Text("Bouaké", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                        const Gap(15),
                        const Text("Destination", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                        Text("Yamoussoukro", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      ],
                    )
                  ],
                )
              ],
            ),

            const Gap(15),

            // 3. INFO PASSAGERS
            _buildSectionCard(
              context,
              title: "Informations passagers",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Nombre de passagers", style: TextStyle(color: AppColors.grey)),
                    Text("1 passager", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
                const Gap(10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Date de départ", style: TextStyle(color: AppColors.grey)),
                    Text("Ven. 23 janv.", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ],
            ),

            const Gap(15),

            // 4. RÉSUMÉ DU PRIX
            _buildSectionCard(
              context,
              title: "Résumé du prix",
              children: [
                _buildPriceRow(context, "Prix unitaire", "8 000F"),
                const Gap(10),
                _buildPriceRow(context, "Nombre de passagers", "x 1"),

                const Gap(10),
                _buildPriceRow(context, "Sous-total", "8 000F", isBold: true),
                Divider(height: 20, color: dividerColor), // <--- Divider adapté
                _buildPriceRow(context, "Frais de service", "500 F"),
                const Divider(height: 20, color: AppColors.primary), // Ligne orange (reste orange)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                    const Text("8 500 F", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                )
              ],
            ),

            const Gap(15),

            // 5. EQUIPEMENTS
            _buildSectionCard(
              context,
              title: "Equipements",
              children: [
                Row(
                  children: [
                    _buildChip(Icons.wifi, "Wifi", Colors.blue),
                    const Gap(10),
                    _buildChip(Icons.flash_on, "Recharge USB", Colors.purple),
                  ],
                )
              ],
            ),

            const Gap(40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS REUTILISABLES ADAPTÉS ---

  // Ajout du context pour récupérer les couleurs
  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.03);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor, // <--- FOND DYNAMIQUE
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 5))
          ]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
          const Gap(20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value, {bool isBold = false}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppColors.grey, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: textColor)),
      ],
    );
  }

  // Pas de changement majeur ici, car les chips utilisent des couleurs spécifiques (Bleu/Violet)
  // qui passent bien sur fond blanc comme sur fond noir.
  Widget _buildChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const Gap(5),
          Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}