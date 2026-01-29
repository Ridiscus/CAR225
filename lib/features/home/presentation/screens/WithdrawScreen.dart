import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';

class WithdrawScreen extends StatelessWidget {
  const WithdrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor; // Blanc (Light) ou Gris Foncé (Dark)
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final inputFillColor = isDark ? Colors.black.withOpacity(0.3) : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text("RETRAIT", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          decoration: BoxDecoration(
            color: cardColor, // <--- FOND CARTE DYNAMIQUE
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                blurRadius: 15,
                offset: const Offset(0, 5),
              )
            ],
          ),
          child: Column(
            children: [
              // SOLDE
              const Text("SOLDE ACTUEL", style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
              const Gap(10),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "50 000 ",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: textColor, fontFamily: 'Montserrat'),
                    ),
                    const TextSpan(
                      text: "FCFA",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                    ),
                  ],
                ),
              ),
              const Gap(40),

              // INPUT MONTANT
              Align(alignment: Alignment.centerLeft, child: Text("MONTANT A RETIRER", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold))),
              const Gap(8),
              TextField(
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: "Montant (FCFA)",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: inputFillColor, // Fond input
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const Gap(20),

              // INPUT NUMÉRO
              Align(alignment: Alignment.centerLeft, child: Text("NUMERO DE DESTINATION", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold))),
              const Gap(8),
              TextField(
                keyboardType: TextInputType.phone,
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone_android, color: Colors.grey),
                  hintText: "07 00 00 00 00",
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: inputFillColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: borderColor)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                ),
              ),
              const Gap(40),

              // BOUTON CONFIRMER
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // Action de retrait
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE64A19), // Orange foncé
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text("Confirmer le retrait", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                      Gap(10),
                      Icon(Icons.money, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
              const Gap(20),

              Text(
                "Les frais de transfert (1%) sont déduits du montant total du retrait",
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[400], fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}