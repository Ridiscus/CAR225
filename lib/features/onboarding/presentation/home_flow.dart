/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

// Tes imports (Assure-toi que AppColors.primary est une couleur qui passe bien sur le noir, comme un vert ou bleu vif)
import '../../../../core/theme/app_colors.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../booking/presentation/screens/search_results_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Variables
  String depart = "Abidjan";
  String destination = "Bouaké";
  bool isAllerRetour = false;


    @override
    Widget build(BuildContext context) {
      // -----------------------------------------------------------
      // 🌗 LOGIQUE DARK MODE / LIGHT MODE
      // -----------------------------------------------------------
      final isDark = Theme.of(context).brightness == Brightness.dark;

      // Couleurs dynamiques
      final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

      final mainTextColor = isDark ? Colors.white : Colors.black;

      // CORRECTION ICI : Ajout du '!' après [400]
      final subTextColor = isDark ? Colors.grey[400]! : AppColors.grey;

      // CORRECTION ICI : Ajout du '!' après [700]
      final borderColor = isDark ? Colors.grey[700]! : Colors.grey.shade300;

      // CORRECTION ICI : Ajout du '!' après [800]
      final circleBtnColor = isDark ? Colors.grey[800]! : Colors.white;
      // -----------------------------------------------------------


    return Scaffold(
      // MODIFICATION : On utilise la couleur du thème (défini dans ton main.dart)
      // Si ton main.dart est bien configuré, ça sera noir/gris foncé auto.
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. LE HEADER (IMAGE + BOUTONS) ---
            Stack(
              children: [
                // Image de fond
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black, // Le fond derrière l'image reste noir, c'est mieux pour l'image
                    image: DecorationImage(
                      image: AssetImage("assets/images/bus_header.jpg"),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    ),
                  ),
                ),
                // Boutons du haut
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // PROFIL -> Login
                        _buildCircleBtn(
                            "assets/images/user.png",
                                () => _goToLogin(context),
                            circleBtnColor // On passe la couleur dynamique
                        ),

                        // TICKET -> SearchResultsScreen
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchResultsScreen(
                                  isGuestMode: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 40, width: 40,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: circleBtnColor, // Couleur dynamique
                                shape: BoxShape.circle
                            ),
                            child: Image.asset(
                              "assets/images/paper.png",
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- 2. LA CARTE DE RECHERCHE ---
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor, // <--- APPLICATION DE LA COULEUR DYNAMIQUE
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1), // Ombre plus forte en dark pour le contraste
                          blurRadius: 10,
                          offset: const Offset(0, 5)
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Où souhaitez-vous voyager ?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainTextColor)), // Couleur texte dynamique

                      Text("Réservez votre billet en quelques clics",
                          style: TextStyle(color: subTextColor, fontSize: 12)), // Couleur sous-titre dynamique

                      const Gap(20),

                      // Champs Départ / Arrivée
                      Row(
                        children: [
                          Expanded(
                              child: _buildInputBox(
                                  "assets/images/map.png", "Départ", "Abidjan",
                                  mainTextColor, subTextColor, borderColor) // On passe les couleurs
                          ),
                          const Gap(10),
                          Expanded(
                              child: _buildInputBox(
                                  "assets/images/map.png", "Arrivée", "Yamoussoukro",
                                  mainTextColor, subTextColor, borderColor, isGreen: true)
                          ),
                        ],
                      ),
                      const Gap(15),

                      // Date + Checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: _buildInputBox(
                                "assets/images/agenda.png", "Date départ", "Ven. 30 Jan",
                                mainTextColor, subTextColor, borderColor),
                          ),

                          const Gap(10),

                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isAllerRetour,
                                activeColor: AppColors.primary,
                                // En dark mode, le checkColor (la coche) est blanc par défaut, c'est ok.
                                side: BorderSide(color: isDark ? Colors.grey : Colors.black54), // Bordure checkbox visible en dark
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                onChanged: (bool? value) {
                                  setState(() {
                                    isAllerRetour = value ?? false;
                                  });
                                },
                              ),
                              const Gap(4),
                              Text("Aller-retour",
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: mainTextColor)),
                            ],
                          ),
                        ],
                      ),

                      const Gap(20),

                      // BOUTON RECHERCHER
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchResultsScreen(
                                  isGuestMode: true,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Rechercher des trajets", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // --- 3. BANNIÈRE PRÊT À RÉSERVER ---
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // En dark mode, 0xFF37474F est déjà sombre, mais on peut le garder
                  // ou le rendre un tout petit peu plus clair que le fond noir pour ressortir.
                  // Ici je le garde tel quel car c'est une couleur "Identité" gris/bleuté qui marche sur le noir.
                  color: const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(15),
                  border: isDark ? Border.all(color: Colors.grey[800]!) : null, // Petite bordure subtile en dark mode
                ),
                child: Column(
                  children: [
                    const Text("Prêt à réserver ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("Trouvez votre voyage parfait.", style: TextStyle(color: Colors.white70)), // AppColors.grey risque d'être trop sombre ici
                    const Gap(15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _goToLogin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                        ),
                        child: const Text("Réserver maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const Gap(20),
          ],
        ),
      ),
    );
  }

  // Helper : Bouton Rond Header (Modifié pour accepter la couleur)
  Widget _buildCircleBtn(String imagePath, VoidCallback onTap, Color bgColor) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        height: 40, width: 40,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Image.asset(
          imagePath,
          color: AppColors.primary,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  // Helper : Champ de saisie (Modifié pour accepter les couleurs dynamiques)
  Widget _buildInputBox(
      String imagePath,
      String label,
      String value,
      Color textColor,
      Color labelColor,
      Color borderColor,
      {bool isGreen = false}) {

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor), // Bordure dynamique
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 20,
            height: 20,
            color: isGreen ? AppColors.secondary : AppColors.primary,
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: labelColor)), // Label dynamique
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)), // Valeur dynamique
            ],
          )
        ],
      ),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
}*/





