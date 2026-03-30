import 'package:flutter/material.dart';
import 'package:car225/core/services/networking/api_config.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/core/providers/user_provider.dart';
import 'package:car225/features/driver/presentation/providers/driver_provider.dart';
import 'package:car225/features/driver/presentation/screens/driver_profile_screen.dart';
import 'package:car225/features/driver/presentation/screens/driver_history_screen.dart';
import 'package:car225/features/home/presentation/screens/notification_screen.dart';

class DriverHeader extends StatelessWidget {
  final String title;
  final bool isDashboard;
  final bool showBack;
  final List<Widget>? actions;

  const DriverHeader({
    super.key,
    required this.title,
    this.isDashboard = false,
    this.showBack = false,
    this.actions,
    @Deprecated('Use isDashboard instead') bool showProfile = true,
  });

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);
    final user = userProvider.user;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, Color(0xFFFF8C1A)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: isDashboard
            ? _buildDashboardHeader(context, user, driverProvider)
            : _buildStandardHeader(context),
      ),
    );
  }

  Widget _buildDashboardHeader(BuildContext context, dynamic user, DriverProvider driverProvider) {
    return Row(
      children: [
        const Gap(8),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DriverProfileScreen()),
          ),
          child: Container(
            height: 55,
            width: 55,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: driverProvider.profileImage != null
                  ? Image.file(driverProvider.profileImage!, fit: BoxFit.cover, width: 55, height: 55)
                  : (driverProvider.profile?.profilePictureUrl != null
                      ? Image.network(
                          "${ApiConfig.baseUrl.replaceAll('/api', '')}${driverProvider.profile!.profilePictureUrl}",
                          fit: BoxFit.cover,
                          width: 55,
                          height: 55,
                          errorBuilder: (context, error, stackTrace) => Image.asset(
                            'assets/images/driver_profile.png',
                            fit: BoxFit.cover,
                            width: 55,
                            height: 55,
                          ),
                        )
                      : Image.asset(
                          'assets/images/driver_profile.png',
                          fit: BoxFit.cover,
                          width: 55,
                          height: 55,
                        )),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  user != null ? "${user.name} ${user.prenom}" : "Chauffeur",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (actions != null) ...actions!,
        if (actions == null && isDashboard)
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.history, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DriverHistoryScreen()),
                ),
              ),
              Stack(
                children: [
                   IconButton(
                    icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const NotificationScreen()),
                      );
                    },
                  ),
                  if (driverProvider.messages.any((m) => !m.isRead))
                    Positioned(
                      right: 5,
                      top: 5,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Center(
                          child: Text(
                            "${driverProvider.messages.where((m) => !m.isRead).length}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    )
                ],
              ),
            ],
          ),
        if (actions == null && !isDashboard)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
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

  Widget _buildStandardHeader(BuildContext context) {
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
          // Back Button on left
          if (showBack)
            Positioned(
              left: 0,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
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
