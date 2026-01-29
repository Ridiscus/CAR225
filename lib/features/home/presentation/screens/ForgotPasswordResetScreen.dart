import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class ForgotPasswordResetScreen extends StatefulWidget {
  const ForgotPasswordResetScreen({super.key});

  @override
  State<ForgotPasswordResetScreen> createState() => _ForgotPasswordResetScreenState();
}

class _ForgotPasswordResetScreenState extends State<ForgotPasswordResetScreen> {
  // 1. AJOUT DES CONTRÔLEURS POUR RÉCUPÉRER LE TEXTE
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE VALIDATION (Inchangée) ---
  void _attemptReset() async {
    // Fermer le clavier avant de valider
    FocusScope.of(context).unfocus();

    String pass = _passController.text.trim();
    String confirm = _confirmController.text.trim();

    // CAS D'ECHEC 1 : Champs vides
    if (pass.isEmpty || confirm.isEmpty) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    // CAS D'ECHEC 2 : Mots de passe différents
    if (pass != confirm) {
      _showTopNotification("Les mots de passe ne correspondent pas", isError: true);
      return;
    }

    // CAS D'ECHEC 3 : Mot de passe trop court
    if (pass.length < 6) {
      _showTopNotification("Le mot de passe est trop court (min 6)", isError: true);
      return;
    }

    // --- TOUT EST BON : SIMULATION SUCCÈS ---
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSuccessDialog();
    }
  }

  // --- FONCTION UNIFIÉE : Notification Top ---
  // (Le style Noir/Blanc marche très bien sur les deux modes, je le garde tel quel)
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

  // Affiche le succès (Adapté Dark Mode)
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        // Variables locales au Dialog pour le thème
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final cardColor = Theme.of(context).cardColor;
        final textColor = Theme.of(context).textTheme.bodyLarge?.color;

        return AlertDialog(
          backgroundColor: isDark ? cardColor : Colors.white, // <--- FOND DIALOG
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.all(20),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, color: Colors.green, size: 40),
              ),
              const Gap(20),
              Text(
                  "Félicitations !",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor)
              ),
              const Gap(10),
              Text(
                "Votre mot de passe a été réinitialisé avec succès. Vous pouvez maintenant vous connecter.",
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
              ),
              const Gap(30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Retour à l'écran de connexion
                    Navigator.popUntil(context, (route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Se connecter", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              )
            ],
          ),
        );
      },
    );
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Réinitialisation",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: textColor)
            ),
            const Gap(10),
            Text(
              "Votre identité est confirmée. Créez votre nouveau mot de passe sécurisé.",
              style: TextStyle(color: secondaryTextColor, fontSize: 14),
            ),
            const Gap(40),

            _buildPasswordField(context, "Nouveau mot de passe", _passController, _obscure1, () => setState(() => _obscure1 = !_obscure1)),
            const Gap(20),
            _buildPasswordField(context, "Confirmer le mot de passe", _confirmController, _obscure2, () => setState(() => _obscure2 = !_obscure2)),

            const Gap(40),

            // Bouton Final
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _attemptReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  disabledBackgroundColor: Colors.green.withOpacity(0.5),
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Terminer", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget mis à jour avec Context pour le thème
  Widget _buildPasswordField(BuildContext context, String label, TextEditingController controller, bool obscure, VoidCallback onToggle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)
        ),
        const Gap(8),
        Container(
          decoration: BoxDecoration(
            color: cardColor, // <--- FOND CHAMP
            borderRadius: BorderRadius.circular(12),
            // Petite bordure en mode sombre
            border: isDark ? Border.all(color: Colors.grey[800]!) : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: textColor), // <--- COULEUR TEXTE SAISI
            decoration: InputDecoration(
              hintText: "••••••••",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.grey),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}