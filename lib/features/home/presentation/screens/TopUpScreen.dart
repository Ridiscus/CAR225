import 'dart:async';

import 'package:app_links/app_links.dart';
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
  // On a supprimé _selectedOperator qui ne sert plus à rien
  int _amount = 100; // Montant par défaut
  final int _step = 500;
  bool _isLoading = false;
  late TextEditingController _amountController;


  // --- 🔗 VARIABLES POUR LES DEEP LINKS ---
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: _amount.toString());

    // Initialiser l'écouteur de liens au démarrage de l'écran
    _initDeepLinks();
  }

  @override
  void dispose() {
    _amountController.dispose();
    // ⚠️ IMPORTANT : Annuler l'écoute pour éviter les fuites de mémoire
    _linkSubscription?.cancel();
    super.dispose();
  }

  // --- 🎧 LOGIQUE D'ÉCOUTE DES LIENS ---
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Cas où l'application était COMPLÈTEMENT FERMÉE et est réveillée par le lien
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    // 2. Cas où l'application était juste EN ARRIÈRE-PLAN (le cas le plus fréquent avec Wave)
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print("Erreur Deep Link: $err");
    });
  }

  // --- 🛠️ TRAITEMENT DU LIEN REÇU ---
  /*void _handleDeepLink(Uri uri) {
    print("🔗 Lien reçu : $uri");

    // On vérifie que c'est bien notre scheme (car225://) et notre host (payment)
    if (uri.scheme == 'car225' && uri.host == 'payment') {

      // Si le backend redirige vers car225://payment/success
      if (uri.path == '/success') {
        _showTopNotification("Paiement réussi ! 🎉 Ton wallet est rechargé.");

        // 💡 BONUS : Ici tu peux appeler une fonction pour rafraîchir le solde
        // de l'utilisateur depuis l'API !

      }
      // Si le backend redirige vers car225://payment/error ou /cancel
      else if (uri.path == '/error' || uri.path == '/cancel') {
        _showTopNotification("Le paiement a échoué ou a été annulé.", isError: true);
      }
    }
  }*/

  // --- 🛠️ TRAITEMENT DU LIEN REÇU ---
  // --- 🛠️ TRAITEMENT DU LIEN REÇU ---
  void _handleDeepLink(Uri uri) {
    print("🔗 Lien reçu : $uri");
    if (!mounted) return; // Sécurité pour éviter les crashs de contexte

    // On vérifie que c'est bien notre scheme (car225) et notre host (payment)
    if (uri.scheme == 'car225' && uri.host == 'payment') {

      // 💡 CORRECTION ICI : On lit le paramètre "?success=true" ou "?success=false"
      final isSuccess = uri.queryParameters['success'] == 'true';
      final isCancel = uri.queryParameters['cancel'] == 'true'; // Au cas où le backend envoie cancel=true

      if (isSuccess) {
        // 1. 🔄 Rafraîchir le solde du Wallet en arrière-plan
        context.read<UserProvider>().loadUser();

        // 2. 🎉 Afficher la belle modale de Succès
        showDialog(
            context: context,
            barrierDismissible: false, // Force l'utilisateur à cliquer sur le bouton
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Column(
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 70),
                    Gap(15),
                    Text("Paiement Réussi !", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22), textAlign: TextAlign.center),
                  ],
                ),
                content: const Text(
                  "Ton compte CAR 225 a été rechargé avec succès. Ton nouveau solde est disponible.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () {
                        // 3. 🔙 On ferme la modale
                        Navigator.pop(dialogContext);
                        // 4. 🔙 On ramène l'utilisateur à l'écran du Wallet
                        Navigator.pop(context);
                      },
                      child: const Text("Génial", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }
        );

      } else {
        // ❌ Gérer l'erreur ou l'annulation si success n'est pas "true"
        showDialog(
            context: context,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: const Column(
                  children: [
                    Icon(Icons.cancel_outlined, color: Colors.redAccent, size: 70),
                    Gap(15),
                    Text("Paiement Échoué", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22), textAlign: TextAlign.center),
                  ],
                ),
                content: const Text(
                  "Le paiement n'a pas pu aboutir ou a été annulé. Aucun montant n'a été débité.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                ),
                actions: [
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: () => Navigator.pop(dialogContext), // On ferme juste la modale
                      child: const Text("Réessayer", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }
        );
      }
    }
  }

  // --- LOGIQUE MISE A JOUR ---
  void _updateAmount(int newAmount) {
    setState(() {
      _amount = newAmount;
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

  void _onAmountTyped(String value) {
    if (value.isEmpty) {
      setState(() => _amount = 0);
      return;
    }
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
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -20 * (1 - value)),
                child: Opacity(
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

  // --- 🚀 LOGIQUE PAIEMENT BACKEND (WAVE) ---
  Future<void> _initiateDeposit() async {
    // 1. Validation locale : On vérifie que le montant est valide
    if (_amount <= 0) {
      _showTopNotification("Veuillez entrer un montant valide", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio(BaseOptions(
        baseUrl: 'https://car225.com/api/',
        //baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 15),
      ));

      // 4. Données (Payload Wave)
      final data = {
        'amount': _amount,
        'payment_method': 'wave',
      };

      print("📤 Envoi vers /user/wallet/recharge : $data");

      final response = await dio.post('/user/wallet/recharge', data: data);

      print("📥 Réponse Backend : ${response.data}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String? paymentUrl = response.data['payment_url'];

        if (paymentUrl != null && paymentUrl.isNotEmpty) {
          _showTopNotification("Redirection vers Wave... 🚀");
          await Future.delayed(const Duration(milliseconds: 500));
          await _launchPaymentUrl(paymentUrl);
        } else {
          final paymentDetails = response.data['payment_details'];
          final fallbackUrl = paymentDetails != null ? paymentDetails['payment_url'] : null;

          if (fallbackUrl != null && fallbackUrl.toString().isNotEmpty) {
            _showTopNotification("Redirection vers Wave... 🚀");
            await Future.delayed(const Duration(milliseconds: 500));
            await _launchPaymentUrl(fallbackUrl);
          } else {
            throw Exception("L'URL de paiement Wave est introuvable dans la réponse.");
          }
        }
      }
    } catch (e) {
      print("🔴 Erreur API : $e");
      String message = "Impossible d'initier le paiement.";

      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          message = "Vérifiez votre connexion internet.";
        } else if (e.response != null) {
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
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    final String userName = user != null ? "${user.name} ${user.prenom}" : "Membre CAR 225";
    final String? userPhotoUrl = user?.photoUrl;

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

      // --- BOUTON PAYER ---
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              // ✅ Le bouton est cliquable dès que le montant est > 0
              onPressed: (_isLoading || _amount <= 0) ? null : _initiateDeposit,
              style: ElevatedButton.styleFrom(
                backgroundColor: (_amount <= 0) ? Colors.grey : const Color(0xFFE64A19),
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

            // --- 2. MOYEN DE PAIEMENT (WAVE UNIQUE) ---
            Text("MOYEN DE PAIEMENT", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            const Gap(15),

            // ✅ Carte Unique pour Wave
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5EC2F2).withOpacity(0.1), // Bleu léger de Wave
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: const Color(0xFF5EC2F2), width: 2),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                leading: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      "assets/images/wavee.png", // Assure-toi que cette image existe
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => const Icon(Icons.waves, color: Colors.blue),
                    ),
                  ),
                ),
                title: const Text(
                  "Paiement Mobile",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                subtitle: const Text(
                  "Sécurisé par Wave",
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
                trailing: const Icon(Icons.check_circle, color: Color(0xFF5EC2F2)),
              ),
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
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(15),
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
}