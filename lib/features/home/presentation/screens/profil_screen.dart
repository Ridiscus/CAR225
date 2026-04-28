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
import '../../../booking/data/models/user_stats_model.dart';
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
  late AuthRepositoryImpl _repo;
  UserStatsModel? _userStats;
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _repo = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSourceImpl(),
      fcmService: FcmService(),
      deviceService: DeviceService(),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().loadUser();
      _fetchStats(); // 🟢 On charge les stats au lancement
    });
  }


  // --- 🟢 CHARGEMENT DES STATS GLOBALES ---
  Future<void> _fetchStats() async {
    try {
      final stats = await _repo.getUserStats();
      if (mounted) {
        setState(() {
          _userStats = stats;
          _isLoadingStats = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStats = false);
      }
      print("Erreur Stats: $e");
    }
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



  // --- 🟢 AFFICHER LES DÉTAILS (BOTTOM SHEET) ---
  void _showTripDetails() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(10)))),
              const Gap(20),
              Text("Détails de vos trajets", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
              const Gap(20),

              // 🟢 UTILISATION D'UN FUTURE BUILDER POUR CHARGER À LA VOLÉE
              Expanded(
                child: FutureBuilder<TripDetailsModel>(
                  future: _repo.getTripDetails(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Erreur de chargement", style: TextStyle(color: Colors.red.shade300)));
                    } else if (!snapshot.hasData) {
                      return const Center(child: Text("Aucune donnée disponible"));
                    }

                    final data = snapshot.data!;
                    return ListView(
                      children: [
                        _buildSectionTitle("Départs fréquents", Icons.flight_takeoff),
                        ...data.departsFrequents.map((e) => _buildTripTile(e.city, e.count, isDark)),
                        const Gap(20),
                        _buildSectionTitle("Arrivées fréquentes", Icons.flight_land),
                        ...data.arriveesFrequentes.map((e) => _buildTripTile(e.city, e.count, isDark)),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  // Widgets utilitaires pour le BottomSheet
  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const Gap(10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTripTile(String city, int count, bool isDark) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(city, style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade300 : Colors.black87)),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
        child: Text("$count fois", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
      ),
    );
  }

  /*@override
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
        // 🟢 AJOUT DU BOUTON RETOUR ICI
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context), // Retour à la page précédente
        ),
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
                Expanded(
                  child: GestureDetector(
                    onTap: _showTripDetails, // 🟢 Rendu cliquable ici !
                    child: _buildStatCard(
                      context,
                      _isLoadingStats ? "..." : "${_userStats?.totalReservations ?? 0}", // 🟢 Affiche 25 ou 0
                      "VOYAGES",
                    ),
                  ),
                ),
                const Gap(15),
                Expanded(
                    child: _buildStatCard(context, "2.25K", "POINTS", isPoints: true)
                ),
              ],
            ),
            const Gap(25),

            // --- 4. LISTE DES OPTIONS ---
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
  }*/


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    // ✅ ON ÉCOUTE LE PROVIDER ICI
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
        // 🟢 AJOUT DU BOUTON RETOUR ICI
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
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
                          image: NetworkImage(user.fullPhotoUrl),
                          onError: (_, __) {
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
                Expanded(
                  child: GestureDetector(
                    onTap: _showTripDetails,
                    child: _buildStatCard(
                      context,
                      _isLoadingStats ? "..." : "${_userStats?.totalReservations ?? 0}",
                      "VOYAGES",
                    ),
                  ),
                ),
                const Gap(15),
                Expanded(
                    child: _buildStatCard(context, "2.25K", "POINTS", isPoints: true)
                ),
              ],
            ),
            const Gap(25),

            // --- 4. LISTE DES OPTIONS ---
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
              iconColor: Colors.red,
              // 🟢 MODIFICATION ICI : Appel de la nouvelle fonction BottomSheet
              onTap: () => _showLogoutBottomSheet(context),
            ),

            const Gap(40), // Espace avant la version

            // 🟢 AJOUT DE LA VERSION ICI
            Text(
              "Version 1.0.0",
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),

            const Gap(40), // Espace après la version pour ne pas coller au bord
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


  // 🟢 NOUVEAU BOTTOM SHEET DE DÉCONNEXION
  void _showLogoutBottomSheet(BuildContext parentContext) {
    final isDark = Theme.of(parentContext).brightness == Brightness.dark;

    showModalBottomSheet(
      context: parentContext,
      backgroundColor: isDark ? Theme.of(parentContext).scaffoldBackgroundColor : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Bords bien arrondis
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Prend juste la hauteur nécessaire
              children: [
                // 1. Le petit trait gris en haut (Drag handle)
                Container(
                  width: 45,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const Gap(25),

                // 2. L'icône rouge dans le cercle clair
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1), // Fond rouge très clair
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFC60000), size: 30),
                ),
                const Gap(20),

                // 3. Le Titre
                Text(
                  "Déconnexion",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const Gap(10),

                // 4. Le sous-titre
                Text(
                  "Êtes-vous sûr de vouloir vous déconnecter ?",
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(30),

                // 5. Les boutons (Annuler / Déconnexion)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(sheetContext), // Ferme le menu
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey.shade300),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: Text(
                          "Annuler",
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const Gap(15),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(sheetContext); // Ferme la popup

                          // 1. Appel Logout
                          final repo = AuthRepositoryImpl(
                            remoteDataSource: AuthRemoteDataSourceImpl(),
                            fcmService: FcmService(),
                            deviceService: DeviceService(),
                          );
                          await repo.logout();

                          // 2. Navigation Login
                          if (!parentContext.mounted) return;
                          Navigator.pushAndRemoveUntil(
                              parentContext,
                              MaterialPageRoute(builder: (context) => const LoginScreen()),
                                  (route) => false
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC60000), // Rouge sombre
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          elevation: 0,
                        ),
                        child: const Text(
                          "Déconnexion",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(10), // Un peu d'espace en bas
              ],
            ),
          ),
        );
      },
    );
  }

}