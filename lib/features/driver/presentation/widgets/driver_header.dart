import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../providers/driver_provider.dart';

class DriverHeader extends StatelessWidget {
  final String title;
  final bool isDashboard;
  final List<Widget>? actions;

  const DriverHeader({
    super.key,
    required this.title,
    this.isDashboard = false,
    this.actions,
    @Deprecated('Use isDashboard instead') bool showProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);
    final user = userProvider.user;

    return Container(
      padding: const EdgeInsets.fromLTRB(5, 0, 24, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFFFF8C1A)],
        ),
        boxShadow: [
          BoxShadow(
            color: Color(0x4DFF7900),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: isDashboard
            ? _buildDashboardHeader(user, driverProvider)
            : _buildStandardHeader(),
      ),
    );
  }

  Widget _buildDashboardHeader(dynamic user, DriverProvider driverProvider) {
    return Row(
      children: [
        const Gap(8),
        GestureDetector(
          onTap: () =>
              driverProvider.setIndex(4), // Redirige vers l'onglet Profil
          child: Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: driverProvider.profileImage != null
                  ? Image.file(driverProvider.profileImage!, fit: BoxFit.cover)
                  : Container(
                      color: Colors.white.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 35,
                      ),
                    ),
            ),
          ),
        ),
        const Gap(15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Bienvenue",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                user != null ? "${user.name} ${user.prenom}" : "Chauffeur",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (actions != null) ...actions!,
        if (actions == null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              "CHAUFFEUR",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildStandardHeader() {
    return SizedBox(
      width: double.infinity,
      height: 50, // Slightly reduced to better match standard app bars
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Title centered
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 19,
              fontWeight: FontWeight.bold,
            ),
          ),
          // Actions on the right
          if (actions != null)
            Positioned(
              right: 0,
              child: Row(mainAxisSize: MainAxisSize.min, children: actions!),
            ),
        ],
      ),
    );
  }
}