/*import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart'; // Pour le formatage date

import '../../../../core/theme/app_colors.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../booking/presentation/screens/search_results_screen.dart';

// Imports de TA Clean Architecture
import '../../booking/data/datasources/booking_remote_data_source.dart';
import '../../booking/domain/repositories/booking_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ETAT ---
  String? villeDepart;
  String? villeArrivee;
  DateTime? dateDepart; // Changé en DateTime pour manipuler logicement
  bool isAllerRetour = false;

  // Liste chargée depuis l'API
  List<String> villesDisponibles = [];
  bool isLoadingCities = true;

  late BookingRepositoryImpl _bookingRepository;

  @override
  void initState() {
    super.initState();

    // Initialisation "Manuelle" du repo (Idéalement via GetIt/Provider)
    final dio = Dio(BaseOptions(baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/'));
    _bookingRepository = BookingRepositoryImpl(remoteDataSource: BookingRemoteDataSourceImpl(dio: dio));

    // Charger les villes
    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _bookingRepository.getCities();
    setState(() {
      villesDisponibles = cities;
      isLoadingCities = false;
      // Valeurs par défaut si dispo
      if (cities.isNotEmpty) {
        villeDepart = cities.first;
        if (cities.length > 1) villeArrivee = cities[1];
      }
    });
  }

  // --- LOGIQUE DATE PICKER (Griser dates passées) ---
  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateDepart ?? now,
      firstDate: now, // ⚠️ EMPÊCHE DE CHOISIR AVANT AUJOURD'HUI
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dateDepart = picked;
      });
    }
  }

  // --- NAVIGATION VERS SEARCH ---
  void _onSearchPressed() {
    if (villeDepart == null || villeArrivee == null || dateDepart == null) {
      // Petite alerte si champs vides
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez remplir tous les champs")));
      return;
    }

    // Formatage date pour l'API (yyyy-MM-dd)
    String dateApi = DateFormat('yyyy-MM-dd').format(dateDepart!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          isGuestMode: true,
          // On passe les paramètres de recherche
          searchParams: {
            "depart": villeDepart,
            "arrivee": villeArrivee,
            "date": dateApi,
            "isAllerRetour": isAllerRetour
          },
        ),
      ),
    );
  }

  // --- UI ---
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final mainTextColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400]! : AppColors.grey;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey.shade300;

    // Formatage affichage date
    String dateDisplay = dateDepart != null
        ? DateFormat('EEE d MMM', 'fr_FR').format(dateDepart!)
        : "Choisir date";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [

            // --- 1. LE HEADER (IMAGE + BOUTONS) ---
            Stack(
              children: [
                // Image de fond
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black, // Le fond derrière l'image reste noir, c'est mieux pour l'image
                    image: DecorationImage(
                      image: AssetImage("assets/images/bus_header.jpg"),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    ),
                  ),
                ),
                // Boutons du haut
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // PROFIL -> Login
                        _buildCircleBtn(
                            "assets/images/user.png",
                                () => _goToLogin(context),
                            circleBtnColor // On passe la couleur dynamique
                        ),

                        // TICKET -> SearchResultsScreen
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SearchResultsScreen(
                                  isGuestMode: true,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            height: 40, width: 40,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: circleBtnColor, // Couleur dynamique
                                shape: BoxShape.circle
                            ),
                            child: Image.asset(
                              "assets/images/paper.png",
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),


            // --- CARTE DE RECHERCHE ---
            Transform.translate(
              offset: const Offset(0, -40),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 10, offset: const Offset(0, 5)
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Où souhaitez-vous voyager ?", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainTextColor)),
                      Text("Réservez votre billet en quelques clics", style: TextStyle(color: subTextColor, fontSize: 12)),
                      const Gap(20),

                      // INPUTS VILLES (Dropdown ou Modal)
                      isLoadingCities
                          ? const Center(child: CircularProgressIndicator())
                          : Row(
                        children: [
                          Expanded(
                              child: _buildCitySelector(
                                  label: "Départ",
                                  value: villeDepart,
                                  items: villesDisponibles,
                                  onChanged: (val) => setState(() => villeDepart = val),
                                  textColor: mainTextColor,
                                  subTextColor: subTextColor,
                                  borderColor: borderColor
                              )
                          ),
                          const Gap(10),
                          Expanded(
                              child: _buildCitySelector(
                                  label: "Arrivée",
                                  value: villeArrivee,
                                  items: villesDisponibles,
                                  onChanged: (val) => setState(() => villeArrivee = val),
                                  textColor: mainTextColor,
                                  subTextColor: subTextColor,
                                  borderColor: borderColor,
                                  isGreen: true
                              )
                          ),
                        ],
                      ),
                      const Gap(15),

                      // DATE + CHECKBOX
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: _buildInputBoxUI(
                                  "assets/images/agenda.png", "Date départ", dateDisplay,
                                  mainTextColor, subTextColor, borderColor
                              ),
                            ),
                          ),
                          const Gap(10),
                          Row(
                            children: [
                              Checkbox(
                                value: isAllerRetour,
                                activeColor: AppColors.primary,
                                side: BorderSide(color: isDark ? Colors.grey : Colors.black54),
                                onChanged: (v) => setState(() => isAllerRetour = v ?? false),
                              ),
                              Text("Aller-retour", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mainTextColor)),
                            ],
                          )
                        ],
                      ),
                      const Gap(20),

                      // BOUTON RECHERCHER
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _onSearchPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Rechercher des trajets", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),


            // --- 3. BANNIÈRE PRÊT À RÉSERVER ---
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  // En dark mode, 0xFF37474F est déjà sombre, mais on peut le garder
                  // ou le rendre un tout petit peu plus clair que le fond noir pour ressortir.
                  // Ici je le garde tel quel car c'est une couleur "Identité" gris/bleuté qui marche sur le noir.
                  color: const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(15),
                  border: isDark ? Border.all(color: Colors.grey[800]!) : null, // Petite bordure subtile en dark mode
                ),
                child: Column(
                  children: [
                    const Text("Prêt à réserver ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("Trouvez votre voyage parfait.", style: TextStyle(color: Colors.white70)), // AppColors.grey risque d'être trop sombre ici
                    const Gap(15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _goToLogin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                        ),
                        child: const Text("Réserver maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),

            const Gap(20),

          ],
        ),
      ),
    );
  }

  // Widget Sélecteur de ville simplifié (Dropdown)
  Widget _buildCitySelector({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required Color textColor, required Color subTextColor, required Color borderColor,
    bool isGreen = false
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: subTextColor)),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down, color: isGreen ? AppColors.secondary : AppColors.primary),
              dropdownColor: Theme.of(context).cardColor,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor),
              items: items.map((String ville) {
                return DropdownMenuItem<String>(
                  value: ville,
                  child: Text(ville),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  // Widget UI simple pour la Date (reprend ton style)
  Widget _buildInputBoxUI(String icon, String label, String value, Color textColor, Color subColor, Color borderColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 20,
            height: 20,
            color: isGreen ? AppColors.secondary : AppColors.primary,
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: labelColor)), // Label dynamique
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)), // Valeur dynamique
            ],
          )
        ],
      ),
    );
  }







  // Helper : Bouton Rond Header (Modifié pour accepter la couleur)
  Widget _buildCircleBtn(String imagePath, VoidCallback onTap, Color bgColor) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        height: 40, width: 40,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Image.asset(
          imagePath,
          color: AppColors.primary,
          fit: BoxFit.contain,
        ),
      ),
    );
  }




  void _goToLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
}*/










