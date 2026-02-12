import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../booking/data/models/ticket_model.dart';
import '../../../booking/domain/repositories/ticket_repository.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel initialTicket;
  final TicketRepository repository;

  const TicketDetailScreen({
    Key? key,
    required this.initialTicket,
    required this.repository
  }) : super(key: key);

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late TicketModel ticket;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    ticket = widget.initialTicket;
    _loadFullDetails();
  }

  Future<void> _loadFullDetails() async {
    try {
      final fullTicket = await widget.repository.getTicketDetails(widget.initialTicket.id);
      if (mounted) {
        setState(() {
          ticket = fullTicket;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          errorMessage = "Mise à jour impossible (Hors ligne).";
        });
      }
    }
  }

  // ------------------------------------------------------------------------
  // 🧮 LOGIQUE DE CALCUL (DATES & REMBOURSEMENT)
  // ------------------------------------------------------------------------

  // Récupère la date précise du départ
  DateTime? get _departureDateTime {
    try {
      final datePart = ticket.date; // Supposons DateTime(2024, 02, 12)
      final timeParts = ticket.departureTimeRaw.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      return DateTime(datePart.year, datePart.month, datePart.day, hour, minute);
    } catch (e) {
      print("Erreur parsing date: $e");
      return null;
    }
  }

  // Vérifie si on est à plus de 15 min du départ
  bool get _isActionPossible {
    if (ticket.status == "Terminé" || ticket.status == "Annulé" || ticket.status == "Expiré") {
      return false;
    }
    final departure = _departureDateTime;
    if (departure == null) return false;

    final now = DateTime.now();
    return departure.difference(now).inMinutes > 15;
  }

  // 👇 C'EST ICI QUE TA LOGIQUE EST APPLIQUÉE
  Map<String, dynamic> _calculateRefundInfo() {
    final departure = _departureDateTime;
    if (departure == null) return {'percent': 0.0, 'amount': 0, 'penalty': 0};

    final now = DateTime.now();
    final difference = departure.difference(now);
    final int daysBefore = difference.inDays;
    final int minutesBefore = difference.inMinutes;

    double refundPercent = 0.0;

    // Tes règles :
    if (daysBefore >= 7) {
      refundPercent = 1.0; // 100% (Plus d'1 semaine)
    } else if (daysBefore >= 4) {
      refundPercent = 0.7; // 70% (Entre 4 jours et 1 semaine)
    } else if (daysBefore >= 2) {
      refundPercent = 0.4; // 40% (Entre 2 et 4 jours)
    } else if (minutesBefore > 15) {
      refundPercent = 0.2; // 20% (Moins de 2 jours, jusqu'à 15 min)
    } else {
      refundPercent = 0.0; // 0% (Moins de 15 min)
    }

    // Nettoyage du prix (ex: "5 000" -> 5000.0)
    double price = 0.0;
    try {
      String cleanPrice = ticket.price.replaceAll(RegExp(r'[^0-9]'), '');
      price = double.parse(cleanPrice);
    } catch (e) {
      price = 0.0;
    }

    double refundAmount = price * refundPercent;
    double penaltyAmount = price - refundAmount;

    return {
      'percent': (refundPercent * 100).toInt(),
      'amount': refundAmount.toInt(),
      'penalty': penaltyAmount.toInt(),
      'daysBefore': daysBefore,
    };
  }

  // ------------------------------------------------------------------------
  // 🛠 ACTIONS BOUTONS
  // ------------------------------------------------------------------------

  void _onCancelPressed() {
    final refundInfo = _calculateRefundInfo();
    final int percent = refundInfo['percent'];
    final int amount = refundInfo['amount'];
    final int penalty = refundInfo['penalty'];

    // Couleurs dynamiques selon le remboursement
    Color percentColor = percent >= 70 ? Colors.green : (percent >= 40 ? Colors.orange : Colors.red);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Annulation", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Conditions selon le délai restant :"),
            const SizedBox(height: 15),

            // LIGNE 1 : Pourcentage remboursé
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Remboursement :", style: TextStyle(color: Colors.grey)),
                Text("$percent%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: percentColor)),
              ],
            ),

            // LIGNE 2 : Pénalité
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Frais d'annulation :", style: TextStyle(color: Colors.grey)),
                Text("- $penalty F", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              ],
            ),
            const Divider(),

            // LIGNE 3 : Total crédité
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Crédité sur Wallet :", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                  Text("$amount F", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.green)),
                ],
              ),
            ),

            const SizedBox(height: 10),
            const Text(
              "Cette action est irréversible. Le montant sera crédité immédiatement sur votre solde virtuel.",
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Retour", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              // TODO: Appeler l'API d'annulation ici (passer refundAmount si besoin)
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text("Réservation annulée. $amount F crédités."),
                backgroundColor: Colors.green,
              ));
              // Tu peux rafraîchir l'écran ou revenir en arrière ici
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Confirmer l'annulation"),
          ),
        ],
      ),
    );
  }

  void _onModifyPressed() {
    // Modification = Annulation + Nouvelle réservation
    // On réutilise la logique de remboursement pour informer l'utilisateur
    final refundInfo = _calculateRefundInfo();
    final int percent = refundInfo['percent'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Modifier le trajet"),
        content: Text("Pour modifier, vous devez annuler ce ticket et en réserver un nouveau.\n\n"
            "Compte tenu de la date, vous récupérerez $percent% du montant ($percent%) sur votre Wallet pour la nouvelle réservation."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _onCancelPressed(); // On redirige vers le flux d'annulation
            },
            child: const Text("Procéder à l'annulation"),
          ),
        ],
      ),
    );
  }

  void _showQRCodeModal(BuildContext context, String qrData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.65,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
          child: Column(
            children: [
              const SizedBox(height: 15),
              Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
              const Spacer(),
              Hero(tag: 'qr_code_hero', child: Image.memory(base64Decode(qrData), width: 280, height: 280, fit: BoxFit.contain)),
              const Spacer(),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: SizedBox(width: double.infinity, child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: const Text("Fermer", style: TextStyle(color: Colors.white, fontSize: 16)))),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime d) => "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

    String siegeDisplay = ticket.seatNumber;
    if (ticket.isAllerRetour && ticket.returnSeatNumber != null) {
      siegeDisplay = "${ticket.seatNumber} (Aller) / ${ticket.returnSeatNumber} (Retour)";
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text("Détails du Billet"),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isLoading) const LinearProgressIndicator(),
            if (errorMessage != null)
              Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(errorMessage!, style: const TextStyle(color: Colors.red))),

            // 🎫 CARTE DU BILLET (inchangé)
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(ticket.companyName.toUpperCase(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                        _buildStatusChip(ticket.status),
                      ],
                    ),
                    const Divider(height: 25),
                    _buildTripDetails(ticket, formatDate),
                    const Divider(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(child: _buildCityInfo(ticket.departureCity, "Départ")),
                        const Icon(Icons.arrow_forward, color: Colors.blue, size: 24),
                        Expanded(child: _buildCityInfo(ticket.arrivalCity, "Arrivée")),
                      ],
                    ),
                    const Divider(height: 30),
                    _buildRow("Passager", ticket.passengerName),
                    _buildRow("Siège N°", siegeDisplay),
                    _buildRow("Prix Total", "${ticket.price} F"),
                    _buildRow("Référence", ticket.ticketNumber),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ⚙️ BOUTONS INTELLIGENTS
            if (_isActionPossible)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _onCancelPressed,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 20),
                      label: const Text("Annuler"),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _onModifyPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade700,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      label: const Text("Modifier"),
                    ),
                  ),
                ],
              )
            else if (ticket.status == "Validé")
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: const [
                    Icon(Icons.lock_clock, color: Colors.orange, size: 20),
                    SizedBox(width: 10),
                    Expanded(child: Text("Modifications impossibles moins de 15 min avant le départ.", style: TextStyle(color: Colors.orange, fontSize: 12))),
                  ],
                ),
              ),

            const SizedBox(height: 30),

            if (ticket.status == "Terminé" || ticket.status == "Expiré" || ticket.status == "Annulé")
              _buildExpiredOrUsedView()
            else
              _buildActiveQRCodeView(context),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS DÉCOUPÉS (Identiques à ta version précédente) ---
  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case "Validé": color = Colors.green; break;
      case "Annulé": color = Colors.red; break;
      case "Terminé": color = Colors.grey; break;
      default: color = Colors.blue;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildTripDetails(TicketModel ticket, Function(DateTime) formatDate) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  const Text("ALLER", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(formatDate(ticket.date), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                  Text(ticket.departureTimeRaw, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ),
            if (ticket.isAllerRetour && ticket.returnDate != null) VerticalDivider(color: Colors.grey.shade300, thickness: 1),
            if (ticket.isAllerRetour && ticket.returnDate != null)
              Expanded(
                child: Column(
                  children: [
                    const Text("RETOUR", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 5),
                    Text(formatDate(ticket.returnDate!), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    Text(ticket.returnTimeRaw ?? "--:--", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  ],
                ),
              )
            else if (!ticket.isAllerRetour) const SizedBox.shrink(),
          ],
        ),
      ),
    );
  }

  Widget _buildCityInfo(String city, String label) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(city.replaceAll(", Côte d'Ivoire", ""), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
      ],
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(child: Text(value, textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildActiveQRCodeView(BuildContext context) {
    return Column(
      children: [
        const Text("Présentez ce code à l'embarquement", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (ticket.qrCodeUrl != null && ticket.qrCodeUrl!.isNotEmpty)
          GestureDetector(
            onTap: () => _showQRCodeModal(context, ticket.qrCodeUrl!),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue.withOpacity(0.3)), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]),
              child: Column(
                children: [
                  Hero(tag: 'qr_code_hero', child: Image.memory(base64Decode(ticket.qrCodeUrl!), height: 180, width: 180, errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey))),
                  const SizedBox(height: 10),
                  Row(mainAxisSize: MainAxisSize.min, children: const [Icon(Icons.zoom_in, size: 16, color: Colors.blue), SizedBox(width: 5), Text("Cliquez pour agrandir", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold))])
                ],
              ),
            ),
          )
        else
          const Text("QR code en cours de génération...")
      ],
    );
  }

  Widget _buildExpiredOrUsedView() {
    bool isTermine = ticket.status == "Terminé";
    bool isAnnule = ticket.status == "Annulé";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.grey.shade300)),
      child: Column(
        children: [
          Icon(isAnnule ? Icons.cancel : (isTermine ? Icons.check_circle : Icons.event_busy), size: 60, color: Colors.grey),
          const SizedBox(height: 15),
          Text(isAnnule ? "Billet Annulé" : (isTermine ? "Voyage Effectué" : "Billet Expiré"), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
        ],
      ),
    );
  }
}