import 'package:car225/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../screens/agent_main_wrapper.dart';
import '../providers/agent_profile_provider.dart';
import '../screens/agent_profile_screen.dart';

class AgentHeader extends StatefulWidget {
  final bool initialIsOnline;

  // On a retiré agentName, agentRole et profileImage car
  // on les récupère maintenant dynamiquement depuis l'API !
  const AgentHeader({
    super.key,
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
    // 🟢 1. On écoute le provider pour récupérer les vraies données de l'agent
    final profileProvider = context.watch<AgentProfileProvider>();
    final data = profileProvider.profileData;
    final pickedImage = profileProvider.profileImage;
    final isLoading = profileProvider.isLoadingProfile;

    // 🟢 2. Extraction dynamique du Nom et de l'Entreprise
    final String firstName = data?['prenom'] ?? (isLoading ? '...' : 'Agent');
    final String lastName = data?['name'] ?? '';
    final String fullName = '$firstName $lastName'.trim();

    final String companyName = data?['compagnie']?['name'] ?? 'Compagnie';
    final String roleText = 'Agent $companyName';

    // 🛠️ 3. RÉPARATION DE L'URL DE L'IMAGE DU BACKEND
    String? rawImageUrl = data?['profile_picture_url']?.toString();
    String? finalImageUrl;

    if (rawImageUrl != null && rawImageUrl.trim().isNotEmpty) {
      if (rawImageUrl.startsWith('http')) {
        finalImageUrl = rawImageUrl;
      } else {
        const String baseUrl = 'https://jingly-lindy-unminding.ngrok-free.dev';
        finalImageUrl = rawImageUrl.startsWith('/')
            ? '$baseUrl$rawImageUrl'
            : '$baseUrl/$rawImageUrl';
      }
    }

    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.85),
          ],
        ),
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
                              color: Colors.white.withOpacity(0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            // 🟢 LOGIQUE D'IMAGE INTELLIGENTE APPLIQUÉE À TON CLIP OVAL
                            child: pickedImage != null
                                ? Image.file(pickedImage, fit: BoxFit.cover)
                                : (finalImageUrl != null
                                ? Image.network(
                              finalImageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackIcon(),
                            )
                                : Image.asset(
                              'assets/images/agent_profile.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  _buildFallbackIcon(),
                            )),
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
                            fullName, // 🟢 Affiche "THE WAYNE"
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
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
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              roleText.toUpperCase(), // 🟢 Affiche "AGENT UNION DES TRANSPORTS DE BOUAKE"
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
                  activeTrackColor: Colors.white.withOpacity(0.3),
                  inactiveThumbColor: const Color(0xFFC62828),
                  inactiveTrackColor: Colors.white.withOpacity(0.3),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              const Gap(4),
              Text(
                _isOnline ? 'En ligne' : 'Hors ligne',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
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

  // Petit widget d'aide si l'image plante
  Widget _buildFallbackIcon() {
    return Container(
      color: Colors.grey.shade200,
      child: const Icon(
        Icons.person,
        color: Colors.grey,
        size: 25,
      ),
    );
  }
}