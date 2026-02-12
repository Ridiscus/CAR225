import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ClaimsHistoryScreen extends StatelessWidget {
  const ClaimsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock Data
    final claims = [
      {"id": "#REQ001", "date": "10/10/2023", "status": "Résolu", "subject": "Objet perdu"},
      {"id": "#REQ002", "date": "12/11/2023", "status": "En cours", "subject": "Retard"},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Mes Réclamations")),
      body: claims.isEmpty
          ? const Center(child: Text("Aucune réclamation"))
          : ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: claims.length,
        separatorBuilder: (_, __) => const Gap(15),
        itemBuilder: (context, index) {
          final claim = claims[index];
          final isResolved = claim['status'] == "Résolu";

          return Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2))
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(claim['subject']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("Dossier ${claim['id']} • ${claim['date']}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: isResolved ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20)
                  ),
                  child: Text(
                    claim['status']!,
                    style: TextStyle(
                        color: isResolved ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.bold,
                        fontSize: 12
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }
}