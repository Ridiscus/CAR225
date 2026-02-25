import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

// ✅ Assure-toi que ces imports sont bons chez toi
import '../../../../common/widgets/BookingConfigurationSheet.dart';
import '../../../../common/widgets/cube_magic.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/screens/real_time_seat_info.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../data/models/program_model.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_summary_screen.dart'; // Import de ton écran de résumé

class AllItinerariesScreen extends StatefulWidget {
  const AllItinerariesScreen({super.key});

  @override
  State<AllItinerariesScreen> createState() => _AllItinerariesScreenState();
}

class _AllItinerariesScreenState extends State<AllItinerariesScreen> with SingleTickerProviderStateMixin {
  // --- ETAT DONNÉES ---
  List<ProgramModel> allItineraries = [];
  List<ProgramModel> filteredItineraries = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // 📅 NOUVEAU : Variable pour stocker la date choisie par l'utilisateur
  DateTime? _selectedDate;

  // ✅ CORRECTION : Une seule variable, bien nommée
  late BookingRepositoryImpl _repository;

  // --- ETAT INTERACTION ---
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  // 🟢 2. DECLARATION DU CONTROLLER D'ANIMATION
  late AnimationController _entranceController;


  @override
  void initState() {
    super.initState();

    // 🟢 3. INITIALISATION DE L'ANIMATION
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800), // La durée que tu as choisie
      vsync: this,
    );

    // Déclencher l'animation
    //_entranceController.forward();

    _initData();
  }


  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    // 🟢 4. NE PAS OUBLIER DE DISPOSE LE CONTROLLER
    _entranceController.dispose();
    super.dispose();
  }

  /*void _initData() async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://car225.com/api/',
      headers: {'Content-Type': 'application/json'},
    ));

    final dataSource = BookingRemoteDataSourceImpl(dio: dio);

    // ✅ CORRECTION : On initialise bien _repository ici
    _repository = BookingRepositoryImpl(remoteDataSource: dataSource);

    try {
      // On utilise _repository
      final trips = await _repository.getAllTrips();
      if (mounted) {
        setState(() {
          allItineraries = trips;
          filteredItineraries = trips;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }*/

  void _initData() async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://car225.com/api/',
      headers: {'Content-Type': 'application/json'},
    ));

    final dataSource = BookingRemoteDataSourceImpl(dio: dio);
    _repository = BookingRepositoryImpl(remoteDataSource: dataSource);

    try {
      final trips = await _repository.getAllTrips();
      if (mounted) {
        setState(() {
          allItineraries = trips;
          filteredItineraries = trips;
          isLoading = false;
        });

        // ✅ AJOUTE CETTE LIGNE ICI : on lance l'animation quand les données sont là
        _entranceController.forward(from: 0.0);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _filterTrips(String query) {
    final lowerQuery = query.toLowerCase();
    setState(() {
      filteredItineraries = allItineraries.where((trip) {
        return trip.compagnieName.toLowerCase().contains(lowerQuery) ||
            trip.villeDepart.toLowerCase().contains(lowerQuery) ||
            trip.villeArrivee.toLowerCase().contains(lowerQuery);
      }).toList();
    });
  }


  // 📅 NOUVEAU : SÉLECTEUR DE DATE
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(), // On ne peut pas réserver dans le passé
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      // Optionnel : Tu pourrais recharger l'API ici si l'API supporte le filtrage par date
    }
  }

  // 🗑️ RESET DATE
  void _clearDateFilter() {
    setState(() {
      _selectedDate = null;
    });
  }


  void _showSelectionOverlay(BuildContext itemContext, ProgramModel program) {
    _removeOverlay();
    final RenderBox renderBox = itemContext.findRenderObject() as RenderBox;
    final Size size = renderBox.size;
    final Offset offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: _removeOverlay,
            child: Container(color: Colors.black.withOpacity(0.8), width: double.infinity, height: double.infinity),
          ),
          Positioned(
            top: offset.dy + size.height - 20,
            left: offset.dx,
            width: size.width * 2,
            height: 150,
            child: _BranchAndButtonWidget(
              onBookPressed: () => _handleBookingLogic(program),
              cardWidth: size.width,
            ),
          ),
          Positioned(
            top: offset.dy,
            left: offset.dx,
            width: size.width,
            height: size.height,
            child: Material(
              color: Colors.transparent,
              elevation: 10,
              borderRadius: BorderRadius.circular(20),
              child: _buildCompanyCard(context, program: program, isInteractive: false),
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  // -----------------------------------------------------------
  // 🧠 LOGIQUE DE RÉSERVATION CORRIGÉE
  // -----------------------------------------------------------
  void _handleBookingLogic(ProgramModel program) {
    _removeOverlay();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingConfigurationSheet(
        program: program,
        // ✅ CORRECTION : _repository est maintenant bien initialisé !
        repository: _repository,
      ),
    );
  }



  Color _getCompanyColor(String name) {
    if (name.toLowerCase().contains("utb")) return const Color(0xFFCA8A04);
    if (name.toLowerCase().contains("fabiola")) return const Color(0xFF15803D);
    if (name.toLowerCase().contains("maless")) return const Color(0xFFA855F7);
    if (name.toLowerCase().contains("sbta")) return const Color(0xFF2563EB);
    return AppColors.primary;
  }



  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: scaffoldColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Tous les itinéraires", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // --- BARRE DE RECHERCHE + CALENDRIER ---
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              children: [
                // Champ Texte
                Expanded(
                  child: Container(
                    height: 50,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _filterTrips,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        icon: const Icon(Icons.search, color: Colors.grey),
                        hintText: "Ville, compagnie...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const Gap(10),
                // Bouton Calendrier
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                        color: _selectedDate != null ? AppColors.primary : cardColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))]
                    ),
                    child: Icon(
                        Icons.calendar_month,
                        color: _selectedDate != null ? Colors.white : Colors.grey
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- AFFICHAGE DE LA DATE SÉLECTIONNÉE (FEEDBACK) ---
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10, left: 20, right: 20),
              child: Row(
                children: [
                  Text(
                    "Départs du ${DateFormat('dd MMM yyyy', 'fr').format(_selectedDate!)}",
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child: const Text("Effacer", style: TextStyle(color: Colors.red, fontSize: 12)),
                  )
                ],
              ),
            ),

          // --- LISTE ---
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItineraries.isEmpty
                ? Center(child: Text("Aucun itinéraire trouvé", style: TextStyle(color: textColor)))
                : GridView.builder(
              padding: const EdgeInsets.only(left: 20, right: 20, top: 10, bottom: 100),
              itemCount: filteredItineraries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              /*itemBuilder: (context, index) {
                // On crée une copie du programme pour injecter la date sélectionnée
                // C'est CRUCIAL pour que RealTimeSeatInfo cherche la bonne date !
                ProgramModel originalProgram = filteredItineraries[index];

                ProgramModel displayProgram = originalProgram;

                if (_selectedDate != null) {
                  // Si une date est choisie, on modifie la dateDepart du modèle
                  // pour que la carte affiche les infos de CETTE date
                  displayProgram = ProgramModel(
                    id: originalProgram.id,
                    compagnieName: originalProgram.compagnieName,
                    prix: originalProgram.prix,
                    heureDepart: originalProgram.heureDepart,
                    heureArrivee: originalProgram.heureArrivee,
                    duree: originalProgram.duree,
                    placesDisponibles: originalProgram.placesDisponibles, // Sera recalculé par le widget
                    capacity: originalProgram.capacity,
                    isAllerRetour: originalProgram.isAllerRetour,
                    villeDepart: originalProgram.villeDepart,
                    villeArrivee: originalProgram.villeArrivee,
                    // 🔥 ON FORCE LA DATE CHOISIE ICI
                    dateDepart: DateFormat('yyyy-MM-dd').format(_selectedDate!) + " " + originalProgram.heureDepart,
                  );
                }

                return Builder(
                    builder: (itemContext) {
                      return GestureDetector(
                        onTap: () => _showSelectionOverlay(itemContext, displayProgram),
                        child: _buildCompanyCard(context, program: displayProgram, isInteractive: true),
                      );
                    }
                );
              },*/

              itemBuilder: (context, index) {
                // 🟢 5. CALCUL DE L'ANIMATION EN CASCADE (Staggered effect)
                // Chaque carte commencera son animation avec un léger décalage selon son index
                final double startDelay = (index % 10) * 0.10;
                final double endDelay = (startDelay + 0.80).clamp(0.0, 1.0);

                final animation = CurvedAnimation(
                  parent: _entranceController,
                  curve: Interval(
                    startDelay,
                    endDelay,
                    curve: Curves.easeOutCubic,
                  ),
                );

                ProgramModel originalProgram = filteredItineraries[index];
                ProgramModel displayProgram = originalProgram;

                if (_selectedDate != null) {
                  displayProgram = ProgramModel(
                    id: originalProgram.id,
                    compagnieName: originalProgram.compagnieName,
                    prix: originalProgram.prix,
                    heureDepart: originalProgram.heureDepart,
                    heureArrivee: originalProgram.heureArrivee,
                    duree: originalProgram.duree,
                    placesDisponibles: originalProgram.placesDisponibles,
                    capacity: originalProgram.capacity,
                    isAllerRetour: originalProgram.isAllerRetour,
                    villeDepart: originalProgram.villeDepart,
                    villeArrivee: originalProgram.villeArrivee,
                    dateDepart: DateFormat('yyyy-MM-dd').format(_selectedDate!) + " " + originalProgram.heureDepart,
                  );
                }

                return Builder(
                    builder: (itemContext) {
                      // 🟢 6. APPLICATION VISUELLE DE L'ANIMATION
                      return SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2), // Commence légèrement plus bas
                          end: Offset.zero,            // Finit à sa position normale
                        ).animate(animation),
                        child: FadeTransition(
                          opacity: animation,          // Fait apparaître en fondu
                          child: GestureDetector(
                            onTap: () => _showSelectionOverlay(itemContext, displayProgram),
                            child: _buildCompanyCard(context, program: displayProgram, isInteractive: true),
                          ),
                        ),
                      );
                    }
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // 🎨 WIDGET CARTE COMPAGNIE (CORRIGÉ AVEC SLIDER)
  // ------------------------------------------------------------------------
  Widget _buildCompanyCard(BuildContext context, {required ProgramModel program, required bool isInteractive}) {
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final color = _getCompanyColor(program.compagnieName);
    final isAR = program.isAllerRetour;

    // Les images pour le slider
    final List<String> busImages = [
      "assets/images/busheader.jpg",
      "assets/images/busheader1.jpg",
      "assets/images/busheader2.jpg",
    ];

    // Calcul de la barre de progression (fallback visuel)
    // Note: RealTimeSeatInfo écrasera l'affichage textuel, mais la barre reste ici pour l'instant
    int placesReservees = program.capacity - program.placesDisponibles;
    if (placesReservees < 0) placesReservees = 0;
    double progress = program.capacity > 0 ? placesReservees / program.capacity : 0.0;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isInteractive
            ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- 🖼️ HEADER AVEC SLIDER (CORRIGÉ) ---
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ✅ UTILISATION DU WIDGET DE SLIDER AUTOMATIQUE
                  BusImageSlider(images: busImages),

                  // Filtre sombre pour lisibilité
                  Container(color: Colors.black.withOpacity(0.4)),

                  // Infos par dessus l'image
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Badge Aller Simple / Retour
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5)),
                              child: Row(
                                children: [
                                  Icon(isAR ? Icons.compare_arrows : Icons.arrow_right_alt, color: Colors.white, size: 10),
                                  const Gap(4),
                                  Text(isAR ? "A/R" : "Simple", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            // Badge Note
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: const [Icon(Icons.star_rounded, color: Colors.orange, size: 10), Gap(2), Text("4.5", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black))]),
                            )
                          ],
                        ),
                        // Nom Compagnie
                        Row(
                          children: [
                            const Icon(Icons.directions_bus_filled, color: Colors.white, size: 18),
                            const Gap(5),
                            Expanded(child: Text(program.compagnieName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, shadows: [Shadow(blurRadius: 2, color: Colors.black)]), overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // --- BODY CARD ---
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Ligne Trajet
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.circle, size: 8, color: color), const Gap(5), Expanded(child: Text(program.villeDepart, style: TextStyle(fontSize: 11, color: textColor), overflow: TextOverflow.ellipsis))]),
                      Container(margin: const EdgeInsets.only(left: 3.5), height: 8, width: 1, color: Colors.grey.shade300),
                      Row(children: [Icon(Icons.location_on, size: 8, color: Colors.grey), const Gap(5), Expanded(child: Text(program.villeArrivee, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis))]),
                    ],
                  ),

                  // Infos Prix & Places INTELLIGENTES
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 15),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("${program.prix} F", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        Text(program.heureDepart, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ]),
                      const Gap(8),

                      // 🚀 C'EST ICI QUE LA MAGIE OPÈRE
                      // On passe le programme qui contient potentiellement la date modifiée
                      RealTimeSeatInfo(program: program),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}





