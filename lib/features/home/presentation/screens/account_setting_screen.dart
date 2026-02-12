/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

// --- IMPORTS ARCHITECTURE ---
import '../../../../core/services/theme_provider.dart';

// --- IMPORTS ECRANS ---
import '../../../../core/theme/app_colors.dart';
import 'faq_screen.dart';
import 'privacy_policy_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  // État local pour les notifs (simulé pour l'instant)
  bool _notifPush = true;
  String _currentLanguage = "Français";

  @override
  Widget build(BuildContext context) {
    // 1. On récupère le ThemeProvider pour écouter les changements
    final themeProvider = Provider.of<ThemeProvider>(context);

    // 2. On récupère les couleurs du thème actuel pour l'UI
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor; // Blanc ou Gris Foncé
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      // La couleur de fond est gérée par le Theme (AppTheme.lightTheme / darkTheme)
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        title: Text(
            "Paramètres",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),

      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- SECTION NOTIFICATIONS ---
          _sectionTitle("Notifications"),
          _buildSwitch(
            context: context,
            title: "Notifications Push",
            subtitle: "Recevoir les alertes trajets",
            value: _notifPush,
            onChanged: (v) => setState(() => _notifPush = v),
          ),

          const Gap(20),

          // --- SECTION APPARENCE ---
          _sectionTitle("Apparence & Affichage"),

          // Switch Mode Sombre relié au Provider
          _buildSwitch(
            context: context,
            title: "Mode Sombre",
            subtitle: "Thème nuit pour l'application",
            value: themeProvider.isDarkMode, // Valeur globale venant du Provider
            onChanged: (v) => themeProvider.toggleTheme(v), // Action globale
          ),

          _buildActionTile(
            context: context,
            title: "Langue",
            subtitle: _currentLanguage,
            icon: Icons.language,
            onTap: () => _showLanguageSelector(context),
          ),

          _buildActionTile(
            context: context,
            title: "Taille de la police",
            subtitle: themeProvider.currentFontSizeName, // Affiche "Petite", "Moyenne" ou "Grande"
            icon: Icons.format_size,
            onTap: () => _showFontSizeSelector(context, themeProvider),
          ),

          const Gap(20),

          // --- SECTION SUPPORT ---
          _sectionTitle("Support & Informations"),
          _buildActionTile(
            context: context,
            title: "FAQ / Aide",
            icon: Icons.help_outline,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen()));
            },
          ),

          _buildActionTile(
            context: context,
            title: "Politique de confidentialité",
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
            },
          ),
        ],
      ),
    );
  }

  // --- POP-UPS (MODALS) ---

  // 1. Sélecteur de Langue
  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor, // Fond adaptatif
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choisir la langue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(15),
              _buildRadioItem("Français", _currentLanguage, (val) => setState(() => _currentLanguage = val!)),
              _buildRadioItem("English", _currentLanguage, (val) => setState(() => _currentLanguage = val!)),
            ],
          ),
        );
      },
    );
  }

  // 2. Sélecteur de Police (Relié au Provider)
  void _showFontSizeSelector(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text("Taille de la police"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Petite", "Moyenne", "Grande"].map((size) {
              return RadioListTile<String>(
                title: Text(size),
                value: size,
                groupValue: provider.currentFontSizeName,
                activeColor: AppColors.primary, // Orange
                onChanged: (value) {
                  // Appel au Provider pour changer la taille partout
                  provider.setFontSize(value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  // --- WIDGETS REUTILISABLES (Adaptés Dark Mode) ---

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSwitch({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Couleur adaptative (Blanc ou Gris foncé)
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        activeColor: AppColors.primary, // Orange Car225
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    required VoidCallback onTap
  }) {
    // Couleur d'icône adaptative
    final iconColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor, // Couleur adaptative
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: icon != null ? Icon(icon, color: iconColor) : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13))
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildRadioItem(String title, String groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title),
      value: title,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        onChanged(value);
        Navigator.pop(context);
      },
    );
  }
}*/





import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

// --- IMPORTS ARCHITECTURE ---
import '../../../../core/services/notifications/notification_prefs.dart';
import '../../../../core/services/notifications/push_notification_service.dart';
import '../../../../core/services/theme_provider.dart';


