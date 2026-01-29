import 'package:car225/features/home/presentation/screens/profil_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'notification_screen.dart';

class MyTicketsTabScreen extends StatelessWidget {
  const MyTicketsTabScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

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
                  // --- 2. TITRE & SOUS-TITRE ---
                  Text(
                    "Mes Billets",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    "Retrouvez tous vos billets de voyage",
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                  const Gap(20),

                  // --- 3. STATISTIQUES ---
                  Row(
                    children: [
                      // On passe le context pour gérer les couleurs pastel en mode sombre
                      Expanded(child: _buildStatCard(context, "3", "Billets Total", Colors.orange)),
                      const Gap(10),
                      Expanded(child: _buildStatCard(context, "2", "Confirmés", Colors.green)),
                      const Gap(10),
                      Expanded(child: _buildStatCard(context, "1", "Terminé", Colors.red)),
                    ],
                  ),
                  const Gap(25),

                  // --- 4. LISTE DES BILLETS ---
                  _buildTicketCard(
                    context,
                    company: "Fabiola Transport",
                    route: "Bouaké ➝ Abidjan",
                    time: "08:00",
                    seat: "12 A",
                    date: "15 janvier 2026",
                    price: "12 000 F",
                    status: "Confirmé",
                    isDetailed: true,
                  ),
                  const Gap(20),
                  _buildTicketCard(
                    context,
                    company: "UTB",
                    route: "Abidjan ➝ Yamoussoukro",
                    time: "06:30",
                    seat: "48",
                    date: "23 janvier 2026",
                    price: "5 000 F",
                    status: "Confirmé",
                    isDetailed: false,
                  ),
                  const Gap(140),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

/*  Widget _buildHeader(BuildContext context) {
    // Variable pour simuler photo
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
            // Gradient légèrement plus foncé en haut pour la lisibilité de la status bar
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
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
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
                          MaterialPageRoute(builder: (context) => const ProfileScreen()),
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        // 2. LOGIQUE D'AFFICHAGE CORRIGÉE
                        backgroundImage: (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
                            ? NetworkImage(userPhotoUrl) as ImageProvider
                            : const AssetImage("assets/images/ci.jpg"), // Image par défaut
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
  }

  // J'ai changé la signature pour prendre la couleur de base au lieu de "shade50" direct
  Widget _buildStatCard(BuildContext context, String count, String label, MaterialColor baseColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // LOGIQUE COULEUR :
    // Light : On utilise shade50 (très clair)
    // Dark : On utilise la couleur de base avec une opacité faible (pour ne pas être fluo)
    final bgColor = isDark ? baseColor.withOpacity(0.15) : baseColor.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              // En dark mode, on peut éclaircir un peu la couleur du texte si nécessaire
              color: label == "Terminé" ? Colors.red : AppColors.primary
          )),
          const Gap(5),
          Text(
              label,
              style: TextStyle(
                  fontSize: 11,
                  color: isDark ? Colors.grey[300] : Colors.black54, // Texte label adapté
                  fontWeight: FontWeight.w500
              )
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, {
    required String company,
    required String route,
    required String time,
    required String seat,
    required String date,
    required String price,
    required String status,
    bool isDetailed = false,
  }) {
    // Variables de thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor; // Gris foncé ou blanc
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey;
    final buttonColor = isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade50;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor, // <--- FOND CARTE DYNAMIQUE
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), // Ombre plus forte en sombre
              blurRadius: 15,
              offset: const Offset(0, 5)
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(company, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  // Badge vert foncé en mode sombre pour lisibilité
                  color: isDark ? const Color(0xFF1B5E20) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                    status,
                    style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF2E7D32),
                        fontSize: 11,
                        fontWeight: FontWeight.bold
                    )
                ),
              ),
            ],
          ),
          const Gap(5),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(route, style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500)),
          ),

          if (isDetailed) ...[
            const Gap(15),
            Divider(color: borderColor, thickness: 1), // Divider discret
            const Gap(15),

            // Ligne Heure & Place
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: subTextColor),
                    const Gap(5),
                    Text(time, style: TextStyle(color: subTextColor, fontWeight: FontWeight.w500)),
                  ],
                ),
                RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14, color: textColor),
                    children: [
                      TextSpan(text: "Place: ", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                      TextSpan(text: seat, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(10),

            // Ligne Date & Prix
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(date, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: textColor)),
                Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
            const Gap(20),

            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.arrow_forward_ios, size: 12, color: textColor),
                    label: Text("Voir détails", style: TextStyle(color: textColor, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: buttonColor
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: Icon(Icons.near_me, size: 14, color: textColor),
                    label: Text("Localisation", style: TextStyle(color: textColor, fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: BorderSide(color: borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        backgroundColor: buttonColor
                    ),
                  ),
                ),
              ],
            ),
            const Gap(10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.download, size: 16, color: textColor),
                label: Text("Télécharger", style: TextStyle(color: textColor, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: buttonColor
                ),
              ),
            ),
          ]
        ],
      ),
    );
  }
}