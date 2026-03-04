import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../widgets/custom_app_bar.dart';
import '../providers/profile_provider.dart';

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

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildDisabledField({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Color(0xFF607D8B),
          ),
        ),
        const Gap(8),
        TextFormField(
          initialValue: value,
          enabled: false,
          style: const TextStyle(
            color: Color(0xFF263238),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8F9FA),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 22),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFECEFF1)),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 18),
          ),
        ),
      ],
    );
  }

  // 5. MÉTHODE BUILD (Assemblage Final)
  @override
  Widget build(BuildContext context) {
    final pickedImage = context.watch<ProfileProvider>().profileImage;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: CustomAppBar(
        title: 'Informations Personnelles',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: Stack(
        children: [
          // --- BACKGROUND DECORATORS ---
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.15),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 250,
            left: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF64748B).withValues(alpha: 0.1),
                    const Color(0xFF64748B).withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
              physics: const BouncingScrollPhysics(),
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
                            color: Colors.black.withValues(alpha: 0.06),
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
                  _buildDisabledField(
                    icon: Icons.badge_outlined,
                    label: 'IDENTIFIANT UNIQUE',
                    value: agentId,
                  ),
                  const Gap(24),
                  _buildDisabledField(
                    icon: Icons.person_outline_rounded,
                    label: 'NOM COMPLET',
                    value: '$lastName $firstName',
                  ),
                  const Gap(24),
                  _buildDisabledField(
                    icon: Icons.business_rounded,
                    label: 'COMPAGNIE D\'APPARTENANCE',
                    value: company,
                  ),
                  const Gap(24),
                  _buildDisabledField(
                    icon: Icons.email_outlined,
                    label: 'ADRESSE E-MAIL',
                    value: email,
                  ),
                  const Gap(24),
                  _buildDisabledField(
                    icon: Icons.phone_outlined,
                    label: 'NUMÉRO DE TÉLÉPHONE',
                    value: phone,
                  ),
                  const Gap(40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
