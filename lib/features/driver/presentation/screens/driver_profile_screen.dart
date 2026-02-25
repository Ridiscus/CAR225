import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/providers/user_provider.dart';
import '../providers/driver_provider.dart';
import 'driver_personal_info_screen.dart';
import 'driver_change_password_screen.dart';

import '../widgets/driver_header.dart';

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
      if (image != null) {
        if (mounted) {
          context.read<DriverProvider>().updateProfileImage(image.path);
        }
        _showSnackBar(message: 'Photo de profil mise à jour');
      }
    } catch (e) {
      _showSnackBar(message: 'Erreur lors du choix de l\'image', isError: true);
    }
  }

  void _showSnackBar({String message = "", bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : AppColors.secondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final driverProvider = Provider.of<DriverProvider>(context);
    final user = userProvider.user;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          const DriverHeader(title: "Mon Profil", showProfile: false),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  const Gap(15),
                  // USER CARD
                  _buildUserCard(user, driverProvider),
                  const Gap(5),
                  // SETTINGS LIST
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Column(
                      children: [
                        _buildSettingTile(
                          icon: Icons.person_outline,
                          label: "Informations personnelles",
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  const DriverPersonalInfoScreen(),
                            ),
                          ),
                        ),
                        _buildSettingTile(
                          icon: Icons.lock_outline,
                          label: "Mot de passe & Sécurité",
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  const DriverChangePasswordScreen(),
                            ),
                          ),
                        ),
                        _buildSettingTile(
                          icon: Icons.notifications_none_rounded,
                          label: "Notifications",
                          trailing: CupertinoSwitch(
                            activeTrackColor: AppColors.primary,
                            value: _notificationEnabled,
                            onChanged: (v) =>
                                setState(() => _notificationEnabled = v),
                          ),
                        ),
                        _buildSettingTile(
                          icon: Icons.translate_rounded,
                          label: "Langue",
                        ),
                        _buildSettingTile(
                          icon: Icons.help_outline_rounded,
                          label: "Centre d'aide",
                        ),
                        _buildSettingTile(
                          icon: Icons.phone_outlined,
                          label: "Contactez-nous",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: Platform.isAndroid ? true : false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                22,
                0,
                22,
                30,
              ), // Ajusté pour être juste au-dessus du CurvedNavigationBar (65px)
              child: _buildLogoutButton(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(dynamic user, DriverProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.grey[100],
                  backgroundImage: provider.profileImage != null
                      ? FileImage(provider.profileImage!)
                      : null,
                  child: provider.profileImage == null
                      ? const Icon(Icons.person, size: 40, color: Colors.grey)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap: () => _pickImage(ImageSource.gallery),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
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
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user != null
                        ? "${user.name} ${user.prenom}"
                        : "Ronald Richards",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const Gap(4),
                  Text(
                    user?.email ?? "ronaldrichards@gmail.com",
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 26),
            const Gap(16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
            ),
            trailing ??
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.black54,
                  size: 14,
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Material(
      color: Colors.red,
      borderRadius: BorderRadius.circular(15),
      elevation: 4,
      shadowColor: Colors.red.withValues(alpha: 0.3),
      child: InkWell(
        onTap: () => _showLogoutConfirmation(),
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 56,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.logout_rounded, color: Colors.white, size: 24),
              Gap(12),
              Text(
                "Se déconnecter",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserProvider>().clearUser();
              _showSnackBar(message: "Déconnexion réussie");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
