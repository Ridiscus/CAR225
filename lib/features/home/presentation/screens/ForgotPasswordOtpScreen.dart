/*import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';

import 'ForgotPasswordResetScreen.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  const ForgotPasswordOtpScreen({super.key});

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _code = "";

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- NOTIFICATION STYLE IPHONE (Reste inchangée, bon contraste) ---
  void _showTopNotification(String message, {bool isError = false}) {
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
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: isError
                          ? Colors.redAccent.withOpacity(0.95)
                          : Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isError ? Icons.error_outline : Icons.check_circle_outline,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            message,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }


  // Fonction pour gérer la validation
  void _verifyCode() async {
    if (_code.length != 4) {
      _showTopNotification("Veuillez entrer les 4 chiffres", isError: true);
      FocusScope.of(context).requestFocus(_focusNode);
      return;
    }

    // 1. Afficher l'animation de succès
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Center(
          child: _SuccessAnimationWidget(),
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ForgotPasswordResetScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), // <--- ICONE DYNAMIQUE
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Vérification",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            RichText(
              text: TextSpan(
                style: TextStyle(color: secondaryTextColor, fontSize: 14, fontFamily: 'Arial'),
                children: [
                  const TextSpan(text: "Nous vous avons envoyé un code de vérification par e-mail.\n\n"),
                  TextSpan(
                      text: "eyeskouassi@gmail.com ",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold) // <--- Email en couleur dynamique
                  ),
                  const WidgetSpan(child: Icon(Icons.edit, size: 16, color: Colors.grey)),
                ],
              ),
            ),
            const Gap(40),

            // --- ZONE DE CODE OTP ---
            Center(
              child: SizedBox(
                height: 80,
                child: Stack(
                  children: [
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: 4,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          setState(() {
                            _code = value;
                          });
                          if (value.length == 4) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),

                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).requestFocus(_focusNode);
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          return _buildCodeBox(context, index); // On passe le context
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Gap(40),

            // Bouton Vérifier
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006400), // Vert foncé reste lisible en sombre
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("Vérifier le code", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const Gap(20),
            Center(
              child: TextButton(
                  onPressed: () {
                    // Logique renvoyer
                  },
                  child: Text(
                      "Renvoyer à nouveau",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                  )
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- DESIGN DES CASES ---
  Widget _buildCodeBox(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Vérifie si cette case contient un chiffre
    bool isFilled = index < _code.length;
    // Récupère le chiffre s'il existe
    String digit = isFilled ? _code[index] : "";
    // Est-ce la case active
    bool isFocused = index == _code.length;

    // COULEUR DE FOND LOGIQUE :
    // - Vide : Vert foncé (inchangé car branding)
    // - Rempli & Light Mode : Noir
    // - Rempli & Dark Mode : CardColor (Gris foncé) pour ne pas disparaître sur le fond noir
    Color fillColor;
    if (isFilled) {
      fillColor = isDark ? Theme.of(context).cardColor : Colors.black;
    } else {
      fillColor = const Color(0xFF006400);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 65,
      height: 75,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
        border: isFocused
            ? Border.all(color: Colors.orange, width: 2)
            : Border.all(color: Colors.transparent),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), // Ombre un peu plus forte en sombre
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: isFilled
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            digit,
            // Si le fond est noir ou gris foncé, le texte blanc est parfait
            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const Gap(2),
          // Les 3 petits points oranges décoratifs
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: 4, height: 4,
              decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            )),
          )
        ],
      )
          : Center(
        // Les 3 points blancs quand c'est vide
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) => Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 6, height: 6,
            decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle),
          )),
        ),
      ),
    );
  }
}

// --- WIDGET ANIMATION SUCCÈS ---
class _SuccessAnimationWidget extends StatefulWidget {
  const _SuccessAnimationWidget();

  @override
  State<_SuccessAnimationWidget> createState() => _SuccessAnimationWidgetState();
}

class _SuccessAnimationWidgetState extends State<_SuccessAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Thème interne au dialog
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: isDark ? cardColor : Colors.white, // <--- FOND DIALOG DYNAMIQUE
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const Gap(15),
            Text(
                "Vérifié !",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)
            ),
          ],
        ),
      ),
    );
  }
}*/







