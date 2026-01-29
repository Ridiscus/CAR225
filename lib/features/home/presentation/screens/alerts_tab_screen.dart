import 'package:car225/features/home/presentation/screens/profil_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'alert_detail_screen.dart';
import 'notification_screen.dart';

class AlertsTabScreen extends StatelessWidget {
  const AlertsTabScreen({super.key});

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
          children: [
            // --- 1. HEADER ---
            _buildHeader(context),

            // --- 2. CONTENU ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Demande d'aide",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    "Signalez un problème pendant votre trajet",
                    style: TextStyle(color: secondaryTextColor, fontSize: 13),
                  ),
                  const Gap(20),

                  // Liste des options d'alerte
                  _buildAlertOption(
                    context,
                    title: "Accident",
                    subtitle: "Cliquez pour signaler ce problème",
                    iconPath: "assets/icons/accident.png",
                    color: Colors.red,
                    // Note : bgColor sera géré dynamiquement dans la méthode
                  ),
                  const Gap(15),
                  _buildAlertOption(
                    context,
                    title: "Problème chauffeur",
                    subtitle: "Comportement, conduite dangereuse...",
                    iconPath: "assets/icons/driver_alert.png",
                    color: Colors.orange,
                  ),
                  const Gap(15),
                  _buildAlertOption(
                    context,
                    title: "Problème véhicule",
                    subtitle: "Panne, climatisation, confort...",
                    iconPath: "assets/icons/bus_issue.png",
                    color: Colors.blue,
                  ),
                  const Gap(15),
                  _buildAlertOption(
                    context,
                    title: "Retard",
                    subtitle: "Départ ou arrivée tardive",
                    iconPath: "assets/icons/time_alert.png",
                    color: Colors.amber.shade700,
                  ),
                  const Gap(15),
                  _buildAlertOption(
                    context,
                    title: "Problème d'itinéraire",
                    subtitle: "Trajet inhabituel ou détour",
                    iconPath: "assets/icons/map_alert.png",
                    color: Colors.green,
                  ),
                  const Gap(15),
                  _buildAlertOption(
                    context,
                    title: "Autre",
                    subtitle: "Autre type de problème",
                    iconPath: "assets/icons/chat.png",
                    color: isDark ? Colors.grey : Colors.grey.shade700, // Ajustement gris
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

  // J'ai retiré 'bgColor' des arguments obligatoires pour le calculer dynamiquement
  // selon le mode sombre/clair à l'intérieur du widget.
  Widget _buildAlertOption(BuildContext context, {
    required String title,
    required String subtitle,
    required String iconPath,
    required Color color,
  }) {
    // Variables de thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.grey[500] : Colors.grey;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade100;

    // Logique couleur de fond de l'icône :
    // Dark Mode : Opacité (Transparence)
    // Light Mode : Shade50 (Pastel)
    // Cas spécial pour le gris qui n'a pas de shade50 propre parfois
    final iconBgColor = isDark
        ? color.withOpacity(0.15)
        : (color is MaterialColor ? color.shade50 : color.withOpacity(0.1));

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlertDetailScreen(alertType: title, alertColor: color, iconPath: iconPath),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: cardColor, // <--- FOND CARTE
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4)
            )
          ],
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Container(
              height: 50, width: 50,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor, // Couleur calculée
                borderRadius: BorderRadius.circular(15),
              ),
              child: Image.asset(iconPath, color: color),
            ),
            const Gap(15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                  const Gap(2),
                  Text(subtitle, style: TextStyle(color: subtitleColor, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: isDark ? Colors.grey[600] : Colors.grey.shade300)
          ],
        ),
      ),
    );
  }

  /*Widget _buildHeader(BuildContext context) {
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
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
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

                // --- NOTIFICATION (Icone Warning ici) ---
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
                      "assets/icons/notification.png", // Icone spécifique à cet écran
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


}