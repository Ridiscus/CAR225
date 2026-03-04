/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'forget_bag_screen.dart';

class ClaimTypeSelectorScreen extends StatelessWidget {
  const ClaimTypeSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Définition des catégories basées sur ta capture d'écran
    final List<Map<String, dynamic>> categories = [
      {
        "title": "Bagage Perdu",
        "desc": "Vous n'avez pas retrouvé votre bagage à l'arrivée ? Signalez-le immédiatement.",
        "icon": Icons.luggage,
        "color": Colors.orange[800],
        "actionText": "DÉCLARER",
      },
      {
        "title": "Objet Oublié",
        "desc": "Vous avez oublié un téléphone, des clés ou un vêtement dans le bus ? Nous allons vérifier.",
        "icon": Icons.visibility_outlined,
        "color": Colors.blue[700],
        "actionText": "DÉCLARER",
      },
      {
        "title": "Remboursement",
        "desc": "Une erreur de paiement ou un voyage annulé ? Demandez un remboursement sur votre solde.",
        "icon": Icons.account_balance_wallet_outlined,
        "color": Colors.green[600],
        "actionText": "DEMANDER",
      },
      {
        "title": "Qualité de Service",
        "desc": "Un problème avec le chauffeur, l'hotesse ou le confort du véhicule ? Dites-le nous.",
        "icon": Icons.stars_rounded,
        "color": Colors.purple[400],
        "actionText": "SIGNALER",
      },
      {
        "title": "Mon Compte",
        "desc": "Problème d'accès, modification de profil ou erreur de solde portefeuille.",
        "icon": Icons.manage_accounts_outlined,
        "color": Colors.grey[700],
        "actionText": "AIDE",
      },
      {
        "title": "Autre demande",
        "desc": "Pour toute autre question ou suggestion non listée ci-dessus.",
        "icon": Icons.help_outline,
        "color": Colors.red[400],
        "actionText": "CONTACTER",
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Fond légèrement gris comme sur le web
      appBar: AppBar(
        title: const Text("Support Client", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Comment pouvons-nous vous aider aujourd'hui ?",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Gap(25),
            // Utilisation d'un GridView pour l'aspect "Cartes"
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1, // On commence par 1 par ligne pour mobile, ou 2 si tu préfères
                childAspectRatio: 1.8,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
              ),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final item = categories[index];
                return _buildCategoryCard(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildCategoryCard(BuildContext context, Map<String, dynamic> item) {
    return GestureDetector(
        onTap: () {
          if (item['title'] == "Bagage Perdu") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GenericClaimFormScreen(
              apiType: "bagage_perdu", // Ajouté
              title: "Déclarer un Bagage Perdu",
              categoryName: "Bagage perdu",
              hintObject: "Ex: Valise bleue à roulettes, sac à dos noir...",
              hintDetails: "Décrivez votre bagage (couleur, taille, contenu) et les circonstances de la perte. Plus vous êtes précis, plus vite nous pourrons le retrouver.",
            )));
          }
          else if (item['title'] == "Objet Oublié") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GenericClaimFormScreen(
              apiType: "objet_oublie", // Ajouté
              title: "Signaler un Objet Oublié",
              categoryName: "Objet oublié",
              hintObject: "Ex: Téléphone Samsung, lunettes de soleil, clés...",
              hintDetails: "Décrivez l'objet oublié et où il se trouvait dans le véhicule (sous le siège, dans le compartiment...). Indiquez aussi votre numéro de place.",
            )));
          }
          else if (item['title'] == "Remboursement") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GenericClaimFormScreen(
              apiType: "remboursement", // Ajouté
              title: "Demander un Remboursement",
              categoryName: "Réservation annulée",
              dropdownLabel: "RÉSERVATION ANNULÉE *",
              hintObject: "Ex: Remboursement réservation annulée du 15/02...",
              hintDetails: "Expliquez les circonstances de l'annulation et le montant que vous attendez. Si vous avez une preuve d'annulation, mentionnez-la.",
            )));
          }
          else if (item['title'] == "Qualité de Service") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GenericClaimFormScreen(
              apiType: "qualite_service", // Ajouté
              title: "Signaler un Problème de Qualité",
              categoryName: "voyage récent à signaler",
              hintObject: "Ex: Comportement du chauffeur, propreté du véhicule...",
              hintDetails: "Décrivez le problème rencontré (chauffeur, hôtesse, véhicule, ponctualité...). Soyez aussi précis que possible.",
            )));
          }
          else if (item['title'] == "Mon Compte") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GenericClaimFormScreen(
              apiType: "mon_compte", // Ajouté
              title: "Aide sur mon Compte",
              categoryName: "Compte",
              showDropdown: false,
              hintObject: "Ex: Erreur de solde portefeuille, accès impossible...",
              hintDetails: "Décrivez votre problème : erreur de solde, problème de connexion, modification de profil...",
            )));
          }
          else if (item['title'] == "Autre demande") {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const GenericClaimFormScreen(
              apiType: "autre", // Ajouté
              title: "Nouvelle Demande d'Assistance",
              categoryName: "Autre",
              showDropdown: false,
              hintObject: "Ex: Suggestion, question sur un service...",
              hintDetails: "Décrivez votre demande ou question en détail.",
            )));
          }
        },

      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),

            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icone avec fond coloré léger
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: item['color'].withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item['icon'], color: item['color'], size: 28),
            ),
            const Gap(12),
            Text(
              item['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                item['desc'],
                style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(10),
            // Bouton d'action en bas
            Row(
              children: [
                Text(
                  item['actionText'],
                  style: TextStyle(
                    color: item['color'],
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 13,
                  ),
                ),
                const Gap(5),
                Icon(Icons.arrow_forward, color: item['color'], size: 16),
              ],
            ),
          ],
        ),
      )
    );
  }

}*/



