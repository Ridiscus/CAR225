// ===========================================================================
// ÉCRAN : LISTE COMPLÈTE DES CONVOIS (ALL CONVOIS)
// ===========================================================================
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'convoi_detail_screen.dart';

class AllConvoisScreen extends StatelessWidget {
  final List<dynamic> allConvois;
  final bool isDark;

  const AllConvoisScreen({super.key, required this.allConvois, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Tous mes convois", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: allConvois.length,
        separatorBuilder: (context, index) => const Gap(15),
        itemBuilder: (context, index) {
          final convoi = allConvois[index];

          // On refait le même mapping que dans l'onglet
          final Map<String, dynamic> mappedConvoi = {
            "id": convoi['id'],
            "ref": convoi['reference'],
            "company": convoi['compagnie']['name'],
            "itineraire": convoi['itineraire'] != null
                ? "${convoi['itineraire']['point_depart']} → ${convoi['itineraire']['point_arrive']}"
                : "${convoi['lieu_depart']} → ${convoi['lieu_retour']}",
            "personnes": convoi['nombre_personnes'],
            "statut": convoi['statut'].toString().toUpperCase(),
            "date": "${convoi['date_depart']} ${convoi['heure_depart']}",
          };

          // Note: Vu que _buildConvoiCard est une méthode de la classe parente _ConvoiTabScreenState,
          // il faudra soit copier la méthode _buildConvoiCard ici, soit la rendre externe.
          // Voici la carte directement intégrée pour cet écran :
          return _buildStandaloneConvoiCard(mappedConvoi, isDark, context);
        },
      ),
    );
  }

  // Version indépendante de la carte (copiée de ton code pour fonctionner hors du State)
  Widget _buildStandaloneConvoiCard(Map<String, dynamic> convoi, bool isDark, BuildContext context) {
    final String statut = convoi["statut"] ?? "EN ATTENTE";

    Color statusColor;
    if (statut == "PAYE") { statusColor = const Color(0xFF1EAE53); }
    else if (statut == "CONFIRME" || statut == "VALIDE") { statusColor = Colors.blue; }
    else if (statut == "REJETE") { statusColor = Colors.redAccent; }
    else { statusColor = Colors.orange; }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(convoi["ref"], style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.bold)),
              Text(convoi["date"], style: TextStyle(color: Colors.grey.shade500, fontSize: 11, fontWeight: FontWeight.w500)),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(convoi["company"], style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87), overflow: TextOverflow.ellipsis)),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withOpacity(0.3), width: 1)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: statusColor)),
                    const Gap(6),
                    Text(statut, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor)),
                  ],
                ),
              )
            ],
          ),
          const Gap(12),
          Row(
            children: [
              Icon(Icons.route, size: 16, color: Colors.grey.shade400),
              const Gap(6),
              Expanded(child: Text(convoi["itineraire"], style: TextStyle(fontSize: 13, color: isDark ? Colors.grey.shade300 : Colors.black87, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.people, size: 14, color: Colors.grey.shade600),
                    const Gap(4),
                    Text("${convoi["personnes"]}", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700, fontSize: 12)),
                  ],
                ),
              ),
              const Gap(10),
              InkWell(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ConvoiDetailScreen(convoi: convoi)));
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.black, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 14, color: isDark ? Colors.white : Colors.white),
                      const Gap(6),
                      Text("VOIR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.white)),
                    ],
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}