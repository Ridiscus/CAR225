import 'package:car225/features/home/presentation/screens/profil_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/presentation/screens/CompanyDetailScreen.dart';
import 'notification_screen.dart';

class CompaniesTabScreen extends StatelessWidget {
  const CompaniesTabScreen({super.key});

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
                  // --- 2. TITRE ---
                  Text(
                    "Nos Compagnies",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    "6 partenaires de confiance",
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                  const Gap(20),

                  // --- 3. LISTE DES COMPAGNIES ---
                  _buildCompanyCard(
                    context,
                    name: "Robin transport",
                    slogan: "Transport rapide et confortable",
                    initials: "RT",
                    color: Colors.orange,
                    rating: "4.8",
                    reviewCount: "1240",
                    stat1: "15", label1: "Personnels",
                    stat2: "45", label2: "Car",
                    stat3: "28", label3: "Trajets",
                  ),
                  const Gap(15),
                  _buildCompanyCard(
                    context,
                    name: "Fabiola Transport",
                    slogan: "Luxe et confort premium",
                    initials: "FT",
                    color: const Color(0xFFD35400),
                    rating: "4.8",
                    reviewCount: "2150",
                    stat1: "15", label1: "Personnels",
                    stat2: "45", label2: "Car",
                    stat3: "28", label3: "Trajets",
                  ),
                  const Gap(15),
                  _buildCompanyCard(
                    context,
                    name: "AVS",
                    slogan: "Transport rapide et confortable",
                    initials: "AVS",
                    color: Colors.redAccent,
                    rating: "4.8",
                    reviewCount: "1240",
                    stat1: "30", label1: "Années",
                    stat2: "56", label2: "Car",
                    stat3: "33", label3: "Trajets",
                  ),
                  const Gap(15),
                  _buildCompanyCard(
                    context,
                    name: "UTB",
                    slogan: "Leader du transport urbain",
                    initials: "UTB",
                    color: Colors.orangeAccent,
                    rating: "4.8",
                    reviewCount: "1890",
                    stat1: "45", label1: "Années",
                    stat2: "75", label2: "Car",
                    stat3: "42", label3: "Trajets",
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

  // --- WIDGETS ---

  /*Widget _buildHeader(BuildContext context) {
    // Simulation
    String? userPhotoUrl;
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
            colors: [Colors.black.withOpacity(0.7), Colors.transparent], // Un peu plus sombre en haut
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



  Widget _buildCompanyCard(BuildContext context, {
    required String name,
    required String slogan,
    required String initials,
    required Color color,
    required String rating,
    required String reviewCount,
    required String stat1, required String label1,
    required String stat2, required String label2,
    required String stat3, required String label3,
  }) {
    // Variables de thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor, // <--- FOND CARTE
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    Text(slogan, style: TextStyle(color: subTextColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
            ],
          ),
          const Gap(10),

          Row(
            children: [
              Row(
                children: List.generate(4, (index) => const Icon(Icons.star, color: Colors.amber, size: 16))
                  ..add(const Icon(Icons.star_border, color: Colors.amber, size: 16)),
              ),
              const Gap(8),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: textColor, fontSize: 12),
                  children: [
                    TextSpan(text: rating, style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " ($reviewCount avis)", style: TextStyle(color: subTextColor)),
                  ],
                ),
              )
            ],
          ),
          const Gap(15),

          Row(
            children: [
              Expanded(child: _buildStatItem(context, stat1, label1)),
              const Gap(10),
              Expanded(child: _buildStatItem(context, stat2, label2)),
              const Gap(10),
              Expanded(child: _buildStatItem(context, stat3, label3)),
            ],
          ),
          const Gap(15),

          Row(
            children: [
              // Adaptation des tags pour qu'ils ne soient pas fluos en mode sombre
              _buildTag(context, "Moderne", Colors.orange),
              const Gap(8),
              _buildTag(context, "Fiable", Colors.green),
              const Gap(8),
              _buildTag(context, "Certifiée", Colors.orange),
            ],
          ),
          const Gap(15),

          // 5. Bouton "Voir les trajets"
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyDetailScreen(companyName: name),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                // Fond légèrement blanc en mode sombre, blanc pur en clair
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black, // Texte
                elevation: 0,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Voir les trajets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }

  // Ajout Context pour thème
  Widget _buildStatItem(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        // Fond gris foncé ou gris très clair
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey[400] : Colors.black54
              )
          ),
          const Gap(2),
          Text(
              value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black
              )
          ),
        ],
      ),
    );
  }

  // Modifié pour prendre la couleur de base et calculer l'opacité
  Widget _buildTag(BuildContext context, String text, MaterialColor color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // En mode sombre, opacité faible. En mode clair, shade50
          color: isDark ? color.withOpacity(0.15) : color.shade50,
          borderRadius: BorderRadius.circular(5)
      ),
      child: Text(
          text,
          style: TextStyle(
              color: color, // La couleur du texte reste vive
              fontSize: 10,
              fontWeight: FontWeight.bold
          )
      ),
    );
  }
}