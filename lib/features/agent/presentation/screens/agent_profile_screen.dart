import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../data/datasources/agent_remote_data_source.dart';
import '../../data/repositories/agent_repository_impl.dart';
import '../providers/agent_profile_provider.dart';
import 'agent_personal_info_screen.dart';
import 'agent_change_password_screen.dart';

class AgentProfileScreen extends StatefulWidget {
  const AgentProfileScreen({super.key});

  @override
  State<AgentProfileScreen> createState() => _AgentProfileScreenState();
}

class _AgentProfileScreenState extends State<AgentProfileScreen> {
  // 1. VARIABLES D'ÉTAT & DONNÉES
  final String _role = 'AGENT';
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
    // 🟢 On déclenche la récupération du profil dès l'ouverture
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AgentProfileProvider>().fetchProfile();
    });
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
          context.read<AgentProfileProvider>().updateImage(image.path);
        }
        _showSnackBar(message: 'Photo de profil mise à jour');
      }
    } catch (e) {
      _showSnackBar(message: 'Erreur lors du choix de l\'image', isError: true);
    }
  }

  // Méthode pour afficher l'aperçu en plein écran
  void _showImagePreview() {
    final pickedImage = context.read<AgentProfileProvider>().profileImage;
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
                color: Colors.black.withOpacity(0.85),
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
                      color: Colors.black.withOpacity(0.3),
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
      barrierDismissible: false, // Empêche de fermer en cliquant à côté pendant le chargement
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Déconnexion'),
        content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              // 1. On ferme la boîte de dialogue
              Navigator.pop(dialogContext);

              // 2. On affiche un petit indicateur de chargement global (optionnel mais UX friendly)
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              );

              try {
                // 3. On instancie le repo et on appelle l'API
                final repo = AgentRepositoryImpl(
                  remoteDataSource: AgentRemoteDataSourceImpl(),
                );

                await repo.logout();

                if (mounted) {
                  // 4. On ferme le loader
                  Navigator.pop(context);

                  // 5. On redirige vers l'écran de Login en vidant la pile de navigation
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  // En cas d'erreur (ex: pas de réseau), on ferme le loader
                  Navigator.pop(context);
                  // On redirige quand même par sécurité car on a vidé le cache local
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                        (route) => false,
                  );
                }
              }
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


  Future<void> _launchPhone(String phone) async {
    // On enlève les espaces pour s'assurer que le dialer le lise bien
    final String cleanPhone = phone.replaceAll(' ', '');
    final Uri phoneUri = Uri(
      scheme: 'tel',
      path: cleanPhone,
    );

    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      debugPrint("Impossible d'ouvrir le clavier téléphonique.");
    }
  }

  String? _encodeQueryParameters(Map<String, String> params) {
    return params.entries
        .map((MapEntry<String, String> e) =>
    '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}')
        .join('&');
  }

  // 🟢 La fonction de lancement mise à jour
  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: email,
      // On remplit l'objet (sujet) ici de manière sécurisée
      query: _encodeQueryParameters(<String, String>{
        'subject': 'Demande de support - Car225',
        // Optionnel : tu peux même pré-remplir le corps du message !
        // 'body': 'Bonjour l\'équipe Car225,\n\nJ\'ai besoin d\'aide concernant : '
      }),
    );

    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      debugPrint("Impossible d'ouvrir l'application d'e-mail.");
      // Tu pourrais afficher un ScaffoldMessenger (SnackBar) ici pour informer l'utilisateur
    }
  }