// --- IMPORTS ECRANS ---
import '../../../../core/theme/app_colors.dart';
import 'faq_screen.dart';
import 'privacy_policy_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> with WidgetsBindingObserver {
  // État local
  bool _notifPush = false; // Par défaut false en attendant le chargement
  String _currentLanguage = "Français";

  // Instance du service
  final NotificationPrefs _notifService = NotificationPrefs();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Pour détecter le retour des paramètres
    _loadNotificationState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Si l'utilisateur revient des Paramètres système, on revérifie
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadNotificationState();
    }
  }

  // 1. Charger l'état sauvegardé
  Future<void> _loadNotificationState() async {
    bool status = await _notifService.getNotificationStatus();
    if (mounted) {
      setState(() {
        _notifPush = status;
      });
    }
  }


  Future<void> _toggleNotifications(bool value) async {
    setState(() => _notifPush = value);

    if (value) {
      // Si l'utilisateur active, on relance l'init pour être sûr d'avoir la permission
      await PushNotificationService().init();
      // Si l'utilisateur refuse dans la pop-up système, le service gérera l'affichage console,
      // mais idéalement on devrait vérifier le statut ici.
    } else {
      // Pour désactiver : Firebase permet de deleteToken() mais c'est radical.
      // Souvent on gère ça côté backend ou on enregistre juste la préférence locale
      // pour ne pas afficher la notif locale.
      FirebaseMessaging.instance.deleteToken(); // Optionnel : ne reçoit plus rien
    }
  }





  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
            "Paramètres",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- SECTION NOTIFICATIONS ---
          _sectionTitle("Notifications"),

          // ✅ Switch avec logique réelle
          _buildSwitch(
            context: context,
            title: "Notifications Push",
            subtitle: _notifPush ? "Activé" : "Désactivé",
            value: _notifPush,
            onChanged: _toggleNotifications, // Appel de notre fonction
          ),

          const Gap(20),

          // --- SECTION APPARENCE (Reste inchangée) ---
          _sectionTitle("Apparence & Affichage"),

          _buildSwitch(
            context: context,
            title: "Mode Sombre",
            subtitle: "Thème nuit pour l'application",
            value: themeProvider.isDarkMode,
            onChanged: (v) => themeProvider.toggleTheme(v),
          ),

          _buildActionTile(
            context: context,
            title: "Langue",
            subtitle: _currentLanguage,
            icon: Icons.language,
            onTap: () => _showLanguageSelector(context),
          ),

          _buildActionTile(
            context: context,
            title: "Taille de la police",
            subtitle: themeProvider.currentFontSizeName,
            icon: Icons.format_size,
            onTap: () => _showFontSizeSelector(context, themeProvider),
          ),

          const Gap(20),

          // --- SECTION SUPPORT ---
          _sectionTitle("Support & Informations"),
          _buildActionTile(
            context: context,
            title: "FAQ / Aide",
            icon: Icons.help_outline,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const FaqScreen()));
            },
          ),

          _buildActionTile(
            context: context,
            title: "Politique de confidentialité",
            icon: Icons.privacy_tip_outlined,
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()));
            },
          ),
        ],
      ),
    );
  }

  // --- WIDGETS ET MODALS (Identiques à ton code précédent) ---

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Choisir la langue", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const Gap(15),
              _buildRadioItem("Français", _currentLanguage, (val) => setState(() => _currentLanguage = val!)),
              _buildRadioItem("English", _currentLanguage, (val) => setState(() => _currentLanguage = val!)),
            ],
          ),
        );
      },
    );
  }

  void _showFontSizeSelector(BuildContext context, ThemeProvider provider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).cardColor,
          title: const Text("Taille de la police"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ["Petite", "Moyenne", "Grande"].map((size) {
              return RadioListTile<String>(
                title: Text(size),
                value: size,
                groupValue: provider.currentFontSizeName,
                activeColor: AppColors.primary,
                onChanged: (value) {
                  provider.setFontSize(value!);
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 5),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
      ),
    );
  }

  Widget _buildSwitch({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: SwitchListTile(
        activeColor: AppColors.primary,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        value: value,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required String title,
    String? subtitle,
    IconData? icon,
    required VoidCallback onTap
  }) {
    final iconColor = Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        onTap: onTap,
        leading: icon != null ? Icon(icon, color: iconColor) : null,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13))
            : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildRadioItem(String title, String groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(title),
      value: title,
      groupValue: groupValue,
      activeColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
      onChanged: (value) {
        onChanged(value);
        Navigator.pop(context);
      },
    );
  }
}