// -------------------------------------------------------------------------
// 🎞️ WIDGET SLIDER D'IMAGES AUTOMATIQUE (AJOUTE LE EN BAS DU FICHIER)
// -------------------------------------------------------------------------
class BusImageSlider extends StatefulWidget {
  final List<String> images;
  const BusImageSlider({super.key, required this.images});

  @override
  State<BusImageSlider> createState() => _BusImageSliderState();
}

class _BusImageSliderState extends State<BusImageSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    // Défilement automatique toutes les 3 secondes
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < widget.images.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }

      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      itemCount: widget.images.length,
      itemBuilder: (context, index) {
        return Image.asset(
          widget.images[index],
          fit: BoxFit.cover,
        );
      },
    );
  }
}

// -------------------------------------------------------------------------
// 🖌️ WIDGET DE LA BRANCHE ET DU BOUTON (CustomPainter pour le design)
// -------------------------------------------------------------------------
class _BranchAndButtonWidget extends StatelessWidget {
  final VoidCallback onBookPressed;
  final double cardWidth;

  const _BranchAndButtonWidget({required this.onBookPressed, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 1. La Ligne (Branche)
        CustomPaint(
          size: Size(cardWidth, 80),
          painter: _BranchPainter(color: AppColors.primary),
        ),
        Positioned(
          top: 50,
          left: (cardWidth / 2) - 70, // Centré
          child: ScaleTransition(
            scale: const AlwaysStoppedAnimation(1.0),
            child: Container(
              width: 140,
              height: 45,
              // ✅ 1. Coupe l'image pour qu'elle suive l'arrondi (25)
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25), // Arrondi bien rond
                // ✅ 2. L'image de fond
                image: const DecorationImage(
                  image: AssetImage("assets/images/tabaa.jpg"),
                  fit: BoxFit.cover,
                ),
                // ✅ 3. On recrée l'effet "Elevation 10" ici
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4), // Ombre teintée c'est plus joli
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onBookPressed,
                style: ElevatedButton.styleFrom(
                  // ✅ 4. Fond transparent
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent, // On désactive l'ombre par défaut
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text("Réserver", style: TextStyle(fontWeight: FontWeight.bold)),
                    Gap(8),
                    Icon(Icons.arrow_forward, size: 18)
                  ],
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

// Le Dessinateur de la courbe
class _BranchPainter extends CustomPainter {
  final Color color;
  _BranchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    // Point de départ : Milieu haut (qui colle au bas de la carte)
    double startX = size.width / 2;
    double startY = -5; // Un peu en haut pour être caché sous la carte

    // Point d'arrivée : Milieu bas (vers le bouton)
    double endX = size.width / 2;
    double endY = 50;

    // Dessin d'une ligne droite simple ou courbe
    // Ici on fait simple : une ligne qui descend
    path.moveTo(startX, startY);

    // Petit effet de zigzag ou courbe
    path.quadraticBezierTo(
        startX - 20, // Point de contrôle (vers la gauche)
        (endY - startY) / 2,
        endX,
        endY
    );

    // Dessiner un petit cercle au début pour la jointure
    canvas.drawCircle(Offset(startX, startY), 4, Paint()..color = color);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