import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';

import '../../../auth/domain/repositories/auth_repository.dart';
import 'ForgotPasswordResetScreen.dart';

class ForgotPasswordOtpScreen extends StatefulWidget {
  final String email;

  const ForgotPasswordOtpScreen({
    super.key,
    required this.email,
  });

  @override
  State<ForgotPasswordOtpScreen> createState() => _ForgotPasswordOtpScreenState();
}

class _ForgotPasswordOtpScreenState extends State<ForgotPasswordOtpScreen> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _code = "";
  bool _isLoading = false;
  bool _isResending = false;

  // ✅ ON DÉFINIT LA LONGUEUR DU CODE ICI (FACILE À CHANGER)
  final int _otpLength = 6;

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }
// --- 1. LOGIQUE DE VÉRIFICATION (API) AVEC DEBUG ---
  void _verifyCode() async {
    print("🟢 [DEBUG] 1. Début de _verifyCode");
    print("👉 [DEBUG] Code saisi : '$_code' (Longueur : ${_code.length})");
    print("👉 [DEBUG] Email cible : '${widget.email}'");

    // Validation locale
    if (_code.length != _otpLength) {
      print("❌ [DEBUG] Validation échouée : Le code ne fait pas $_otpLength chiffres.");
      _showTopNotification("Veuillez entrer les $_otpLength chiffres", isError: true);
      FocusScope.of(context).requestFocus(_focusNode);
      return;
    }

    print("🔄 [DEBUG] 2. Validation OK. Activation du chargement...");
    setState(() => _isLoading = true);

    try {
      print("📡 [DEBUG] 3. Tentative d'appel au Repository (verifyOtp)...");

      // Appel API
      //await context.read<AuthRepository>().verifyOtp(widget.email, _code);
      // Appel API (Nouveau)
      await context.read<AuthRepository>().verifyPasswordOtp(widget.email, _code);

      print("✅ [DEBUG] 4. API SUCCÈS ! Le code est valide.");

      if (!mounted) {
        print("⚠️ [DEBUG] Widget démonté (utilisateur parti), on arrête.");
        return;
      }

      setState(() => _isLoading = false);

      // ✅ SUCCÈS : Animation
      print("🎨 [DEBUG] 5. Affichage de l'animation de succès...");
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Center(
            child: _SuccessAnimationWidget(),
          ),
        ),
      );

      // Attendre la fin de l'animation avant de changer d'écran
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        print("🚀 [DEBUG] 6. Navigation vers ForgotPasswordResetScreen");

        Navigator.pop(context); // Ferme le dialog

        // Navigation vers le reset
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordResetScreen(
                email: widget.email,
                otpCode: _code
            ),
          ),
        );
      }

    } catch (e, stackTrace) {
      // ❌ ERREUR
      print("🛑 [DEBUG] ERREUR ATTRAPÉE DANS _verifyCode !");
      print("👉 Erreur : $e");
      print("👉 StackTrace : $stackTrace");

      if (mounted) {
        setState(() => _isLoading = false);

        // Nettoyage du message d'erreur
        String errorMsg = e.toString().replaceAll("Exception: ", "");
        print("📢 [DEBUG] Affichage notification erreur : $errorMsg");

        _showTopNotification(errorMsg, isError: true);

        _controller.clear();
        setState(() => _code = "");
        FocusScope.of(context).requestFocus(_focusNode);
      }
    }
  }

  // --- 2. LOGIQUE DE RENVOI (API) ---
  void _resendCode() async {
    if (_isResending) return;

    setState(() => _isResending = true);
    try {
      await context.read<AuthRepository>().sendOtp(widget.email);
      if (mounted) {
        _showTopNotification("Nouveau code envoyé !");
      }
    } catch (e) {
      if (mounted) {
        _showTopNotification("Erreur lors du renvoi", isError: true);
      }
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showTopNotification(String message, {bool isError = false}) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, left: 20.0, right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset(0, -50 * (1 - value)),
                child: Opacity(
                  opacity: value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: isError ? Colors.redAccent.withOpacity(0.95) : Colors.black.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 8))],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: Colors.white, size: 22),
                        const SizedBox(width: 12),
                        Flexible(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
                      ],
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
    Future.delayed(const Duration(seconds: 3), () { if (overlayEntry.mounted) overlayEntry.remove(); });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vérification", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)),
            const Gap(10),
            RichText(
              text: TextSpan(
                style: TextStyle(color: secondaryTextColor, fontSize: 14, fontFamily: 'Arial'),
                children: [
                  const TextSpan(text: "Nous vous avons envoyé un code de vérification par e-mail.\n\n"),
                  TextSpan(
                      text: "${widget.email} ",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                  ),
                  const WidgetSpan(child: Icon(Icons.edit, size: 16, color: Colors.grey)),
                ],
              ),
            ),
            const Gap(40),

            // --- ZONE DE CODE OTP (6 CHIFFRES) ---
            Center(
              child: SizedBox(
                height: 70, // Hauteur ajustée
                child: Stack(
                  children: [
                    // Champ caché
                    Opacity(
                      opacity: 0,
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        keyboardType: TextInputType.number,
                        maxLength: _otpLength, // ✅ 6 Chiffres
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                        onChanged: (value) {
                          setState(() {
                            _code = value;
                          });
                          if (value.length == _otpLength) {
                            FocusScope.of(context).unfocus();
                            // _verifyCode(); // Auto-submit optionnel
                          }
                        },
                      ),
                    ),

                    // Cases visibles
                    GestureDetector(
                      onTap: () {
                        FocusScope.of(context).requestFocus(_focusNode);
                      },
                      child: Row(
                        // ✅ SpaceBetween permet d'étaler les 6 cases sur toute la largeur
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_otpLength, (index) {
                          return _buildCodeBox(context, index);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Gap(40),

            // Bouton Vérifier
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _verifyCode,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006400),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  disabledBackgroundColor: const Color(0xFF006400).withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Vérifier le code", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),

            const Gap(20),

            Center(
              child: TextButton(
                  onPressed: _isResending ? null : _resendCode,
                  child: _isResending
                      ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: textColor))
                      : Text(
                      "Renvoyer à nouveau",
                      style: TextStyle(color: textColor, fontWeight: FontWeight.bold)
                  )
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- DESIGN ADAPTÉ POUR 6 CASES ---
  Widget _buildCodeBox(BuildContext context, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    bool isFilled = index < _code.length;
    String digit = isFilled ? _code[index] : "";
    bool isFocused = index == _code.length;

    Color fillColor;
    if (isFilled) {
      fillColor = isDark ? Theme.of(context).cardColor : Colors.black;
    } else {
      fillColor = const Color(0xFF006400);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      // ✅ TAILLES RÉDUITES POUR FAIRE TENIR 6 CASES
      width: 45,  // Réduit de 65 à 45
      height: 55, // Réduit de 75 à 55
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12), // Radius un peu plus petit
        border: isFocused ? Border.all(color: Colors.orange, width: 2) : Border.all(color: Colors.transparent),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: isFilled
          ? Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ✅ Police réduite pour s'adapter à la petite case
          Text(digit, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const Gap(2),
          Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 1), width: 3, height: 3, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle)))
          ),
        ],
      )
          : Center(
        child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            // ✅ Points un peu plus petits
            children: List.generate(3, (i) => Container(margin: const EdgeInsets.symmetric(horizontal: 1.5), width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white70, shape: BoxShape.circle)))
        ),
      ),
    );
  }
}

class _SuccessAnimationWidget extends StatefulWidget {
  const _SuccessAnimationWidget();

  @override
  State<_SuccessAnimationWidget> createState() => _SuccessAnimationWidgetState();
}

class _SuccessAnimationWidgetState extends State<_SuccessAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _controller.forward();
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: isDark ? cardColor : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20)]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 80),
            const Gap(15),
            Text("Vérifié !", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }
}