

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/hostess_profile_provider.dart';
import '../screens/hostess_main_wrapper.dart';

class HostessHeader extends StatefulWidget {
  final bool initialIsOnline;

  const HostessHeader({
    super.key,
    this.initialIsOnline = true,
  });

  @override
  State<HostessHeader> createState() => _HostessHeaderState();
}

class _HostessHeaderState extends State<HostessHeader> {
  late bool _isOnline;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.initialIsOnline;
  }

  @override
  Widget build(BuildContext context) {
    // 🟢 On écoute activement le provider pour réagir aux chargements
    final profileProvider = context.watch<HostessProfileProvider>();
    final profile = profileProvider.profileData;
    final isLoading = profileProvider.isLoading;
    final pickedImage = profileProvider.profileImage;

    // 🟢 L'URL de l'image est nettoyée directement depuis le provider
    final String cleanImageUrl = profileProvider.cleanProfileImageUrl;

    final safeAreaTop = MediaQuery.paddingOf(context).top;

    // Variables dynamiques
    final String firstName = profile?.prenom ?? (isLoading ? '...' : '');
    final String lastName = profile?.name ?? (isLoading ? 'Chargement' : 'Inconnu');
    final String company = profile?.nomCompagnie ?? (isLoading ? '...' : 'Inconnue');

    final String fullName = '$firstName $lastName'.trim();
    final String roleText = 'HÔTESSE $company';

    return Container(
      padding: EdgeInsets.fromLTRB(24, 8 + safeAreaTop, 24, 25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withValues(alpha: 0.85),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          // PROFIL AVATAR
          InkWell(
            onTap: () {
              final state = context.findAncestorStateOfType<HostessMainWrapperState>();
              if (state != null) {
                // CHANGE LE 4 PAR LE BON INDEX (sûrement 3 ou 2)
                state.setIndex(3);
              }
            },
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  // 🟢 REMPLACEMENT DU CLIP OVAL PAR LE CIRCLE AVATAR (PLUS SÉCURISÉ)
                  child: CircleAvatar(
                    radius: 32, // Correspond à height/width 64 (rayon de 32 = diamètre de 64)
                    backgroundColor: Colors.white24,
                    backgroundImage: pickedImage != null
                        ? FileImage(pickedImage) // 1. Priorité à l'image locale (File)
                        : (cleanImageUrl.isNotEmpty
                        ? NetworkImage(cleanImageUrl) // 2. Ensuite l'URL réseau
                        : const AssetImage('assets/images/hostess_profile.jpg') as ImageProvider), // 3. Fallback

                    // Gestion de l'erreur réseau invisible
                    onBackgroundImageError: (exception, stackTrace) {
                      print("⚠️ Erreur image HostessHeader : $exception");
                    },
                  ),
                ),

                // Pastille En ligne / Hors ligne
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    height: 14,
                    width: 14,
                    decoration: BoxDecoration(
                      color: _isOnline
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFC62828),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Gap(16),
          // TEXTES
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour,',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const Gap(4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    roleText.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          // ONLINE/OFFLINE SWITCH
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: _isOnline,
                  onChanged: (value) {
                    HapticFeedback.mediumImpact();
                    setState(() {
                      _isOnline = value;
                    });
                  },
                  activeThumbColor: const Color(0xFF4CAF50),
                  activeTrackColor: Colors.white.withValues(alpha: 0.3),
                  inactiveThumbColor: const Color(0xFFC62828),
                  inactiveTrackColor: Colors.white.withValues(alpha: 0.3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Gap(1),
              Text(
                _isOnline ? 'En ligne' : 'Hors ligne',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}