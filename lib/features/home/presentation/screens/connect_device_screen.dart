/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ConnectedDevicesScreen extends StatelessWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- 1. THEME VARIABLES ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        title: Text(
            "Appareils connectés",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // Transparent ou surface
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Illustration Header
          Center(
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1), // Reste vert clair, ça passe bien en dark mode
                  shape: BoxShape.circle
              ),
              child: const Icon(Icons.devices_other, size: 50, color: Colors.green),
            ),
          ),
          const Gap(20),

          Text(
            "Vous êtes connecté sur ces appareils. Si vous ne reconnaissez pas un appareil, déconnectez-le immédiatement.",
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryTextColor, height: 1.5),
          ),
          const Gap(30),

          // Section 1
          Text(
              "Appareil actuel",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
          ),
          const Gap(10),
          _buildDeviceTile(context, "iPhone 13 Pro", "Abidjan, Côte d'Ivoire • En ligne", Icons.phone_iphone, isCurrent: true),

          const Gap(25),

          // Section 2
          Text(
              "Autres appareils",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
          ),
          const Gap(10),
          _buildDeviceTile(context, "Samsung Galaxy S21", "Bouaké, Côte d'Ivoire • Il y a 2h", Icons.android, isCurrent: false),
          const Gap(10),
          _buildDeviceTile(context, "Chrome sur Windows", "Yamoussoukro • Il y a 5 jours", Icons.laptop_mac, isCurrent: false),

          const Gap(40),

          // Bouton tout déconnecter
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                // Couleur de l'effet de vague au clic
                foregroundColor: Colors.green,
              ),
              child: const Text(
                  "Déconnecter tous les autres appareils",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(BuildContext context, String name, String info, IconData icon, {bool isCurrent = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // Logique des bordures :
    // - Si c'est l'appareil actuel : Vert (Highlight)
    // - Sinon et si mode sombre : Gris très foncé subtil (pour séparer du fond noir)
    // - Sinon (mode clair) : Rien (le fond blanc suffit)
    Border? border;
    if (isCurrent) {
      border = Border.all(color: Colors.green, width: 1.5);
    } else if (isDark) {
      border = Border.all(color: Colors.grey[800]!);
    } else {
      border = null;
    }

    // Couleur des icônes et infos secondaires
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey;

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor, // <--- FOND DYNAMIQUE
        borderRadius: BorderRadius.circular(15),
        border: border,
      ),
      child: Row(
        children: [
          Icon(
              icon,
              size: 30,
              color: isCurrent ? Colors.green : secondaryColor
          ),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)
                ),
                const Gap(4),
                Text(
                    info,
                    style: TextStyle(
                        fontSize: 12,
                        color: isCurrent ? Colors.green : secondaryColor
                    )
                ),
              ],
            ),
          ),
          if (!isCurrent)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent),
              onPressed: () {
                // Logique pour déconnecter cet appareil spécifique
              },
            )
        ],
      ),
    );
  }
}*/




import 'dart:io'; // Pour détecter la plateforme (Platform.isAndroid...)
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

// Assure-toi que le chemin d'import est correct selon ton projet
import '../../../../core/services/device/device_service.dart';

class ConnectedDevicesScreen extends StatefulWidget {
  const ConnectedDevicesScreen({super.key});

  @override
  State<ConnectedDevicesScreen> createState() => _ConnectedDevicesScreenState();
}

class _ConnectedDevicesScreenState extends State<ConnectedDevicesScreen> {
  // Variables d'état
  String _currentDeviceName = "Chargement...";
  bool _isLoading = true;
  IconData _currentDeviceIcon = Icons.smartphone; // Icone par défaut

  @override
  void initState() {
    super.initState();
    _loadCurrentDeviceInfo();
  }

  // Fonction pour récupérer les infos réelles du téléphone
  Future<void> _loadCurrentDeviceInfo() async {
    final deviceService = DeviceService();

    try {
      final deviceData = await deviceService.getDeviceInfo();

      // On détecte la plateforme pour choisir l'icône
      IconData icon = Icons.smartphone;
      if (Platform.isAndroid) icon = Icons.android;
      if (Platform.isIOS) icon = Icons.phone_iphone;

      if (mounted) {
        setState(() {
          // 'model' est la clé qu'on avait définie dans DeviceService
          _currentDeviceName = deviceData['model'] ?? "Appareil Inconnu";
          _currentDeviceIcon = icon;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentDeviceName = "Appareil inconnu";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- THEME VARIABLES ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
            "Appareils connectés",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Illustration Header
          Center(
            child: Container(
              height: 100,
              width: 100,
              decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  shape: BoxShape.circle
              ),
              child: const Icon(Icons.devices_other, size: 50, color: Colors.green),
            ),
          ),
          const Gap(20),

          Text(
            "Vous êtes connecté sur ces appareils. Si vous ne reconnaissez pas un appareil, déconnectez-le immédiatement.",
            textAlign: TextAlign.center,
            style: TextStyle(color: secondaryTextColor, height: 1.5),
          ),
          const Gap(30),

          // --- SECTION 1 : APPAREIL ACTUEL (DYNAMIQUE) ---
          Text(
              "Appareil actuel",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
          ),
          const Gap(10),

          _buildDeviceTile(
              context,
              _currentDeviceName, // <--- Nom récupéré via DeviceService
              "En ligne maintenant", // <--- Statut
              _currentDeviceIcon, // <--- Icone selon la plateforme
              isCurrent: true
          ),

          const Gap(25),

          // --- SECTION 2 : AUTRES APPAREILS (STATIQUE POUR L'INSTANT) ---
          // TODO: Pour rendre ça dynamique, il faut une API Backend qui renvoie la liste des sessions actives (ex: GET /sessions)
          Text(
              "Autres sessions récentes",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
          ),
          const Gap(10),

          // Exemples statiques (tu peux les retirer si tu préfères ne rien afficher)
          _buildDeviceTile(context, "Chrome sur Windows", "Il y a 2 jours", Icons.laptop_windows, isCurrent: false),
          const Gap(10),

          const Gap(40),

          // Bouton tout déconnecter
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Appeler API logout_all
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                foregroundColor: Colors.green,
              ),
              child: const Text(
                  "Déconnecter tous les autres appareils",
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceTile(BuildContext context, String name, String info, IconData icon, {bool isCurrent = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryColor = isDark ? Colors.grey[400] : Colors.grey;

    Border? border;
    if (isCurrent) {
      border = Border.all(color: Colors.green, width: 1.5);
    } else if (isDark) {
      border = Border.all(color: Colors.grey[800]!);
    } else {
      border = null; // Pas de bordure en mode clair pour les items non sélectionnés
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          border: border,
          boxShadow: isCurrent ? [] : [
            // Légère ombre pour les autres items en mode clair
            if(!isDark) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0,2))
          ]
      ),
      child: Row(
        children: [
          Icon(
              icon,
              size: 30,
              color: isCurrent ? Colors.green : secondaryColor
          ),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    name,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor)
                ),
                const Gap(4),
                Text(
                    info,
                    style: TextStyle(
                        fontSize: 12,
                        color: isCurrent ? Colors.green : secondaryColor
                    )
                ),
              ],
            ),
          ),
          // Bouton suppression (ne s'affiche pas pour l'appareil actuel)
          if (!isCurrent)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.redAccent, size: 20),
              onPressed: () {
                // Logique déconnexion
              },
            )
        ],
      ),
    );
  }
}