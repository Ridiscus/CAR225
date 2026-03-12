import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../../../../core/services/device/device_service.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../providers/hostess_profile_provider.dart';
import 'hostess_personal_info_screen.dart';
import 'hostess_change_password_screen.dart';
import 'package:car225/core/utils/page_transitions.dart';

class HostessProfileScreen extends StatefulWidget {
  const HostessProfileScreen({super.key});

  @override
  State<HostessProfileScreen> createState() => _HostessProfileScreenState();
}

class _HostessProfileScreenState extends State<HostessProfileScreen> {
  // 🟢 On a supprimé les variables en dur (_firstName, _lastName, etc.)
  final String _role = 'HÔTESSE'; // On garde le rôle en dur car c'est l'app Hôtesse
  bool _notificationEnabled = true;

  bool _isLoadingLogout = false;

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

  @override
  void initState() {
    super.initState();
    // 🟢 On lance le chargement des données au démarrage de l'écran (s'il est vide)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<HostessProfileProvider>();
      if (provider.profileData == null) {
        provider.fetchProfile(
          AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSourceImpl(),
            fcmService: FcmService(),
            deviceService: DeviceService(),
          ),
        );
      }
    });
  }

  Future<void> _handleLogout() async {
    // Demander confirmation avant de déconnecter
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Êtes-vous sûr de vouloir vous déconnecter ?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Annuler"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Se déconnecter", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoadingLogout = true);

    try {
      // Instanciation de ton repository (tu peux aussi utiliser un Provider/GetIt si tu en as un)
      final authRepository = AuthRepositoryImpl(
        remoteDataSource: AuthRemoteDataSourceImpl(),
        fcmService: FcmService(),       // Remplace si tu as une injection de dépendance
        deviceService: DeviceService(), // Remplace si tu as une injection de dépendance
      );

      await authRepository.logouut();

      if (!mounted) return;

      // Rediriger vers l'écran de connexion en vidant la pile de navigation
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );

    } catch (e) {
      _showSnackBar(message: "Erreur lors de la déconnexion", isError: true);
    } finally {
      if (mounted) {
        setState(() => _isLoadingLogout = false);
      }
    }
  }

  void _showImagePreview() {
    final provider = context.read<HostessProfileProvider>();
    final pickedImage = provider.profileImage;
    final profile = provider.profileData;

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
                    // 🟢 MÊME LOGIQUE POUR L'URL DE L'IMAGE DANS LA PRÉVISUALISATION
                    image: pickedImage != null
                        ? FileImage(pickedImage)
                        : (profile?.profilePicture != null && profile!.profilePicture!.isNotEmpty
                        ? NetworkImage('https://jingly-lindy-unminding.ngrok-free.dev/storage/${profile.profilePicture}')
                        : const AssetImage('assets/images/hostess_profile.png'))
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
    // 🟢 On écoute le provider complet ici
    final provider = context.watch<HostessProfileProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(provider), // On passe le provider
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
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
                            type: PageTransitionType.cupertino,
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
                  const Gap(100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*Widget _buildPremiumHeader() {
    final pickedImage = context.watch<HostessProfileProvider>().profileImage;
    final double topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        // ── Image de Fond (Car) ──
        Container(
          height: 300 + topPadding,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/busheader5.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // ── Dégradé noir protecteur ──
        Container(
          height: 300 + topPadding,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        // ── Contenu du profil ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: topPadding + 40, bottom: 40),
          child: Column(
            children: [
              // Photo de Profil avec bordure brillante
              Stack(
                children: [
                  GestureDetector(
                    onTap: _showImagePreview,
                    child: Hero(
                      tag: 'hostess_profile_hero',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: DecorationImage(
                            image: pickedImage != null
                                ? FileImage(pickedImage)
                                : const AssetImage(
                                        'assets/images/hostess_profile.png',
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
                          border: Border.all(color: Colors.white, width: 2.5),
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
              const Gap(20),
              // Nom et Prénoms (Blanc)
              Text(
                '$_firstName $_lastName',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Gap(8),
              // Badge Rôle (Orange UTB)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Gap(10),
              // Entreprise (Blanc cassé)
              Text(
                'EMPLOYÉE PAR $_company'.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }*/


  Widget _buildPremiumHeader(HostessProfileProvider provider) {
    final pickedImage = provider.profileImage;
    final profile = provider.profileData;
    final isLoading = provider.isLoading;

    final double topPadding = MediaQuery.of(context).padding.top;

    // 🟢 Données dynamiques avec fallbacks pendant le chargement
    final String firstName = profile?.prenom ?? (isLoading ? '...' : '');
    final String lastName = profile?.name ?? (isLoading ? 'Chargement' : 'Inconnu');
    final String company = profile?.nomCompagnie ?? (isLoading ? '...' : 'Inconnue');

    return Stack(
      children: [
        // ── Image de Fond (Car) ──
        Container(
          height: 300 + topPadding,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/busheader5.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        // ── Dégradé noir protecteur ──
        Container(
          height: 300 + topPadding,
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.1),
                Colors.black.withValues(alpha: 0.8),
              ],
            ),
          ),
        ),
        // ── Contenu du profil ──
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(top: topPadding + 40, bottom: 40),
          child: Column(
            children: [
              // Photo de Profil avec bordure brillante
              Stack(
                children: [
                  GestureDetector(
                    onTap: _showImagePreview,
                    child: Hero(
                      tag: 'hostess_profile_hero',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: DecorationImage(
                            // 🟢 MÊME LOGIQUE D'URL ICI
                            image: pickedImage != null
                                ? FileImage(pickedImage)
                                : (profile?.profilePicture != null && profile!.profilePicture!.isNotEmpty
                                ? NetworkImage('https://jingly-lindy-unminding.ngrok-free.dev/storage/${profile.profilePicture}')
                                : const AssetImage('assets/images/hostess_profile.png'))
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
                          border: Border.all(color: Colors.white, width: 2.5),
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
              const Gap(20),
              // 🟢 Nom et Prénoms Dynamiques
              Text(
                '$firstName $lastName'.trim(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Gap(8),
              // Badge Rôle (Orange UTB)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _role,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Gap(10),
              // 🟢 Entreprise Dynamique
              Text(
                'EMPLOYÉE PAR $company'.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
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
        onPressed: _isLoadingLogout ? null : _handleLogout, // 🟢 Utilise la nouvelle méthode
        icon: _isLoadingLogout
            ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.red)
        )
            : const Icon(Icons.logout_rounded),
        label: Text(
          _isLoadingLogout ? 'Déconnexion...' : 'Se déconnecter',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