import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../auth/presentation/screens/login_screen.dart';
import '../../booking/presentation/screens/search_results_screen.dart';

// Imports Clean Architecture
import '../../booking/data/datasources/booking_remote_data_source.dart';
import '../../booking/domain/repositories/booking_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- ETAT ---
  String? villeDepart;
  String? villeArrivee;
  DateTime? dateDepart;
  bool isAllerRetour = false;

  List<String> villesDisponibles = [];
  bool isLoadingCities = true;

  late BookingRepositoryImpl _bookingRepository;

  @override
  void initState() {
    super.initState();
    _setupDependenciesAndLoad();
  }

  void _setupDependenciesAndLoad() {
    // ⚠️ IMPORTANT : Ici, idéalement, tu récupères ton instance Dio globale (via GetIt ou Provider).
    // Pour l'instant, je crée une instance qui pointe vers ta BaseUrl unique pour respecter ta logique,
    // mais sans la redéfinir partout dans le code métier.

    final dio = Dio(BaseOptions(
      baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/', // L'URL centrale
      headers: {'Content-Type': 'application/json'},
    ));

    // Injection de dépendance manuelle
    final dataSource = BookingRemoteDataSourceImpl(dio: dio);
    _bookingRepository = BookingRepositoryImpl(remoteDataSource: dataSource);

    _loadCities();
  }

  Future<void> _loadCities() async {
    final cities = await _bookingRepository.getCities();
    if (mounted) {
      setState(() {
        villesDisponibles = cities;
        isLoadingCities = false;
        // Valeurs par défaut intelligentes
        if (cities.isNotEmpty) {
          villeDepart = cities.contains("Abidjan") ? "Abidjan" : cities.first;
          // Si possible, mettre une ville d'arrivée différente
          if (cities.length > 1) {
            villeArrivee = cities.first == villeDepart ? cities[1] : cities.first;
          }
        }
      });
    }
  }

  // --- LOGIQUE DATE ---
  Future<void> _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: dateDepart ?? now,
      firstDate: now, // Bloque les dates passées
      lastDate: DateTime(now.year + 1),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        dateDepart = picked;
      });
    }
  }



  // --- NAVIGATION ---
  void _onSearchPressed() {
    // Validation : On vérifie si les champs sont vides
    if (villeDepart == null || villeArrivee == null || dateDepart == null) {
      // APPEL DE LA NOUVELLE NOTIFICATION STYLÉE
      _showTopNotification(context, "Veuillez remplir tous les champs ⚠️");
      return; // On arrête l'exécution ici
    }

    // Formatage date API (yyyy-MM-dd)
    String dateApi = DateFormat('yyyy-MM-dd').format(dateDepart!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          isGuestMode: true,
          searchParams: {
            "depart": villeDepart,
            "arrivee": villeArrivee,
            "date": dateApi,
            "isAllerRetour": isAllerRetour
          },
        ),
      ),
    );
  }



  // --- NAVIGATION ---
  /*void _onSearchPressed() {
    if (villeDepart == null || villeArrivee == null || dateDepart == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Veuillez remplir tous les champs"),
            backgroundColor: Colors.red,
          )
      );
      return;
    }

    // Formatage date API (yyyy-MM-dd)
    String dateApi = DateFormat('yyyy-MM-dd').format(dateDepart!);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          isGuestMode: true,
          searchParams: {
            "depart": villeDepart,
            "arrivee": villeArrivee,
            "date": dateApi,
            "isAllerRetour": isAllerRetour
          },
        ),
      ),
    );
  }*/




  // --- WIDGET NOTIFICATION TOP (Custom Toast) ---
  void _showTopNotification(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, // Position sous la barre de statut
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF222222), // Fond sombre élégant
              borderRadius: BorderRadius.circular(30), // Bords très arrondis
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône d'erreur rouge/orange pour attirer l'attention
                const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                    ),
                    textAlign: TextAlign.start,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Afficher l'overlay
    overlay.insert(overlayEntry);

    // Le retirer après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }






  @override
  Widget build(BuildContext context) {
    // Thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final mainTextColor = isDark ? Colors.white : Colors.black;
    final subTextColor = isDark ? Colors.grey[400]! : AppColors.grey;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey.shade300;
    final circleBtnColor = isDark ? Colors.grey[800]! : Colors.white;

    // Affichage Date
    String dateDisplay = dateDepart != null
        ? DateFormat('EEE d MMM', 'fr_FR').format(dateDepart!)
        : "Choisir date";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. HEADER ---
            Stack(
              children: [
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    image: DecorationImage(
                      image: AssetImage("assets/images/bus_header.jpg"),
                      fit: BoxFit.cover,
                      opacity: 0.8,
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildCircleBtn(
                            "assets/images/user.png",
                                () => _goToLogin(context),
                            circleBtnColor
                        ),
                        _buildCircleBtn(
                            "assets/images/paper.png",
                                () {
                              // Accès direct aux résultats (sans recherche précise)
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => const SearchResultsScreen(isGuestMode: true)
                                  )
                              );
                            },
                            circleBtnColor
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // --- 2. CARTE DE RECHERCHE ---
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                          blurRadius: 10, offset: const Offset(0, 5)
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Où souhaitez-vous voyager ?",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: mainTextColor)),
                      Text("Réservez votre billet en quelques clics",
                          style: TextStyle(color: subTextColor, fontSize: 12)),
                      const Gap(20),

                      // SÉLECTEURS DE VILLES
                      isLoadingCities
                          ? const Center(child: Padding(
                        padding: EdgeInsets.all(10.0),
                        child: CircularProgressIndicator(),
                      ))
                          : Row(
                        children: [
                          Expanded(
                              child: _buildCitySelector(
                                assetPath: "assets/images/map.png", // Ajoute ton image ici
                                label: "Départ",
                                value: villeDepart, // Ta variable d'état
                                items: villesDisponibles,
                                onChanged: (val) {
                                  setState(() => villeDepart = val);
                                  // Réinitialiser l'arrivée si besoin ou autre logique
                                },
                                textColor: mainTextColor,
                                subTextColor: subTextColor,
                                borderColor: borderColor,
                                isGreen: false, // Icône flèche normale
                              )
                          ),
                          const Gap(10),
                          Expanded(
                              child: _buildCitySelector(
                                  assetPath: "assets/images/map.png",
                                  label: "Arrivée",
                                  value: villeArrivee,
                                  items: villesDisponibles,
                                  onChanged: (val) => setState(() => villeArrivee = val),
                                  textColor: mainTextColor,
                                  subTextColor: subTextColor,
                                  borderColor: borderColor,
                                  isGreen: true
                              )
                          ),
                        ],
                      ),
                      const Gap(15),

                      // DATE + CHECKBOX
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: _buildInputBoxUI(
                                  imagePath: "assets/images/agenda.png", // CORRIGÉ
                                  label: "Date départ",
                                  value: dateDisplay,
                                  textColor: mainTextColor,
                                  subTextColor: subTextColor, // CORRIGÉ (subColor -> subTextColor)
                                  borderColor: borderColor
                              ),
                            ),
                          ),
                          const Gap(10),
                          Row(
                            children: [
                              Checkbox(
                                value: isAllerRetour,
                                activeColor: AppColors.primary,
                                side: BorderSide(color: isDark ? Colors.grey : Colors.black54),
                                onChanged: (v) => setState(() => isAllerRetour = v ?? false),
                              ),
                              Text("Aller-retour",
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: mainTextColor)),
                            ],
                          )
                        ],
                      ),
                      const Gap(20),

                      // BOUTON RECHERCHER
                      SizedBox(
                        width: double.infinity, height: 50,
                        child: ElevatedButton(
                          onPressed: _onSearchPressed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text("Rechercher des trajets",
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // --- 3. BANNIÈRE PRÊT À RÉSERVER ---
            Transform.translate(
              offset: const Offset(0, -40),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF37474F),
                  borderRadius: BorderRadius.circular(15),
                  border: isDark ? Border.all(color: Colors.grey[800]!) : null,
                ),
                child: Column(
                  children: [
                    const Text("Prêt à réserver ?",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("Trouvez votre voyage parfait.",
                        style: TextStyle(color: Colors.white70)),
                    const Gap(15),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _goToLogin(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.secondary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Réserver maintenant",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const Gap(20),
          ],
        ),
      ),
    );
  }

  // --- WIDGETS HELPERS CORRIGÉS ---

  Widget _buildCitySelector({
    required String assetPath, // 1. NOUVEAU PARAMÈTRE
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    required Color textColor,
    required Color subTextColor,
    required Color borderColor,
    bool isGreen = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), // Un peu plus d'espace vertical
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12), // Arrondi un peu plus moderne
      ),
      child: Row( // 2. ON UTILISE UNE ROW POUR METTRE L'IMAGE À GAUCHE
        children: [
          // --- L'IMAGE ---
          Image.asset(
            assetPath,
            width: 24, // Taille de l'icone
            height: 24,
            // Si tu veux colorier l'icone selon le thème, décommente la ligne ci-dessous :
            color: isGreen ? AppColors.secondary : AppColors.primary,
          ),

          const SizedBox(width: 12), // Espacement entre l'image et le texte

          // --- LA COLONNE (Label + Dropdown) ---
          Expanded( // Important : Expanded permet au texte de prendre toute la place restante
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // Prend juste la place nécessaire
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: subTextColor)), // Police un peu plus grande (10 -> 12)

                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: items.contains(value) ? value : null,
                    isExpanded: true,
                    isDense: true, // Réduit la hauteur interne du dropdown pour mieux s'aligner
                    hint: Text("Choisir", style: TextStyle(color: subTextColor)),
                    icon: Icon(
                        Icons.keyboard_arrow_down,
                        color: isGreen ? Colors.green : Colors.grey // Utilise tes couleurs ici
                    ),
                    dropdownColor: Theme.of(context).cardColor,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: textColor
                    ),
                    items: items.map((String ville) {
                      return DropdownMenuItem<String>(
                        value: ville,
                        child: Text(ville),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBoxUI({
    required String imagePath, // J'ai renommé 'icon' en 'imagePath' pour correspondre à ton appel
    required String label,
    required String value,
    required Color textColor,
    required Color subTextColor, // Renommé 'subColor' pour cohérence
    required Color borderColor,
    bool isGreen = false, // Ajouté car tu l'utilises pour la couleur de l'icône
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Image.asset(
            imagePath,
            width: 20,
            height: 20,
            color: isGreen ? AppColors.secondary : AppColors.primary,
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 10, color: subTextColor)),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildCircleBtn(String imagePath, VoidCallback onTap, Color bgColor) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        height: 40, width: 40,
        decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
        child: Image.asset(
          imagePath,
          color: AppColors.primary,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  void _goToLogin(BuildContext context) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
}