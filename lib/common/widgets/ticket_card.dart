import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../features/booking/data/models/ticket_model.dart';

class TicketCard extends StatelessWidget {
  final TicketModel ticket;
  final VoidCallback onDetailPressed;
  final VoidCallback onDownloadPressed;
  final bool isDownloading;

  const TicketCard({
    super.key,
    required this.ticket,
    required this.onDetailPressed,
    required this.onDownloadPressed,
    this.isDownloading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final primaryColor = AppColors.primary;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;

    // Badges logic...
    Color badgeBg;
    Color badgeText;
    String badgeLabel = ticket.status.toUpperCase();

    if (ticket.status == "Confirmé") {
      badgeBg = isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
      badgeText = Colors.green[700]!;
    } else if (ticket.status == "Terminé") {
      badgeBg = isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade200;
      badgeText = Colors.grey[700]!;
    } else if (ticket.status == "Expiré") {
      badgeBg = isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50;
      badgeText = Colors.red[700]!;
    } else {
      badgeBg = Colors.orange.withOpacity(0.1);
      badgeText = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // EN-TÊTE
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text("PAYÉ", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeLabel, style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const Gap(20),

          // SIÈGE GÉANT
          Column(
            children: [
              const Text("N° SIÈGE", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const Gap(5),
              if (ticket.isAllerRetour && ticket.returnSeatNumber != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(ticket.seatNumber, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: textColor)),
                    Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("/", style: TextStyle(fontSize: 30, color: Colors.grey[300]))),
                    Text("${ticket.returnSeatNumber}", style: const TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.orange)),
                  ],
                )
              else
                Text(ticket.seatNumber, style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: textColor)),
            ],
          ),
          const Gap(20),

          // BOUTONS
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: onDetailPressed,
                      icon: Icon(Icons.info_outline, size: 16, color: textColor),
                      label: Text("Détails", style: TextStyle(color: textColor, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))))),
              const Gap(10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isDownloading ? null : onDownloadPressed,
                  icon: isDownloading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.download, size: 16, color: Colors.white),
                  label: Text(isDownloading ? "..." : "Télécharger", style: const TextStyle(color: Colors.white, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}