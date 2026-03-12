import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/agent_profile_provider.dart';
import '../widgets/success_modal.dart';

class AgentPersonalInfoScreen extends StatefulWidget {
  const AgentPersonalInfoScreen({super.key});
  @override
  State<AgentPersonalInfoScreen> createState() =>
      _AgentPersonalInfoScreenState();
}

class _AgentPersonalInfoScreenState extends State<AgentPersonalInfoScreen> {
  // 1. VARIABLES D'ÉTAT & DONNÉES
  final String firstName = 'Fabiola';
  final String lastName = 'Kouassi';
  final String email = 'fabiola.kouassi@car225.ci';
  final String phone = '+225 07 00 00 00 00';
  final String agentId = 'AG-2026-001';
  final String company = 'UTB EXPRESS';

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: email);
    _phoneController = TextEditingController(text: phone);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _handleUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    // Simulation d'appel API
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      SuccessModal.show(
        context: context,
        message:
            'Vos informations personnelles ont été mises à jour avec succès.',
        onPressed: () => Navigator.pop(context),
      );
    }
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildInfoField({
    required IconData icon,
    required String label,
    String? value,
    TextEditingController? controller,
    bool isEnabled = false,
    String? Function(String?)? validator,
  }) {
    return FormField<String>(
      initialValue: controller?.text ?? value,
      validator: validator,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color.fromARGB(255, 56, 57, 58),
                letterSpacing: 0.5,
              ),
            ),
            const Gap(10),
            TextFormField(
              initialValue: controller == null ? value : null,
              controller: controller,
              enabled: isEnabled,
              onChanged: (v) {
                state.didChange(v);
                if (state.hasError) {
                  state.validate();
                }
              },
              style: TextStyle(
                color: isEnabled
                    ? const Color(0xFF1E293B)
                    : const Color(0xFF64748B),
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: isEnabled ? Colors.white : const Color(0xFFF1F5F9),
                prefixIcon: Icon(
                  icon,
                  color: isEnabled
                      ? AppColors.primary
                      : const Color(0xFF94A3B8),
                  size: 22,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFE2E8F0),
                    width: 1.5,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 2,
                  ),
                ),
                disabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFFCBD5E1),
                    width: 1,
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
                    width: 2,
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
                          fontWeight: FontWeight.w600,
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
    final pickedImage = context.watch<AgentProfileProvider>().profileImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Informations Personnelles',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              physics: const BouncingScrollPhysics(),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Photo de profil au centre
                    Center(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 66,
                          backgroundColor: Colors.white,
                          backgroundImage: pickedImage != null
                              ? FileImage(pickedImage)
                              : const AssetImage(
                                      'assets/images/agent_profile.png',
                                    )
                                    as ImageProvider,
                        ),
                      ),
                    ),
                    const Gap(45),
                    // Liste des champs d'informations
                    _buildInfoField(
                      icon: Icons.badge_outlined,
                      label: 'IDENTIFIANT UNIQUE',
                      value: agentId,
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.person_outline_rounded,
                      label: 'NOM COMPLET',
                      value: '$lastName $firstName',
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.business_rounded,
                      label: 'COMPAGNIE',
                      value: company,
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.email_outlined,
                      label: 'ADRESSE E-MAIL',
                      controller: _emailController,
                      isEnabled: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'L\'adresse e-mail est obligatoire';
                        }
                        if (!value.contains('@')) {
                          return 'Veuillez entrer un e-mail valide';
                        }
                        return null;
                      },
                    ),
                    const Gap(24),
                    _buildInfoField(
                      icon: Icons.phone_outlined,
                      label: 'NUMÉRO DE TÉLÉPHONE',
                      controller: _phoneController,
                      isEnabled: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Le numéro de téléphone est obligatoire';
                        }
                        return null;
                      },
                    ),
                    const Gap(40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'ENREGISTRER LES MODIFICATIONS',
                      style: TextStyle(
                        fontSize: 14,
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
