import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class LostBagFormScreen extends StatefulWidget {
  const LostBagFormScreen({super.key});

  @override
  State<LostBagFormScreen> createState() => _LostBagFormScreenState();
}

class _LostBagFormScreenState extends State<LostBagFormScreen> {
  String? selectedTrip;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Déclarer un Bagage Perdu",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Veuillez remplir le formulaire ci-dessous pour que nos équipes puissent vous aider.",
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const Gap(20),

            // --- Banner d'Alerte (Jaune) ---
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9E7),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[800], size: 24),
                      const Gap(10),
                      Text(
                        "Aucune réservation disponible",
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[900]),
                      ),
                    ],
                  ),
                  const Gap(8),
                  const Text(
                    "Vous n'avez aucun voyage terminé. Vous pourrez déclarer un bagage perdu une fois votre voyage effectué.",
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                  const Gap(10),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      "← Choisir une autre catégorie",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[900],
                          decoration: TextDecoration.underline
                      ),
                    ),
                  )
                ],
              ),
            ),
            const Gap(30),

            // --- Formulaire ---
            _buildLabel("VOYAGE CONCERNÉ *"),
            _buildDropdown(),
            const Gap(5),
            const Text("  Sélectionnez le voyage durant lequel votre bagage a été perdu.",
                style: TextStyle(color: Colors.grey, fontSize: 11)),

            const Gap(25),
            _buildLabel("OBJET DU MESSAGE *"),
            _buildTextField(hint: "Ex: Valise bleue à roulettes, sac à dos noir..."),

            const Gap(25),
            _buildLabel("DÉTAILS DE VOTRE PROBLÈME *"),
            _buildTextField(
                hint: "Décrivez votre bagage (couleur, taille, contenu) et les circonstances de la perte...",
                maxLines: 5
            ),

            const Gap(40),

            // --- Bouton Envoyer ---
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton.icon(
                onPressed: () {}, // Action d'envoi
                icon: const Icon(Icons.send, size: 18),
                label: const Text("ENVOYER MA DEMANDE", style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600], // Gris comme sur l'image
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Helper pour les labels
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
    );
  }

  // Widget Helper pour le Dropdown
  Widget _buildDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: const Text("-- Sélectionner --"),
          value: selectedTrip,
          items: const [], // À remplir avec tes données de voyages
          onChanged: (val) => setState(() => selectedTrip = val),
        ),
      ),
    );
  }

  // Widget Helper pour les champs texte
  Widget _buildTextField({required String hint, int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        contentPadding: const EdgeInsets.all(15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.withOpacity(0.2)),
        ),
      ),
    );
  }
}