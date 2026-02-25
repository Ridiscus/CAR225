import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/screens/notification_screen.dart';
import '../../../home/presentation/screens/profil_screen.dart';

class CompanyDetailScreen extends StatelessWidget {
  final String companyName;

  const CompanyDetailScreen({super.key, required this.companyName});

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER ---
            _buildHeader(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- 2. TITRE PRINCIPAL ---
                  Text(
                    "Nos Compagnies",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  Text(
                    "6 partenaires de confiance",
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                  const Gap(25),

                  // --- 3. SECTION DÉTAILS ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Trajets - $companyName",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Fermer",
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Gap(10),

                  // --- 4. IMAGE DE LA CARTE (Map) ---
                  Container(
                    height: 220,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color:
                          cardColor, // Fond du container si l'image charge mal
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      image: const DecorationImage(
                        image: AssetImage("assets/images/map_preview.jpg"),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: const Stack(
                      children: [
                        Center(
                          child: Icon(
                            Icons.location_on,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(25),

                  // --- 5. LISTE DES TRAJETS ACTIFS ---
                  Text(
                    "Trajets actifs",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const Gap(15),

                  _buildRouteItem(
                    context,
                    origin: "Abidjan",
                    destination: "Yamoussoukro",
                    color: Colors.orange,
                    label: "Trajet 1",
                  ),
                  const Gap(10),
                  _buildRouteItem(
                    context,
                    origin: "Korhogo",
                    destination: "Abidjan",
                    color: const Color(0xFF1E88E5), // Bleu
                    label: "Trajet 2",
                  ),
                  const Gap(10),
                  _buildRouteItem(
                    context,
                    origin: "Gagnoa",
                    destination: "Yamoussoukro",
                    color: const Color(0xFF1E88E5), // Bleu
                    label: "Trajet 3",
                  ),

                  const Gap(50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS ---

  /*Widget _buildHeader(BuildContext context) {
    String? userPhotoUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white, // Fond de sécurité
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: const DecorationImage(
          image: AssetImage("assets/images/bus_header.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent], // Légèrement plus sombre en haut
            stops: const [0.0, 0.4],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // --- PROFIL ---
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        backgroundImage: userPhotoUrl != null
                            ? NetworkImage(userPhotoUrl) as ImageProvider
                            : const AssetImage("assets/images/ci.jpg"),
                      ),
                    ),
                    const Gap(10),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("Ma localisation", style: TextStyle(color: Colors.white70, fontSize: 11)),
                        Row(
                          children: [
                            Image.asset(
                              "assets/icons/pin.png",
                              width: 14,
                              height: 14,
                              color: AppColors.primary,
                            ),
                            const Gap(5),
                            const Text("Abidjan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                      ],
                    )
                  ],
                ),

                // --- NOTIFICATION ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const NotificationScreen()),
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
                )
              ],
            ),
          ),
        ),
      ),
    );
  }*/

  Widget _buildHeader(BuildContext context) {
    // 1. RÉCUPÉRATION DU USER VIA LE PROVIDER
    // "watch" permet de reconstruire ce widget si la photo change ailleurs dans l'app
    final userProvider = context.watch<UserProvider>();
    final userPhotoUrl = userProvider.user?.photoUrl;

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: const DecorationImage(
          image: AssetImage("assets/images/bus_header.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(30),
          ),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            stops: const [0.0, 0.5],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // --- PROFIL DYNAMIQUE ---
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        // 2. LOGIQUE D'AFFICHAGE CORRIGÉE
                        backgroundImage:
                            (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
                            ? NetworkImage(userPhotoUrl) as ImageProvider
                            : const AssetImage(
                                "assets/images/ci.jpg",
                              ), // Image par défaut
                      ),
                    ),

                    const Gap(10),

                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ma localisation",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              "assets/icons/pin.png",
                              width: 14,
                              height: 14,
                              color: AppColors.primary,
                            ),
                            const Gap(4),
                            const Text(
                              "Abidjan",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                // --- NOTIFICATION ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const NotificationScreen(),
                      ),
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
  }

  // Ajout de Context ici pour récupérer le thème
  Widget _buildRouteItem(
    BuildContext context, {
    required String origin,
    required String destination,
    required Color color,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade100;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor, // <--- FOND CARTE DYNAMIQUE
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 12, color: color),
          const Gap(15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    origin,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Icon(
                      Icons.arrow_right_alt,
                      size: 16,
                      color: isDark ? Colors.grey[400] : Colors.grey,
                    ),
                  ),
                  Text(
                    destination,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const Gap(2),
              Text(
                label,
                style: TextStyle(
                  color: isDark ? Colors.grey[500] : Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              // Adaptation du vert : shade50 en Light, Opacity en Dark
              color: isDark
                  ? Colors.green.withOpacity(0.2)
                  : Colors.green.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.circle, size: 6, color: Colors.green),
                const Gap(5),
                Text(
                  "Actif",
                  style: TextStyle(
                    color: isDark ? Colors.greenAccent[400] : Colors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
