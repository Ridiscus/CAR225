import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class NotificationModel {
  final String id;
  final String title;
  final String description; // C'est le champ "message" de ton API
  final String type; // info, warning, success
  final DateTime createdAt;
  final DateTime? readAt;

  // Helpers UI
  final IconData icon;
  final Color color;
  final Color bgColor;

  NotificationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    this.readAt,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // 1. Extraction des données imbriquées dans "data"
    final content = json['data'] ?? {};
    final String msgType = content['type'] ?? 'info';

    // 2. Définition du style selon le type
    IconData iconData;
    Color iconColor;
    Color bg;

    switch (msgType) {
      case 'warning':
      case 'alert':
        iconData = Icons.warning_amber_rounded;
        iconColor = const Color(0xFFE65100); // Orange
        bg = const Color(0xFFFFF3E0);
        break;
      case 'success':
        iconData = Icons.check_circle_outline;
        iconColor = const Color(0xFF2E7D32); // Vert
        bg = const Color(0xFFE8F5E9);
        break;
      case 'security':
        iconData = Icons.security;
        iconColor = const Color(0xFFD32F2F); // Rouge
        bg = const Color(0xFFFFEBEE);
        break;
      case 'info':
      default:
        iconData = Icons.info_outline;
        iconColor = const Color(0xFF1565C0); // Bleu
        bg = const Color(0xFFE3F2FD);
        break;
    }

    return NotificationModel(
      id: json['id'],
      title: content['title'] ?? "Notification",
      description: content['message'] ?? "",
      type: msgType,
      createdAt: DateTime.tryParse(json['created_at']) ?? DateTime.now(),
      readAt: json['read_at'] != null ? DateTime.tryParse(json['read_at']) : null,
      icon: iconData,
      color: iconColor,
      bgColor: bg,
    );
  }

  // Helper pour le format "Il y a X temps"
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 7) {
      return DateFormat('dd/MM/yyyy').format(createdAt);
    } else if (diff.inDays >= 1) {
      return "IL Y A ${diff.inDays} JOUR${diff.inDays > 1 ? 'S' : ''}";
    } else if (diff.inHours >= 1) {
      return "IL Y A ${diff.inHours} H";
    } else if (diff.inMinutes >= 1) {
      return "IL Y A ${diff.inMinutes} MIN";
    } else {
      return "À L'INSTANT";
    }
  }

  // Helper pour la date détaillée
  String get fullDate => DateFormat('EEEE d MMM • HH:mm', 'fr_FR').format(createdAt);

  // Helper pour savoir si lu
  bool get isRead => readAt != null;
}