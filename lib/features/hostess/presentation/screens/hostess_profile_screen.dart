import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/hostess_profile_provider.dart';
import 'hostess_personal_info_screen.dart';
import 'hostess_change_password_screen.dart';
import '../../../../core/utils/page_transitions.dart';

class HostessProfileScreen extends StatefulWidget {
  const HostessProfileScreen({super.key});

  @override
  State<HostessProfileScreen> createState() => _HostessProfileScreenState();
}

class _HostessProfileScreenState extends State<HostessProfileScreen> {
  final String _firstName = 'Fabiola';
  final String _lastName = 'Kouassi';
  final String _role = 'HÔTESSE';
  final String _company = 'UTB EXPRESS';
  bool _notificationEnabled = true;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        if (mounted) {
          context.read<HostessProfileProvider>().updateImage(image.path);
        }
        _showSnackBar(message: 'Photo de profil mise à jour');
      }
    } catch (e) {
      _showSnackBar(message: 'Erreur lors du choix de l\'image', isError: true);
    }
  }

  void _showImagePreview() {
    final pickedImage = context.read<HostessProfileProvider>().profileImage;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withValues(alpha: 0.85),
              ),
            ),
            Hero(
              tag: 'hostess_profile_hero',
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                height: MediaQuery.of(context).size.width * 0.85,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  image: DecorationImage(
                    image: pickedImage != null
                        ? FileImage(pickedImage)
                        : const AssetImage('assets/images/agent_profile.png')
                              as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 10,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 35),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 25),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              _buildPhotoOption(
                icon: Icons.camera_alt_rounded,
                label: 'Prendre une photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              const Gap(12),
              _buildPhotoOption(
                icon: Icons.photo_library_rounded,
                label: 'Choisir dans la galerie',
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildPremiumHeader(),
              const Divider(height: 1, color: Color(0xFFF5F5F5)),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSection(
                      children: [
                        _buildActionTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Informations personnelles',
                          onTap: () => Navigator.push(
                            context,
                            PageTransitions.create(
                              page: const HostessPersonalInfoScreen(),
                              type: PageTransitionType.cupertino,
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.lock_outline_rounded,
                          label: 'Changer le mot de passe',
                          onTap: () => Navigator.push(
                            context,
                            PageTransitions.create(
                              page: const HostessChangePasswordScreen(),
                              type: PageTransitionType
                                  .cupertino, // Style iOS standard
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.notifications_outlined,
                          label: 'Notifications',
                          trailing: Switch(
                            value: _notificationEnabled,
                            activeThumbColor: AppColors.primary,
                            inactiveThumbColor: AppColors.grey,
                            onChanged: (value) {
                              setState(() => _notificationEnabled = value);
                            },
                          ),
                        ),
                      ],
                    ),
                    const Gap(30),
                    _buildLogoutButton(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    final pickedImage = context.watch<HostessProfileProvider>().profileImage;
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          Stack(
            children: [
              GestureDetector(
                onTap: _showImagePreview,
                child: Hero(
                  tag: 'hostess_profile_hero',
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        width: 4,
                      ),
                      image: DecorationImage(
                        image: pickedImage != null
                            ? FileImage(pickedImage)
                            : const AssetImage(
                                    'assets/images/agent_profile.png',
                                  )
                                  as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Gap(20),
          Text(
            '$_firstName $_lastName',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF263238),
            ),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _role,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          const Gap(8),
          Text(
            'EMPLOYÉE PAR $_company'.toUpperCase(),
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F2F5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: const Color(0xFF263238), size: 20),
      ),
      title: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Color(0xFF263238),
        ),
      ),
      trailing:
          trailing ??
          const Icon(Icons.chevron_right_rounded, color: Color(0xFFCFD8DC)),
      onTap: onTap,
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      onTap: onTap,
    );
  }

  Widget _buildDivider() =>
      const Divider(height: 1, indent: 60, color: Color(0xFFF5F5F7));

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          'Se déconnecter',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
