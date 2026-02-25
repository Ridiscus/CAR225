import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/hostess_profile_provider.dart';
import '../screens/hostess_main_wrapper.dart';

class HostessHeader extends StatefulWidget {
  final String hostessName;
  final String hostessRole;
  final String profileImage;
  final bool initialIsOnline;

  const HostessHeader({
    super.key,
    this.hostessName = 'Fabiola Kouassi',
    this.hostessRole = 'Hôtesse UTB',
    this.profileImage = 'assets/images/agent_profile.png',
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
    final profileProvider = Provider.of<HostessProfileProvider>(context);
    final pickedImage = profileProvider.profileImage;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 25),
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
          // PROFIL AVATAR AVEC DESIGN DISTINCT
          InkWell(
            onTap: () {
              final state = context
                  .findAncestorStateOfType<HostessMainWrapperState>();
              if (state != null) {
                state.setIndex(4);
              }
            },
            child: Stack(
              children: [
                Container(
                  height: 64,
                  width: 64,
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
                  child: ClipOval(
                    child: pickedImage != null
                        ? Image.file(pickedImage, fit: BoxFit.cover)
                        : Image.asset(widget.profileImage, fit: BoxFit.cover),
                  ),
                ),
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
                  widget.hostessName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
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
                    widget.hostessRole.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ONLINE/OFFLINE SWITCH - Minimal
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
