import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/profile_provider.dart';
import 'agent_personal_info_screen.dart';
import 'agent_change_password_screen.dart';

class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  // 1. VARIABLES D'ÉTAT & DONNÉES
  final String _firstName = 'Fabiola';
  final String _lastName = 'Kouassi';
  final String _role = 'AGENT';
  final String _company = 'UTB';
  bool _notificationEnabled = false;

  final ImagePicker _picker = ImagePicker();

  // 2. CYCLE DE VIE (Lifecycle)
  @override
  void dispose() {
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
  }

  // 3. LOGIQUE & ACTIONS

  // Méthode pour choisir une image
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (image != null) {
        if (mounted) {
          context.read<ProfileProvider>().updateImage(image.path);
        }
        _showSnackBar(message: 'Photo de profil mise à jour');
      }
    } catch (e) {
      _showSnackBar(message: 'Erreur lors du choix de l\'image', isError: true);
    }
  }

  // Méthode pour afficher l'aperçu en plein écran
  void _showImagePreview() {
    final pickedImage = context.read<ProfileProvider>().profileImage;
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
              tag: 'profile_hero',
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
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

  void _showLogoutDialog() {
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
              _showSnackBar(message: 'Déconnexion réussie');
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

  void _showSupportModal() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 5, bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.greyLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const Gap(16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aide & Support',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF263238),
                        ),
                      ),
                      Text(
                        'Une équipe à votre écoute',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(32),
              const Text(
                'Besoin d\'aide ? Contactez notre support technique pour signaler un problème ou poser vos questions.',
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF455A64),
                  height: 1.5,
                ),
              ),
              const Gap(24),
              _buildContactTile(
                icon: Icons.alternate_email_rounded,
                label: 'Par Email',
                value: 'support@car225.ci',
                onTap: () {},
              ),
              const Gap(12),
              _buildContactTile(
                icon: Icons.phone_in_talk_rounded,
                label: 'Par Téléphone',
                value: '+225 01 02 03 04 05',
                onTap: () {},
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 231, 62, 36),
                    foregroundColor: const Color.fromARGB(255, 255, 255, 255),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Fermer',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 4. COMPOSANTS UI (Helper Méthodes)
  Widget _buildPremiumHeader() {
    const Color peachBorder = Color(0xFFFFCCBC);
    const Color peachBadge = Color(0xFFFFE0B2);
    const Color textOrange = Color(0xFFFF7043);
    const Color companyGrey = Color(0xFF90A4AE);

    final pickedImage = context.watch<ProfileProvider>().profileImage;

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 30),
      child: Column(
        children: [
          // Avatar avec bordure premium
          Stack(
            children: [
              GestureDetector(
                onTap: _showImagePreview,
                child: Hero(
                  tag: 'profile_hero',
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: peachBorder, width: 4),
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
              // Bouton d'ajout/edition
              Positioned(
                bottom: 5,
                right: 5,
                child: GestureDetector(
                  onTap: _showPhotoOptions,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: peachBadge,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      color: textOrange,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const Gap(25),
          Text(
            '$_firstName $_lastName',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 23,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),

          const Gap(12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: peachBadge.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Text(
              _role,
              style: const TextStyle(
                color: textOrange,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),

          const Gap(12),
          Text(
            'EMPLOYE PAR $_company'.toUpperCase(),
            style: const TextStyle(
              color: companyGrey,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    VoidCallback? onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.greyDark, size: 20),
              ),
              const Gap(15),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.greyDark,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.grey.withValues(alpha: 0.5),
                    size: 22,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F2F5)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const Gap(16),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF263238),
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Color(0xFFB0BEC5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFF0F2F5)),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const Gap(16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF263238),
                  ),
                ),
              ],
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, color: AppColors.greyLight),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.greyLight.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: _showLogoutDialog,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: const BorderSide(color: Colors.red, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, size: 20),
            Gap(10),
            Text(
              'Se déconnecter',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  // 5. MÉTHODE BUILD (Assemblage Final)
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
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSection(
                      title: 'Mon Compte',
                      children: [
                        _buildActionTile(
                          icon: Icons.person_outline_rounded,
                          label: 'Informations personnelles',
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  const AgentPersonalInfoScreen(),
                            ),
                          ),
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.lock_outline_rounded,
                          label: 'Changer le mot de passe',
                          onTap: () => Navigator.push(
                            context,
                            CupertinoPageRoute(
                              builder: (context) =>
                                  const AgentChangePasswordScreen(),
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
                            onChanged: (value) {
                              setState(() {
                                _notificationEnabled = value;
                              });
                            },
                          ),
                        ),
                        _buildDivider(),
                        _buildActionTile(
                          icon: Icons.help_outline_rounded,
                          label: 'Aide & Support',
                          onTap: _showSupportModal,
                        ),
                      ],
                    ),
                    const Gap(30),
                    _buildLogoutButton(),
                    const Gap(20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
