import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart'; // 🟢 Ajout pour formater proprement l'argent

import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/networking/api_config.dart';

class TopUpScreen extends StatefulWidget {
  const TopUpScreen({super.key});

  @override
  State<TopUpScreen> createState() => _TopUpScreenState();
}

class _TopUpScreenState extends State<TopUpScreen> {
  // --- ETAT ---
  int _amount = 100;
  final int _step = 500;
  bool _isLoading = false;
  late TextEditingController _amountController;

  static Uri? _lastProcessedUri;

  // --- 🔗 VARIABLES POUR LES DEEP LINKS ---
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: _amount.toString());
    _initDeepLinks();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _linkSubscription?.cancel();
    super.dispose();
  }

  // Helper pour formater l'argent
  String _formatCurrency(int amount) {
    return NumberFormat.currency(locale: 'fr_FR', symbol: '', decimalDigits: 0).format(amount).trim();
  }

  // --- 🎧 LOGIQUE D'ÉCOUTE DES LIENS ---
  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      _handleDeepLink(initialUri);
    }

    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      print("Erreur Deep Link: $err");
    });
  }

  // --- 🛠️ TRAITEMENT DU LIEN REÇU ---
  Future<void> _handleDeepLink(Uri uri) async {
    print("🔗 Lien reçu : $uri");
    if (!mounted) return;

    if (uri.scheme == 'car225' && uri.host == 'payment') {
      final transactionId = uri.queryParameters['transactionId'];

      if (transactionId != null) {
        final prefs = await SharedPreferences.getInstance();
        final bool isAlreadyProcessed = prefs.getBool('processed_$transactionId') ?? false;

        if (isAlreadyProcessed) {
          print("⚠️ Transaction $transactionId déjà traitée, on ignore !");
          return;
        }

        await prefs.setBool('processed_$transactionId', true);
      }

      final isSuccess = uri.queryParameters['success'] == 'true';

      if (isSuccess) {
        await context.read<UserProvider>().loadUser();
        if (!mounted) return;

        showDialog(
            context: context,
            barrierDismissible: false,
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
                        Navigator.pop(dialogContext);
                        Navigator.pop(context, true);
                      },
                      child: const Text("Génial", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              );
            }
        );

      } else {
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
                      onPressed: () {
                        Navigator.pop(dialogContext);
                      },
                      child: const Text("Fermer", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    if (_amount <= 0) {
      _showTopNotification("Veuillez entrer un montant valide", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    _lastProcessedUri = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 15),
      ));

      // ⚠️ IMPORTANT : On envoie "_amount" (le montant net à recharger).
      // Si ton API gère les 2% de son côté, c'est bon.
      // Si c'est à l'appli d'envoyer le total (net + frais), il faut envoyer "totalAmount" ici.
      final data = {
        'amount': _amount,
        'payment_method': 'wave',
      };

      final response = await dio.post('/user/wallet/recharge', data: data);

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
      String message = "Impossible d'initier le paiement.";
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout) {
          message = "Vérifiez votre connexion internet.";
        } else if (e.response != null) {
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

  /*Future<void> _initiateDeposit() async {
    if (_amount <= 0) {
      _showTopNotification("Veuillez entrer un montant valide", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    _lastProcessedUri = null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 15),
      ));

      final data = {
        'amount': _amount,
        'payment_method': 'wave',
      };

      final response = await dio.post('/user/wallet/recharge', data: data);

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
      // ... gestion d'erreur inchangée
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }*/

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

    // 🟢 CALCUL DES FRAIS
    final int fees = (_amount * 0.02).toInt();
    final int totalAmount = _amount + fees;

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

      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Pour ne pas prendre toute la hauteur
            children: [
              // 🟢 INFO FRAIS JUSTE AU-DESSUS DU BOUTON
              if (_amount > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Frais Wave (2%)",
                        style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[700], fontSize: 14),
                      ),
                      Text(
                        "+ ${_formatCurrency(fees)} F",
                        style: TextStyle(
                            color: isDark ? Colors.grey[300] : Colors.black87,
                            fontSize: 14,
                            fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),

              // BOUTON PAYER
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (_isLoading || _amount <= 0) ? null : _initiateDeposit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (_amount <= 0) ? Colors.grey : const Color(0xFFE64A19),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 25, height: 25, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
                      : Text(
                    "PAYER ${_formatCurrency(totalAmount)} F", // 🟢 Affichage du total
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
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

            Container(
              width: double.infinity,
              height: 290,
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
                    Positioned(
                      right: -20,
                      bottom: -30,
                      child: Transform.rotate(
                        angle: -0.2,
                        child: Text(
                          "CAR 225",
                          style: TextStyle(
                            fontSize: 120,
                            fontWeight: FontWeight.w900,
                            color: Colors.white.withOpacity(0.03),
                            letterSpacing: -5,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(25.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFE64A19).withOpacity(0.8), width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white12,
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
                                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const Icon(Icons.contactless_outlined, color: Colors.white54, size: 28),
                            ],
                          ),

                          const Spacer(),

                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                    "MONTANT À RECHARGER", // 🟢 Petit changement de texte
                                    style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 11, letterSpacing: 1.5, fontWeight: FontWeight.bold)
                                ),
                                const Gap(8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: IntrinsicWidth(
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: IntrinsicWidth(
                                            child: TextField(
                                              controller: _amountController,
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                LengthLimitingTextInputFormatter(7),
                                              ],
                                              onChanged: _onAmountTyped,
                                              textAlign: TextAlign.center,
                                              cursorColor: const Color(0xFFE64A19),
                                              style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 42,
                                                  fontWeight: FontWeight.w900,
                                                  fontFamily: "Montserrat"
                                              ),
                                              decoration: const InputDecoration(
                                                border: InputBorder.none,
                                                filled: true,
                                                fillColor: Colors.transparent,
                                                contentPadding: EdgeInsets.zero,
                                                isDense: true,
                                                hintText: "0",
                                                hintStyle: TextStyle(color: Colors.white24),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const Gap(8),
                                        const Text(
                                          "FCFA",
                                          style: TextStyle(
                                              color: Color(0xFFE64A19),
                                              fontSize: 16,
                                              fontWeight: FontWeight.w800
                                          ),
                                        ),
                                        const Gap(10),
                                        const Icon(Icons.edit, color: Colors.white54, size: 18),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildGlassChip(context, "+1.000", 1000),
                              const Gap(10),
                              _buildGlassChip(context, "+2.000", 2000),
                              const Gap(10),
                              _buildGlassChip(context, "+5.000", 5000),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(30),

            Text("MOYEN DE PAIEMENT", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.blueGrey, fontSize: 12, fontWeight: FontWeight.bold)),
            const Gap(15),

            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF5EC2F2).withOpacity(0.1),
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
                      "assets/images/wavee.png",
                      fit: BoxFit.contain,
                      errorBuilder: (c, o, s) => const Icon(Icons.waves, color: Colors.blue),
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    const Text(
                      "Paiement Mobile",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const Gap(8),
                    // 🟢 BADGE INFORMATIF SUR LA TUILE WAVE
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange, width: 1),
                      ),
                      child: const Text(
                        "2% frais",
                        style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
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