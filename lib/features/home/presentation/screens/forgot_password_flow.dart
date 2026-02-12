/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'ForgotPasswordOtpScreen.dart';

// --- ECRAN 1 : EMAIL ---
class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE VALIDATION (Inchangée) ---
  void _validateAndSend() async {
    FocusScope.of(context).unfocus();

    String email = _emailController.text.trim();

    // 1. Validation : Champ vide
    if (email.isEmpty) {
      _showTopNotification("Veuillez entrer une adresse email", isError: true);
      return;
    }

    // 2. Validation : Format Email
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showTopNotification("Format d'email invalide", isError: true);
      return;
    }

    // --- SIMULATION API ---
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    // 3. Validation : Simulation compte inexistant
    if (email == "inconnu@gmail.com") {
      if (mounted) {
        setState(() => _isLoading = false);
        _showTopNotification("Aucun compte associé à cet email", isError: true);
      }
      return;
    }

    // --- SUCCÈS ---
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ForgotPasswordOtpScreen()),
      );
    }
  }

  // --- NOTIFICATION STYLE IPHONE ---
  // (Le design noir/blanc/rouge marche très bien dans les deux modes, pas besoin de changer)
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

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), // <--- ICONE RETOUR DYNAMIQUE
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Mot de passe oublié ?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            Text(
              "Ne vous inquiétez pas, cela arrive. Entrez l'adresse email associée à votre compte.",
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey, // Gris clair en sombre
                  fontSize: 14
              ),
            ),
            const Gap(40),

            // Champ Email
            Text(
                "Adresse Email",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            Container(
              decoration: BoxDecoration(
                color: cardColor, // <--- FOND CHAMP DYNAMIQUE
                borderRadius: BorderRadius.circular(15),
                // Petite bordure en mode sombre
                border: isDark ? Border.all(color: Colors.grey[800]!) : null,
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor), // <--- COULEUR TEXTE SAISI
                decoration: const InputDecoration(
                  hintText: "exemple@email.com",
                  // hintStyle par défaut est gris, ça passe, mais on peut forcer si besoin
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            const Gap(30),

            // Bouton Envoyer
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _validateAndSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  disabledBackgroundColor: Colors.green.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Envoyer le code", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}*/



import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart'; // ✅ Nécessaire pour appeler le Repo

import '../../../auth/domain/repositories/auth_repository.dart';
import 'ForgotPasswordOtpScreen.dart';

class ForgotPasswordEmailScreen extends StatefulWidget {
  const ForgotPasswordEmailScreen({super.key});

  @override
  State<ForgotPasswordEmailScreen> createState() => _ForgotPasswordEmailScreenState();
}

class _ForgotPasswordEmailScreenState extends State<ForgotPasswordEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
// --- LOGIQUE CONNECTÉE À L'API (VERSION DEBUG) ---
  void _validateAndSend() async {
    print("🟢 [DEBUG] 1. Début de la fonction _validateAndSend");

    FocusScope.of(context).unfocus();

    String email = _emailController.text.trim();
    print("📧 [DEBUG] 2. Email récupéré : '$email'");

    // 1. Validation locale
    if (email.isEmpty) {
      print("❌ [DEBUG] Erreur : L'email est vide");
      _showTopNotification("Veuillez entrer une adresse email", isError: true);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      print("❌ [DEBUG] Erreur : Format email invalide");
      _showTopNotification("Format d'email invalide", isError: true);
      return;
    }

    print("🔄 [DEBUG] 3. Validation OK. Activation du chargement...");
    setState(() => _isLoading = true);

    try {
      print("📡 [DEBUG] 4. Appel de context.read<AuthRepository>().sendOtp()...");

      // Je sépare l'accès au repo pour voir si le Provider plante ici
      final authRepo = context.read<AuthRepository>();
      print("📦 [DEBUG] Repository trouvé : $authRepo");

      // Appel réel
      await authRepo.sendOtp(email);

      print("✅ [DEBUG] 5. API SUCCÈS ! Le code OTP a été envoyé.");

      if (mounted) {
        setState(() => _isLoading = false);

        print("➡️ [DEBUG] 6. Navigation vers ForgotPasswordOtpScreen...");

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ForgotPasswordOtpScreen(email: email),
          ),
        );
      } else {
        print("⚠️ [DEBUG] Le widget n'est plus monté (l'utilisateur a quitté l'écran ?)");
      }

    } catch (e, stackTrace) {
      // On capture l'erreur ET la trace complète
      print("🛑 [DEBUG] ERREUR ATTRAPÉE !");
      print("👉 Message : $e");
      print("👉 StackTrace : $stackTrace");

      if (mounted) {
        setState(() => _isLoading = false);
        // Nettoyage du message d'erreur pour l'utilisateur
        String message = e.toString().replaceAll("Exception: ", "");
        _showTopNotification(message, isError: true);
      }
    }
  }


  // (Le design noir/blanc/rouge marche très bien dans les deux modes, pas besoin de changer)
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










  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- FOND DYNAMIQUE
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor), // <--- ICONE RETOUR DYNAMIQUE
      ),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Mot de passe oublié ?",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            Text(
              "Ne vous inquiétez pas, cela arrive. Entrez l'adresse email associée à votre compte.",
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey, // Gris clair en sombre
                  fontSize: 14
              ),
            ),
            const Gap(40),

            // Champ Email
            Text(
                "Adresse Email",
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            Container(
              decoration: BoxDecoration(
                color: cardColor, // <--- FOND CHAMP DYNAMIQUE
                borderRadius: BorderRadius.circular(15),
                // Petite bordure en mode sombre
                border: isDark ? Border.all(color: Colors.grey[800]!) : null,
              ),
              child: TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: TextStyle(color: textColor), // <--- COULEUR TEXTE SAISI
                decoration: const InputDecoration(
                  hintText: "exemple@email.com",
                  // hintStyle par défaut est gris, ça passe, mais on peut forcer si besoin
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.email_outlined, color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),

            const Gap(30),

            // Bouton Envoyer
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _validateAndSend,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  disabledBackgroundColor: Colors.green.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Envoyer le code", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }





}