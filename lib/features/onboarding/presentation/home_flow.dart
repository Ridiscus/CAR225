import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
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
      baseUrl: 'https://car225.com/api/', // L'URL centrale
      headers: {'Content-Type': 'application/json'},
    ));

    // Injection de dépendance manuelle
    final dataSource = BookingRemoteDataSourceImpl(dio: dio);
    _bookingRepository = BookingRepositoryImpl(remoteDataSource: dataSource);

    _loadCities();
  }



// --- FONCTION UTILITAIRE POUR LA POSITION GPS ---
  Future<Position?> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Vérifier si le service de localisation est activé.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Les services de localisation ne sont pas activés, on ne peut pas continuer.
      return null;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Les permissions sont refusées
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Les permissions sont refusées de façon permanente
      return null;
    }

    // Quand on arrive ici, les permissions sont accordées et on peut récupérer la position.
    return await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
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

            // --- NOUVEAU : 2.5 BANNIÈRE SIGNALEMENT URGENCE ---
            Transform.translate(
              offset: const Offset(0, -50), // Aligné avec le décalage actuel
              child: _buildEmergencyBanner(context, isDark),
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


  // ===========================================================================
  // 🚨 UI : BANNIÈRE DE SIGNALEMENT D'ACCIDENT
  // ===========================================================================
  Widget _buildEmergencyBanner(BuildContext context, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A1C1C) : const Color(0xFFFFF0F0),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => _showAccidentReportModal(context),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icône d'alerte
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 28),
                ),
                const Gap(15),
                // Textes
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Témoin d'un accident ?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isDark ? Colors.white : Colors.red[900],
                        ),
                      ),
                      const Gap(4),
                      Text(
                        "Alertez les secours rapidement, même sans compte.",
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.red[200] : Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Flèche
                const Icon(Icons.arrow_forward_ios, color: Colors.redAccent, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

// ===========================================================================
// 🚨 LOGIQUE : MODALE ET APPEL API SIGNALEMENT
// ===========================================================================
  // ===========================================================================
// 🚨 LOGIQUE : MODALE ET APPEL API SIGNALEMENT (AVEC PHOTO)
// ===========================================================================
  void _showAccidentReportModal(BuildContext context) {
    final TextEditingController descController = TextEditingController();
    bool isSubmitting = false;
    File? selectedPhoto; // 📸 Stockera la photo sélectionnée
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        builder: (ctx) {
          return StatefulBuilder(
              builder: (context, setStateModal) {

                // --- FONCTION POUR CHOISIR LA PHOTO ---
                Future<void> _pickImage(ImageSource source) async {
                  try {
                    final XFile? pickedFile = await picker.pickImage(
                      source: source,
                      imageQuality: 70, // Compresse légèrement l'image
                    );
                    if (pickedFile != null) {
                      setStateModal(() {
                        selectedPhoto = File(pickedFile.path);
                      });
                    }
                  } catch (e) {
                    _showTopNotification(context, "❌ Erreur lors de la sélection de l'image.");
                  }
                }

                // --- MODALE DE CHOIX (CAMERA / GALERIE) ---
                void _showImageSourceOptions() {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (context) => SafeArea(
                      child: Wrap(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                            title: const Text('Prendre une photo'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                          ),
                          ListTile(
                            leading: const Icon(Icons.photo_library, color: AppColors.primary),
                            title: const Text('Choisir depuis la galerie'),
                            onTap: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return Padding(
                  // 1. Gère l'espace pris par le clavier
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: SafeArea( // 🟢 NOUVEAU : Protège contre la barre de navigation système
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 20, right: 20, top: 20, bottom: 10, // 🟢 Marge interne basique
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                      // --- HEADER MODALE ---
                      Row(
                        children: [
                          const Icon(Icons.emergency_share, color: Colors.redAccent, size: 28),
                          const Gap(10),
                          const Expanded(
                            child: Text("Signaler une urgence", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () => Navigator.pop(context),
                          )
                        ],
                      ),
                      const Gap(15),

                      // --- CHAMP TEXTE ---
                      const Text("Décrivez la situation (gravité, lieu, véhicules) :", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                      const Gap(10),
                      TextField(
                        controller: descController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: "Ex: Accident grave au niveau du péage...",
                          filled: true,
                          fillColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : Colors.grey[100],
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.redAccent)),
                        ),
                      ),
                      const Gap(15),

                      // --- APERÇU DE LA PHOTO (Si sélectionnée) ---
                      if (selectedPhoto != null) ...[
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                selectedPhoto!,
                                height: 100,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 5, right: 5,
                              child: InkWell(
                                onTap: () => setStateModal(() => selectedPhoto = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                                ),
                              ),
                            )
                          ],
                        ),
                        const Gap(15),
                      ],

                      // --- BOUTONS PIÈCES JOINTES ---
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _showImageSourceOptions, // 📸 Action activée
                              icon: Icon(selectedPhoto == null ? Icons.camera_alt : Icons.check_circle, size: 18, color: selectedPhoto == null ? Colors.grey[700] : Colors.green),
                              label: Text(selectedPhoto == null ? "Photo" : "Photo ajoutée", style: TextStyle(fontSize: 13, color: selectedPhoto == null ? Colors.grey[700] : Colors.green)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: selectedPhoto == null ? Colors.grey.shade300 : Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                          const Gap(10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                _showTopNotification(context, "📍 Localisation automatique activée lors de l'envoi.");
                              },
                              icon: const Icon(Icons.location_on, size: 18, color: Colors.blueAccent),
                              label: const Text("Position", style: TextStyle(fontSize: 13, color: Colors.blueAccent)),
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: Colors.blueAccent.withOpacity(0.5)),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(20),

                      // --- BOUTON DE SOUMISSION API ---
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isSubmitting ? null : () async {
                            if (descController.text.trim().isEmpty) {
                              _showTopNotification(context, "⚠️ Veuillez décrire l'accident.");
                              return;
                            }

                            setStateModal(() => isSubmitting = true);

                            try {
                              // 1. Récupération de la position GPS
                              Position? position = await _determinePosition();

                              // 2. Préparation des données textuelles
                              Map<String, dynamic> dataMap = {
                                "type": "accident",
                                "description": descController.text.trim(),
                                "latitude": position?.latitude,
                                "longitude": position?.longitude,
                              };

                              // 3. Préparation du FormData (avec la photo si elle existe)
                              FormData formData = FormData.fromMap(dataMap);

                              if (selectedPhoto != null) {
                                formData.files.add(MapEntry(
                                  "photo", // ⚠️ Vérifie que ton API attend bien ce nom (ex: "photo" ou "image")
                                  await MultipartFile.fromFile(selectedPhoto!.path, filename: "accident_photo.jpg"),
                                ));
                              }

                              // 4. Appel API
                              final dio = Dio(BaseOptions(baseUrl: 'https://car225.com/api/'));
                              final response = await dio.post('public/signalement-accident', data: formData);

                              if (mounted) Navigator.pop(context); // Fermer la modale

                              // Succès stylé
                              _showTopNotification(context, "✅ Signalement envoyé aux secours. Merci de votre aide !");

                            } catch (e) {
                              setStateModal(() => isSubmitting = false);
                              _showTopNotification(context, "❌ Erreur de réseau. Veuillez réessayer.");
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: isSubmitting
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text("Envoyer l'alerte", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const Gap(20),
                    ],
                  ),
                ),
                    ),
                );
              }
          );
        }
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