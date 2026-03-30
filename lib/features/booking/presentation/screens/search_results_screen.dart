import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

// --- IMPORTS CORE & THEME ---
import '../../../../core/services/networking/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/presentation/bando.dart';

// --- IMPORTS CLEAN ARCHITECTURE ---
import '../../data/datasources/booking_remote_data_source.dart';
import '../../data/models/program_model.dart';
import '../../domain/repositories/booking_repository.dart';
import 'seat_selection_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final bool isModificationMode; // 1️⃣ AJOUTER CECI
  final bool isGuestMode;
  final Map<String, dynamic>? searchParams;
  // 🟢 On récupère l'info depuis l'écran précédent
  final bool ticketWasAllerRetour;

  const SearchResultsScreen({
    super.key,
    this.isModificationMode = false, // 2️⃣ Initialiser à false par défaut
    this.ticketWasAllerRetour = false, // Par défaut false
    this.isGuestMode = false,
    this.searchParams,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}


  class _SearchResultsScreenState extends State<SearchResultsScreen> with SingleTickerProviderStateMixin { // 👈 1. AJOUT DU MIXIN
  int passengerCount = 1;
  bool isLoading = true;
  String? errorMessage;
  List<ProgramModel> programs = [];

  // 🟢 NOUVELLE VARIABLE POUR LES GROUPES
  List<List<ProgramModel>> groupedPrograms = [];

  late BookingRepositoryImpl _repository;

  // 🟢 2. DÉCLARATION DU CONTROLLER
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();

    // 🟢 3. INITIALISATION DU CONTROLLER (Sans faire le .forward() ici !)
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _setupDependenciesAndFetch();
  }

  // 🟢 4. AJOUT DU DISPOSE POUR ÉVITER LES FUITES DE MÉMOIRE
  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }



  void _setupDependenciesAndFetch() {
    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      //baseUrl: 'https://car225.com/api/',
      //baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      /*headers: {'Content-Type': 'application/json'},*/
    ));

    final dataSource = BookingRemoteDataSourceImpl(dio: dio);
    _repository = BookingRepositoryImpl(remoteDataSource: dataSource);

    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() { isLoading = true; errorMessage = null; });

    try {
      List<ProgramModel> results;
      if (widget.searchParams != null) {
        results = await _repository.searchTrips(
          widget.searchParams!['depart'],
          widget.searchParams!['arrivee'],
          widget.searchParams!['date'],
          false,
        );
      } else {
        results = await _repository.getAllTrips();
      }

      // 🟢 LOGIQUE DE GROUPEMENT
      Map<String, List<ProgramModel>> groupsMap = {};
      for (var program in results) {
        // Clé unique par Compagnie + Départ + Arrivée
        String key = "${program.compagnieId}_${program.villeDepart}_${program.villeArrivee}";
        if (!groupsMap.containsKey(key)) {
          groupsMap[key] = [];
        }
        groupsMap[key]!.add(program);
      }

      List<List<ProgramModel>> newGroupedPrograms = groupsMap.values.toList();

      if (mounted) {
        setState(() {
          programs = results;
          groupedPrograms = newGroupedPrograms; // 🟢 On stocke les groupes
          isLoading = false;
        });
      }

      _entranceController.forward(from: 0.0);

    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll("Exception:", "").trim();
          isLoading = false;
        });
      }
    }
  }

  void _incrementPassengers() { if (passengerCount < 8) setState(() => passengerCount++); }
  void _decrementPassengers() { if (passengerCount > 1) setState(() => passengerCount--); }


  Future<void> _showBookingOptionsModal(BuildContext context, List<ProgramModel> availableOutboundTrips) async {
    final Map<String, dynamic>? configResult = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) {
            return _BookingConfigModalContent(
              availableOutboundTrips: availableOutboundTrips,
              passengerCount: passengerCount,
              isGuestMode: widget.isGuestMode,
              isModificationMode: widget.isModificationMode,
              repository: _repository,
              ticketWasAllerRetour: widget.ticketWasAllerRetour,
              // 🟢 NOUVEAU : On passe la date cherchée au modal
              searchedDate: widget.searchParams?['date'],
            );
          },
        );
      },
    );
    // Si on revient avec des résultats, on va vers la sélection des sièges
    if (configResult != null && mounted) {
      _navigateToSeatSelection(
        program: configResult['program'],
        returnProgram: configResult['returnProgram'], // Sera null si isRoundTrip était false
        // 🟢 NOUVEAU : On récupère le paramètre
        isAutomaticSeatSelection: configResult['isAutomaticSeatSelection'] ?? false,
        // 🟢 LA PIÈCE MANQUANTE EST LÀ !!
        dateRetourChoisie: configResult['dateRetourChoisie'],
      );
    }
  }


  void _navigateToSeatSelection({
    required ProgramModel program,
    ProgramModel? returnProgram,
    String? dateRetourChoisie,
    bool isAutomaticSeatSelection = false, // 🟢 NOUVEAU
  }) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          program: program,
          returnProgram: returnProgram, // ✅ On transmet le programme retour
          passengerCount: passengerCount,
          isGuestMode: widget.isGuestMode,
          isModificationMode: widget.isModificationMode,
          dateRetourChoisie: dateRetourChoisie,
          // 🟢 NOUVEAU : On passe l'information à l'écran des sièges
          isAutomaticSeatSelection: isAutomaticSeatSelection,
          seatSelectionFee: isAutomaticSeatSelection ? 0 : 100,
        ),
      ),
    );

    // Si on a terminé la modif, on remonte le résultat
    if (widget.isModificationMode && result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);

    String titrePage = "Résultats";
    List<String> sousTitres = ["Trajets disponibles"];

    if (widget.searchParams != null) {
      titrePage = "${widget.searchParams!['depart']} ➔ ${widget.searchParams!['arrivee']}";
      sousTitres = [
        "Date : ${widget.searchParams!['date']}",
        "${programs.length} trajet(s) trouvé(s)"
      ];
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () => Navigator.pop(context)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titrePage, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16)),
            ScrollingSubtitle(texts: sousTitres),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4))]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text("PASSAGERS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const Gap(5),
                    Text("$passengerCount passager${passengerCount > 1 ? 's' : ''}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                  ]),
                  Container(
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.background, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      IconButton(onPressed: _decrementPassengers, icon: const Icon(Icons.remove, size: 18), color: passengerCount > 1 ? textColor : Colors.grey),
                      Text("$passengerCount", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      IconButton(onPressed: _incrementPassengers, icon: const Icon(Icons.add, size: 18), color: AppColors.primary),
                    ]),
                  )
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                ? Center(child: Padding(padding: const EdgeInsets.all(20), child: Text("Oups ! $errorMessage", textAlign: TextAlign.center, style: TextStyle(color: textColor))))
                : programs.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.directions_bus_outlined, size: 60, color: Colors.grey.shade400), const Gap(10), Text("Aucun trajet disponible", style: TextStyle(color: Colors.grey.shade600))]))

                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: groupedPrograms.length, // 🟢 Utiliser la longueur des groupes
              itemBuilder: (context, index) {
                // 🟢 On récupère le GROUPE entier
                final group = groupedPrograms[index];
                // On utilise le premier élément du groupe pour afficher les infos générales de la carte
                final representatifProgram = group.first;

                final double startDelay = (index % 10) * 0.1;
                final double endDelay = (startDelay + 0.5).clamp(0.0, 1.0);
                final animation = CurvedAnimation(parent: _entranceController, curve: Interval(startDelay, endDelay, curve: Curves.easeOutCubic));

                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    // 🟢 On passe TOUT LE GROUPE à la méthode qui construit la carte
                    child: _buildTicketCard(context, group),
                  ),
                );
              },

            ),

          ),
        ],
      ),
    );
  }



    Widget _buildTicketCard(BuildContext context, List<ProgramModel> group) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);
    final program = group.first;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4))]
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          "assets/images/bus.png",
                          color: AppColors.primary,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            program.compagnieName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_filled,
                                size: 12,
                                color: AppColors.primary,
                              ),
                              const Gap(4),
                              Expanded(
                                child: Text(
                                  "Départ : ${program.heureDepart}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${program.prix} F",
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  Text(
                    "${program.placesDisponibles} places dispo",
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: program.placesDisponibles < 5
                          ? Colors.red
                          : AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Gap(15),
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          const Gap(15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(program.villeDepart, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), overflow: TextOverflow.ellipsis),
                    Text(program.heureDepart, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Column(
                  children: [
                    Icon(Icons.arrow_forward, size: 20, color: Colors.grey.shade400),
                    Text(program.duree, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(program.villeArrivee, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textColor), overflow: TextOverflow.ellipsis),
                    Text(program.heureArrivee, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          // MODIFICATION ICI
          Container(
            width: double.infinity,
            height: 45, // On fixe une hauteur pour que l'image se voie bien
            clipBehavior: Clip.hardEdge, // Coupe l'image aux bords
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10), // Rayon original
              image: const DecorationImage(
                image: AssetImage("assets/images/tabaa.jpg"),
                fit: BoxFit.cover,
              ),
            ),

            child: ElevatedButton(
              onPressed: () {
                // 🟢 On passe LE GROUPE ENTIER au modal, plus seulement un programme
                _showBookingOptionsModal(context, group);
              },


              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent, // Transparent !
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 0) // Le Container gère la hauteur
              ),
              child: const Text("Réserver", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          )

        ],
      ),
    );
  }
}





