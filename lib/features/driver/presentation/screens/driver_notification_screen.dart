import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';

const _kNavy = Color(0xFF0f172a);

class DriverNotificationScreen extends StatelessWidget {
  const DriverNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: _kNavy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18),
        ),
        actions: [
          Consumer<DriverProvider>(
            builder: (_, provider, __) {
              final unread =
                  provider.notifications.where((n) => !n.isRead).length;
              if (unread == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () {
                  for (final n in provider.notifications) {
                    if (!n.isRead) provider.markNotificationAsRead(n.id);
                  }
                },
                child: const Text(
                  'Tout lire',
                  style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<DriverProvider>(
        builder: (context, provider, _) {
          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return _buildEmpty();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: notifications.length,
            separatorBuilder: (_, __) => const Gap(8),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _NotificationCard(
                notification: notif,
                onTap: () {
                  if (!notif.isRead) {
                    provider.markNotificationAsRead(notif.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded,
                size: 48, color: AppColors.primary),
          ),
          const Gap(16),
          const Text(
            'Aucune notification',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B)),
          ),
          const Gap(6),
          Text(
            'Vous serez alerté ici de vos nouveaux voyages\net messages importants.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE NOTIFICATION
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final DriverNotification notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _typeColor(notification.type);
    final icon = _typeIcon(notification.type);

    final now = DateTime.now();
    final diff = now.difference(notification.timestamp);
    String timeLabel;
    if (diff.inMinutes < 1) {
      timeLabel = "À l'instant";
    } else if (diff.inHours < 1) {
      timeLabel = 'Il y a ${diff.inMinutes} min';
    } else if (notification.timestamp.day == now.day &&
        notification.timestamp.month == now.month &&
        notification.timestamp.year == now.year) {
      timeLabel =
          "Aujourd'hui ${DateFormat('HH:mm').format(notification.timestamp)}";
    } else if (diff.inDays == 1) {
      timeLabel =
          "Hier ${DateFormat('HH:mm').format(notification.timestamp)}";
    } else {
      timeLabel = DateFormat('dd MMM yyyy', 'fr_FR')
          .format(notification.timestamp);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead
              ? Colors.white
              : AppColors.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: notification.isRead
                ? const Color(0xFFE2E8F0)
                : AppColors.primary.withOpacity(0.15),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const Gap(12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead
                                ? FontWeight.w600
                                : FontWeight.w800,
                            fontSize: 14,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                      const Gap(8),
                      Text(
                        timeLabel,
                        style: TextStyle(
                          color: notification.isRead
                              ? Colors.grey[400]
                              : AppColors.primary.withOpacity(0.8),
                          fontSize: 11,
                          fontWeight: notification.isRead
                              ? FontWeight.normal
                              : FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const Gap(5),
                  Text(
                    notification.body,
                    style: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 13,
                        height: 1.4),
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const Gap(8),
              Container(
                margin: const EdgeInsets.only(top: 4),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'voyage_assigned':
        return Colors.blue;
      case 'voyage_cancelled':
        return Colors.red;
      case 'message':
        return AppColors.primary;
      case 'voyage_started':
        return const Color(0xFF10B981);
      case 'voyage_completed':
        return const Color(0xFF10B981);
      default:
        return Colors.grey;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'voyage_assigned':
        return Icons.directions_bus_rounded;
      case 'voyage_cancelled':
        return Icons.cancel_rounded;
      case 'message':
        return Icons.chat_bubble_outline_rounded;
      case 'voyage_started':
        return Icons.play_circle_outline_rounded;
      case 'voyage_completed':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }
}
