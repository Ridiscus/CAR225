import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/screens/main_wrapper_screen.dart';
import '../../data/models/program_model.dart';

class BookingSummaryScreen extends StatefulWidget {
  final Map<String, dynamic> bookingData;
  final ProgramModel program;

  const BookingSummaryScreen({
    super.key,
    required this.bookingData,
    required this.program,
  });

  @override
  State<BookingSummaryScreen> createState() => _BookingSummaryScreenState();
}

class _BookingSummaryScreenState extends State<BookingSummaryScreen> {
  bool isSubmitting = false;
  int? userWalletBalance;
  bool isLoadingBalance = true;

  @override
  void initState() {
    super.initState();
    _fetchRealWalletBalance();
  }

  // --- 1. RÉCUPÉRATION DU SOLDE RÉEL ---
  Future<void> _fetchRealWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      if (token == null) return;

      final dio = Dio(BaseOptions(
        baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api',
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      ));

      final response = await dio.get('/user/wallet');

      if (response.statusCode == 200) {
        final data = response.data['data'] ?? response.data;
        double soldeDouble = double.tryParse(data['solde'].toString()) ?? 0.0;
        if (mounted) {
          setState(() {
            userWalletBalance = soldeDouble.toInt();
            isLoadingBalance = false;
          });
        }
      }
    } catch (e) {
      print("Erreur chargement solde: $e");
      if (mounted) setState(() => isLoadingBalance = false);
    }
  }



  // --- 2. ENVOI PAIEMENT (VERSION BLINDÉE) ---
  Future<void> _processPayment(String methodKey) async {
    //Navigator.pop(context); // Fermer le modal
    setState(() => isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio(BaseOptions(
        baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token'
        },
      ));

      // --- PRÉPARATION DES DONNÉES ---
      Map<String, dynamic> finalData = Map.from(widget.bookingData);

      // 1. Correction Dates (Retrait de l'heure si présente)
      String rawDate = finalData['date_voyage'].toString();
      finalData['date_voyage'] = rawDate.contains('T') ? rawDate.split('T')[0] : rawDate.split(' ')[0];

      if (finalData['date_retour'] != null) {
        String rawRetour = finalData['date_retour'].toString();
        finalData['date_retour'] = rawRetour.contains('T') ? rawRetour.split('T')[0] : rawRetour.split(' ')[0];
      }

      // 2. Sécurisation du flag Aller-Retour (Bool -> Int)
      // Certains backends préfèrent 1/0 à true/false
      if (finalData['is_aller_retour'] == true || finalData['is_aller_retour'] == 'true') {
        finalData['is_aller_retour'] = 1;
      } else {
        finalData['is_aller_retour'] = 0;
      }

      // 3. Nettoyage Passagers
      List<dynamic> passengers = List.from(finalData['passagers']);
      List<Map<String, dynamic>> cleanPassengers = [];

      for (var p in passengers) {
        Map<String, dynamic> pMap = Map.from(p);

        // Suppression email vide
        if (pMap['email'] == null || pMap['email'].toString().trim().isEmpty) {
          pMap.remove('email');
        }

        // Vérification console pour être sûr
        if (finalData['is_aller_retour'] == 1) {
          print("👮 Passager ${pMap['nom']} - Siège Aller: ${pMap['seat_number']} | Retour: ${pMap['seat_number_return']}");
        }

        cleanPassengers.add(pMap);
      }
      finalData['passagers'] = cleanPassengers;

      // 4. Paiement
      finalData['payment_method'] = methodKey.toLowerCase() == 'carpay' ? 'wallet' : 'cinetpay';

      // 🛑 DEBUG CRITIQUE : Vérifie cette ligne dans ta console avant l'envoi
      print("🚀 PAYLOAD FINAL ENVOYÉ API : $finalData");

      final response = await dio.post('/user/reservations', data: finalData);

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data['requires_payment'] == true && response.data['payment_details'] != null) {
          final String url = response.data['payment_details']['payment_url'];
          await _launchPaymentUrl(url);
        } else {
          if (mounted) _showSuccessDialog();
        }
      }

    } catch (e) {
      print("❌ ERREUR API : $e");
      if (e is DioException && e.response != null) {
        print("❌ RÉPONSE ERREUR : ${e.response?.data}"); // Regarde ici si l'API te renvoie une erreur précise
        String userMsg = "Erreur de validation.";

        if (e.response?.statusCode == 422 && e.response?.data['errors'] != null) {
          final errors = e.response?.data['errors'] as Map;
          userMsg = errors.values.first[0].toString();
        } else {
          userMsg = e.response?.data['message'] ?? "Erreur inconnue";
        }

        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Oups: $userMsg"), backgroundColor: Colors.red)
          );
        }
      } else {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Une erreur technique est survenue."), backgroundColor: Colors.red)
          );
        }
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }









  Future<void> _launchPaymentUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible d\'ouvrir la page de paiement'))
        );
      }
    }
  }

  void _showTopNotification(String message) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, left: 20.0, right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center, maxLines: 2)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () { if(mounted) overlayEntry.remove(); });
  }
  void _showPaymentMethodSelector(BuildContext context, int totalAmount) {
    final int currentBalance = userWalletBalance ?? 0;
    final bool hasEnoughFunds = currentBalance >= totalAmount;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true, // Permet au modal de s'adapter au contenu
        builder: (modalContext) {
          return Container(
            // Pas de padding global ici pour que le SafeArea gère le bas
            padding: const EdgeInsets.only(top: 20, left: 20, right: 20),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: SafeArea( // ✅ AJOUT DU SAFE AREA ICI
              top: false, // On ne touche pas au haut
              child: Column(
                mainAxisSize: MainAxisSize.min, // S'adapte à la hauteur du contenu
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre de poignée
                  Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
                  const Gap(20),

                  const Text("Moyen de paiement", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Gap(20),

                  // 1. OPTION WALLET (CarPay)
                  if (isLoadingBalance)
                    const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
                  else
                    Opacity(
                      opacity: hasEnoughFunds ? 1.0 : 0.5,
                      child: Container(
                        decoration: BoxDecoration(
                            border: Border.all(color: hasEnoughFunds ? AppColors.primary : Colors.grey.shade300, width: 2),
                            borderRadius: BorderRadius.circular(15),
                            color: hasEnoughFunds ? AppColors.primary.withOpacity(0.05) : null
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                          onTap: hasEnoughFunds
                              ? () {
                            Navigator.pop(modalContext); // Ferme le modal avant de lancer le paiement
                            _processPayment("CARPAY");
                          }
                              : () {
                            Navigator.pop(modalContext);
                            _showTopNotification("Solde insuffisant. Rechargez votre compte.");
                          },
                          // 🎨 IMAGE FLATICON WALLET
                          leading: Image.asset(
                            "assets/images/wallet-filled-money-tool.png", // Assure-toi que cette image existe
                            width: 45,
                            height: 45,
                            // Fallback au cas où l'image n'est pas trouvée
                            errorBuilder: (c,o,s) => const Icon(Icons.account_balance_wallet, color: AppColors.primary, size: 35),
                          ),
                          title: const Text("CarPay Wallet", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              hasEnoughFunds ? "Solde: ${_formatCurrency(currentBalance)}" : "Insuffisant (${_formatCurrency(currentBalance)})",
                              style: TextStyle(color: hasEnoughFunds ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 13)
                          ),
                          trailing: hasEnoughFunds
                              ? const Icon(Icons.check_circle, color: AppColors.primary)
                              : const Icon(Icons.block, color: Colors.grey),
                        ),
                      ),
                    ),

                  const Gap(15),

                  // 2. OPTION MOBILE MONEY (CinetPay / Wave / Orange)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                      onTap: () {
                        Navigator.pop(modalContext);
                        _processPayment("CINETPAY");
                      },
                      // 🎨 IMAGE FLATICON MOBILE PAYMENT
                      leading: Image.asset(
                        "assets/images/digital-wallet.png", // Image représentant Orange/MTN/Wave
                        width: 45,
                        height: 45,
                        errorBuilder: (c,o,s) => const Icon(Icons.smartphone, color: Colors.orange, size: 35),
                      ),
                      title: const Text("Paiement Mobile", style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text("Orange, MTN, Moov, Wave", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                    ),
                  ),

                  const Gap(20), // Un petit espace en bas avant la fin du SafeArea
                ],
              ),
            ),
          );
        }
    );
  }

  /*void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const Gap(10),
            const Text("Réservation Réussie !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Gap(10),
            const Text(
              "Votre billet a été réservé avec succès.\nVous pouvez le retrouver dans l'onglet Billets.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const Gap(20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const MainScreen()), (route) => false);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("OK, Retour accueil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }*/


  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 60),
            const Gap(10),
            const Text("Réservation Réussie !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const Gap(10),
            const Text(
              "Votre billet a été réservé avec succès.\nVous pouvez le retrouver dans l'onglet Billets.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const Gap(20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // ✅ CORRECTION ICI : on ajoute initialIndex: 1
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const MainScreen(initialIndex: 1)
                      ),
                          (route) => false
                  );
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
                ),
                child: const Text("OK, Voir mes billets", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calcul Prix
    final int ticketPrice = widget.program.isAllerRetour ? (widget.program.prix * 2) : widget.program.prix;
    final int passengerCount = (widget.bookingData['nombre_places'] as num).toInt();
    final int subTotal = ticketPrice * passengerCount;
    final int fees = (subTotal * 0.04).toInt();
    final int total = subTotal + fees;

    // Date Départ
    String rawDateDepart = widget.bookingData['date_voyage']?.toString() ?? widget.program.dateDepart;
    if (rawDateDepart.contains('T')) rawDateDepart = rawDateDepart.split('T')[0];
    DateTime dateD = DateTime.tryParse(rawDateDepart) ?? DateTime.now();
    String formattedDateDepart = DateFormat("EEE d MMM yyyy", "fr_FR").format(dateD);

    // Date Retour
    String formattedDateRetour = "";
    if (widget.program.isAllerRetour && widget.bookingData['date_retour'] != null) {
      String rawDateRetour = widget.bookingData['date_retour'].toString();
      if (rawDateRetour.contains('T')) rawDateRetour = rawDateRetour.split('T')[0];
      DateTime dateR = DateTime.tryParse(rawDateRetour) ?? DateTime.now();
      formattedDateRetour = DateFormat("EEE d MMM yyyy", "fr_FR").format(dateR);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;
    final dividerColor = isDark ? Colors.grey[800] : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Text("Confirmation", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: cardColor,
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))]
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity, height: 55,
            child: ElevatedButton(
              onPressed: isSubmitting ? null : () => _showPaymentMethodSelector(context, total),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0),
              child: isSubmitting
                  ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text("Payer ${_formatCurrency(total)}", style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Vérifiez les détails de votre réservation", style: TextStyle(color: AppColors.grey, fontSize: 14)),
            const Gap(20),

            // 1. DÉTAILS DU TRAJET
            _buildSectionCard(
              context,
              title: "Détails du trajet",
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Compagnie", style: TextStyle(color: AppColors.grey, fontSize: 12)),
                    const Text("Type", style: TextStyle(color: AppColors.grey, fontSize: 12)),
                  ],
                ),
                const Gap(5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(widget.program.compagnieName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                    // Badge Aller-Retour ou Standard
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: widget.program.isAllerRetour ? Colors.orange.withOpacity(0.2) : (isDark ? Colors.grey[800] : Colors.grey.shade200), borderRadius: BorderRadius.circular(5)),
                      child: Text(
                        widget.program.isAllerRetour ? "Aller-Retour" : "Aller Simple",
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: widget.program.isAllerRetour ? Colors.orange : textColor),
                      ),
                    ),
                  ],
                ),
                Divider(height: 30, color: dividerColor),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Départ", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                        const Gap(5),
                        Text(widget.program.villeDepart, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
                      ],
                    ),
                    Column(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: AppColors.primary),
                        const Gap(5),
                        Text(widget.program.heureDepart, style: const TextStyle(fontSize: 10, color: AppColors.grey)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text("Arrivée", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                        const Gap(5),
                        Text(widget.program.villeArrivee, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      ],
                    ),
                  ],
                )
              ],
            ),
            const Gap(15),

            // 2. ITINÉRAIRE (Visuel Simple)
            _buildSectionCard(
              context,
              title: "Itinéraire",
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                        Container(width: 1, height: 25, color: isDark ? Colors.grey[700] : Colors.grey.shade300),
                        const Icon(Icons.location_on_outlined, color: Colors.grey, size: 20),
                      ],
                    ),
                    const Gap(15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Départ", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                        Text(widget.program.villeDepart, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                        const Gap(15),
                        const Text("Destination", style: TextStyle(color: AppColors.grey, fontSize: 10)),
                        Text(widget.program.villeArrivee, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                      ],
                    )
                  ],
                )
              ],
            ),
            const Gap(15),

            // 3. INFO PASSAGERS
            _buildSectionCard(
              context,
              title: "Informations passagers",
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Passagers", style: TextStyle(color: AppColors.grey)),
                  Text("$passengerCount personne(s)", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ]),
                const Gap(10),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Date de départ", style: TextStyle(color: AppColors.grey)),
                  Text(formattedDateDepart, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                ]),
                // Affichage Date Retour
                if (widget.program.isAllerRetour && formattedDateRetour.isNotEmpty) ...[
                  const Gap(10),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text("Date de retour", style: TextStyle(color: AppColors.grey)),
                    Text(formattedDateRetour, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ]),
                ],
                Divider(height: 20, color: dividerColor),

                // LISTE DES PASSAGERS AVEC SIÈGES A/R
                ...List.generate(passengerCount, (index) {
                  final List rawPassengers = widget.bookingData['passagers'] as List;
                  final p = rawPassengers[index] as Map<String, dynamic>;

                  // Récupération des sièges
                  final seatAller = p['seat_number'];
                  final seatRetour = p['seat_number_return']; // Peut être null si aller simple

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(Icons.person, size: 16, color: AppColors.primary),
                        const Gap(8),
                        Expanded(child: Text("${p['prenom']} ${p['nom']} ", style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 13))),

                        // Badge Sièges
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            children: [
                              Text("Aller: $seatAller", style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                              if (seatRetour != null) ...[
                                Container(width: 1, height: 10, color: AppColors.primary, margin: const EdgeInsets.symmetric(horizontal: 5)),
                                Text("Ret: $seatRetour", style: const TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                              ]
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                }),
              ],
            ),
            const Gap(15),

            // 4. RÉSUMÉ DU PRIX
            _buildSectionCard(
              context,
              title: "Résumé du prix",
              children: [
                _buildPriceRow(context, widget.program.isAllerRetour ? "Prix unitaire (A/R)" : "Prix unitaire", _formatCurrency(ticketPrice)),
                const Gap(10),
                _buildPriceRow(context, "Nombre de passagers", "x $passengerCount"),
                const Gap(10),
                _buildPriceRow(context, "Sous-total", _formatCurrency(subTotal), isBold: true),
                Divider(height: 20, color: dividerColor),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text("Frais de service (4%)", style: TextStyle(color: AppColors.grey, fontSize: 14)),
                  Text(_formatCurrency(fees), style: TextStyle(fontSize: 14, color: textColor)),
                ]),
                const Divider(height: 20, color: AppColors.primary),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text("Total à payer", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                  Text(_formatCurrency(total), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                ])
              ],
            ),
            const Gap(40),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS HELPERS ---
  Widget _buildSectionCard(BuildContext context, {required String title, required List<Widget> children}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 5))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        const Gap(20),
        ...children,
      ]),
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value, {bool isBold = false}) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: TextStyle(color: AppColors.grey, fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: textColor)),
    ]);
  }

  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(amount);
  }
}