// -----------------------------------------------------------------------------
// 🟢 COMPOSANT INTERNE : LE CONTENU DU MODAL AVEC L'INFORMATION
// -----------------------------------------------------------------------------
class _BookingConfigModalContent extends StatefulWidget {
  final List<ProgramModel> availableOutboundTrips;
  final int passengerCount;
  final bool isModificationMode;
  final bool isGuestMode;
  final bool ticketWasAllerRetour;
  final BookingRepositoryImpl repository;

  // 🟢 NOUVEAU : La date initialement cherchée
  final String? searchedDate;

  const _BookingConfigModalContent({
    super.key,
    required this.availableOutboundTrips,
    required this.passengerCount,
    required this.isModificationMode,
    required this.isGuestMode,
    this.ticketWasAllerRetour = false,
    required this.repository,
    this.searchedDate, // 🟢 NOUVEAU
  });

  @override
  State<_BookingConfigModalContent> createState() => _BookingConfigModalContentState();
}

class _BookingConfigModalContentState extends State<_BookingConfigModalContent> {
  // 🟢 Nouveau : On stocke le programme Aller sélectionné par l'utilisateur
  ProgramModel? selectedOutboundProgram;
  bool isRoundTrip = false;
  late String selectedDepartureTime;
  DateTime? selectedReturnDate;
  bool isLoadingReturnTrips = false;
  List<ProgramModel> availableReturnTrips = [];
  ProgramModel? selectedReturnProgram;


