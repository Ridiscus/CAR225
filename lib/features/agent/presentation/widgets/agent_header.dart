import 'package:car225/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../screens/agent_main_wrapper.dart';
import '../providers/profile_provider.dart';
import '../screens/agent_profile_screen.dart';

class AgentHeader extends StatefulWidget {
  final String agentName;
  final String agentRole;
  final String profileImage;
  final bool initialIsOnline;

  const AgentHeader({
    super.key,
    this.agentName = 'Fabiola Kouassi',
    this.agentRole = 'Agent UTB',
    this.profileImage = 'assets/images/agent_profile.png',
    this.initialIsOnline = true,
  });

  @override
  State<AgentHeader> createState() => _AgentHeaderState();
}

class _AgentHeaderState extends State<AgentHeader> {
  late bool _isOnline;

  @override
  void initState() {
    super.initState();
    _isOnline = widget.initialIsOnline;
  }

  @override
  Widget build(BuildContext context) {
    // On écoute les changements de l'image de profil via le Provider
    final profileProvider = Provider.of<ProfileProvider>(context);
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
          Expanded(
            child: InkWell(
              onTap: () {
                final state = context
                    .findAncestorStateOfType<AgentMainWrapperState>();
                if (state != null) {
                  state.setIndex(4);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AgentProfileScreen(),
                    ),
                  );
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: pickedImage != null
                                ? Image.file(pickedImage, fit: BoxFit.cover)
                                : Image.asset(
                                    widget.profileImage,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            Container(
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.grey,
                                                size: 25,
                                              ),
                                            ),
                                  ),
                          ),
                        ),
                        // Status indicator dot
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: _isOnline
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFFC62828),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.agentName,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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
                              widget.agentRole.toUpperCase(),
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
                  ],
                ),
              ),
            ),
          ),
          const Gap(10),
          // Online/Offline Switch - Minimal
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Transform.scale(
                scale: 0.8,
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
              const Gap(4),
              Text(
                _isOnline ? 'En ligne' : 'Hors ligne',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 10,
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
