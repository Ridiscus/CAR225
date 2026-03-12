import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/core/providers/user_provider.dart';
import '../providers/driver_provider.dart';
import 'driver_personal_info_screen.dart';
import 'driver_change_password_screen.dart';

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
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(user, driverProvider),
            const Gap(10),
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
                        builder: (context) => const DriverPersonalInfoScreen(),
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
            const Gap(30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: _buildLogoutButton(),
            ),
            const Gap(
              100,
            ), // Espace supplémentaire pour scroller au-delà du CurvedNavigationBar
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(dynamic user, DriverProvider provider) {
    final double topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // ── Image de Fond ──
        Container(
          height: 280 + topPadding,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/busheader2.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // ── Dégradé noir ──
        Container(
          height: 280 + topPadding,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),
        // ── Contenu ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: topPadding + 40, bottom: 30),
          child: Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 15,
                        ),
                      ],
                      image: DecorationImage(
                        image: provider.profileImage != null
                            ? FileImage(provider.profileImage!)
                            : const AssetImage(
                                    'assets/images/driver_profile.png',
                                  )
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () => _pickImage(ImageSource.gallery),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(15),
              Text(
                user != null ? "${user.name} ${user.prenom}" : "Chauffeur",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Gap(5),
              Text(
                user?.email ?? "chauffeur@car225.ci",
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Gap(15),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  "CHAUFFEUR",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 10,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Back Button
        Positioned(
          top: topPadding + 10,
          left: 10,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
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
