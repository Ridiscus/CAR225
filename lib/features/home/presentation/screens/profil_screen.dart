import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // ✅ Indispensable
import 'package:gap/gap.dart';

// --- IMPORTS ---
import '../../../../core/providers/user_provider.dart'; // Ton Provider
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/datasources/auth_remote_data_source.dart';
import '../../../auth/data/repositories/auth_repository_impl.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../../core/services/notifications/fcm_service.dart';
import '../../../../core/services/device/device_service.dart';

// Ecrans
import 'personal_info_screen.dart';
import 'security_screen.dart';
import 'wallet_screen.dart';
import 'account_setting_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    // ✅ On demande au Provider de rafraîchir les données quand on arrive sur cette page
    // (Juste au cas où, c'est une sécurité)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUser();
    });
  }

  // Navigation vers l'édition
  void _navigateToEdit() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PersonalInfoScreen()),
    ).then((_) {
      // ✅ Quand on revient, on recharge le profil via le Provider
      if(mounted) context.read<UserProvider>().loadUser();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    // ✅ ON ÉCOUTE LE PROVIDER ICI
    // Dès que l'image change ailleurs, cette page se mettra à jour toute seule !
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isLoading = userProvider.isLoading;

    if (isLoading || user == null) {
      return Scaffold(backgroundColor: scaffoldColor, body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            // --- 1. PHOTO DE PROFIL DYNAMIQUE ---
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.shade300, width: 3),
                      image: DecorationImage(
                          fit: BoxFit.cover,
                          // ✅ MAGIE : On utilise ton getter intelligent ici !
                          // Plus besoin de vérifier null ou isNotEmpty, le getter le fait.
                          image: NetworkImage(user.fullPhotoUrl),
                          onError: (_, __) {
                            // Petit fix si l'image plante vraiment
                            print("Erreur affichage image profil");
                          }
                      ),
                    ),
                  ),
                  // Le petit bouton "+" (Édition)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _navigateToEdit,
                      child: Container(
                        height: 32, width: 32,
                        decoration: BoxDecoration(
                            color: cardColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
                            boxShadow: [BoxShadow(color: isDark ? Colors.black26 : Colors.black.withOpacity(0.1), blurRadius: 5)]
                        ),
                        child: Icon(Icons.edit, size: 16, color: textColor),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const Gap(15),

            // --- 2. NOM DYNAMIQUE ---
            Text(
              "${user.prenom} ${user.name}",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
            ),
            const Gap(5),
            Text(
              "MEMBRE CAR 225",
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: secondaryTextColor, letterSpacing: 1.0),
            ),
            const Gap(25),

            // --- 3. STATISTIQUES ---
            Row(
              children: [
                Expanded(child: _buildStatCard(context, "12", "VOYAGES")),
                const Gap(15),
                Expanded(child: _buildStatCard(context, "2.25K", "POINTS", isPoints: true)),
              ],
            ),
            const Gap(25),

            // --- 4. LISTE DES OPTIONS ---
            // Le reste de ton code est parfait, je l'ai gardé tel quel
            _buildMenuOption(
              context: context,
              imagePath: "assets/images/user.png",
              title: "Mes informations personnelles",
              onTap: _navigateToEdit,
            ),
            const Gap(15),

            _buildMenuOption(
              context: context,
              imagePath: "assets/images/wallet.png",
              title: "Portefeuille Mobile Money",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const WalletScreen())),
            ),
            const Gap(15),

            _buildMenuOption(
              context: context,
              imagePath: "assets/images/setting.png",
              title: "Paramètre du compte",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccountSettingsScreen())),
            ),
            const Gap(15),

            _buildMenuOption(
              context: context,
              imagePath: "assets/images/security.png",
              title: "Sécurité & Confidentialité",
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityScreen())),
            ),
            const Gap(15),

            _buildMenuOption(
              context: context,
              imagePath: "assets/images/logout.png",
              title: "Déconnexion",
              textColor: Colors.red,
              iconColor: Colors.red, // On garde l'icône rouge pour la déconnexion
              onTap: () => _showLogoutDialog(context),
            ),

            const Gap(120),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS HELPER ---

  Widget _buildMenuOption({
    required BuildContext context,
    required String imagePath,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
    Color? iconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;
    final finalTextColor = textColor ?? (isDark ? Colors.grey[300] : Colors.grey.shade600);
    final arrowColor = isDark ? Colors.grey[600] : Colors.grey.shade400;

    // Si iconColor est null, on adapte au thème (Noir/Blanc), sinon on prend la couleur forcée (ex: Rouge)
    final finalIconColor = iconColor ?? (isDark ? Colors.white70 : Colors.black87);

    return Container(
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: isDark ? Colors.transparent : Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 2))],
          border: Border.all(color: borderColor)
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Image.asset(
                  imagePath,
                  width: 24,
                  height: 24,
                  color: finalIconColor,
                ),
                const Gap(15),
                Expanded(child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: finalTextColor))),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: arrowColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String value, String label, {bool isPoints = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white10 : const Color(0xFFFFF3E0);
    final borderColor = Colors.orange.withOpacity(0.1);
    final valueColor = isDark ? Colors.white : Colors.black;
    final labelColor = isDark ? Colors.grey[400] : Colors.black54;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: valueColor)),
          const Gap(5),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: labelColor)),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext parentContext) {
    showDialog(
      context: parentContext,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Déconnexion"),
        content: const Text("Voulez-vous vraiment vous déconnecter ?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Annuler", style: TextStyle(color: Colors.grey))),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext); // Ferme la popup

              // 1. Appel Logout
              final repo = AuthRepositoryImpl(
                remoteDataSource: AuthRemoteDataSourceImpl(),
                fcmService: FcmService(),
                deviceService: DeviceService(),
              );
              await repo.logout();

              // 2. Navigation Login
              if (!parentContext.mounted) return;
              Navigator.pushAndRemoveUntil(parentContext, MaterialPageRoute(builder: (context) => const LoginScreen()), (route) => false);
            },
            child: const Text("Déconnexion", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}