import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../booking/data/models/categorie_models.dart';
import '../../../booking/data/repositories/support_repository.dart';
import 'forget_bag_screen.dart'; // Ton fichier GenericClaimFormScreen

class ClaimTypeSelectorScreen extends StatefulWidget {
  const ClaimTypeSelectorScreen({super.key});

  @override
  State<ClaimTypeSelectorScreen> createState() => _ClaimTypeSelectorScreenState();
}

class _ClaimTypeSelectorScreenState extends State<ClaimTypeSelectorScreen> {
  final SupportRepository _repository = SupportRepository();
  List<SupportCategory> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final data = await _repository.fetchCategories();
      setState(() {
        _categories = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Optionnel: Afficher une erreur si l'API échoue
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Support Client",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Comment pouvons-nous vous aider aujourd'hui ?",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Gap(25),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 1.8,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
              ),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                return _buildCategoryCard(context, _categories[index]);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, SupportCategory cat) {
    // Conversion de la couleur String (#hex) en Color Flutter
    final cardColor = Color(int.parse(cat.color.replaceFirst('#', '0xff')));

    return GestureDetector(
      onTap: () {
        // PLUS BESOIN DE IF/ELSE ! On passe juste l'objet
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GenericClaimFormScreen(category: cat),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: cardColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_getIconData(cat.icon), color: cardColor, size: 28),
            ),
            const Gap(12),
            Text(
              cat.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                cat.description,
                style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Gap(10),
            Row(
              children: [
                Text(
                  "CONTINUER",
                  style: TextStyle(
                    color: cardColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.1,
                    fontSize: 13,
                  ),
                ),
                const Gap(5),
                Icon(Icons.arrow_forward, color: cardColor, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Helper pour mapper les noms d'icônes de l'API vers des Icons Flutter
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'suitcase-rolling': return Icons.luggage;
      case 'glasses': return Icons.visibility_outlined;
      case 'hand-holding-usd': return Icons.account_balance_wallet_outlined;
      case 'star': return Icons.stars_rounded;
      case 'user-cog': return Icons.manage_accounts_outlined;
      default: return Icons.help_outline;
    }
  }
}