  // 🟢 NOUVEAU : État pour le mode de sélection des sièges
  //bool isAutomaticSeatSelection = false; // Par défaut sur Manuel



  @override
  void initState() {
    super.initState();

    // 🟢 Par défaut, on sélectionne le premier horaire de la liste pour l'Aller
    if (widget.availableOutboundTrips.isNotEmpty) {
      selectedOutboundProgram = widget.availableOutboundTrips.first;
    }

    if (widget.isModificationMode) {
      isRoundTrip = widget.ticketWasAllerRetour;
    } else {
      // 🟢 On se base sur le premier élément pour savoir si on active l'AR par défaut
      isRoundTrip = widget.availableOutboundTrips.isNotEmpty
          ? widget.availableOutboundTrips.first.isAllerRetour
          : false;
    }
  }

  void _showTopNotification(String message, {bool isError = true}) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, left: 20.0, right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF222222),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isError ? Icons.error_outline : Icons.check_circle_outline, color: isError ? Colors.redAccent : Colors.greenAccent, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center, maxLines: 2)),
              ],
            ),
          ),
        ),
      ),
    );
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () { if(mounted) overlayEntry.remove(); });
  }

  Future<void> _fetchReturnTrips(DateTime date) async {
    setState(() { isLoadingReturnTrips = true; availableReturnTrips = []; selectedReturnProgram = null; });
    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);
      String formatCity(String city) => "${city.split(',')[0].trim()}, Côte d'Ivoire";
      //final villeDepartRetour = formatCity(widget.program.villeArrivee.trim());
      final villeArriveeRetour = formatCity(selectedOutboundProgram!.villeDepart.trim());
      // Remplacer widget.program.villeArrivee par :
      final villeDepartRetour = formatCity(selectedOutboundProgram!.villeArrivee.trim());

      final results = await widget.repository.searchTrips(villeDepartRetour, villeArriveeRetour, dateStr, false);
      if (mounted) setState(() { availableReturnTrips = results; isLoadingReturnTrips = false; });
    } catch (e) {
      if (mounted) {
        setState(() => isLoadingReturnTrips = false);
        _showTopNotification("Erreur de connexion: $e");
      }
    }
  }

  Future<void> _pickReturnDate() async {
    // 🟢 1. ON UTILISE LA DATE RECHERCHÉE PAR L'UTILISATEUR EN PRIORITÉ
    String dateStringToParse = widget.searchedDate ?? selectedOutboundProgram!.dateDepart.split(' ')[0];

    // 🟢 2. On parse la date
    DateTime departureDate = DateTime.tryParse(dateStringToParse) ?? DateTime.now();

    // 🟢 3. SÉCURITÉ : On remet les heures à zéro pour que le calendrier compare uniquement les jours
    departureDate = DateTime(departureDate.year, departureDate.month, departureDate.day);

    // Date sélectionnée par défaut à l'ouverture du calendrier (le lendemain par défaut)
    DateTime initialDate = selectedReturnDate ?? departureDate.add(const Duration(days: 1));

    // Si la date initiale calculée est avant le départ (cas rare), on la force au jour du départ
    if (initialDate.isBefore(departureDate)) {
      initialDate = departureDate;
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: departureDate, // 🔒 C'est ici que la magie opère : bloque avant l'Aller !
      lastDate: DateTime(departureDate.year + 1),
      builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(primary: AppColors.primary)
          ),
          child: child!
      ),
    );

    if (picked != null) {
      setState(() => selectedReturnDate = picked);
      _fetchReturnTrips(picked);
    }
  }



  void _onValidate() {
    // 🟢 On vérifie qu'une heure d'Aller est bien sélectionnée
    if (selectedOutboundProgram == null) {
      _showTopNotification("Veuillez sélectionner une heure de départ.");
      return;
    }

    if (isRoundTrip) {
      if (selectedReturnDate == null) {
        _showTopNotification("Veuillez choisir une date de retour.");
        return;
      }
      if (selectedReturnProgram == null) {
        if (availableReturnTrips.isEmpty && !isLoadingReturnTrips) {
          _showTopNotification("Aucun bus disponible à cette date.");
        } else {
          _showTopNotification("Veuillez sélectionner une heure de retour.");
        }
        return;
      }
    }

    Navigator.pop(context, {
      'program': selectedOutboundProgram!.copyWith(
        isAllerRetour: isRoundTrip,
        // 🟢 Sécurité absolue : On force la date du programme avec celle cherchée
        dateDepart: widget.searchedDate != null
            ? "${widget.searchedDate} ${selectedOutboundProgram!.heureDepart}"
            : selectedOutboundProgram!.dateDepart,
      ),
      'returnProgram': isRoundTrip ? selectedReturnProgram : null,
      'dateRetourChoisie': isRoundTrip && selectedReturnDate != null
          ? DateFormat('yyyy-MM-dd').format(selectedReturnDate!)
          : null,
      // 🟢 NOUVEAU : On passe le choix de sélection
      //'isAutomaticSeatSelection': isAutomaticSeatSelection,
      'isAutomaticSeatSelection': true,
      'seatSelectionFee': 0,
      // 🟢 NOUVEAU : On transmet le montant des frais pour l'écran suivant
      //'seatSelectionFee': isAutomaticSeatSelection ? 0 : 100,
    });

  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;


    // 🟢 Sécurité : on récupère les infos globales du trajet sur le premier élément
    final trajetAller = widget.availableOutboundTrips.isNotEmpty
        ? widget.availableOutboundTrips.first
        : null;

    if (trajetAller == null) {
      return const SizedBox(); // Sécurité si la liste est vide
    }

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const Gap(20),
              Text("Configuration du voyage", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              const Gap(20),

              // 🔒 LE BLOC DE CHOIX DU TYPE DE VOYAGE
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Row(
                  children: [
                    _buildTypeOption(
                        "Aller Simple",
                        !isRoundTrip,
                        widget.isModificationMode
                            ? null
                            : () { setState(() { isRoundTrip = false; selectedReturnProgram = null; selectedReturnDate = null; }); }
                    ),
                    _buildTypeOption(
                        "Aller - Retour",
                        isRoundTrip,
                        widget.isModificationMode
                            ? null
                            : () => setState(() => isRoundTrip = true)
                    ),
                  ],
                ),
              ),

              const Gap(20),

              // RÉCAP ALLER
              Text(
                  "Aller : ${trajetAller.villeDepart} ➔ ${trajetAller.villeArrivee}",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)
              ),
              const Gap(8),

              // Affichage de la date
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                    const Gap(5),
                    Text(
                        DateFormat("d MMM yyyy", "fr_FR").format(
                            DateTime.parse(
                                widget.searchedDate ?? trajetAller.dateDepart.split(' ')[0]
                            )
                        ),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)
                    ),
                  ],
                ),
              ),
              const Gap(15),

              const Text("Choisissez l'heure de départ :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              const Gap(8),

              // AFFICHAGE DES HEURES DE DÉPART DISPONIBLES
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: widget.availableOutboundTrips.map((prog) {
                  final bool isSelected = selectedOutboundProgram?.id == prog.id;
                  return ChoiceChip(
                    label: Text(
                        prog.heureDepart,
                        style: TextStyle(color: isSelected ? Colors.white : textColor, fontWeight: FontWeight.bold)
                    ),
                    selected: isSelected,
                    selectedColor: AppColors.primary,
                    backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          selectedOutboundProgram = prog;
                        }
                      });
                    },
                  );
                }).toList(),
              ),

              if (isRoundTrip) ...[
                const Gap(25),
                const Divider(),
                const Gap(10),
                Text("Retour : ${trajetAller.villeArrivee} ➔ ${trajetAller.villeDepart}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
                const Gap(10),
                GestureDetector(
                  onTap: _pickReturnDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(10), color: isDark ? Colors.white.withOpacity(0.05) : Colors.white),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(selectedReturnDate == null ? "Sélectionner la date retour" : DateFormat("EEEE d MMMM yyyy", "fr_FR").format(selectedReturnDate!), style: TextStyle(fontWeight: FontWeight.bold, color: selectedReturnDate == null ? Colors.grey : textColor, fontSize: 14)),
                        const Icon(Icons.calendar_month, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                const Gap(15),
                if (isLoadingReturnTrips)
                  const Center(child: Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2)))
                else if (selectedReturnDate != null && availableReturnTrips.isEmpty)
                  Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: const Row(children: [Icon(Icons.warning, color: Colors.red, size: 16), Gap(8), Expanded(child: Text("Aucun bus disponible pour ce retour.", style: TextStyle(color: Colors.red, fontSize: 12)))])
                  )
                else if (selectedReturnDate != null) ...[
                    const Text("Choisissez l'heure de retour :", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    const Gap(8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: availableReturnTrips.map((prog) {
                        final bool isSelected = selectedReturnProgram?.id == prog.id;
                        return ChoiceChip(
                          label: Text(prog.heureDepart, style: TextStyle(color: isSelected ? Colors.white : textColor, fontWeight: FontWeight.bold)),
                          selected: isSelected,
                          selectedColor: AppColors.primary,
                          backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                          onSelected: (bool selected) { setState(() { selectedReturnProgram = selected ? prog : null; }); },
                        );
                      }).toList(),
                    ),
                  ]
              ],

              const Gap(25),

              // 🟢 NOUVEAU : BLOC DE CHOIX DES SIÈGES
              /*Text("Attribution des sièges", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor)),
              const Gap(10),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(10)
                ),
                child: Row(
                  children: [
                    // BOUTON MANUEL
                    _buildTypeOption(
                        "Manuel",
                        !isAutomaticSeatSelection,
                            () => setState(() => isAutomaticSeatSelection = false)
                    ),
                    // BOUTON AUTOMATIQUE
                    _buildTypeOption(
                        "Automatique",
                        isAutomaticSeatSelection,
                            () => setState(() => isAutomaticSeatSelection = true)
                    ),
                  ],
                ),
              ),

              // 🟢 NOUVEAU : MESSAGE D'INFORMATION POUR LES FRAIS MANUELS
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: !isAutomaticSeatSelection
                    ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "La sélection manuelle des sièges entraîne des frais de 100 FCFA.",
                            style: TextStyle(fontSize: 12, color: textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),

              const Gap(30),*/

              // BLOC INFO FLEXIBILITÉ
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFCA8A04).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCA8A04).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Color(0xFFCA8A04), size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(fontSize: 12, color: textColor),
                          children: const [
                            TextSpan(text: "Annulation & Modification possibles jusqu'à ", style: TextStyle(fontWeight: FontWeight.normal)),
                            TextSpan(text: "15 min avant le départ ", style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFCA8A04))),
                            TextSpan(text: "via l'écran 'Mes Réservations'.", style: TextStyle(fontWeight: FontWeight.normal)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 🟢 BOUTON INTELLIGENT QUI CHANGE DE TEXTE
              /*Container(
                width: double.infinity,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/tabaa.jpg"),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _onValidate,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: Text(
                    // ✨ La magie est ici !
                      isAutomaticSeatSelection ? "Valider et Continuer" : "Choisir les sièges",
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

              const Gap(10),
            ],*/

              Container(
                width: double.infinity,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/tabaa.jpg"),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _onValidate,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text(
                      "Continuer", // ✨ Plus de logique complexe, on avance !
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

              const Gap(10),
            ],

          ),
        ),
      ),
    );
  }


  Widget _buildTypeOption(String label, bool isSelected, VoidCallback? onTap) {
    // Si onTap est null, c'est que le bouton est désactivé
    bool isDisabled = onTap == null;

    // Si c'est désactivé mais que ce n'est PAS l'option sélectionnée, on la grise fort
    // Exemple : Je modifie un Aller Simple. "Aller Retour" est désactivé et non sélectionné.
    double opacity = isDisabled && !isSelected ? 0.3 : 1.0;

    return Expanded(
      child: GestureDetector(
        onTap: onTap, // Peut être null, donc pas de clic
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            // Si sélectionné : Blanc. Si pas sélectionné : Transparent.
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
          ),
          child: Opacity(
            opacity: opacity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Petit cadenas si c'est l'option sélectionnée mais verrouillée
                if (isDisabled && isSelected) ...[
                  Icon(Icons.lock, size: 12, color: Colors.grey),
                  SizedBox(width: 5),
                ],
                Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.black : Colors.grey,
                        fontSize: 13
                    )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

}