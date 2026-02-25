import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/features/agent/presentation/widgets/custom_app_bar.dart';
import '../providers/hostess_profile_provider.dart';

class HostessPersonalInfoScreen extends StatefulWidget {
  const HostessPersonalInfoScreen({super.key});
  @override
  State<HostessPersonalInfoScreen> createState() =>
      _HostessPersonalInfoScreenState();
}

class _HostessPersonalInfoScreenState extends State<HostessPersonalInfoScreen> {
  final String firstName = 'Fabiola';
  final String lastName = 'Kouassi';
  final String email = 'fabiola.kouassi@car225.ci';
  final String phone = '+225 07 00 00 00 00';
  final String hostessId = 'HT-2026-005';
  final String company = 'UTB EXPRESS';

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

  @override
  Widget build(BuildContext context) {
    final pickedImage = context.watch<HostessProfileProvider>().profileImage;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'Informations Personnelles',
        leadingIcon: Icons.arrow_back,
        leadingOnPressed: () => Navigator.pop(context),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 54,
                    backgroundColor: const Color(0xFFF5F5F5),
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage)
                        : const AssetImage('assets/images/agent_profile.png')
                              as ImageProvider,
                  ),
                ),
              ),
              const Gap(40),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDisabledField(
                    icon: Icons.badge_outlined,
                    label: 'ID Hôtesse',
                    value: hostessId,
                  ),
                  const Gap(20),
                  _buildDisabledField(
                    icon: Icons.person_outline_rounded,
                    label: 'Nom',
                    value: lastName,
                  ),
                  const Gap(20),
                  _buildDisabledField(
                    icon: Icons.person_outline_rounded,
                    label: 'Prénom',
                    value: firstName,
                  ),
                  const Gap(20),
                  _buildDisabledField(
                    icon: Icons.business_rounded,
                    label: 'Compagnie',
                    value: company,
                  ),
                  const Gap(20),
                  _buildDisabledField(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: email,
                  ),
                  const Gap(20),
                  _buildDisabledField(
                    icon: Icons.phone_outlined,
                    label: 'Téléphone',
                    value: phone,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