// 🟢 3. Ta méthode mise à jour
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
                      color: AppColors.primary.withOpacity(0.1),
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

              // 🟢 4. Ajout des actions dans les onTap
              _buildContactTile(
                icon: Icons.alternate_email_rounded,
                label: 'Par Email',
                value: 'contact@car225.com',
                onTap: () {
                  Navigator.pop(context); // Optionnel: fermer la modale avant d'ouvrir l'app externe
                  _launchEmail('contact@car225.com');
                },
              ),
              const Gap(12),
              _buildContactTile(
                icon: Icons.phone_in_talk_rounded,
                label: 'Par Téléphone',
                value: '+225 01 02 03 04 05',
                onTap: () {
                  Navigator.pop(context); // Optionnel: fermer la modale avant d'ouvrir le dialer
                  _launchPhone('+225 01 02 03 04 05');
                },
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


  Widget _buildPremiumHeader() {
    // 🟢 On écoute le provider pour récupérer les données et l'image locale
    final provider = context.watch<AgentProfileProvider>();
    final pickedImage = provider.profileImage;
    final data = provider.profileData;
    final isLoading = provider.isLoadingProfile;

    final double topPadding = MediaQuery.of(context).padding.top;

    // 🛠️ RÉPARATION DE L'URL DE L'IMAGE (Même logique que l'autre écran)
    String? rawImageUrl = data?['profile_picture_url']?.toString();
    String? finalImageUrl;

    if (rawImageUrl != null && rawImageUrl.trim().isNotEmpty) {
      if (rawImageUrl.startsWith('http')) {
        finalImageUrl = rawImageUrl;
      } else {
        final String baseUrl = 'https://jingly-lindy-unminding.ngrok-free.dev';
        finalImageUrl = rawImageUrl.startsWith('/')
            ? '$baseUrl$rawImageUrl'
            : '$baseUrl/$rawImageUrl';
      }
    }

    // 🟢 Extraction sécurisée des données avec valeurs par défaut pendant le chargement
    final String firstName = data?['prenom'] ?? (isLoading ? '...' : 'Agent');
    final String lastName = data?['name'] ?? (isLoading ? '...' : 'Anonyme');
    final String company = data?['compagnie']?['name'] ?? (isLoading ? '...' : 'Non définie');

    return Stack(
      children: [
        // ── Image de Fond (Car) ──
        Container(
          height: 300 + topPadding,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/busheader4.jpg'),
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
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.8),
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
                      tag: 'profile_hero',
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                          image: DecorationImage(
                            // 🟢 LOGIQUE DE L'IMAGE INTELLIGENTE
                            image: pickedImage != null
                                ? FileImage(pickedImage) as ImageProvider
                                : (finalImageUrl != null
                                ? NetworkImage(finalImageUrl) as ImageProvider
                                : const AssetImage('assets/images/agent_profile.png')),
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
              // Nom et Prénoms (Dynamique)
              Text(
                '$firstName $lastName'.toUpperCase(),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const Gap(8),
              // Badge Rôle (Statique ou dynamique selon ton API)
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
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Text(
                  _role, // On garde "AGENT" en dur car c'est le rôle
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const Gap(10),
              // Entreprise (Dynamique)
              Text(
                'EMPLOYÉ PAR $company'.toUpperCase(),
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
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
              color: Colors.grey.withOpacity(0.2),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
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
                    color: AppColors.grey.withOpacity(0.5),
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
                  color: AppColors.primary.withOpacity(0.1),
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
        color: AppColors.greyLight.withOpacity(0.5),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: const Text(
          'Profil',
          style: TextStyle(
            color: Colors.white,
            fontSize: 23,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildPremiumHeader(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSection(
                    title: 'Mon Compte',
                    children: [
                      _buildActionTile(
                        icon: Icons.person_outline_rounded,
                        label: 'Informations personnelles',
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const AgentPersonalInfoScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SlideTransition(
                                    position:
                                        Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                    child: child,
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        icon: Icons.lock_outline_rounded,
                        label: 'Changer le mot de passe',
                        onTap: () => Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    const AgentChangePasswordScreen(),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return SlideTransition(
                                    position:
                                        Tween<Offset>(
                                          begin: const Offset(1.0, 0.0),
                                          end: Offset.zero,
                                        ).animate(
                                          CurvedAnimation(
                                            parent: animation,
                                            curve: Curves.easeOutCubic,
                                          ),
                                        ),
                                    child: child,
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 400,
                            ),
                          ),
                        ),
                      ),
                      _buildDivider(),
                      _buildActionTile(
                        icon: Icons.notifications_outlined,
                        label: 'Notifications',
                        trailing: Switch(
                          value: _notificationEnabled,
                          activeTrackColor: AppColors.primary,
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
                  const Gap(
                    130,
                  ), // Espace supplémentaire pour scroller au-delà du CurvedNavigationBar
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
