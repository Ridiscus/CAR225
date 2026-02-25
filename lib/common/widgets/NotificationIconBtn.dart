import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/providers/notification_provider.dart';
import '../../features/home/presentation/screens/notification_screen.dart';
// Importe ton provider et ton écran de notifs

class NotificationIconBtn extends StatelessWidget {
  const NotificationIconBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Navigation vers l'écran des notifs
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const NotificationScreen()),
        ).then((_) {
          // Au retour, on rafraîchit le compteur car l'utilisateur a peut-être lu des trucs
          context.read<NotificationProvider>().fetchUnreadCount();
        });
      },
      child: Stack(
        clipBehavior: Clip.none, // Permet au point rouge de dépasser un peu
        children: [
          // L'icône de base (ton design existant)
          Container(
            height: 45,
            width: 45,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Image.asset("assets/icons/notification.png", color: Colors.white),
          ),

          // Le Badge Rouge (Consommateur du Provider)
          Consumer<NotificationProvider>(
            builder: (context, notifProvider, child) {
              if (notifProvider.unreadCount == 0) return const SizedBox(); // Rien si 0

              return Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      notifProvider.unreadCount > 99 ? '99+' : '${notifProvider.unreadCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}