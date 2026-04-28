import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Imports Clean Arch
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/networking/api_config.dart';
import '../../../wallet/data/datasources/wallet_remote_data_source.dart';
import '../../../wallet/data/models/wallet_model.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import 'TopUpScreen.dart';
import 'main_wrapper_screen.dart';

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
        // 🟢 UTILISATION DE L'INTERRUPTEUR MAGIQUE
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          // ✅ On s'assure d'envoyer le token fraîchement récupéré
          'Authorization': 'Bearer $token',
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
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        // 🟢 NOUVEAU : Remplacement du Text par Image.asset
        title: Image.asset(
          "assets/images/carpay_logo.png", // 👈 Mets le bon chemin ici
          height: 75, // Ajuste la taille pour que ça rentre bien dans l'AppBar
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
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
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const Gap(10),
          Text(errorMessage!, style: TextStyle(color: textColor)),
          TextButton(onPressed: _fetchWalletData, child: const Text("Réessayer"))
        ],
      ))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // --- CARTE DARK PREMIUM ---
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF161822),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Stack(
                  children: [
                    // FILIGRANE
                    Positioned(
                      right: -30,
                      bottom: -30,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Text(
                          "CAR",
                          style: TextStyle(
                            fontSize: 150,
                            fontWeight: FontWeight.w900,
                            color: Colors.green.withOpacity(0.2),
                            letterSpacing: -5,
                          ),
                        ),
                      ),
                    ),

                    // CONTENU CARTE
                    Padding(
                      padding: const EdgeInsets.all(25),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "SOLDE ACTUEL",
                            style: TextStyle(
                                color: Color(0xFF9E9E9E),
                                fontSize: 11,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.bold
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
                                        fontSize: 38,
                                        fontWeight: FontWeight.w900,
                                        fontFamily: 'Montserrat'
                                    )
                                ),
                                const TextSpan(
                                    text: "FCFA",
                                    style: TextStyle(
                                        color: Color(0xFFE64A19),
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800
                                    )
                                ),
                              ],
                            ),
                          ),
                          const Gap(30),
                          Row(
                            children: [
                              // BOUTON RECHARGER
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (context) => const TopUpScreen())
                                    );
                                    if (context.mounted) {
                                      context.read<UserProvider>().loadUser();
                                      _fetchWalletData();
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      backgroundColor: const Color(0xFFE64A19),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  icon: const Icon(Icons.add_circle_outline, size: 18),
                                  label: const Text("Recharger", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              const Gap(10),

                              // BOUTON RÉSERVER
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.pushAndRemoveUntil(
                                        context,
                                        MaterialPageRoute(builder: (context) => const MainScreen()),
                                            (route) => false
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 13),
                                      backgroundColor: Colors.white.withOpacity(0.1),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                                  ),
                                  icon: const Icon(Icons.directions_bus_outlined, size: 18),
                                  label: const Text("Réserver", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Gap(30),

            // --- LISTE DES TRANSACTIONS ---
            Text("Dernières transactions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const Gap(15),

            if (walletData != null && walletData!.transactions.isNotEmpty)
              ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: walletData!.transactions.length,
                  itemBuilder: (context, index) {
                    final transac = walletData!.transactions[index];
                    DateTime? dateT = DateTime.tryParse(transac.date);

                    return _buildTransactionTile(
                      context: context,
                      title: transac.titre,
                      amountText: "${transac.isCredit ? '+' : '-'} ${transac.montant} F",
                      date: dateT ?? DateTime.now(),
                      isCredit: transac.isCredit,
                      status: transac.status,
                    );
                  }
              )
            else
            // 🟢 ICI ON APPELLE NOTRE NOUVELLE INTERFACE ÉLÉGANTE
              _buildEmptyTransactions(context),

          ],
        ),
      ),
    );
  }

  // --- ÉTAT VIDE POUR LES TRANSACTIONS ---
  Widget _buildEmptyTransactions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = const Color(0xFFE64A19); // La même couleur que ton bouton Recharger

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Le "Sticker" élégant pour les transactions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: brandColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.receipt_long_outlined, size: 60, color: brandColor), // Icône de reçu/historique
          ),

          const Gap(20),

          // Titre
          Text(
            "Aucune transaction",
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : Colors.black87
            ),
          ),

          const Gap(8),

          // Description
          Text(
            "Votre historique est vide. Effectuez une recharge ou achetez un billet pour voir vos opérations ici.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // 🟢 NOUVELLE MÉTHODE DE TUILE GÉRANT LES 3 STATUTS
  Widget _buildTransactionTile({
    required BuildContext context,
    required String title,
    required String amountText,
    required DateTime date,
    required bool isCredit,
    required String status,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final defaultTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black12 : Colors.black.withOpacity(0.03);

    // --- LOGIQUE DES COULEURS ET ICÔNES SELON LE STATUT ---
    Color iconColor;
    IconData iconData;
    String badgeText = "";
    Color? badgeColor;

    bool isFailed = status == 'failed';
    bool isPending = status == 'pending';
    bool isCompleted = status == 'completed';

    if (isFailed) {
      iconColor = Colors.redAccent;
      iconData = Icons.close;
      badgeText = "Échoué";
      badgeColor = Colors.red;
    } else if (isPending) {
      iconColor = Colors.orange;
      iconData = Icons.schedule; // Icône d'horloge pour l'attente
      badgeText = "En attente";
      badgeColor = Colors.orange;
    } else {
      // Completed (Succès)
      iconColor = isCredit ? Colors.green : Colors.redAccent;
      iconData = isCredit ? Icons.arrow_downward : Icons.arrow_upward;
    }

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
          // 🟢 ICÔNE
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle
            ),
            child: Icon(iconData, color: iconColor, size: 20),
          ),
          const Gap(15),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🟢 TITRE
                Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isFailed ? Colors.grey : defaultTextColor,
                      decoration: isFailed ? TextDecoration.lineThrough : null, // Barré si échec
                    )
                ),
                const Gap(4),
                // 🟢 DATE ET BADGE DE STATUT
                Row(
                  children: [
                    Text(
                        DateFormat('dd/MM • HH:mm').format(date),
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey, fontSize: 12)
                    ),
                    // Affichage du badge seulement si En attente ou Échoué
                    if (isPending || isFailed) ...[
                      const Gap(8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor!.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                            badgeText,
                            style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)
                        ),
                      )
                    ]
                  ],
                ),
              ],
            ),
          ),

          // 🟢 MONTANT
          Text(
              amountText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                // Couleur : Gris si échec, Orange si en attente, Vert/Rouge si succès
                color: isFailed
                    ? Colors.grey
                    : (isPending ? Colors.orange : (isCredit ? Colors.green : defaultTextColor)),
                decoration: isFailed ? TextDecoration.lineThrough : null, // Barré si échec
              )
          ),
        ],
      ),
    );
  }
}