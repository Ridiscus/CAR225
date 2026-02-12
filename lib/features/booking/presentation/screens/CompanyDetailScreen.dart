import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

// --- IMPORTS ---
import '../../../../common/widgets/local_badge.dart';
import '../../../../core/providers/company_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/models/compagnie_program_model2.dart';

import '../../../home/presentation/screens/notification_screen.dart';
import '../../../home/presentation/screens/profil_screen.dart';

class CompanyDetailScreen extends StatefulWidget {
  final int companyId;
  final String companyName;

  const CompanyDetailScreen({
    super.key,
    required this.companyId,
    required this.companyName
  });

  @override
  State<CompanyDetailScreen> createState() => _CompanyDetailScreenState();
}

class _CompanyDetailScreenState extends State<CompanyDetailScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().fetchCompanyDetailsWithProgrammes(widget.companyId);
    });
  }

  // --- ACTIONS ---
  // --- APPELER ---
  Future<void> _makePhoneCall(String phoneNumber) async {
    // 1. Nettoyer le numéro (enlever les espaces qui font planter l'URI)
    final cleanNumber = phoneNumber.replaceAll(RegExp(r'\s+'), '');

    final Uri launchUri = Uri(
      scheme: 'tel',
      path: cleanNumber,
    );

    debugPrint("Tentative d'appel vers : $cleanNumber"); // Pour vérifier dans la console

    // Mode externalApplication est souvent requis pour le dialer
    try {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      } else {
        // Fallback: force le lancement même si canLaunch retourne false (bug connu sur certains Android)
        await launchUrl(launchUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint("Erreur lors de l'appel : $e");
    }
  }

  // --- LOCALISER ---
  Future<void> _openMap(String address) async {
    // On encode l'adresse pour qu'elle passe dans l'URL (ex: les espaces deviennent %20)
    final query = Uri.encodeComponent(address);

    // Utilisation d'une URL Google Maps universelle (marche sur App + Navigateur)
    final Uri googleMapsUrl = Uri.parse("https://www.google.com/maps/search/?api=1&query=$query");

    debugPrint("Ouverture Maps : $googleMapsUrl");

    try {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Erreur Maps : $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: Consumer<CompanyProvider>(
        builder: (context, provider, child) {

          if (provider.isLoadingDetails) {
            return const Center(child: CircularProgressIndicator());
          }

          final company = provider.selectedCompany;
          final programmes = provider.selectedCompanyProgrammes;

          if (company == null && !provider.isLoadingDetails) {
            return Scaffold(
              appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
              body: Center(child: Text("Info indisponible. ${provider.error ?? ''}")),
            );
          }

          // --- DONNÉES & LOGIQUE URL IMAGE ---
          final contactPhone = company?.contact?.telephone ?? "";
          final contactLocation = company?.contact?.commune ?? "Abidjan";
          final slogan = (company?.slogan != null && company!.slogan.isNotEmpty)
              ? company!.slogan
              : "Votre partenaire de voyage";

          // ⚠️ IMPORTANT : Remplace ceci par l'URL racine de ton API Laravel
          // Exemple local émulateur: "http://10.0.2.2:8000/"
          // Exemple réel: "https://mon-site-transport.com/"
          const String baseUrl = "https://jingly-lindy-unminding.ngrok-free.dev/";

          String? fullLogoUrl;

          if (company?.logoUrl != null && company!.logoUrl.isNotEmpty) {
            // Si l'API renvoie déjà http... (peu probable ici mais bonne pratique)
            if (company!.logoUrl.startsWith('http')) {
              fullLogoUrl = company!.logoUrl;
            } else {
              // On nettoie pour éviter les doubles slashs "//"
              String cleanPath = company!.logoUrl;
              if (cleanPath.startsWith('/')) {
                cleanPath = cleanPath.substring(1);
              }

              // On colle : Base + Chemin
              // Résultat : https://jingly...dev/storage/compagnies/...
              fullLogoUrl = "$baseUrl$cleanPath";
            }
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),

                Transform.translate(
                  offset: const Offset(0, -20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: scaffoldColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // --- IDENTITÉ AVEC LOGO CORRIGÉ ---
                        Row(
                          children: [
                            Container(
                              height: 60, width: 60,
                              decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                  image: (fullLogoUrl != null)
                                      ? DecorationImage(
                                    image: NetworkImage(fullLogoUrl),
                                    fit: BoxFit.cover,
                                    // Gestion d'erreur si l'image ne charge pas malgré l'URL
                                    onError: (exception, stackTrace) {
                                      debugPrint("Erreur chargement image: $exception");
                                    },
                                  )
                                      : null
                              ),
                              // Fallback si pas d'image ou erreur
                              child: (fullLogoUrl == null)
                                  ? Center(child: Text(company?.name[0] ?? "C", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)))
                                  : null,
                            ),
                            const Gap(15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    company?.name ?? widget.companyName,
                                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: textColor),
                                  ),
                                  const Gap(4),
                                  Text(
                                    slogan,
                                    style: TextStyle(color: secondaryTextColor, fontSize: 13, fontStyle: FontStyle.italic),
                                    maxLines: 1, overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const Gap(25),

                        // --- BOUTONS ACTIONS ---
                        Row(
                          children: [
                            Expanded(
                              child: _buildActionButton(
                                  context,
                                  icon: Icons.phone_in_talk,
                                  label: "Appeler",
                                  color: Colors.green,
                                  onTap: () => contactPhone.isNotEmpty ? _makePhoneCall(contactPhone) : null,
                                  subText: contactPhone.isNotEmpty ? contactPhone : "Non dispo"
                              ),
                            ),
                            const Gap(15),
                            Expanded(
                              child: _buildActionButton(
                                  context,
                                  icon: Icons.map,
                                  label: "Localiser",
                                  color: Colors.blueAccent,
                                  onTap: () => _openMap(contactLocation),
                                  subText: contactLocation
                              ),
                            ),
                          ],
                        ),

                        const Gap(30),

                        // --- LISTE DES TRAJETS ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Nos Itinéraires",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                "${programmes.length} trajets",
                                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                        const Gap(15),

                        if (programmes.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                                color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey[50],
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(color: isDark ? Colors.white10 : Colors.grey[200]!)
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.route_outlined, size: 40, color: secondaryTextColor),
                                const Gap(10),
                                Text("Aucun trajet planifié.", style: TextStyle(color: secondaryTextColor)),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: programmes.length,
                            separatorBuilder: (ctx, i) => const Gap(15),
                            itemBuilder: (ctx, i) {
                              return _buildImprovedRouteCard(context, programmes[i]);
                            },
                          ),

                        const Gap(80),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- WIDGETS ---
  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onTap, required String subText}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const Gap(8),
            Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
            const Gap(2),
            Text(subText, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  Widget _buildImprovedRouteCard(BuildContext context, ProgrammeModel programme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final mutedColor = isDark ? Colors.grey[500] : Colors.grey[600];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Column(
                  children: [
                    Icon(Icons.circle, size: 10, color: AppColors.primary),
                    Container(height: 30, width: 2, color: isDark ? Colors.grey[800] : Colors.grey[200]),
                    Icon(Icons.location_on, size: 14, color: Colors.orange),
                  ],
                ),
                const Gap(15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(programme.depart, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                      const Gap(15),
                      Text(programme.arrivee, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: mutedColor),
              ],
            ),
            const Gap(15),
            Divider(color: borderColor, height: 1),
            const Gap(10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time_rounded, size: 16, color: mutedColor),
                    const Gap(6),
                    Text(
                      programme.duree.isNotEmpty ? programme.duree : "-- h --",
                      style: TextStyle(color: mutedColor, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: const Text("Disponible", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    // Code du header identique à avant...
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user; // ✅ On prend l'objet user entier
    final userPhotoUrl = userProvider.user?.photoUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: const DecorationImage(
          image: AssetImage("assets/images/busheader2.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[200],
                          // ✅ C'EST ICI QUE TOUT SE JOUE :
                          // On utilise user.fullPhotoUrl (ton getter magique)
                          backgroundImage: user != null
                              ? NetworkImage(user.fullPhotoUrl)
                              : const AssetImage("assets/images/ci.jpg") as ImageProvider,

                          // Petit bonus : gestion d'erreur silencieuse
                          onBackgroundImageError: (_, __) {},
                        ),
                      ),
                    ),
                    const Gap(12),
                    const LocationBadge(),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                  child: Container(
                    height: 45, width: 45,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle, border: Border.all(color: Colors.white.withOpacity(0.1))),
                    child: Image.asset("assets/icons/notification.png", color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}