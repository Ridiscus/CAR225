import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import 'driver_personal_info_screen.dart';
import 'driver_change_password_screen.dart';
import 'package:car225/features/auth/presentation/screens/login_screen.dart';

const _kNavy = Color(0xFF0f172a);
const _kNavyCard = Color(0xFF1e293b);

class DriverProfileScreen extends StatefulWidget {
  const DriverProfileScreen({super.key});

  @override
  State<DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<DriverProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  bool _notificationEnabled = true;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (image != null && mounted) {
        context.read<DriverProvider>().updateProfileImage(image.path);
        _toast('Photo de profil mise à jour');
      }
    } catch (_) {
      _toast('Erreur lors du choix de l\'image', isError: true);
    }
  }

  void _toast(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final profile = provider.profile;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar (orange → navy) ──
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: _kNavy,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text('Mon Profil',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, _kNavy],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Gap(40),
                      // ── Avatar ──
                      Stack(
                        children: [
                          _buildAvatar(provider, profile),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: () => _pickImage(ImageSource.gallery),
                              child: Container(
                                padding: const EdgeInsets.all(7),
                                decoration: BoxDecoration(
                                  color: _kNavy,
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      // ── Nom ──
                      Text(
                        profile != null
                            ? '${profile.prenom ?? ''} ${profile.name ?? ''}'.trim()
                            : 'Chauffeur',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Gap(4),
                      // ── Code ID ──
                      if (profile?.codeId != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            profile!.codeId!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ── Infos rapides ──
                  if (profile != null) _buildInfoRow(profile),
                  const Gap(16),

                  // ── Menu paramètres ──
                  _buildMenuSection(context, provider),
                  const Gap(24),

                  // ── Bouton Déconnexion ──
                  _buildLogoutButton(context, provider),
                  const Gap(30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(DriverProvider provider, dynamic profile) {
    final initials = profile != null
        ? '${(profile.prenom ?? ' ')[0].toUpperCase()}${(profile.name ?? ' ')[0].toUpperCase()}'
        : 'CH';

    final initialsWidget = Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    Widget? imageWidget;
    if (provider.profileImage != null) {
      imageWidget = Image.file(provider.profileImage!, fit: BoxFit.cover,
          width: 90, height: 90, errorBuilder: (_, __, ___) => initialsWidget);
    } else if (profile?.fullProfilePictureUrl != null) {
      imageWidget = Image.network(profile!.fullProfilePictureUrl!,
          fit: BoxFit.cover, width: 90, height: 90,
          errorBuilder: (_, __, ___) => initialsWidget);
    }

    return Container(
      width: 90,
      height: 90,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        color: _kNavyCard,
      ),
      child: imageWidget ?? initialsWidget,
    );
  }

  Widget _buildInfoRow(dynamic profile) {
    return Row(
      children: [
        _InfoTile(
          icon: Icons.business_rounded,
          label: 'Compagnie',
          value: profile.compagnie?.name ?? '—',
        ),
        const Gap(10),
        _InfoTile(
          icon: Icons.location_city_rounded,
          label: 'Gare',
          value: profile.gare?.nomGare ?? '—',
        ),
        const Gap(10),
        _InfoTile(
          icon: Icons.verified_rounded,
          label: 'Statut',
          value: profile.statut ?? '—',
          valueColor: AppColors.secondary,
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context, DriverProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.person_outline_rounded,
            iconColor: AppColors.primary,
            label: 'Informations personnelles',
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (_) => const DriverPersonalInfoScreen()),
            ),
          ),
          _Divider(),
          _MenuTile(
            icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF6366F1),
            label: 'Mot de passe & Sécurité',
            onTap: () => Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (_) => const DriverChangePasswordScreen()),
            ),
          ),
          _Divider(),
          _MenuTile(
            icon: Icons.notifications_none_rounded,
            iconColor: const Color(0xFFF59E0B),
            label: 'Notifications',
            trailing: CupertinoSwitch(
              activeTrackColor: AppColors.primary,
              value: _notificationEnabled,
              onChanged: (v) => setState(() => _notificationEnabled = v),
            ),
          ),
          _Divider(),
          _MenuTile(
            icon: Icons.help_outline_rounded,
            iconColor: Colors.teal,
            label: 'Centre d\'aide',
            onTap: () {},
          ),
          _Divider(),
          _MenuTile(
            icon: Icons.phone_outlined,
            iconColor: Colors.green,
            label: 'Contactez-nous',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, DriverProvider provider) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _showLogoutDialog(context, provider),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Se déconnecter',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, DriverProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'Êtes-vous sûr de vouloir vous déconnecter de votre session ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.logout();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SOUS-WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 20),
            const Gap(4),
            Text(
              value,
              style: TextStyle(
                color: valueColor ?? const Color(0xFF1E293B),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(2),
            Text(
              label,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _MenuTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const Gap(14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            trailing ??
                Icon(Icons.arrow_forward_ios_rounded,
                    size: 14, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
        height: 1, indent: 56, endIndent: 16, color: Color(0xFFF1F5F9));
  }
}
