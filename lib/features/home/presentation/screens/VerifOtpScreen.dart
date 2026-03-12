import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; // 🟢 NOUVEAU : Import FCM

import '../../../../core/services/notifications/global_otp_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import 'main_wrapper_screen.dart';

class VerifOtpScreen extends StatefulWidget {
  final String email;
  final String contact;

  const VerifOtpScreen({super.key, required this.email, required this.contact});

  @override
  State<VerifOtpScreen> createState() => _VerifOtpScreenState();
}

class _VerifOtpScreenState extends State<VerifOtpScreen> {
  final List<TextEditingController> _controllers = List.generate(
    6,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(6, (index) => FocusNode());

  bool _isLoading = false;
  bool _canResend = false;

  int _validitySeconds = 600;
  int _resendSeconds = 600;
  Timer? _timer;

  // 1. Remplace l'abonnement FCM par un abonnement String
  StreamSubscription<String>? _otpSubscription;

  @override
  void initState() {
    super.initState();
    _startCountdown();
    _listenForOtpNotification(); // 🟢 NOUVEAU : On lance l'écoute au démarrage de l'écran
  }

  // --- 🟢 NOUVELLE LOGIQUE : AUTO-REMPLISSAGE OTP ---
  /*void _listenForOtpNotification() {
    _fcmSubscription = FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("🔔 [VerifOtpScreen] Notification reçue au premier plan !");

      // On récupère le texte du message (soit dans la notification, soit dans les datas invisibles)
      String textToAnalyze = message.notification?.body ?? message.data['body'] ?? message.data['message'] ?? "";

      if (textToAnalyze.isNotEmpty) {
        // Expression régulière : on cherche exactement 6 chiffres d'affilée isolés
        RegExp regExp = RegExp(r'\b\d{6}\b');
        Match? match = regExp.firstMatch(textToAnalyze);

        if (match != null) {
          String extractedOtp = match.group(0)!;
          print("✅ [VerifOtpScreen] Code OTP trouvé : $extractedOtp");
          _autoFillOtp(extractedOtp);
        }
      }
    });
  }*/

  // 2. Modifie la méthode d'écoute :
  void _listenForOtpNotification() {
    // On écoute notre flux global personnalisé
    _otpSubscription = GlobalOtpService.otpStream.stream.listen((String otp) {
      print(
        "✅ [VerifOtpScreen] OTP intercepté depuis le service global : $otp",
      );
      _autoFillOtp(otp);
    });
  }

  void _autoFillOtp(String otp) {
    if (otp.length == 6 && mounted) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = otp[i];
      }
      setState(() {});
      _showTopNotification("Code détecté automatiquement !", isError: false);

      // On lance automatiquement la vérification
      _verifyCode();
    }
  }
  // --------------------------------------------------

  void _startCountdown() {
    _timer?.cancel();
    setState(() {
      _validitySeconds = 600;
      _resendSeconds = 600;
      _canResend = false;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_validitySeconds > 0) {
            _validitySeconds--;
            _resendSeconds--;
          } else {
            _canResend = true;
            _timer?.cancel();
          }
        });
      }
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return "$minutes:${remainingSeconds.toString().padLeft(2, '0')}";
  }

  void _showTopNotification(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFF222222) : Colors.green.shade700,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isError ? Icons.info_outline : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  // 3. N'oublie pas de nettoyer dans le dispose() :
  @override
  void dispose() {
    _timer?.cancel();
    _otpSubscription?.cancel(); // 🟢 On coupe l'écoute globale ici
    for (var c in _controllers) c.dispose();
    for (var f in _focusNodes) f.dispose();
    super.dispose();
  }

  Future<void> _handleResendCode() async {
    if (!_canResend) return;
    setState(() => _isLoading = true);
    try {
      final authRepo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );
      await authRepo.sendOtp(widget.email);
      _showTopNotification("Nouveau code envoyé !", isError: false);

      // On vide les champs si on renvoie un code
      for (var c in _controllers) {
        c.clear();
      }

      _startCountdown();
    } catch (e) {
      _showTopNotification("Erreur : ${e.toString()}", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyCode() async {
    String otpCode = _controllers.map((e) => e.text).join();
    if (otpCode.length < 6) return;

    setState(() => _isLoading = true);
    try {
      final authRepo = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),
        deviceService: DeviceService(),
      );

      await authRepo.verifyOtp(widget.contact, otpCode);
      if (!mounted) return;

      _showTopNotification("Code vérifié avec succès !", isError: false);

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      _showTopNotification(
        e.toString().replaceAll("Exception:", ""),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFF18C6E);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 40,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: primaryColor.withOpacity(0.1),
                      child: Icon(
                        Icons.shield_outlined,
                        color: primaryColor,
                        size: 35,
                      ),
                    ),
                    const Gap(20),
                    const Text(
                      "Vérification OTP 🔐",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(10),
                    const Text(
                      "Saisissez le code envoyé au",
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const Gap(10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F4F8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.contact,
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Gap(30),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(
                        6,
                        (index) => _buildOtpBox(index, primaryColor),
                      ),
                    ),
                    const Gap(30),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: Colors.orange,
                          ),
                          const Gap(8),
                          Text(
                            "Expire dans : ${_formatTime(_validitySeconds)}",
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(30),

                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Vérifier maintenant",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                    const Gap(25),

                    const Divider(),
                    const Gap(15),

                    _canResend
                        ? TextButton.icon(
                            onPressed: _isLoading ? null : _handleResendCode,
                            icon: const Icon(Icons.refresh),
                            label: const Text(
                              "Renvoyer un nouveau code",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          )
                        : Column(
                            children: [
                              const Text(
                                "Code encore valide.",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const Gap(5),
                              Text(
                                "Renvoi possible dans ${_formatTime(_resendSeconds)}",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              const Gap(20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "← Retour",
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index, Color primary) {
    return Container(
      width: 44,
      height: 54,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focusNodes[index].hasFocus ? primary : Colors.grey.shade300,
          width: 2,
        ),
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        textAlign: TextAlign.center,
        textAlignVertical: TextAlignVertical.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        cursorColor: primary,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.black,
          height: 1.2,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          counterText: "",
          border: InputBorder.none,
          isDense: true,
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            _focusNodes[index + 1].requestFocus();
          } else if (value.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
          }
          if (index == 5 && value.isNotEmpty) _verifyCode();
          setState(() {});
        },
      ),
    );
  }
}
