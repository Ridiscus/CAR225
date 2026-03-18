import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../data/models/driver_message_model.dart';
import '../widgets/driver_header.dart';

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
    final driverProvider = Provider.of<DriverProvider>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const DriverHeader(title: "Messages", showBack: true),
          Expanded(
            child: driverProvider.isLoading && driverProvider.messages.isEmpty
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : driverProvider.messages.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: () => driverProvider.loadMessages(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: driverProvider.messages.length,
                          separatorBuilder: (context, index) => const Gap(12),
                          itemBuilder: (context, index) {
                            final message = driverProvider.messages[index];
                            return _buildMessageCard(message);
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewMessageDialog(context),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.edit, color: Colors.white),
      ),
    );
  }

  void _showNewMessageDialog(BuildContext context) {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    final driverProvider = context.read<DriverProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Message à la gare"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(labelText: "Objet"),
            ),
            const Gap(10),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(labelText: "Message"),
              maxLines: 5,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ANNULER"),
          ),
          ElevatedButton(
            onPressed: () async {
              final subject = subjectController.text.trim();
              final message = messageController.text.trim();
              if (subject.isNotEmpty && message.isNotEmpty) {
                 final success = await driverProvider.sendMessage(subject, message);
                 if (context.mounted) {
                   Navigator.pop(context);
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text(success ? "Message envoyé !" : "Erreur lors de l'envoi")),
                   );
                 }
              }
            },
            child: const Text("ENVOYER"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.grey[50], shape: BoxShape.circle),
            child: Icon(Icons.mail_outline_rounded, size: 48, color: Colors.grey[300]),
          ),
          const Gap(20),
          const Text("Aucun message", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Gap(8),
          Text("Vous recevrez ici les notifications de la gare.", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildMessageCard(DriverMessageModel message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: message.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: message.isRead ? Colors.grey[100]! : AppColors.primary.withValues(alpha: 0.1)),
        boxShadow: [
          if (!message.isRead) 
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: InkWell(
        onTap: () => _showMessageDetails(message),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSourceColor(message.senderType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    message.senderType.toUpperCase(),
                    style: TextStyle(
                      color: _getSourceColor(message.senderType),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(message.createdAt),
                  style: TextStyle(color: Colors.grey[400], fontSize: 11),
                ),
              ],
            ),
            const Gap(12),
            Text(
              message.subject,
              style: TextStyle(
                fontWeight: message.isRead ? FontWeight.w600 : FontWeight.w800,
                fontSize: 15,
                color: message.isRead ? Colors.blueGrey[900] : AppColors.primary,
              ),
            ),
            const Gap(8),
            Text(
              message.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Color _getSourceColor(String type) {
    switch (type.toLowerCase()) {
      case 'gare': return Colors.orange;
      case 'admin': return Colors.red;
      case 'system': return Colors.blue;
      default: return AppColors.primary;
    }
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      if (date.day == now.day && date.month == now.month && date.year == now.year) {
         return DateFormat('HH:mm').format(date);
      }
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  void _showMessageDetails(DriverMessageModel message) {
    if (!message.isRead) {
      context.read<DriverProvider>().markMessageAsRead(message);
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: EdgeInsets.zero,
        title: Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
          ),
          child: Row(
            children: [
              const Icon(Icons.mail, color: Colors.white),
              const Gap(12),
              const Expanded(
                child: Text(
                  "Détails du message",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                 Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getSourceColor(message.senderType).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    message.senderType.toUpperCase(),
                    style: TextStyle(
                      color: _getSourceColor(message.senderType),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  _formatDate(message.createdAt),
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
            const Gap(16),
            const Text("OBJET :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const Gap(4),
            Text(
              message.subject,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
            ),
            const Gap(16),
            const Text("MESSAGE :", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
            const Gap(8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Text(
                message.message,
                style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text("FERMER", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
