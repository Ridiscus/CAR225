import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/driver_message_model.dart';

const _kNavy = Color(0xFF0f172a);

class DriverMessagesScreen extends StatefulWidget {
  const DriverMessagesScreen({super.key});

  @override
  State<DriverMessagesScreen> createState() => _DriverMessagesScreenState();
}

class _DriverMessagesScreenState extends State<DriverMessagesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadMessages();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: Column(
        children: [
          _MessagesHeader(unreadCount: provider.unreadMessagesCount),
          Expanded(
            child: provider.isLoadingMessages && provider.messages.isEmpty
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary))
                : provider.messages.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () => provider.loadMessages(),
                        child: ListView.builder(
                          padding:
                              const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: provider.messages.length,
                          itemBuilder: (_, i) => _MessageCard(
                            message: provider.messages[i],
                            onTap: () =>
                                _showDetail(provider.messages[i], provider),
                          ),
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () => _showNewMessage(context, provider),
        child: const Icon(Icons.edit_rounded, color: Colors.white),
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
            child: Icon(Icons.mail_outline_rounded,
                size: 48, color: Colors.grey[300]),
          ),
          const Gap(16),
          const Text('Aucun message',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const Gap(6),
          Text(
            'Vous recevrez ici les messages de la gare.',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _showDetail(DriverMessageModel msg, DriverProvider provider) {
    if (!msg.isRead) provider.markMessageAsRead(msg);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MessageDetailSheet(message: msg),
    );
  }

  void _showNewMessage(BuildContext context, DriverProvider provider) {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Poignée ──
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
                const Text('Nouveau message',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Gap(16),
                TextField(
                  controller: subjectCtrl,
                  decoration: InputDecoration(
                    labelText: 'Objet',
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const Gap(12),
                TextField(
                  controller: messageCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: const Color(0xFFF1F5F9),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const Gap(16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final s = subjectCtrl.text.trim();
                      final m = messageCtrl.text.trim();
                      if (s.isEmpty || m.isEmpty) return;
                      final ok = await provider.sendMessage(s, m);
                      if (ctx.mounted) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(ok
                                ? 'Message envoyé !'
                                : 'Erreur lors de l\'envoi'),
                            backgroundColor:
                                ok ? AppColors.secondary : Colors.red,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.send_rounded,
                        color: Colors.white),
                    label: const Text('ENVOYER',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EN-TÊTE
// ─────────────────────────────────────────────────────────────────────────────
class _MessagesHeader extends StatelessWidget {
  final int unreadCount;

  const _MessagesHeader({required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _kNavy,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Row(
        children: [
          const Icon(Icons.chat_bubble_outline_rounded,
              color: AppColors.primary, size: 22),
          const Gap(10),
          const Text(
            'Messages',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (unreadCount > 0) ...[
            const Gap(10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$unreadCount non lus',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE MESSAGE
// ─────────────────────────────────────────────────────────────────────────────
class _MessageCard extends StatelessWidget {
  final DriverMessageModel message;
  final VoidCallback onTap;

  const _MessageCard({required this.message, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final srcColor = _sourceColor(message.senderType);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: message.isRead
              ? Colors.white
              : AppColors.primary.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: message.isRead
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Badge source
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: srcColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: srcColor.withOpacity(0.25)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_sourceIcon(message.senderType),
                          size: 11, color: srcColor),
                      const SizedBox(width: 4),
                      Text(
                        message.senderType.toUpperCase(),
                        style: TextStyle(
                          color: srcColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDate(message.createdAt),
                  style: TextStyle(
                    color: message.isRead
                        ? Colors.grey[400]
                        : AppColors.primary.withOpacity(0.8),
                    fontSize: 11,
                    fontWeight: message.isRead
                        ? FontWeight.normal
                        : FontWeight.w600,
                  ),
                ),
                if (!message.isRead) ...[
                  const SizedBox(width: 8),
                  Container(
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
            const Gap(10),
            Text(
              message.subject,
              style: TextStyle(
                fontWeight:
                    message.isRead ? FontWeight.w600 : FontWeight.w800,
                fontSize: 15,
                color: const Color(0xFF1E293B),
              ),
            ),
            const Gap(5),
            Text(
              message.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _sourceColor(String type) {
    switch (type.toLowerCase()) {
      case 'gare':
        return const Color(0xFFFF9800);
      case 'compagnie':
      case 'admin':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _sourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'gare':
        return Icons.directions_bus_rounded;
      case 'compagnie':
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.settings_suggest_rounded;
    }
  }

  String _formatDate(DateTime date) {
    try {
      final now = DateTime.now();
      final diff = now.difference(date);
      if (date.day == now.day &&
          date.month == now.month &&
          date.year == now.year) {
        return "Aujourd'hui ${DateFormat('HH:mm').format(date)}";
      } else if (diff.inDays == 1) {
        return "Hier ${DateFormat('HH:mm').format(date)}";
      } else if (diff.inDays < 7) {
        return "${DateFormat('EEEE', 'fr_FR').format(date)} ${DateFormat('HH:mm').format(date)}";
      }
      return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
    } catch (_) {
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DÉTAIL MESSAGE (Bottom Sheet)
// ─────────────────────────────────────────────────────────────────────────────
class _MessageDetailSheet extends StatelessWidget {
  final DriverMessageModel message;

  const _MessageDetailSheet({required this.message});

  @override
  Widget build(BuildContext context) {
    final srcColor = _sourceColor(message.senderType);

    return SafeArea(
      child: Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Poignée ──
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // ── En-tête coloré ──
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: srcColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: srcColor.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: srcColor.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_sourceIcon(message.senderType),
                      color: srcColor, size: 22),
                ),
                const Gap(12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.senderName.isNotEmpty
                            ? message.senderName
                            : message.senderType,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: srcColor,
                            fontSize: 15),
                      ),
                      Text(
                        DateFormat('dd MMM yyyy à HH:mm', 'fr_FR')
                            .format(message.createdAt),
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // ── Contenu ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.subject,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const Gap(12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    message.message,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: Color(0xFF475569),
                    ),
                  ),
                ),
                const Gap(20),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kNavy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('FERMER',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const Gap(20),
              ],
            ),
          ),
        ],
        ),
      ),
      ),
    );
  }

  Color _sourceColor(String type) {
    switch (type.toLowerCase()) {
      case 'gare':
        return const Color(0xFFFF9800);
      case 'compagnie':
      case 'admin':
        return const Color(0xFFE91E63);
      default:
        return const Color(0xFF2196F3);
    }
  }

  IconData _sourceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'gare':
        return Icons.directions_bus_rounded;
      case 'compagnie':
      case 'admin':
        return Icons.admin_panel_settings_rounded;
      default:
        return Icons.settings_suggest_rounded;
    }
  }
}
