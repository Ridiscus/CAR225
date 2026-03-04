import 'package:car225/features/home/presentation/screens/profil_screen.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart' hide Provider;
import 'package:provider/provider.dart';
// Imports Clean Architecture
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/presentation/screens/all_itineraire_screen.dart';
import '../../../booking/presentation/screens/search_results_screen.dart';
import 'notification_screen.dart';

class HomeTabScreen extends StatefulWidget {
  final bool isModificationMode;
  final String? initialDepart;
  final String? initialArrivee;
  final DateTime? initialDate;
  final bool ticketWasAllerRetour;

  const HomeTabScreen({
    super.key,
    this.isModificationMode = false,
    this.initialDepart,
    this.initialArrivee,
    this.initialDate,
    this.ticketWasAllerRetour = false,
  });

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  // Variables d'état
  String? departureCity;
  String? arrivalCity;
  DateTime? departureDate;
  bool isRoundTrip = false;

  // Données factices pour les itinéraires (limité aux 3 récents)
  final List<Map<String, dynamic>> _recentItineraries = [
    {
      "company": "Maless Travel",
      "color": const Color(0xFFA855F7),
      "price": "15 000 F",
      "type": "Standard",
      "rating": "4.7",
      "route": "Korhogo ➝ Abidjan",
    },
    {
      "company": "UTB",
      "color": const Color(0xFFCA8A04),
      "price": "15 000 F",
      "type": "Express",
      "rating": "4.8",
      "route": "Bouaké ➝ Abidjan",
    },
    {
      "company": "Fabiola",
      "color": const Color(0xFF15803D),
      "price": "12 000 F",
      "type": "Standard",
      "rating": "4.5",
      "route": "Man ➝ Abidjan",
    },
  ];

  @override
  void initState() {
    super.initState();
    departureCity = widget.initialDepart;
    arrivalCity = widget.initialArrivee;
    departureDate = widget.initialDate;
    isRoundTrip = widget.ticketWasAllerRetour;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.user == null) {
        userProvider.loadUser();
      }
    });
  }

  // Action pour le bouton de la bannière
  void _goToBooking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchResultsScreen()),
    );
  }

  void _goToAllItineraries(BuildContext context) {
    // Navigation vers la page voir tout
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AllItinerariesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    // 4. ECOUTE DU PROVIDER (La magie opère ici)
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user; // On récupère l'objet User

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. HEADER MODIFIÉ ---
            _buildHeader(context, currentUser?.photoUrl),

            // --- 2. CARTE DE RECHERCHE ---
            Transform.translate(
              offset: const Offset(0, -80),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _buildSearchCard(context),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Itinéraire de la semaine",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        TextButton(
                          onPressed: () => _goToAllItineraries(context),
                          child: const Text(
                            "Voir tout",
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Gap(10),
                  SizedBox(
                    height: 240,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: _recentItineraries.length,
                      separatorBuilder: (context, index) => const Gap(15),
                      itemBuilder: (context, index) {
                        final item = _recentItineraries[index];
                        return SizedBox(
                          width: 200,
                          child: _buildCompanyCard(
                            context,
                            companyName: item['company'],
                            color: item['color'],
                            price: item['price'],
                            type: item['type'],
                            rating: item['rating'],
                            route: item['route'],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 20,
                ),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF263238)
                      : const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  children: [
                    const Text(
                      "Prêt à réserver ?",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const Text(
                      "Trouvez votre voyage parfait.",
                      style: TextStyle(color: AppColors.grey),
                    ),
                    const Gap(15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _goToBooking(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "Réserver maintenant",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(120),
          ],
        ),
      ),
    );
  }

  // MODIFICATION ICI : On accepte l'URL photo en paramètre
  Widget _buildHeader(BuildContext context, String? photoUrl) {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage("assets/images/bus_header.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.6), Colors.transparent],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    // --- 1. PROFIL DYNAMIQUE ---nnn
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ProfileScreen(),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl) as ImageProvider
                            : const AssetImage("assets/images/ci.jpg"),
                      ),
                    ),
                    const Gap(10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Ma localisation",
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        Row(
                          children: [
                            Image.asset(
                              "assets/icons/pin.png",
                              width: 14,
                              height: 14,
                              color: AppColors.primary,
                            ),
                            const Gap(4),
                            const Text(
                              "Abidjan",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                // --- NOTIFICATION ---
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationScreen(),
                    ),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "assets/icons/notification.png",
                      width: 20,
                      height: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ou souhaitez-vous voyager ?",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Text(
            "Réservez votre billet en quelques clics",
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Gap(20),

          Row(
            children: [
              Expanded(
                child: _buildDropdownField(
                  context,
                  "Départ",
                  departureCity ?? "Sélectionner",
                  "assets/images/map.png",
                ),
              ),
              const Gap(10),
              Expanded(
                child: _buildDropdownField(
                  context,
                  "Destination",
                  arrivalCity ?? "Sélectionner",
                  "assets/images/map.png",
                  isGreen: true,
                ),
              ),
            ],
          ),
          const Gap(15),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 3, child: _buildDateField(context)),
              const Gap(15),

              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: Checkbox(
                            value: isRoundTrip,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (v) => setState(() => isRoundTrip = v!),
                          ),
                        ),
                        const Gap(5),
                        const Expanded(
                          child: Text(
                            "Aller-retour",
                            style: TextStyle(fontSize: 13, height: 1.2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(20),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _goToBooking(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Rechercher des trajets",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyCard(
    BuildContext context, {
    required String companyName,
    required Color color,
    required String price,
    required String type,
    required String rating,
    required String route,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.1);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 100,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.star,
                            color: Colors.orange,
                            size: 10,
                          ),
                          const Gap(2),
                          Text(
                            rating,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.directions_bus, color: Colors.white, size: 30),
                Text(
                  companyName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        companyName,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        route,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Gap(5),
                      Row(
                        children: const [
                          Icon(Icons.wifi, size: 14, color: AppColors.primary),
                          Gap(5),
                          Icon(Icons.flash_on, size: 14, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 10),
                      const Text(
                        "15 places",
                        style: TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(
    BuildContext context,
    String label,
    String hint,
    String imagePath, {
    bool isGreen = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final imageColor = isGreen ? AppColors.secondary : AppColors.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const Gap(5),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent,
          ),
          child: Row(
            children: [
              Image.asset(
                imagePath,
                width: 20,
                height: 20,
                color: imageColor,
                fit: BoxFit.contain,
              ),

              const Gap(10),

              Expanded(
                child: Text(
                  hint,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const Icon(
                Icons.keyboard_arrow_down,
                color: Colors.grey,
                size: 18,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    String dateText = "Sélectionner";
    if (departureDate != null) {
      dateText =
          "${departureDate!.day.toString().padLeft(2, '0')}/${departureDate!.month.toString().padLeft(2, '0')}/${departureDate!.year}";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Date de départ",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const Gap(5),
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.grey, size: 18),
              const Gap(10),
              Expanded(
                child: Text(
                  dateText,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
