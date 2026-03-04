import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class TicketPdfGenerator {
  static Future<void> printAllTickets({
    required int passengerCount,
    required String passengerName,
    required String departure,
    required String arrival,
    required String travelDate,
    required String travelTime,
    required bool isRoundTrip,
    required int totalPrice,
  }) async {
    final pdf = pw.Document();
    final pricePerTicket = totalPrice ~/ passengerCount;

    // Générer une page pour chaque billet
    for (int i = 1; i <= passengerCount; i++) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => _buildTicketPage(
            ticketNumber: i,
            passengerName: passengerName,
            departure: departure,
            arrival: arrival,
            travelDate: travelDate,
            travelTime: travelTime,
            isRoundTrip: isRoundTrip,
            price: pricePerTicket,
          ),
        ),
      );
    }

    // Afficher l'aperçu d'impression
    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Billets_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  static Future<void> printSingleTicket({
    required int ticketNumber,
    required String passengerName,
    required String departure,
    required String arrival,
    required String travelDate,
    required String travelTime,
    required bool isRoundTrip,
    required int price,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => _buildTicketPage(
          ticketNumber: ticketNumber,
          passengerName: passengerName,
          departure: departure,
          arrival: arrival,
          travelDate: travelDate,
          travelTime: travelTime,
          isRoundTrip: isRoundTrip,
          price: price,
        ),
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'Billet_$ticketNumber.pdf',
    );
  }

  static pw.Widget _buildTicketPage({
    required int ticketNumber,
    required String passengerName,
    required String departure,
    required String arrival,
    required String travelDate,
    required String travelTime,
    required bool isRoundTrip,
    required int price,
  }) {
    final referenceId =
        'RES-${DateTime.now().year}${DateTime.now().month.toString().padLeft(2, '0')}${DateTime.now().day.toString().padLeft(2, '0')}11-5T4V4V-$ticketNumber';

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.orange, width: 3),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      padding: const pw.EdgeInsets.all(30),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'BILLET DE VOYAGE ÉLECTRONIQUE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.orange,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '(STANDARD)',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.green,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text(
                    'Référence: $referenceId',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.orange, thickness: 2),
          pw.SizedBox(height: 20),

          // Itinéraire
          pw.Text(
            'Itinéraire du voyage',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Text(
            'Départ: $departure - Arrivée: $arrival',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Date: $travelDate - Heure: $travelTime',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            'Passager: $passengerName',
            style: const pw.TextStyle(fontSize: 12),
          ),
          pw.SizedBox(height: 24),

          // Place
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColors.orange,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Center(
              child: pw.Text(
                'Place N° $ticketNumber',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ),
          ),
          pw.SizedBox(height: 24),

          // Type de voyage
          pw.Center(
            child: pw.Text(
              'TYPE DE VOYAGE : ${isRoundTrip ? "ALLER-RETOUR" : "STANDARD"}',
              style: pw.TextStyle(
                fontSize: 12,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue,
              ),
            ),
          ),
          pw.SizedBox(height: 20),

          // QR Code
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Validation du billet',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.BarcodeWidget(
                  data:
                      'TICKET-$ticketNumber-${DateTime.now().millisecondsSinceEpoch}',
                  barcode: pw.Barcode.qrCode(),
                  width: 120,
                  height: 120,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Scannez pour vérification',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Montant
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.all(16),
            decoration: const pw.BoxDecoration(
              color: PdfColors.green,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Montant du billet :',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  '$price FCFA',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Transaction validée (Hôtesse)',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.white,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Avertissement
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Avertissement:',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Ce billet est nominatif, non échangeable et non remboursable. Toute falsification est passible de poursuites.',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
          pw.Spacer(),

          // Footer
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Servi par: Ali Abibu',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Pour toute assistance : contact@siedemarchee-ci.com',
                  style: const pw.TextStyle(
                    fontSize: 9,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '© ${DateTime.now().year} CAR 225 - Tous droits réservés',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
