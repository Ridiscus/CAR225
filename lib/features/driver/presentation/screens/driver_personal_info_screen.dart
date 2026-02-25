import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import '../../../../core/providers/user_provider.dart';

class DriverPersonalInfoScreen extends StatelessWidget {
  const DriverPersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final driverProvider = Provider.of<DriverProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Informations Personnelles",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                    color: AppColors.primary.withOpacity(0.2),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: 54,
                  backgroundColor: const Color(0xFFF5F5F5),
                  backgroundImage: driverProvider.profileImage != null
                      ? FileImage(driverProvider.profileImage!)
                      : null,
                  child: driverProvider.profileImage == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),
              ),
            ),
            const Gap(40),
            _buildDisabledField(
              icon: Icons.person_outline_rounded,
              label: 'NOM',
              value: user?.name ?? "Non défini",
            ),
            const Gap(20),
            _buildDisabledField(
              icon: Icons.person_outline_rounded,
              label: 'PRÉNOM',
              value: user?.prenom ?? "Non défini",
            ),
            const Gap(20),
            _buildDisabledField(
              icon: Icons.badge_outlined,
              label: 'ID CHAUFFEUR',
              value: "CH-2024-001", // Valeur simulée pour l'instant
            ),
            const Gap(20),
            _buildDisabledField(
              icon: Icons.work_outline,
              label: 'RÔLE',
              value: "Chauffeur",
            ),
            const Gap(40),
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Text(
                      "Ces informations sont gérées par l'administration. Contactez-les pour toute modification.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

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
            fontSize: 11,
            fontWeight: FontWeight.w900,
            color: Color(0xFF607D8B),
            letterSpacing: 1.2,
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
}
