import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import "../widgets/custom_app_bar.dart";

class AgentChangePasswordScreen extends StatefulWidget {
  const AgentChangePasswordScreen({super.key});

  @override
  State<AgentChangePasswordScreen> createState() =>
      _AgentChangePasswordScreenState();
}

class _AgentChangePasswordScreenState extends State<AgentChangePasswordScreen> {
  // 1. VARIABLES D'ÉTAT & CONTROLLERS
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // 2. CYCLE DE VIE (Lifecycle)
  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // 3. LOGIQUE & ACTIONS
  void _handleSubmit() async {
    if (_oldPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showSnackBar('Veuillez remplir tous les champs', isError: true);
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      _showSnackBar(
        'Les nouveaux mots de passe ne correspondent pas',
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // Simulation d'appel API (2 secondes)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      _showSnackBar('Mot de passe mis à jour avec succès');
      Navigator.pop(context);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    // Nettoyer les messages précédents pour éviter l'empilement
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFFB0BEC5),
            letterSpacing: 1.2,
          ),
        ),
        const Gap(10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECEFF1)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF263238),
            ),
            decoration: InputDecoration(
              hintText: '••••••••',
              hintStyle: const TextStyle(color: Color(0xFFCFD8DC)),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              prefixIcon: const Icon(
                Icons.lock_outline,
                color: Color(0xFFB0BEC5),
                size: 22,
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: const Color(0xFFB0BEC5),
                  size: 22,
                ),
                onPressed: onToggle,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 5. MÉTHODE BUILD (Assemblage Final)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Sécurité',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Modifier le mot de passe',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                  letterSpacing: -0.8,
                ),
              ),
              const Gap(12),
              const Text(
                'Votre nouveau mot de passe doit être différent des anciens mots de passe utilisés précédemment.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF78909C),
                  fontWeight: FontWeight.w500,
                  height: 1.5,
                ),
              ),
              const Gap(32),
              _buildPasswordField(
                label: 'Mot de passe actuel',
                controller: _oldPasswordController,
                obscure: _obscureOld,
                onToggle: () => setState(() => _obscureOld = !_obscureOld),
              ),
              const Gap(24),
              _buildPasswordField(
                label: 'Nouveau mot de passe',
                controller: _newPasswordController,
                obscure: _obscureNew,
                onToggle: () => setState(() => _obscureNew = !_obscureNew),
              ),
              const Gap(24),
              _buildPasswordField(
                label: 'Confirmer le nouveau mot de passe',
                controller: _confirmPasswordController,
                obscure: _obscureConfirm,
                onToggle: () =>
                    setState(() => _obscureConfirm = !_obscureConfirm),
              ),
              const Gap(40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(
            top: 0,
            left: 24,
            right: 24,
            bottom: 10,
          ),
          child: SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : const Text(
                      'Mettre à jour',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
