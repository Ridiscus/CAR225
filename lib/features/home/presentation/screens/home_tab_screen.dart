import 'package:car225/features/home/presentation/screens/profil_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart' hide Provider;
import 'package:provider/provider.dart';
// Imports Clean Architecture
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/presentation/screens/all_itineraire_screen.dart';
import '../../../booking/presentation/screens/search_results_screen.dart';
import 'notification_screen.dart';


class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  // Variables d'état
  String? departureCity;
  String? arrivalCity;
  DateTime? departureDate;
  bool isRoundTrip = false;

  // Données factices pour les itinéraires (limité aux 3 récents)
  final List<Map<String, dynamic>> _recentItineraries = [
    {
      "company": "Maless Travel",
      "color": const Color(0xFFA855F7),
      "price": "15 000 F",
      "type": "Standard",
      "rating": "4.7",
      "route": "Korhogo ➝ Abidjan"
    },
    {
      "company": "UTB",
      "color": const Color(0xFFCA8A04),
      "price": "15 000 F",
      "type": "Express",
      "rating": "4.8",
      "route": "Bouaké ➝ Abidjan"
    },
    {
      "company": "Fabiola",
      "color": const Color(0xFF15803D),
      "price": "12 000 F",
      "type": "Standard",
      "rating": "4.5",
      "route": "Man ➝ Abidjan"
    },
  ];




  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ✅ CORRECTION ICI : Utilise context.read<T>()
      final userProvider = context.read<UserProvider>();

      if (userProvider.user == null) {
        userProvider.loadUser();
      }
    });
  }

  // Action pour le bouton de la bannière
  void _goToBooking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchResultsScreen()),
    );
  }

  void _goToAllItineraries(BuildContext context) {
    // Navigation vers la page voir tout
    Navigator.push(context, MaterialPageRoute(builder: (context) => const AllItinerariesScreen()));
  }

  /*@override
  Widget build(BuildContext context) {
    // 1. Récupération des couleurs dynamiques
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      // 2. FOND DYNAMIQUE (Blanc cassé le jour, Gris très foncé la nuit)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER ---
            _buildHeader(context), // On passe le context pour adapter le header aussi

            // --- 2. CARTE DE RECHERCHE FLOTTANTE ---
            Transform.translate(
              offset: const Offset(0, -80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchCard(context), // <--- Passe le context
              ),
            ),

            // --- 3. SECTION ITINÉRAIRE DE LA SEMAINE ---
            Transform.translate(
              offset: const Offset(0, -60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Itinéraire de la semaine",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            // 3. TEXTE DYNAMIQUE (Noir le jour, Blanc la nuit)
                            color: textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _goToAllItineraries(context),
                          child: const Text(
                            "Voir tout",
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                  ),
                  const Gap(10),

                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentItineraries.length,
                      separatorBuilder: (context, index) => const Gap(15),
                      itemBuilder: (context, index) {
                        final item = _recentItineraries[index];
                        return SizedBox(
                          width: 200,
                          child: _buildCompanyCard(
                            context, // <--- Important : on passe le context
                            companyName: item['company'],
                            color: item['color'],
                            price: item['price'],
                            type: item['type'],
                            rating: item['rating'],
                            route: item['route'],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // --- 4. BANNIÈRE PRÊT À RÉSERVER ---
            // Note : Ce bloc a un fond foncé spécifique (#37474F).
            // Il est beau en mode jour. En mode nuit, il reste lisible car le texte est blanc.
            // On peut le garder tel quel ou l'éclaircir légèrement si besoin.
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // Optionnel : Adapter légèrement la couleur en mode sombre si tu veux
                  color: isDark ? const Color(0xFF263238) : const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text("Prêt à réserver ?",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("Trouvez votre voyage parfait.",
                        style: TextStyle(color: AppColors.grey)),
                    const Gap(15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _goToBooking(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Réserver maintenant",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const Gap(120),
          ],
        ),
      ),
    );
  }*/





  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // 4. ECOUTE DU PROVIDER (La magie opère ici)
    // "watch" signifie : "Si UserProvider change, relance la fonction build de cet écran"
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user; // On récupère l'objet User

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER MODIFIÉ ---
            // On passe currentUser au header pour l'affichage
            _buildHeader(context, currentUser?.photoUrl),

            // --- 2. CARTE DE RECHERCHE ---
            Transform.translate(
              offset: const Offset(0, -80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchCard(context),
              ),
            ),

            // ... LE RESTE DU CODE UI NE CHANGE PAS ...
            // (Copie-colle le reste de tes widgets Itinéraires, Bannière, etc ici)
            Transform.translate(
              offset: const Offset(0, -60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Itinéraire de la semaine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                        TextButton(onPressed: () => _goToAllItineraries(context), child: const Text("Voir tout", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ),
                  const Gap(10),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentItineraries.length,
                      separatorBuilder: (context, index) => const Gap(15),
                      itemBuilder: (context, index) {
                        final item = _recentItineraries[index];
                        return SizedBox(width: 200, child: _buildCompanyCard(context, companyName: item['company'], color: item['color'], price: item['price'], type: item['type'], rating: item['rating'], route: item['route']));
                      },
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF263238) : const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text("Prêt à réserver ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("Trouvez votre voyage parfait.", style: TextStyle(color: AppColors.grey)),
                    const Gap(15),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: () => _goToBooking(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Réserver maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),
            const Gap(120),
          ],
        ),
      ),
    );
  }



  // MODIFICATION ICI : On accepte l'URL photo en paramètre
  Widget _buildHeader(BuildContext context, String? photoUrl) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage("assets/images/bus_header.jpg"), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent])),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // --- 1. PROFIL DYNAMIQUE ---
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        // 5. LOGIQUE D'AFFICHAGE MISE À JOUR
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl) as ImageProvider
                            : const AssetImage("assets/images/ci.jpg"),
                      ),
                    ),
                    const Gap(10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ma localisation", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Row(
                          children: [
                            Image.asset("assets/icons/pin.png", width: 14, height: 14, color: AppColors.primary),
                            const Gap(4),
                            const Text("Abidjan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),
                // --- NOTIFICATION ---
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                    child: Image.asset("assets/icons/notification.png", width: 20, height: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



  // Ajoute 'BuildContext context' ici pour pouvoir faire la navigation
 /* Widget _buildHeader(BuildContext context) {

    // --- SIMULATION DE LA LOGIQUE USER ---
    // Dans ton vrai code, cette variable viendra de ta base de données ou de ton Provider/Bloc.
    // Si null => Affiche user.png. Si rempli => Affiche la photo.
    String? userPhotoUrl; // Mets une URL ici pour tester l'affichage photo (ex: "https://i.pravatar.cc/300")

    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/bus_header.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // --- 1. PROFIL CLIQUABLE & DYNAMIQUE ---
                    GestureDetector(
                      onTap: () {
                        // Navigation vers le profil
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()), // <--- Ton écran Profil
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white, // Fond blanc pour faire ressortir le PNG si transparent
                        // LOGIQUE D'AFFICHAGE :
                        backgroundImage: userPhotoUrl != null
                            ? NetworkImage(userPhotoUrl) as ImageProvider // La vraie photo si elle existe
                            : const AssetImage("assets/images/ci.jpg"), // Sinon l'icône par défaut
                      ),
                    ),

                    const Gap(10),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Ma localisation", style: TextStyle(color: Colors.white70, fontSize: 12)),
                        Row(
                          children: [
                            Image.asset(
                              "assets/icons/pin.png",
                              width: 14,
                              height: 14,
                              color: AppColors.primary,
                            ),
                            const Gap(4),
                            const Text("Abidjan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),

                // --- 2. NOTIFICATION CLIQUABLE ---
                GestureDetector(
                  onTap: () {
                    // Navigation vers les notifications
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()), // <--- Ton écran Notif
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),

                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "assets/icons/notification.png",
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }*/

  // ---------------------------------------------------------------------------
  // WIDGETS BUILDERS
  // ---------------------------------------------------------------------------

  Widget _buildSearchCard(BuildContext context) {
    // Récupère les couleurs
    final cardColor = Theme.of(context).cardColor; // Blanc ou Gris Foncé
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black26 // Ombre plus discrète en mode nuit
        : Colors.grey.withOpacity(0.2);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, // <--- ICI C'EST IMPORTANT
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Ou souhaitez-vous voyager ?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Text("Réservez votre billet en quelques clics", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const Gap(20),

          // Ligne 1 : Départ et Destination
          /*Row(
            children: [
              Expanded(child: _buildDropdownField(context,"Départ", "Sélectionner", Icons.my_location)),
              const Gap(10),
              Expanded(child: _buildDropdownField(context,"Destination", "Sélectionner", Icons.location_on_outlined, isGreen: true)),
            ],
          ),
          const Gap(15),*/

          // Ligne 1 : Départ et Destination
          Row(
            children: [
              Expanded(
                  child: _buildDropdownField(
                      context,
                      "Départ",
                      "Sélectionner",
                      "assets/images/map.png" // <--- Ton image de départ ici
                  )
              ),
              const Gap(10),
              Expanded(
                  child: _buildDropdownField(
                      context,
                      "Destination",
                      "Sélectionner",
                      "assets/images/map.png", // <--- Ton image d'arrivée ici
                      isGreen: true
                  )
              ),
            ],
          ),
          const Gap(15),

          // Ligne 2 : Date et Checkbox sur la même ligne
          Row(
            crossAxisAlignment: CrossAxisAlignment.center, // Alignement vertical centré
            children: [
              // Champ Date (prend plus de place)
              Expanded(
                  flex: 3,
                  child: _buildDateField(context)
              ),
              const Gap(15),

              // Checkbox (prend moins de place)
              // On utilise un Column pour aligner visuellement la checkbox avec le champ input (en sautant le label)
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Petit espace pour que la checkbox s'aligne avec le champ input et pas le label "Date"
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isRoundTrip,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),

                            onChanged: (v) => setState(() => isRoundTrip = v!),
                          ),
                        ),
                        const Gap(5),
                        const Expanded(
                          child: Text("Aller-retour", style: TextStyle(fontSize: 13, height: 1.2)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(20),

          // Bouton Rechercher
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _goToBooking(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("Rechercher des trajets", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }






  Widget _buildCompanyCard(BuildContext context, {
    required String companyName,
    required Color color,
    required String price,
    required String type,
    required String rating,
    required String route,
  }) {
    // Récupération des couleurs du thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // Ombre plus sombre et discrète en mode nuit
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: cardColor, // <--- FOND DYNAMIQUE
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 5, offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Partie haute colorée (Reste identique car le contraste White/Color est bon)
          Container(
            height: 100,
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
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.3), borderRadius: BorderRadius.circular(10)),
                      child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 10),
                          const Gap(2),
                          // IMPORTANT : Fond blanc ici -> Texte forcé en Noir même en mode nuit
                          Text(rating, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black)),
                        ],
                      ),
                    )
                  ],
                ),
                const Icon(Icons.directions_bus, color: Colors.white, size: 30),
                Text(companyName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
          ),

          // Partie basse infos
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(companyName, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      // ICI : On applique textColor pour que le nom du trajet soit visible en nuit
                      Text(route, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const Gap(5),
                      Row(
                        children: const [
                          Icon(Icons.wifi, size: 14, color: AppColors.primary),
                          Gap(5),
                          Icon(Icons.flash_on, size: 14, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 10),
                      const Text("15 places", style: TextStyle(fontSize: 10, color: Colors.grey)),
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




  Widget _buildDropdownField(BuildContext context, String label, String hint, String imagePath, {bool isGreen = false}) {
    // --- 1. Gestion des couleurs (Dark / Light) ---
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Texte : Blanc si sombre, Noir (ou couleur du thème) si clair
    final textColor = isDark ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;

    // Bordure : Subtile en dark mode, grise classique en light mode
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    // Couleur de l'image (si tu veux la teindre en vert/bleu)
    final imageColor = isGreen ? AppColors.secondary : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LABEL (Au-dessus de la boîte)
        Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)
        ),
        const Gap(5),

        // BOÎTE (Champ de saisie)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
            // Optionnel : fond très léger en mode sombre pour détacher le champ
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              // --- REMPLACEMENT DE L'ICÔNE PAR L'IMAGE ---
              Image.asset(
                imagePath,
                width: 20, // Taille contrainte pour ne pas casser le layout
                height: 20,
                color: imageColor, // ⚠️ Retire cette ligne si ton image est déjà colorée (ex: drapeau)
                fit: BoxFit.contain,
              ),
              // -------------------------------------------

              const Gap(10), // Un peu plus d'espace qu'avec une icône simple

              Expanded(
                  child: Text(
                      hint,
                      style: TextStyle(color: textColor, fontWeight: FontWeight.w500),
                      overflow: TextOverflow.ellipsis
                  )
              ),

              const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    // Définition des couleurs locales
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Date de départ", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
        const Gap(5),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor), // <--- BORDURE DYNAMIQUE
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
              const Gap(10),
              Expanded(
                  child: Text(
                      "Sélectionner",
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: textColor), // <--- TEXTE DYNAMIQUE
                      overflow: TextOverflow.ellipsis
                  )
              ),
            ],
          ),
        ),
      ],
    );
  }
}


