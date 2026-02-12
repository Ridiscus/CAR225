import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/providers/user_provider.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  // --- ETAT ---
  int _selectedOperator = -1; // -1 = aucun, 0 = Orange, 1 = MTN, etc.
  int _amount = 5000; // Montant par défaut
  final int _step = 500;
  bool _isLoading = false;

  late TextEditingController _amountController; // 1. Le contrôleur

  @override
  void initState() {
    super.initState();
    // 2. Initialisation avec la valeur par défaut
    _amountController = TextEditingController(text: _amount.toString());
  }

  @override
  void dispose() {
    _amountController.dispose(); // 3. Nettoyage
    super.dispose();
  }

  // --- LOGIQUE MISE A JOUR ---

  // Fonction centrale pour mettre à jour la valeur ET le champ texte
  void _updateAmount(int newAmount) {
    setState(() {
      _amount = newAmount;
      // On met à jour le texte seulement si on utilise les boutons
      // (pour ne pas gêner si l'utilisateur est en train de taper)
      _amountController.text = _amount.toString();
    });
  }

  void _incrementAmount() {
    _updateAmount(_amount + _step);
  }

  void _decrementAmount() {
    if (_amount > 500) {
      _updateAmount(_amount - _step);
    }
  }

  void _addAmount(int value) {
    _updateAmount(_amount + value);
  }

  // Nouvelle fonction appelée quand l'utilisateur tape au clavier
  void _onAmountTyped(String value) {
    if (value.isEmpty) {
      setState(() => _amount = 0);
      return;
    }
    // On nettoie l'entrée (au cas où) et on convertit
    int? parsed = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (parsed != null) {
      setState(() => _amount = parsed);
    }
  }




  void _showTopNotification(String message, {bool isError = false}) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutBack, // Le rebond est conservé pour le mouvement
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (1 - value)), // Effet de glissement
                child: Opacity(
                  // ✅ CORRECTION ICI : On force la valeur entre 0 et 1
                  opacity: value.clamp(0.0, 1.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                        color: const Color(0xFF222222),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          )
                        ]
                    ),
                    child: Row(
                        children: [
                          Icon(
                              isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                              color: isError ? Colors.redAccent : Colors.greenAccent,
                              size: 24
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                              child: Text(
                                  message,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14)
                              )
                          )
                        ]
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () => overlayEntry.remove());
  }



  // --- 🚀 LOGIQUE PAIEMENT BACKEND ---
  Future<void> _initiateDeposit() async {
    // 1. Validation locale : On vérifie qu'un opérateur est choisi
    if (_selectedOperator == -1) {
      _showTopNotification("Veuillez sélectionner un opérateur", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 2. Récupération Token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      // 3. Config Dio
      final dio = Dio(BaseOptions(
        baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 15), // Augmenté un peu pour le mobile
      ));

      // 4. Données (Payload)
      // J'envoie l'amount. J'ajoute aussi l'opérateur au cas où ton backend
      // voudrait l'enregistrer pour des stats, sinon il sera juste ignoré par Laravel.
      final data = {
        'amount': _amount,
        'operator_id': _selectedOperator, // Optionnel
        'payment_method': 'cinetpay'      // Optionnel
      };

      print("📤 Envoi vers /user/wallet/recharge : $data");

      // 5. Appel API
      final response = await dio.post('/user/wallet/recharge', data: data);

      print("📥 Réponse Backend : ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {

        // --- CORRECTION ICI ---
        // On va chercher dans payment_details
        final paymentDetails = response.data['payment_details'];
        final paymentUrl = paymentDetails != null ? paymentDetails['payment_url'] : null;

        if (paymentUrl != null && paymentUrl.toString().isNotEmpty) {
          _showTopNotification("Redirection vers le paiement... 🚀");
          await Future.delayed(const Duration(milliseconds: 500));
          await _launchPaymentUrl(paymentUrl);
        } else {
          throw Exception("L'URL de paiement est introuvable dans la réponse.");
        }
      }
    } catch (e) {
      print("🔴 Erreur API : $e");
      String message = "Impossible d'initier le paiement.";

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          message = "Vérifiez votre connexion internet.";
        } else if (e.response != null) {
          // Gestion des erreurs Laravel (400, 422, 500)
          print("Erreur Data: ${e.response?.data}");
          if (e.response?.data is Map && e.response?.data['message'] != null) {
            message = e.response?.data['message'];
          } else {
            message = "Erreur serveur (${e.response?.statusCode})";
          }
        }
      }
      _showTopNotification(message, isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Ouvre le navigateur externe
  Future<void> _launchPaymentUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        _showTopNotification("Impossible d'ouvrir le navigateur", isError: true);
      }
    } catch (e) {
      _showTopNotification("Erreur lors de l'ouverture du lien", isError: true);
    }
  }






  @override
  Widget build(BuildContext context) {
    // --- 1. RECUPERATION DE L'UTILISATEUR ---
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    final String userName = user != null ? "${user.name} ${user.prenom}" : "Membre CAR 225";
    final String? userPhotoUrl = user?.photoUrl;

    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        title: Text("RECHARGER", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textColor)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // --- BOUTON PAYER CORRIGÉ ---
      // ✅ On ajoute SafeArea ici pour "pousser" le bouton au-dessus de la barre Android
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: (_isLoading || _selectedOperator == -1 || _amount <= 0) ? null : _initiateDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_selectedOperator == -1 || _amount <= 0) ? Colors.grey : const Color(0xFFE64A19),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 5,
              ),
              child: _isLoading
                  ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                  : Text(
                "PAYER $_amount FCFA",
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("MA CARTE VIRTUELLE", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            const Gap(10),

            // --- 1. CARTE STYLE "CREDIT CARD" PREMIUM ---
            Container(
              width: double.infinity,
              height: 240,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFbf360c), Color(0xFFff7043)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE64A19).withOpacity(0.5),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Stack(
                  children: [
                    // ARRIÈRE-PLAN
                    Positioned(
                      right: -40,
                      bottom: -40,
                      child: Transform.rotate(
                        angle: -0.5,
                        child: Opacity(
                          opacity: 0.15,
                          child: Image.asset(
                            "assets/images/busheader.png",
                            width: 250,
                            errorBuilder: (c, o, s) => const Icon(Icons.directions_car, size: 250, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -50,
                      left: -50,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),

                    // CONTENU CARTE
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // HEADER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white24,
                                      backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl) : null,
                                      child: userPhotoUrl == null
                                          ? const Icon(Icons.person, color: Colors.white)
                                          : null,
                                    ),
                                  ),
                                  const Gap(12),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName.toUpperCase(),
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
                                      ),
                                      Text(
                                        "Membre CAR 225",
                                        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Icon(Icons.wifi, color: Colors.white54, size: 28),
                            ],
                          ),
                          const Spacer(),

                          // MONTANT
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("SOLDE A AJOUTER", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 10, letterSpacing: 2)),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    IntrinsicWidth(
                                      child: TextField(
                                        controller: _amountController,
                                        keyboardType: TextInputType.number,
                                        onChanged: _onAmountTyped,
                                        textAlign: TextAlign.center,
                                        cursorColor: Colors.white,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 42,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 1,
                                            fontFamily: "Monospace"
                                        ),
                                        decoration: const InputDecoration(
                                          border: InputBorder.none,
                                          filled: true,
                                          fillColor: Colors.transparent,
                                          contentPadding: EdgeInsets.zero,
                                          isDense: true,
                                          hintText: "0",
                                          hintStyle: TextStyle(color: Colors.white38),
                                        ),
                                      ),
                                    ),
                                    const Text(
                                      " FCFA",
                                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),

                          // CHIPS
                          SizedBox(
                            height: 35,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                _buildGlassChip(context, "+1.000", 1000),
                                const Gap(8),
                                _buildGlassChip(context, "+2.000", 2000),
                                const Gap(8),
                                _buildGlassChip(context, "+5.000", 5000),
                                const Gap(8),
                                _buildGlassChip(context, "+10.000", 10000),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(30),

            // --- 2. OPERATEURS ---
            Text("MOYEN DE PAIEMENT", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            const Gap(15),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 15,
              mainAxisSpacing: 15,
              childAspectRatio: 1.6,
              children: [
                _buildSelectableOperator(
                  index: 0,
                  color: cardColor,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Image.asset("assets/images/om.png", fit: BoxFit.contain),
                  ),
                ),
                _buildSelectableOperator(
                  index: 1,
                  color: const Color(0xFFFFCC00),
                  isBrandColor: true,
                  child: Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Image.asset("assets/images/MTNmoney.png", fit: BoxFit.contain),
                  ),
                ),
                _buildSelectableOperator(
                  index: 2,
                  color: const Color(0xFF5EC2F2),
                  isBrandColor: true,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Image.asset("assets/images/wavee.png", fit: BoxFit.contain),
                  ),
                ),
                _buildSelectableOperator(
                  index: 3,
                  color: cardColor,
                  isBrandColor: false,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.asset("assets/images/moov.png", width: double.infinity, height: double.infinity, fit: BoxFit.cover),
                  ),
                ),
              ],
            ),
            const Gap(80),
          ],
        ),
      ),
    );
  }





  // --- WIDGET HELPER : CHIP STYLE "GLASS" ---
  Widget _buildGlassChip(BuildContext context, String label, int value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _addAmount(value),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            // Fond blanc semi-transparent
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
            // Bordure subtile
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 1),
          ),
          child: Text(
            label,
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13
            ),
          ),
        ),
      ),
    );
  }







  // --- WIDGET HELPER : CHIP MONTANT ---
  Widget _buildAmountChip(BuildContext context, String label, int value) {
    return InkWell(
      onTap: () => _addAmount(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.5), width: 1)
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ),
    );
  }

  // --- WIDGET HELPER : CARTE OPÉRATEUR ---
  Widget _buildSelectableOperator({
    required int index,
    required Color color,
    required Widget child,
    bool isBrandColor = false,
  }) {
    final isSelected = _selectedOperator == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _selectedOperator = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transform: isSelected ? Matrix4.identity().scaled(1.02) : Matrix4.identity(),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected ? const Color(0xFFE64A19) : Colors.transparent,
            width: isSelected ? 3 : 0,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? const Color(0xFFE64A19).withOpacity(0.4)
                  : Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: isSelected ? 15 : 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: ColorFiltered(
          colorFilter: isSelected
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : const ColorFilter.matrix(<double>[
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0.2126, 0.7152, 0.0722, 0, 0,
            0, 0, 0, 1, 0,
          ]),
          child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
              child: child
          ),
        ),
      ),
    );
  }
}