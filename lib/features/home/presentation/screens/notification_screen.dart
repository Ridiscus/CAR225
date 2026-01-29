import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

// --- MODÈLE DE DONNÉES (Pour simuler tes notifs) ---
class NotificationModel {
  final String title;
  final String description;
  final String date;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String timeAgo;

  NotificationModel({
    required this.title,
    required this.description,
    required this.date,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.timeAgo,
  });
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  // Données factices basées sur ton image notif1.png
  final List<NotificationModel> notifications = [
    NotificationModel(
      title: "Voyage confirmé",
      description: "Votre billet pour Yamoussoukro est prêt. Bon voyage avec UTB.",
      date: "Mardi 20 janv. • 14:52",
      icon: Icons.confirmation_number_outlined,
      color: const Color(0xFF2E7D32), // Vert
      bgColor: const Color(0xFFE8F5E9),
      timeAgo: "À L'INSTANT",
    ),
    NotificationModel(
      title: "Offre Spéciale Assinie",
      description: "Profitez de -20% sur tous les trajets vers Assinie ce weekend.",
      date: "Lundi 19 janv. • 09:30",
      icon: Icons.flash_on,
      color: const Color(0xFFE65100), // Orange
      bgColor: const Color(0xFFFFF3E0),
      timeAgo: "À L'INSTANT",
    ),
    NotificationModel(
      title: "Sécurité du compte",
      description: "Votre mot de passe a été modifié avec succès.",
      date: "Dimanche 18 janv. • 18:00",
      icon: Icons.security,
      color: const Color(0xFF1565C0), // Bleu
      bgColor: const Color(0xFFE3F2FD),
      timeAgo: "HIER",
    ),
    NotificationModel(
      title: "N'oubliez pas !",
      description: "Départ imminent dans 4h pour votre trajet Abidjan-Bouaké.",
      date: "Samedi 17 janv. • 10:15",
      icon: Icons.access_time_filled,
      color: const Color(0xFF7B1FA2), // Violet
      bgColor: const Color(0xFFF3E5F5),
      timeAgo: "IL Y A DEUX JOURS",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: bgColor,
      // --- HEADER TYPE MESSAGERIE (Xiaomi/Android) ---
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Notifications",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Photo de profil clicable (Style WhatsApp)
          GestureDetector(
            onTap: () => _showProfileDialog(context),
            child: const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Hero(
                tag: "profile_pic",
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: AssetImage("assets/images/user_avatar.png"), // Remplace par ton image
                  // Si pas d'image, mettre un backgroundColor et une lettre
                  backgroundColor: Colors.orange,
                  child: Text("K", style: TextStyle(color: Colors.white)),
                ),
              ),
            ),
          )
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: notifications.length,
        separatorBuilder: (context, index) => const Gap(15),
        itemBuilder: (context, index) {
          final notif = notifications[index];
          return _buildNotificationCard(context, notif);
        },
      ),
    );
  }

  // --- WIDGET : CARTE NOTIFICATION (Liste) ---
  Widget _buildNotificationCard(BuildContext context, NotificationModel notif) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Navigation vers le détail style "SMS"
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NotificationDetailScreen(notif: notif)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          // Bordure fine à gauche comme sur notif1 (optionnel)
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône avec fond coloré
            Container(
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                color: notif.bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(notif.icon, color: notif.color, size: 24),
            ),
            const Gap(15),
            // Textes
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        notif.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        notif.timeAgo,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Gap(5),
                  Text(
                    notif.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- LOGIQUE : POPUP PROFIL (Style WhatsApp) ---
  void _showProfileDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Hero(
                tag: "profile_pic",
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage("assets/images/user_avatar.png"), // Ton image
                      fit: BoxFit.cover,
                    ),
                    color: Colors.orange, // Fallback color
                  ),
                ),
              ),
              // Optionnel : Icones d'action en dessous comme WhatsApp
              Container(
                color: Colors.white,
                width: 250,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    Icon(Icons.message, color: Colors.green),
                    Icon(Icons.info_outline, color: Colors.green),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// --- ÉCRAN DÉTAIL : STYLE SMS (Bulle de conversation) ---
class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notif;

  const NotificationDetailScreen({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F5), // Fond gris clair comme SMS
      appBar: AppBar(
        title: Text(notif.title), // Nom de l'expéditeur
        elevation: 0.5,
        backgroundColor: Theme.of(context).cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 15),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.orange, // Couleur Avatar
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          const Gap(20),
          // Date centrée
          Center(
            child: Text(
              notif.date,
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ),
          const Gap(20),

          // --- BULLE SMS ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar Expéditeur (Optionnel, comme sur les groupes)
                CircleAvatar(
                  radius: 12,
                  backgroundColor: notif.color,
                  child: Icon(notif.icon, size: 12, color: Colors.white),
                ),
                const Gap(8),

                // La Bulle
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE3F2FD), // Bleu très clair ou Gris sombre
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                        bottomLeft: Radius.circular(0), // Coin carré en bas à gauche
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.description,
                          style: TextStyle(
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const Gap(5),
                        // Petit label de sécurité ou signature
                        Text(
                          "Envoyé automatiquement par le système",
                          style: TextStyle(fontSize: 10, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),
          // Zone de réponse (Désactivée ou "Lecture seule" pour une notif)
          Container(
            padding: const EdgeInsets.all(15),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: Colors.grey[400]),
                const Gap(10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text("Ne pas répondre à ce message", style: TextStyle(color: Colors.grey[500])),
                  ),
                ),
                const Gap(10),
                Icon(Icons.send, color: Colors.grey[400]),
              ],
            ),
          )
        ],
      ),
    );
  }
}