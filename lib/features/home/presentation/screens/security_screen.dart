import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'change_password_screen.dart';
import 'connect_device_screen.dart';

class SecurityScreen extends StatelessWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. THEME VARIABLES ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        title: Text(
          "Sécurité",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(
          context,
        ).appBarTheme.backgroundColor, // Transparent ou surface
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), // Flèche retour dynamique
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // 1. Navigation vers Changer Mot de passe
          _buildSecurityOption(
            context,
            icon: Icons.lock_outline,
            title: "Changer le mot de passe",
            subtitle: "Dernière modif. il y a 3 mois",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChangePasswordScreen(),
                ),
              );
            },
          ),
          const Gap(10),

          // 2. Switch Biométrique
          _buildSecurityOption(
            context,
            icon: Icons.fingerprint,
            title: "Authentification Biométrique",
            subtitle: "Activé",
            isSwitch: true,
          ),
          const Gap(10),

          // 3. Navigation vers Appareils Connectés
          _buildSecurityOption(
            context,
            icon: Icons.devices,
            title: "Appareils connectés",
            subtitle: "iPhone 13, Samsung S21",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ConnectedDevicesScreen(),
                ),
              );
            },
          ),

          const Gap(40),

          // Zone Danger (Le rouge reste rouge, c'est universel)
          const Text(
            "Zone Danger",
            style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
          ),
          const Gap(10),
          Container(
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(
                isDark ? 0.1 : 0.05,
              ), // Un peu plus opaque en sombre pour être visible
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text(
                "Supprimer mon compte",
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () {
                // Logique suppression
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    bool isSwitch = false,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subtitleColor = isDark ? Colors.grey[400] : Colors.grey;

    return Container(
      decoration: BoxDecoration(
        color: cardColor, // <--- FOND DYNAMIQUE
        borderRadius: BorderRadius.circular(15),
        // Optionnel : petite bordure subtile en mode sombre pour délimiter
        border: isDark ? Border.all(color: Colors.white10) : null,
      ),
      child: ListTile(
        onTap: isSwitch ? null : onTap,
        leading: Icon(icon, color: textColor), // <--- ICONE DYNAMIQUE
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: subtitleColor),
        ),
        trailing: isSwitch
            ? Switch(
                value: true,
                activeThumbColor: Colors.green,
                // Couleur de la track (barre) du switch quand inactif ou actif
                trackColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected))
                    return Colors.green.withOpacity(0.4);
                  return isDark ? Colors.grey[700] : Colors.grey[300];
                }),
                onChanged: (v) {},
              )
            : Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: isDark ? Colors.grey[600] : Colors.grey,
              ),
      ),
    );
  }
}
