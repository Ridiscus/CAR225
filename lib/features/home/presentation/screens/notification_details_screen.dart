
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../booking/data/models/notification_model.dart';

class NotificationDetailScreen extends StatelessWidget {
  final NotificationModel notif;

  const NotificationDetailScreen({super.key, required this.notif});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(notif.title),
        elevation: 0.5,
        backgroundColor: Theme.of(context).cardColor,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
      ),
      body: Column(
        children: [
          const Gap(20),
          // Date centrée
          Center(
            child: Text(
              notif.fullDate, // Utilisation du helper dynamique
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
                CircleAvatar(
                  radius: 12,
                  backgroundColor: notif.color,
                  child: Icon(notif.icon, size: 12, color: Colors.white),
                ),
                const Gap(8),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE3F2FD),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(15),
                        topRight: Radius.circular(15),
                        bottomRight: Radius.circular(15),
                        bottomLeft: Radius.circular(0),
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
                        const Gap(10),
                        Text(
                          "ID: ${notif.id.split('-').first}...", // Petit détail technique style ticket
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

          // Zone de "réponse" factice
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(15),
              color: Theme.of(context).cardColor,
              child: Row(
                children: [
                  Icon(Icons.block, color: Colors.grey[400]),
                  const Gap(10),
                  Expanded(
                    child: Text(
                        "Ce message est une notification automatique.",
                        style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic, fontSize: 12)
                    ),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}