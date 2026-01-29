/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import 'forgot_password_flow.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Contrôleurs
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // Visibilité
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // État de chargement
  bool _isLoading = false;

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE VALIDATION (Inchangée) ---
  void _updatePassword() async {
    FocusScope.of(context).unfocus();

    String oldPass = _oldPassController.text.trim();
    String newPass = _newPassController.text.trim();
    String confirmPass = _confirmPassController.text.trim();

    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    if (newPass.length < 8) {
      _showTopNotification("Le nouveau mot de passe doit faire 8 caractères min.", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showTopNotification("Les nouveaux mots de passe ne correspondent pas", isError: true);
      return;
    }

    if (oldPass == newPass) {
      _showTopNotification("Le nouveau mot de passe doit être différent de l'actuel", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    if (oldPass == "1234") {
      if (mounted) {
        setState(() => _isLoading = false);
        _showTopNotification("L'ancien mot de passe est incorrect", isError: true);
      }
      return;
    }

    if (mounted) {
      setState(() => _isLoading = false);
      _showTopNotification("Mot de passe mis à jour avec succès !", isError: false);
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  // --- NOTIFICATION (Reste inchangée car le contraste Noir/Blanc est bon partout) ---
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

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- DYNAMIQUE
      appBar: AppBar(
        title: Text(
            "Changer mot de passe",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Pour votre sécurité, votre mot de passe doit contenir au moins 8 caractères, un chiffre et un caractère spécial.",
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey, // Gris plus clair en mode sombre
                  fontSize: 13,
                  height: 1.5
              ),
            ),
            const Gap(30),

            _buildPasswordField(context, "Mot de passe actuel", _oldPassController, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
            const Gap(20),
            _buildPasswordField(context, "Nouveau mot de passe", _newPassController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
            const Gap(20),
            _buildPasswordField(context, "Confirmer le nouveau", _confirmPassController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),

            const Gap(40),

            // Bouton de validation
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  disabledBackgroundColor: Colors.green.withOpacity(0.5), // Style quand désactivé
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Mettre à jour le mot de passe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const Gap(20),

            // Lien "Mot de passe oublié"
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPasswordEmailScreen())
                );
              },
              child: Text(
                  "J'ai oublié mon mot de passe actuel",
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)
              ),
            )
          ],
        ),
      ),
    );
  }

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
            color: cardColor, // <--- FOND DYNAMIQUE
            borderRadius: BorderRadius.circular(12),
            // Petite bordure en mode sombre pour bien voir le champ
            border: isDark ? Border.all(color: Colors.grey[800]!) : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: textColor), // Couleur du texte tapé
            decoration: InputDecoration(
              hintText: "••••••••",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}*/








import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import 'forgot_password_flow.dart';

// --- IMPORTS CLEAN ARCHITECTURE ---
import '../../../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../../../features/auth/data/repositories/auth_repository_impl.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  // Contrôleurs
  final TextEditingController _oldPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();
  final TextEditingController _confirmPassController = TextEditingController();

  // Visibilité
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  // État de chargement
  bool _isLoading = false;

  // --- 1. INSTANCIATION DU REPOSITORY ---
  // (Dans une vraie clean arch avec GetIt/Provider, on l'injecterait, mais ici on l'instancie direct)
  late AuthRepositoryImpl _authRepository;



  @override
  void initState() {
    super.initState();

    // Instanciation des services
    final deviceService = DeviceService();
    final fcmService = FcmService();

    // ✅ CORRECTION ICI :
    // On instancie AuthRemoteDataSourceImpl() avec les parenthèses vides ()
    // car Dio est géré à l'intérieur.
    _authRepository = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
      deviceService: deviceService,
      fcmService: fcmService,
    );
  }



  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  // --- LOGIQUE DE VALIDATION & APPEL API ---
  void _updatePassword() async {
    FocusScope.of(context).unfocus();

    String oldPass = _oldPassController.text.trim();
    String newPass = _newPassController.text.trim();
    String confirmPass = _confirmPassController.text.trim();

    // 1. Validations locales
    if (oldPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    if (newPass.length < 8) {
      _showTopNotification("Le nouveau mot de passe doit faire 8 caractères min.", isError: true);
      return;
    }

    if (newPass != confirmPass) {
      _showTopNotification("Les nouveaux mots de passe ne correspondent pas", isError: true);
      return;
    }

    if (oldPass == newPass) {
      _showTopNotification("Le nouveau mot de passe doit être différent de l'actuel", isError: true);
      return;
    }

    // 2. Appel API
    setState(() => _isLoading = true);

    try {
      await _authRepository.changePassword(
        currentPassword: oldPass,
        newPassword: newPass,
        confirmPassword: confirmPass,
      );

      // SUCCÈS
      if (mounted) {
        setState(() => _isLoading = false);
        _showTopNotification("Mot de passe mis à jour avec succès !", isError: false);

        // On vide les champs
        _oldPassController.clear();
        _newPassController.clear();
        _confirmPassController.clear();

        // On ferme l'écran après un petit délai
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }

    } catch (e) {
      // ERREUR
      if (mounted) {
        setState(() => _isLoading = false);
        // On retire "Exception: " du message si présent pour faire plus propre
        final message = e.toString().replaceAll("Exception: ", "");
        _showTopNotification(message, isError: true);
      }
    }
  }

  // ... LE RESTE DU CODE UI (BUILD, NOTIFICATION, ETC.) RESTE IDENTIQUE ...
  // Copie-colle le reste de ton code UI ici (build, _showTopNotification, _buildPasswordField)

  void _showTopNotification(String message, {bool isError = false}) {
    // ... ta fonction existante ...
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

    return Scaffold(
      backgroundColor: scaffoldColor, // <--- DYNAMIQUE
      appBar: AppBar(
        title: Text(
            "Changer mot de passe",
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)
        ),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              "Pour votre sécurité, votre mot de passe doit contenir au moins 8 caractères, un chiffre et un caractère spécial.",
              style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey, // Gris plus clair en mode sombre
                  fontSize: 13,
                  height: 1.5
              ),
            ),
            const Gap(30),

            _buildPasswordField(context, "Mot de passe actuel", _oldPassController, _obscureOld, () => setState(() => _obscureOld = !_obscureOld)),
            const Gap(20),
            _buildPasswordField(context, "Nouveau mot de passe", _newPassController, _obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
            const Gap(20),
            _buildPasswordField(context, "Confirmer le nouveau", _confirmPassController, _obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),

            const Gap(40),

            // Bouton de validation
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _updatePassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  disabledBackgroundColor: Colors.green.withOpacity(0.5), // Style quand désactivé
                ),
                child: _isLoading
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Mettre à jour le mot de passe", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),

            const Gap(20),

            // Lien "Mot de passe oublié"
            TextButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ForgotPasswordEmailScreen())
                );
              },
              child: Text(
                  "J'ai oublié mon mot de passe actuel",
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)
              ),
            )
          ],
        ),
      ),
    );
  }

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
            color: cardColor, // <--- FOND DYNAMIQUE
            borderRadius: BorderRadius.circular(12),
            // Petite bordure en mode sombre pour bien voir le champ
            border: isDark ? Border.all(color: Colors.grey[800]!) : null,
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: TextStyle(color: textColor), // Couleur du texte tapé
            decoration: InputDecoration(
              hintText: "••••••••",
              hintStyle: TextStyle(color: Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}