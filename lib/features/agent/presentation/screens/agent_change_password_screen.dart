import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import "../widgets/custom_app_bar.dart";
import "../widgets/success_modal.dart";

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
  final _formKey = GlobalKey<FormState>();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _oldPasswordError;

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
    // Reset simulated old password error
    setState(() => _oldPasswordError = null);

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // Simulation d'appel API (2 secondes)
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Simulation d'une erreur de "mot de passe actuel incorrect"
      // Pour l'exemple, on considère '1234' comme le bon ancien mot de passe
      if (_oldPasswordController.text != '1234') {
        setState(() {
          _isLoading = false;
          _oldPasswordError = 'Le mot de passe actuel est incorrect';
        });
        _formKey.currentState!.validate();
        return;
      }
      setState(() => _isLoading = false);
      SuccessModal.show(
        context: context,
        message: 'Votre mot de passe a été modifié avec succès.',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      initialValue: controller.text,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB0BEC5),
                letterSpacing: 1.2,
              ),
            ),
            const Gap(10),
            TextFormField(
              controller: controller,
              obscureText: obscure,
              onChanged: (v) {
                state.didChange(v);
                if (state.hasError) {
                  state.validate();
                }
              },
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Color(0xFF263238),
              ),
              decoration: InputDecoration(
                hintText: '••••••••',
                hintStyle: const TextStyle(color: Color(0xFFCFD8DC)),
                filled: true,
                fillColor: const Color(0xFFF8F9FA),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
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
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFECEFF1)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Colors.redAccent),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Colors.redAccent,
                    width: 1.5,
                  ),
                ),
                errorStyle: const TextStyle(height: 0, fontSize: 0),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8, left: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: Colors.redAccent,
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(
                        state.errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  // 5. MÉTHODE BUILD (Assemblage Final)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Sécurité',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.opaque,
        child: Stack(
          children: [
            // --- BACKGROUND DECORATORS ---
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Modifier le mot de passe',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1E293B),
                          letterSpacing: -0.8,
                        ),
                      ),
                      const Gap(12),
                      const Text(
                        'Votre nouveau mot de passe doit être différent des anciens mots de passe utilisés précédemment.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const Gap(32),
                      _buildPasswordField(
                        label: 'Mot de passe actuel',
                        controller: _oldPasswordController,
                        obscure: _obscureOld,
                        onToggle: () =>
                            setState(() => _obscureOld = !_obscureOld),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          return _oldPasswordError;
                        },
                      ),
                      const Gap(24),
                      _buildPasswordField(
                        label: 'Nouveau mot de passe',
                        controller: _newPasswordController,
                        obscure: _obscureNew,
                        onToggle: () =>
                            setState(() => _obscureNew = !_obscureNew),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          if (value.length < 6) {
                            return 'Minimum 6 caractères';
                          }
                          return null;
                        },
                      ),
                      const Gap(24),
                      _buildPasswordField(
                        label: 'Confirmer le nouveau mot de passe',
                        controller: _confirmPasswordController,
                        obscure: _obscureConfirm,
                        onToggle: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ce champ est obligatoire';
                          }
                          if (value != _newPasswordController.text) {
                            return 'Les mots de passe ne correspondent pas';
                          }
                          return null;
                        },
                      ),
                      const Gap(120),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 8,
                shadowColor: AppColors.primary.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
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
                      'Mettre à jour le mot de passe',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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
