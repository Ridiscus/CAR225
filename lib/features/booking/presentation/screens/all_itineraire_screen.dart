import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

// ✅ Assure-toi que ces imports sont bons chez toi
import '../../../../common/widgets/BookingConfigurationSheet.dart';
import '../../../../common/widgets/cube_magic.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/datasources/booking_remote_data_source.dart';
import '../../data/models/program_model.dart';
import '../../domain/repositories/booking_repository.dart';
import 'booking_summary_screen.dart'; // Import de ton écran de résumé

class AllItinerariesScreen extends StatefulWidget {
  const AllItinerariesScreen({super.key});

  @override
  State<AllItinerariesScreen> createState() => _AllItinerariesScreenState();
}

class _AllItinerariesScreenState extends State<AllItinerariesScreen> {
  // --- ETAT DONNÉES ---
  List<ProgramModel> allItineraries = [];
  List<ProgramModel> filteredItineraries = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  // ✅ CORRECTION : Une seule variable, bien nommée
  late BookingRepositoryImpl _repository;

  // --- ETAT INTERACTION ---
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    super.dispose();
  }

  void _initData() async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
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

  // ... [Le reste de tes méthodes _showSelectionOverlay, _removeOverlay restent identiques] ...

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

  // ... [Le reste du build et _buildCompanyCard reste identique] ...

  Color _getCompanyColor(String name) {
    if (name.toLowerCase().contains("utb")) return const Color(0xFFCA8A04);
    if (name.toLowerCase().contains("fabiola")) return const Color(0xFF15803D);
    if (name.toLowerCase().contains("maless")) return const Color(0xFFA855F7);
    if (name.toLowerCase().contains("sbta")) return const Color(0xFF2563EB);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    // ... [Ton code build existant, pas besoin de le changer] ...
    // Je le remets pour que le copier-coller soit facile si tu remplaces tout le fichier

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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Container(
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
                  hintText: "Rechercher une destination...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredItineraries.isEmpty
                ? Center(child: Text("Aucun itinéraire trouvé", style: TextStyle(color: textColor)))
                : GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              itemCount: filteredItineraries.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.70,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
              ),
              itemBuilder: (context, index) {
                final program = filteredItineraries[index];
                return Builder(
                    builder: (itemContext) {
                      return GestureDetector(
                        onTap: () => _showSelectionOverlay(itemContext, program),
                        child: _buildCompanyCard(context, program: program, isInteractive: true),
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

  Widget _buildCompanyCard(BuildContext context, {required ProgramModel program, required bool isInteractive}) {
    // ... [Ton code existant _buildCompanyCard, copie-le tel quel] ...
    // Je te remets juste le début pour la structure
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final color = _getCompanyColor(program.compagnieName);
    final isAR = program.isAllerRetour;
    final List<String> busImages = [
      "assets/images/busheader.jpg",
      "assets/images/busheader1.jpg",
      "assets/images/busheader2.jpg",
    ];

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
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            child: SizedBox(
              height: 90,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Assure-toi d'avoir importé SlidingHeaderBackground ou remplace par Image.asset
                  SlidingHeaderBackground(height: 90, images: busImages),
                  Container(color: Colors.black.withOpacity(0.4)),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                              child: Row(children: const [Icon(Icons.star_rounded, color: Colors.orange, size: 10), Gap(2), Text("4.5", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.black))]),
                            )
                          ],
                        ),
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
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [Icon(Icons.circle, size: 8, color: color), const Gap(5), Expanded(child: Text(program.villeDepart, style: TextStyle(fontSize: 11, color: textColor), overflow: TextOverflow.ellipsis))]),
                      Container(margin: const EdgeInsets.only(left: 3.5), height: 8, width: 1, color: Colors.grey.shade300),
                      Row(children: [Icon(Icons.location_on, size: 8, color: Colors.grey), const Gap(5), Expanded(child: Text(program.villeArrivee, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: textColor), overflow: TextOverflow.ellipsis))]),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(height: 15),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text("${program.prix} F", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        Text(program.heureDepart, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
                      ]),
                      const Gap(4),
                      Text("${program.placesDisponibles} places restantes", style: TextStyle(fontSize: 9, color: program.placesDisponibles < 10 ? Colors.redAccent : Colors.green)),
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

        // 2. Le Bouton au bout de la branche
        Positioned(
          top: 50, // Ajusté selon la courbe du Painter
          left: (cardWidth / 2) - 70, // Centré par rapport à la courbe
          child: ScaleTransition(
            scale: const AlwaysStoppedAnimation(1.0), // Pourrait être animé
            child: SizedBox(
              width: 140,
              height: 45,
              child: ElevatedButton(
                onPressed: onBookPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 10,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
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










// -------------------------------------------------------------------------
// ⚙️ MODAL DE CONFIGURATION (Dates, Passagers, Type)
// -------------------------------------------------------------------------
/*class _BookingConfigurationSheet extends StatefulWidget {
  final ProgramModel program;
  const _BookingConfigurationSheet({required this.program});

  @override
  State<_BookingConfigurationSheet> createState() => _BookingConfigurationSheetState();
}

class _BookingConfigurationSheetState extends State<_BookingConfigurationSheet> {
  // État local de la configuration
  late bool isAllerRetour;
  late DateTime dateAller;
  DateTime? dateRetour;
  int passengerCount = 1;

  @override
  void initState() {
    super.initState();
    isAllerRetour = widget.program.isAllerRetour;

    // Initialisation intelligente de la date
    try {
      dateAller = DateTime.parse(widget.program.dateDepart);
      if (dateAller.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        dateAller = DateTime.now(); // Si la date par défaut est passée, on met aujourd'hui
      }
    } catch (_) {
      dateAller = DateTime.now();
    }
  }

  // Sélecteur de date
  Future<void> _pickDate(bool isRetour) async {
    final initial = isRetour ? (dateRetour ?? dateAller.add(const Duration(days: 1))) : dateAller;
    final first = isRetour ? dateAller : DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isRetour) {
          dateRetour = picked;
        } else {
          dateAller = picked;
          // Si la nouvelle date aller est après la date retour, on reset le retour
          if (dateRetour != null && dateRetour!.isBefore(dateAller)) {
            dateRetour = null;
          }
        }
      });
    }
  }

  void _incrementPassenger() {
    if (passengerCount < widget.program.placesDisponibles) {
      setState(() => passengerCount++);
    }
  }

  void _decrementPassenger() {
    if (passengerCount > 1) {
      setState(() => passengerCount--);
    }
  }

  void _validateAndContinue() {
    if (isAllerRetour && dateRetour == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir une date de retour")),
      );
      return;
    }

    // 🚀 NAVIGATION VERS LA SÉLECTION DES SIÈGES
    Navigator.pop(context); // Fermer la modal

    // TODO: Rediriger vers ton écran de sélection de sièges
    // C'est ici qu'on transmet toutes les infos collectées
    /*
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
           program: widget.program,
           dateAller: dateAller,
           dateRetour: dateRetour,
           passengerCount: passengerCount,
           isAllerRetour: isAllerRetour,
        ),
      ),
    );
    */

    // Pour l'instant, simu vers résumé direct (A REMPLACER PAR SEAT SCREEN)
    print("Configuration validée : $passengerCount pers, $dateAller");
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      padding: const EdgeInsets.all(20),
      // Hauteur dynamique selon le contenu
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header (Barre grise)
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const Gap(20),

          Text("Configurez votre voyage", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const Gap(20),

          // 2. Switch Aller Simple / Retour
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(child: _buildTabOption("Aller Simple", !isAllerRetour, () => setState(() => isAllerRetour = false))),
                Expanded(child: _buildTabOption("Aller-Retour", isAllerRetour, () => setState(() => isAllerRetour = true))),
              ],
            ),
          ),
          const Gap(20),

          // 3. Choix des Dates
          Row(
            children: [
              Expanded(child: _buildDateSelector("Départ", dateAller, () => _pickDate(false))),
              if (isAllerRetour) ...[
                const Gap(15),
                Expanded(child: _buildDateSelector("Retour", dateRetour, () => _pickDate(true))),
              ],
            ],
          ),
          const Gap(20),

          // 4. Nombre de passagers
          Text("Passagers", style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.people_alt_outlined, color: AppColors.primary),
                    const Gap(10),
                    Text("$passengerCount personne(s)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
                Row(
                  children: [
                    _buildCounterBtn(Icons.remove, _decrementPassenger),
                    const Gap(15),
                    _buildCounterBtn(Icons.add, _incrementPassenger),
                  ],
                )
              ],
            ),
          ),
          const Gap(30),

          // 5. Bouton Continuer
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _validateAndContinue,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              child: const Text("Choisir les places", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const Gap(10),
        ],
      ),
    );
  }

  Widget _buildTabOption(String title, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)] : [],
        ),
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isActive ? Colors.black : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap) {
    final isSelected = date != null;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const Gap(5),
          Container(
            height: 50,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 1.5 : 1),
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: isSelected ? AppColors.primary : Colors.grey),
                const Gap(8),
                Text(
                  isSelected ? DateFormat('dd MMM yyyy', 'fr_FR').format(date) : "Choisir date", // Ajoute intl et initializeDateFormatting si besoin
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.primary : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20),
      ),
    );
  }
}*/