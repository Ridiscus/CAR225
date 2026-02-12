import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import '../../../../common/widgets/local_badge.dart';
import '../../../../core/providers/company_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
// Adapte les imports selon ton dossie
import '../../../booking/data/models/company_model.dart';
import '../../../booking/presentation/screens/CompanyDetailScreen.dart';
import 'profil_screen.dart'; // Vérifie tes imports
import 'notification_screen.dart'; // Vérifie tes imports

class CompaniesTabScreen extends StatefulWidget {
  const CompaniesTabScreen({super.key});

  @override
  State<CompaniesTabScreen> createState() => _CompaniesTabScreenState();
}

class _CompaniesTabScreenState extends State<CompaniesTabScreen> {

  @override
  void initState() {
    super.initState();
    // On charge les compagnies au démarrage de l'écran
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CompanyProvider>().fetchCompanies();
    });
  }

  @override
  Widget build(BuildContext context) {
    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: RefreshIndicator(
        onRefresh: () => context.read<CompanyProvider>().fetchCompanies(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- 1. HEADER ---
              _buildHeader(context),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- 2. TITRE & CONSOMMATEUR ---
                    Consumer<CompanyProvider>(
                      builder: (context, provider, child) {
                        if (provider.isLoading) {
                          return const Center(child: Padding(
                            padding: EdgeInsets.all(50.0),
                            child: CircularProgressIndicator(),
                          ));
                        }

                        if (provider.error != null) {
                          return Center(
                            child: Column(
                              children: [
                                const Icon(Icons.error_outline, size: 40, color: Colors.red),
                                const SizedBox(height: 10),
                                Text("Erreur: ${provider.error}", textAlign: TextAlign.center),
                                TextButton(
                                  onPressed: provider.fetchCompanies,
                                  child: const Text("Réessayer"),
                                )
                              ],
                            ),
                          );
                        }

                        // Données chargées
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Nos Compagnies",
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Text(
                              "${provider.companies.length} partenaires de confiance",
                              style: TextStyle(color: secondaryTextColor, fontSize: 13),
                            ),
                            const Gap(20),

                            // --- 3. LISTE DES COMPAGNIES DYNAMIQUE ---
                            if (provider.companies.isEmpty)
                              const Center(child: Text("Aucune compagnie disponible."))
                            else
                              ListView.separated(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true, // Important dans un SingleChildScrollView
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: provider.companies.length,
                                separatorBuilder: (ctx, index) => const Gap(15),
                                itemBuilder: (ctx, index) {
                                  final company = provider.companies[index];
                                  return _buildCompanyCard(context, company);
                                },
                              ),

                            const Gap(140),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS ---

  Widget _buildHeader(BuildContext context) {
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
          image: AssetImage("assets/images/busheader5.jpg"),
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
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
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


  Widget _buildCompanyCard(BuildContext context, CompanyModel company) {
    // --- 1. VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = isDark ? Colors.grey[400] : Colors.grey;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;

    // Couleur par défaut (tu peux la rendre dynamique selon le tag si tu veux)
    final companyColor = Colors.blueAccent;

    // --- 2. LOGIQUE DE L'IMAGE (Intégrée ici) ---
    // Ton URL de base (Backend)
    const String baseUrl = "https://jingly-lindy-unminding.ngrok-free.dev/";

    String? fullLogoUrl;

    if (company.logoUrl.isNotEmpty) {
      if (company.logoUrl.startsWith('http')) {
        // Si c'est déjà une URL complète
        fullLogoUrl = company.logoUrl;
      } else {
        // Sinon, on construit l'URL complète
        // On enlève le '/' au début s'il y est pour éviter les doubles slashs
        String cleanPath = company.logoUrl.startsWith('/')
            ? company.logoUrl.substring(1)
            : company.logoUrl;

        fullLogoUrl = "$baseUrl$cleanPath";
      }
    }

    // --- 3. RENDU VISUEL ---
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 10,
              offset: const Offset(0, 4)
          )
        ],
      ),
      child: Column(
        children: [
          // --- HEADER : LOGO + NOM ---
          Row(
            children: [
              // LE CONTAINER LOGO ADAPTÉ
              Container(
                height: 50, width: 50,
                decoration: BoxDecoration(
                  color: companyColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  image: fullLogoUrl != null
                      ? DecorationImage(
                    image: NetworkImage(fullLogoUrl!), // On utilise l'URL calculée
                    fit: BoxFit.cover,
                    onError: (exception, stackTrace) {
                      debugPrint("Erreur image liste: $exception");
                    },
                  )
                      : null,
                ),
                alignment: Alignment.center,
                // Si pas d'image valide, on affiche le sigle ou la première lettre
                child: fullLogoUrl == null
                    ? Text(
                    company.sigle.isNotEmpty ? company.sigle : company.name[0],
                    style: TextStyle(color: companyColor, fontWeight: FontWeight.bold, fontSize: 18)
                )
                    : null,
              ),

              const Gap(12),

              // TEXTES (Nom + Slogan)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(company.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    if (company.slogan.isNotEmpty)
                      Text(company.slogan, style: TextStyle(color: subTextColor, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              )
            ],
          ),
          const Gap(10),

          // --- ETOILES ET AVIS ---
          Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  if (index < company.rating.round()) {
                    return const Icon(Icons.star, color: Colors.amber, size: 16);
                  } else {
                    return const Icon(Icons.star_border, color: Colors.amber, size: 16);
                  }
                }),
              ),
              const Gap(8),
              RichText(
                text: TextSpan(
                  style: TextStyle(color: textColor, fontSize: 12),
                  children: [
                    TextSpan(text: "${company.rating}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: " (${company.reviewsCount} avis)", style: TextStyle(color: subTextColor)),
                  ],
                ),
              )
            ],
          ),
          const Gap(15),

          // --- STATISTIQUES ---
          Row(
            children: [
              Expanded(child: _buildStatItem(context, "${company.stats.personnels}", "Personnels")),
              const Gap(10),
              Expanded(child: _buildStatItem(context, "${company.stats.vehicules}", "Cars")),
              const Gap(10),
              Expanded(child: _buildStatItem(context, "${company.stats.programmes}", "Trajets")),
            ],
          ),
          const Gap(15),

          // --- TAGS (Optionnel) ---
          if (company.tags.isNotEmpty)
            SizedBox(
              height: 25,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: company.tags.length,
                separatorBuilder: (ctx, i) => const Gap(8),
                itemBuilder: (ctx, i) {
                  return _buildTag(context, company.tags[i].label, company.tags[i].color);
                },
              ),
            ),

          if (company.tags.isNotEmpty) const Gap(15),

          // --- BOUTON ACTION ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CompanyDetailScreen(
                      companyId: company.id,
                      companyName: company.name,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                foregroundColor: isDark ? Colors.white : Colors.black,
                elevation: 0,
                side: BorderSide(color: borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text("Voir les trajets", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String value, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey[400] : Colors.black54)),
          const Gap(2),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
        ],
      ),
    );
  }

  Widget _buildTag(BuildContext context, String text, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: isDark ? color.withOpacity(0.15) : color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(5)
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}