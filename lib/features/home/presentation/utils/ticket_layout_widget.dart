import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../../booking/data/models/ticket_model.dart';


class TicketLayoutWidget extends StatelessWidget {
  final TicketModel ticket;
  final Uint8List qrCodeBytes;

  const TicketLayoutWidget({
    Key? key,
    required this.ticket,
    required this.qrCodeBytes,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Couleurs du design
    final Color blueHeader = const Color(0xFF0D47A1);
    final Color greenRef = const Color(0xFF00C853);
    final Color orangeSeat = const Color(0xFFFF9800);
    final Color greenPrice = const Color(0xFF00BFA5);
    final Color redWarningBg = const Color(0xFFFFEBEE);
    final Color redWarningText = const Color(0xFFB71C1C);

    // On force une largeur fixe pour que le design soit constant
    // On met un fond blanc et un padding global
    return Container(
      width: 400, // Largeur fixe pour le rendu image
      color: Colors.white,
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: orangeSeat, width: 2), // Bordure orange globale
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // --- 1. EN-TÊTE BLEU ---
            Container(
              color: blueHeader,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  const Text("BILLET DE VOYAGE ÉLECTRONIQUE",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.none)),
                  const SizedBox(height: 5),
                  Text(ticket.isAllerRetour ? "(ALLER - RETOUR)" : "(ALLER SIMPLE)",
                      style: const TextStyle(color: Colors.white70, fontSize: 12, decoration: TextDecoration.none)),
                  const SizedBox(height: 10),
                  // Badge Référence Vert
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                    color: greenRef,
                    child: Text("Référence: ${ticket.ticketNumber}",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.none)),
                  ),
                ],
              ),
            ),

            // --- 2. CORPS DU BILLET ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Itinéraire de voyage", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey, decoration: TextDecoration.none)),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text("Départ: ${ticket.departureCity} - Arrivée: ${ticket.arrivalCity}",
                      style: const TextStyle(fontSize: 14, color: Colors.black, decoration: TextDecoration.none)),
                  const SizedBox(height: 5),
                  Text("Date: ${ticket.date.day}/${ticket.date.month}/${ticket.date.year} - Heure: ${ticket.departureTimeRaw}",
                      style: const TextStyle(fontSize: 14, color: Colors.black, decoration: TextDecoration.none)),

                  const SizedBox(height: 25),

                  // BANDE ORANGE (Place)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: orangeSeat,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Center(
                      child: Text("Place N° ${ticket.seatNumber}",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, decoration: TextDecoration.none)),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Center(child: Text("TYPE DE VOYAGE : ${ticket.isAllerRetour ? 'ALLER - RETOUR' : 'ALLER SIMPLE'}",
                      style: TextStyle(color: blueHeader, fontWeight: FontWeight.bold, fontSize: 14, decoration: TextDecoration.none))),

                  const SizedBox(height: 20),

                  // QR CODE
                  Center(
                    child: Column(
                      children: [
                        const Text("Validation du billet", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 14, decoration: TextDecoration.none)),
                        const SizedBox(height: 10),
                        Image.memory(qrCodeBytes, width: 130, height: 130),
                        const SizedBox(height: 5),
                        const Text("Scannez pour vérification", style: TextStyle(fontSize: 12, color: Colors.grey, decoration: TextDecoration.none)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- 3. PRIX (Vert) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(vertical: 15),
              color: greenPrice,
              child: Column(
                children: [
                  const Text("Montant du billet :", style: TextStyle(color: Colors.white, fontSize: 12, decoration: TextDecoration.none)),
                  Text("${ticket.price} FCFA",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22, decoration: TextDecoration.none)),
                  const Text("Transaction validée", style: TextStyle(color: Colors.white70, fontSize: 10, decoration: TextDecoration.none)),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- 4. AVERTISSEMENT (Rouge clair) ---
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: redWarningBg,
                border: Border.all(color: Colors.red.shade200),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Avertissement:", style: TextStyle(color: redWarningText, fontWeight: FontWeight.bold, fontSize: 12, decoration: TextDecoration.none)),
                  const SizedBox(height: 5),
                  Text(
                    "Ce billet est nominal, non échangeable et non remboursable. Toute falsification est passible de poursuites.",
                    style: TextStyle(color: redWarningText, fontSize: 11, height: 1.2, decoration: TextDecoration.none),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}