import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports Clean Arch
import '../../../wallet/data/datasources/wallet_remote_data_source.dart';
import '../../../wallet/data/models/wallet_model.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';


import 'TopUpScreen.dart';
import 'WithdrawScreen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  // --- ETAT ---
  WalletModel? walletData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchWalletData();
  }




  Future<void> _fetchWalletData() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // 1. RÉCUPÉRATION DU TOKEN
      final prefs = await SharedPreferences.getInstance();

      // ✅ CORRECTION ICI : On utilise 'auth_token' comme dans ton AuthRemoteDataSource
      final String? token = prefs.getString('auth_token');

      // DEBUG
      if (token != null) {
        print("✅ WALLET: Token trouvé (auth_token): ${token.substring(0, 10)}...");
      } else {
        print("❌ WALLET: Aucun token trouvé pour la clé 'auth_token'");
        setState(() {
          isLoading = false;
          errorMessage = "Non connecté.";
        });
        return;
      }

      // 2. CONFIGURATION DIO
      final dio = Dio(BaseOptions(
        baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api', // Vérifie si c'est /api ou /api/
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // On injecte le bon token
        },
      ));

      // 3. APPEL API
      final dataSource = WalletRemoteDataSourceImpl(dio: dio);
      final repo = WalletRepository(remoteDataSource: dataSource);

      final data = await repo.getWalletData();

      if (mounted) {
        setState(() {
          walletData = data;
          isLoading = false;
        });
      }
    } catch (e) {
      print("❌ ERREUR WALLET: $e");
      if (mounted) {
        setState(() {
          errorMessage = "Impossible de charger le solde.";
          isLoading = false;
        });
      }
    }
  }






  // Helper pour formater l'argent (ex: 45 000)
  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0).format(amount).trim();
  }

  @override
  Widget build(BuildContext context) {
    // --- THEME VARIABLES ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text(
            "Portefeuille",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Petit bouton refresh pour tester
          IconButton(
            icon: Icon(Icons.refresh, color: textColor),
            onPressed: () {
              setState(() => isLoading = true);
              _fetchWalletData();
            },
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
          ? Center(child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 50, color: Colors.red),
          Gap(10),
          Text(errorMessage!, style: TextStyle(color: textColor)),
          TextButton(onPressed: _fetchWalletData, child: Text("Réessayer"))
        ],
      ))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- CARTE PRINCIPALE ORANGE ---
            // ... (Le début du code reste identique)

            // --- CARTE PRINCIPALE ORANGE ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(25),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFF5722),
                    Color(0xFFE64A19),
                  ],
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE64A19).withOpacity(isDark ? 0.2 : 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Partie Haute : Texte + Icône
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SOLDE DISPONIBLE",
                            style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                letterSpacing: 1.0,
                                fontWeight: FontWeight.w500
                            ),
                          ),
                          const Gap(8),
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                    text: "${_formatCurrency(walletData?.solde ?? 0)} ",
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        fontFamily: 'Montserrat'
                                    )
                                ),
                                const TextSpan(
                                    text: "FCFA",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600
                                    )
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12)
                        ),
                        child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 28),
                      )
                    ],
                  ),

                  const Gap(30),

                  // Partie Basse : Le bouton Recharger (PREND TOUTE LA LARGEUR)
                  SizedBox(
                    width: double.infinity, // Prend toute la largeur
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const TopUpScreen()));
                      },
                      style: ElevatedButton.styleFrom(
                        // J'ai mis le fond blanc pour qu'il ressorte bien sur l'orange
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFFE64A19), // Texte orange
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      ),
                      child: const Text("Recharger mon compte", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),

                  // J'ai supprimé le Gap(15) et le bouton "Retirer" ici
                ],
              ),
            ),

// ... (La suite avec la liste des transactions reste identique)

            const Gap(30),

            // --- LISTE DES TRANSACTIONS ---
            Text("Dernières transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const Gap(15),

            if (walletData != null && walletData!.transactions.isNotEmpty)
              ListView.builder(
                  shrinkWrap: true, // Important dans un SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), // Désactive le scroll interne
                  itemCount: walletData!.transactions.length,
                  itemBuilder: (context, index) {
                    final transac = walletData!.transactions[index];
                    // Parsing simple de la date pour affichage
                    DateTime? dateT = DateTime.tryParse(transac.date);

                    return _buildTransactionTile(
                        context,
                        transac.titre,
                        "${transac.isCredit ? '+' : '-'} ${transac.montant} F",
                        dateT ?? DateTime.now(),
                        transac.isCredit
                    );
                  }
              )
            else
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Text("Aucune transaction récente", style: TextStyle(color: Colors.grey)),
                ),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionTile(BuildContext context, String title, String amount, DateTime date, bool isCredit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black12 : Colors.black.withOpacity(0.03);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
                color: shadowColor,
                blurRadius: 10,
                offset: const Offset(0, 2)
            )
          ]
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: isCredit ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                shape: BoxShape.circle
            ),
            child: Icon(
                isCredit ? Icons.arrow_downward : Icons.arrow_upward,
                color: isCredit ? Colors.green : Colors.red,
                size: 20
            ),
          ),
          const Gap(15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                const Gap(4),
                Text(
                    DateFormat('dd/MM • HH:mm').format(date),
                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 12)
                ),
              ],
            ),
          ),
          Text(
              amount,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isCredit ? Colors.green : textColor
              )
          ),
        ],
      ),
    );
  }
}