import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

class CreateClaimScreen extends StatefulWidget {
  const CreateClaimScreen({super.key});

  @override
  State<CreateClaimScreen> createState() => _CreateClaimScreenState();
}

class _CreateClaimScreenState extends State<CreateClaimScreen> {
  // Mock Data : Simulation des trajets de l'utilisateur
  // Dans la vraie vie, cela viendrait de ton API
  final List<Map<String, dynamic>> _myTrips = [
    {
      "id": "TRIP-001",
      "destination": "Abidjan - Bouaké",
      "date": DateTime.now().subtract(const Duration(hours: 5)), // Fini il y a 5h (ÉLIGIBLE)
      "status": "Terminé"
    },
    {
      "id": "TRIP-002",
      "destination": "Yamoussoukro - Abidjan",
      "date": DateTime.now().add(const Duration(hours: 2)), // Futur (NON ÉLIGIBLE pour objet perdu, mais peut-être actif)
      "status": "Confirmé"
    },
    {
      "id": "TRIP-003",
      "destination": "San Pedro - Abidjan",
      "date": DateTime.now().subtract(const Duration(hours: 30)), // Fini il y a 30h (NON ÉLIGIBLE > 24h)
      "status": "Terminé"
    },
  ];

  String? _selectedTripId;
  String? _selectedSubject;
  final TextEditingController _descriptionController = TextEditingController();

  // Liste filtrée des trajets éligibles
  List<Map<String, dynamic>> get _eligibleTrips {
    final now = DateTime.now();
    return _myTrips.where((trip) {
      final tripDate = trip['date'] as DateTime;
      // Logique : Le trajet est terminé depuis moins de 24h
      // (Ici j'assume que 'date' est l'heure d'arrivée, sinon ajoute la durée du trajet)
      final difference = now.difference(tripDate).inHours;
      return difference < 24 && difference >= 0; // Entre 0 et 24h dans le passé
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final eligibleList = _eligibleTrips;

    return Scaffold(
      appBar: AppBar(title: const Text("Nouvelle Réclamation")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Sélectionnez le trajet concerné", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text("Seuls les trajets des dernières 24h apparaissent ici.", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const Gap(10),

            // --- LISTE DEROULANTE DES TRAJETS ---
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedTripId,
                  hint: const Text("Choisir un trajet..."),
                  isExpanded: true,
                  items: eligibleList.map((trip) {
                    return DropdownMenuItem<String>(
                      value: trip['id'],
                      child: Text("${trip['destination']} (${DateFormat('dd/MM HH:mm').format(trip['date'])})"),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedTripId = value),
                ),
              ),
            ),

            // Message si vide
            if (eligibleList.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("Aucun trajet récent éligible pour une réclamation d'objet perdu.", style: TextStyle(color: Colors.red[300], fontSize: 12)),
              ),

            const Gap(25),

            // --- TYPE DE PROBLEME ---
            const Text("Quel est le problème ?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(10),
            Wrap(
              spacing: 10,
              children: ["Objet perdu", "Problème bagage", "Autre"].map((subject) {
                final isSelected = _selectedSubject == subject;
                return ChoiceChip(
                  label: Text(subject),
                  selected: isSelected,
                  selectedColor: Colors.green.withOpacity(0.2),
                  onSelected: (bool selected) {
                    setState(() {
                      _selectedSubject = selected ? subject : null;
                    });
                  },
                );
              }).toList(),
            ),

            const Gap(25),

            // --- DESCRIPTION ---
            const Text("Description détaillée", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Gap(10),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: "Décrivez l'objet (couleur, marque, emplacement dans le car...)",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                fillColor: Theme.of(context).cardColor,
                filled: true,
              ),
            ),

            const Gap(30),

            // --- BOUTON SOUMETTRE ---
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: (_selectedTripId != null && _selectedSubject != null)
                    ? () {
                  // TODO: Appel API pour envoyer la réclamation
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Réclamation envoyée !"), backgroundColor: Colors.green));
                  Navigator.pop(context);
                }
                    : null, // Désactivé si pas rempli
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("Envoyer la réclamation"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}