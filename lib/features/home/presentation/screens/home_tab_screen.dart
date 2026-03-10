import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports Clean Architecture & Models
import '../../../../common/widgets/NotificationIconBtn.dart';
import '../../../../common/widgets/cube_magic.dart';
import '../../../../core/providers/notification_provider.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';

// Booking Imports
import '../../../booking/data/datasources/booking_remote_data_source.dart';
import '../../../booking/data/models/live_trip_location.dart';
import '../../../booking/data/models/program_model.dart';
import '../../../booking/domain/repositories/booking_repository.dart';
import '../../../booking/presentation/screens/all_itineraire_screen.dart';
import '../../../booking/presentation/screens/search_results_screen.dart';
// ⚠️ Assure-toi que ce chemin d'import est correct par rapport à ton projet
import '../../../../common/widgets/BookingConfigurationSheet.dart';

// Wallet Imports
import '../../../wallet/data/datasources/wallet_remote_data_source.dart';
import '../../../wallet/domain/repositories/wallet_repository.dart';
import 'wallet_screen.dart';

// Alert/Live Trip Imports
import '../../../booking/data/models/active_reservation_model.dart';
import '../../../booking/domain/repositories/alert_repository.dart';

import 'notification_screen.dart';
import 'profil_screen.dart';

class HomeTabScreen extends StatefulWidget {
  final bool isModificationMode;
  final String? initialDepart;
  final String? initialArrivee;
  final DateTime? initialDate;
  final bool ticketWasAllerRetour;

  const HomeTabScreen({
    super.key,
    this.isModificationMode = false, // Par défaut à false (mode normal)
    this.initialDepart,
    this.initialArrivee,
    this.initialDate, // 🟢 2. AJOUT AU CONSTRUCTEUR
    this.ticketWasAllerRetour = false, // Par défaut false
  });

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen>
    with TickerProviderStateMixin {
  // --- ETAT FORMULAIRE ---
  String? departureCity;
  String? arrivalCity;
  DateTime? departureDate;

  Dio dio = Dio();

  // --- ETAT DONNÉES ---
  List<String> cities = [];
  List<ProgramModel> weeklyItineraries = [];
  bool isLoadingCities = true;
  bool isLoadingTrips = true;

  // --- ETAT WALLET ---
  int? walletBalance;
  bool isLoadingWallet = true;

  // --- ETAT LIVE TRIP ---
  List<ActiveReservationModel> activeReservations = [];
  bool isLoadingLiveTrip = true;
  bool isLiveExpanded = false;

  // --- ETAT INTERACTION (OVERLAY) ---
  OverlayEntry? _overlayEntry;

  LiveTripLocation? liveTrip; // null au départ

  // --- ANIMATIONS ---
  late AnimationController _busController;
  late Animation<double> _busAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late BookingRepositoryImpl _bookingRepository;
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();
    fetchLiveTrip();

    // 🟢 AJOUTE CE BLOC ICI
    if (widget.isModificationMode) {
      departureCity = widget.initialDepart;
      arrivalCity = widget.initialArrivee;
      // Optionnel : Si tu veux pré-remplir la date avec aujourd'hui ou demain par défaut
      if (widget.initialDate != null) {
        departureDate = widget.initialDate;
      }

      // 🔒 VERROUILLAGE DU TYPE DE VOYAGE
      // Si on modifie, on force la valeur du ticket original
      //isAllerRetour = widget.ticketWasAllerRetour;
    }

    _initData();

    _entranceController = AnimationController(
      duration: const Duration(
        milliseconds: 1000,
      ), // <--- CHANGE ICI (3000 -> 800)
      vsync: this,
    );

    // Déclencher l'animation dès que l'écran est chargé
    _entranceController.forward();

    // 1. Animation du petit bus
    _busController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _busAnimation = Tween<double>(
      begin: -3.0,
      end: 3.0,
    ).animate(CurvedAnimation(parent: _busController, curve: Curves.easeInOut));
    _busController.repeat(reverse: true);

    // 2. Animation de Pulsation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userProvider = context.read<UserProvider>();
      if (userProvider.user == null) {
        userProvider.loadUser();
      }
    });

    // ✅ On charge les notifs
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationProvider>(
        context,
        listen: false,
      ).fetchUnreadCount();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _busController.dispose();
    _pulseController.dispose();
    _removeOverlay(); // Important de nettoyer l'overlay
    super.dispose();
  }

  Future<void> fetchLiveTrip() async {
    try {
      final response = await dio.get('/user/tracking/location'); // ton dio
      if (response.statusCode == 200 && response.data['success'] == true) {
        setState(() {
          liveTrip = LiveTripLocation.fromJson(response.data);
        });
      }
    } catch (e) {
      debugPrint("Erreur fetchLiveTrip: $e");
    }
  }

  void _initData() async {
    final dio = Dio(
      BaseOptions(
        baseUrl: 'https://car225.com/api/',
        headers: {'Content-Type': 'application/json'},
      ),
    );

    final bookingDataSource = BookingRemoteDataSourceImpl(dio: dio);
    _bookingRepository = BookingRepositoryImpl(
      remoteDataSource: bookingDataSource,
    );

    _loadBookingData();
    _fetchWalletBalance();
    _fetchActiveReservations();
  }

  Future<void> _loadBookingData() async {
    // 1. CHARGEMENT DES VILLES
    try {
      final loadedCities = await _bookingRepository.getCities();

      debugPrint("📋 API Villes chargées : $loadedCities");

      String? matchDepart;
      String? matchArrivee;

      // SI MODE MODIFICATION : On cherche la correspondance
      if (widget.isModificationMode) {
        // --- CORRECTION : NETTOYAGE DES NOMS ---
        // On prend "Abidjan, Côte d'Ivoire", on coupe à la virgule, on garde "Abidjan"
        final cleanTicketDepart =
            widget.initialDepart?.split(',').first.trim().toLowerCase() ?? "";
        final cleanTicketArrivee =
            widget.initialArrivee?.split(',').first.trim().toLowerCase() ?? "";

        debugPrint("🔧 MODE MODIFICATION - Recherche:");
        debugPrint("   -> Ticket Nettoyé (Départ) : '$cleanTicketDepart'");
        debugPrint("   -> Ticket Nettoyé (Arrivée) : '$cleanTicketArrivee'");

        // RECHERCHE DANS LA LISTE API
        if (cleanTicketDepart.isNotEmpty) {
          try {
            // On cherche une ville API qui ressemble à "abidjan"
            matchDepart = loadedCities.firstWhere(
              (apiCity) => apiCity.trim().toLowerCase() == cleanTicketDepart,
              orElse: () => "",
            );
          } catch (e) {
            matchDepart = null;
          }
        }

        if (cleanTicketArrivee.isNotEmpty) {
          try {
            matchArrivee = loadedCities.firstWhere(
              (apiCity) => apiCity.trim().toLowerCase() == cleanTicketArrivee,
              orElse: () => "",
            );
          } catch (e) {
            matchArrivee = null;
          }
        }
      }

      if (mounted) {
        setState(() {
          cities = loadedCities;
          isLoadingCities = false;

          // 🎯 APPLICATION DES VALEURS TROUVÉES
          if (matchDepart != null && matchDepart!.isNotEmpty) {
            departureCity =
                matchDepart; // On met la valeur EXACTE de la liste API
            debugPrint("✅ Succès : Départ pré-rempli avec '$departureCity'");
          }

          if (matchArrivee != null && matchArrivee!.isNotEmpty) {
            arrivalCity =
                matchArrivee; // On met la valeur EXACTE de la liste API
            debugPrint("✅ Succès : Arrivée pré-remplie avec '$arrivalCity'");
          }
        });
      }
    } catch (e) {
      debugPrint("🚨 Erreur villes : $e");
      if (mounted) setState(() => isLoadingCities = false);
    }

    // 2. CHARGEMENT DES ITINÉRAIRES
    try {
      final trips = await _bookingRepository.getAllTrips();
      if (mounted)
        setState(() {
          weeklyItineraries = trips.take(2).toList();
          isLoadingTrips = false;
        });
    } catch (e) {
      if (mounted) setState(() => isLoadingTrips = false);
    }
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token != null) {
        final dioWallet = Dio(
          BaseOptions(
            baseUrl: 'https://car225.com/api/',
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        final walletRepo = WalletRepository(
          remoteDataSource: WalletRemoteDataSourceImpl(dio: dioWallet),
        );
        final walletData = await walletRepo.getWalletData();
        if (mounted)
          setState(() {
            walletBalance = walletData.solde;
            isLoadingWallet = false;
          });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingWallet = false);
    }
  }

  Future<void> _fetchActiveReservations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token != null) {
        final dioAlert = Dio(
          BaseOptions(
            baseUrl: 'https://car225.com/api/',
            headers: {'Authorization': 'Bearer $token'},
          ),
        );
        final alertRepo = AlertRepository(dio: dioAlert);
        final reservations = await alertRepo.getActiveReservations();
        if (mounted) {
          setState(() {
            activeReservations = reservations;
            isLoadingLiveTrip = false;
          });
        }
      } else {
        setState(() => isLoadingLiveTrip = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingLiveTrip = false);
    }
  }

  String _formatCurrency(int amount) => NumberFormat.currency(
    locale: 'fr_FR',
    symbol: 'F',
    decimalDigits: 0,
  ).format(amount).trim();

  Future<void> _selectDepartureDate() async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    DateTime initialDateToShow = departureDate ?? tomorrow;
    if (initialDateToShow.isBefore(tomorrow)) initialDateToShow = tomorrow;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDateToShow,
      firstDate: tomorrow,
      lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
      locale: const Locale("fr", "FR"),
    );
    if (picked != null) setState(() => departureDate = picked);
  }

  // ===========================================================================
  // 🔔 GESTION NOTIFICATION TOP & VALIDATION
  // ===========================================================================

  void _showTopNotification(String message, {bool isError = true}) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, // Position en haut
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFF222222) : Colors.green.shade700,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isError ? Icons.info_outline : Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Suppression automatique après 3 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        try {
          overlayEntry.remove();
        } catch (e) {
          // Ignore si déjà retiré
        }
      }
    });
  }

  void _onSearchPressed() async {
    // ⚠️ Ajoute 'async' ici
    // Validation
    if (departureCity == null || arrivalCity == null || departureDate == null) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    String dateDepartApi = DateFormat('yyyy-MM-dd').format(departureDate!);
    final searchParams = {
      "depart": departureCity,
      "arrivee": arrivalCity,
      "date": dateDepartApi,
    };

    // 🟢 NAVIGATION AVEC ATTENTE DE RÉSULTAT (AWAIT)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SearchResultsScreen(
          // On passe le mode modification à l'écran suivant
          isGuestMode: false,
          searchParams: searchParams,
          isModificationMode: widget.isModificationMode,

          // 🚨 C'EST ICI LA SOURCE DU PROBLÈME SI TU L'OUBLIES
          ticketWasAllerRetour: widget.ticketWasAllerRetour,
        ),
      ),
    );

    // 🟢 GESTION DU RETOUR (Le Relais)
    // Si on est en mode modif et qu'on a reçu des données de SearchResults -> SeatSelection
    if (widget.isModificationMode && result != null) {
      // On ferme HomeTabScreen et on renvoie le résultat à TicketDetailScreen
      if (mounted) {
        Navigator.pop(context, result);
      }
    }
  }

  // ===========================================================================
  // 🧠 LOGIQUE D'OVERLAY ET RÉSERVATION
  // ===========================================================================

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
            child: Container(
              color: Colors.black.withOpacity(0.8),
              width: double.infinity,
              height: double.infinity,
            ),
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
              elevation: 0,
              borderRadius: BorderRadius.circular(15),
              child: _buildCompanyCard(context, program: program),
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

  void _handleBookingLogic(ProgramModel program) {
    _removeOverlay();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingConfigurationSheet(
        program: program,
        repository: _bookingRepository,
      ),
    );
  }

  Widget _buildAnimatedBlock({
    required Widget child,
    required double delay, // Entre 0.0 et 1.0 (début de l'animation)
  }) {
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(delay, delay + 0.4, curve: Curves.easeOutQuart),
    );

    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(
              0,
              50 * (1 - animation.value),
            ), // Glisse de 50px vers le haut
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // ✅ 1. LE SINGLE CHILD SCROLL VIEW RESTE ICI
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        // ✅ 2. AJOUT DU STACK ICI
        child: Stack(
          children: [
            // --- CONTENU DE TA PAGE ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAnimatedBlock(delay: 0.0, child: _buildHeader(context)),
                _buildAnimatedBlock(
                  delay: 0.2,
                  child: Transform.translate(
                    offset: const Offset(0, -60),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildSearchCard(context),
                    ),
                  ),
                ),
                _buildAnimatedBlock(
                  delay: 0.4,
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: _buildPromoBanner(isDark),
                  ),
                ),
                const Gap(15),
                _buildAnimatedBlock(
                  delay: 0.6,
                  child: Transform.translate(
                    offset: const Offset(0, -40),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildItinerairesSection(textColor),
                    ),
                  ),
                ),
                const SizedBox(height: 120),
              ],
            ),

            // --- 🔴 3. LE BADGE FLOTTANT PAR-DESSUS TOUT ---
            if (liveTrip != null)
              Positioned(
                // Calcul : Header (340) - Remontée carte (60) - Moitié du badge (18) = 262
                top: 262,
                left: 0,
                right: 0,
                child: _buildAnimatedBlock(
                  delay: 0.3, // Il apparaitra juste après la carte
                  child: _buildLiveTripPulseBadgeFromLocation(liveTrip!),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPromoBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF263238) : const Color(0xFF37474F),
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

          // --- LE BOUTON MODIFIÉ ICI ---
          Container(
            width: double.infinity,
            height: 50,
            // ✅ 1. On coupe l'image pour qu'elle respecte les bords arrondis
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              // ✅ 2. On met l'image ici
              image: const DecorationImage(
                image: AssetImage("assets/images/row.jpg"),
                fit: BoxFit.cover,
              ),
            ),
            child: ElevatedButton(
              onPressed: _onSearchPressed,
              style: ElevatedButton.styleFrom(
                // ✅ 3. On rend le fond du bouton TRANSPARENT pour voir l'image derrière
                backgroundColor: const Color(0xFF07AC4C),
                shadowColor: Colors.transparent,
                elevation: 0,
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
          // -----------------------------
        ],
      ),
    );
  }

  Widget _buildItinerairesSection(Color? textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // TITRE (Sans le bouton "Voir tout" qui buggait)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            "Itinéraire de la semaine",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ),

        const Gap(15),

        // LISTE HORIZONTALE
        SizedBox(
          height: 240,
          child: isLoadingTrips
              ? const Center(child: CircularProgressIndicator())
              : weeklyItineraries.isEmpty
              ? const Center(child: Text("Aucun itinéraire disponible"))
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  // IMPORTANT : On ajoute +1 pour la carte "Voir tout"
                  itemCount: weeklyItineraries.length + 1,
                  separatorBuilder: (context, index) => const Gap(15),
                  itemBuilder: (context, index) {
                    // Si c'est le dernier élément, on affiche la carte "Voir tout"
                    if (index == weeklyItineraries.length) {
                      return _buildSeeAllCard();
                    }

                    // Sinon, on affiche la carte normale
                    final program = weeklyItineraries[index];
                    return Builder(
                      builder: (itemContext) {
                        return GestureDetector(
                          onTap: () =>
                              _showSelectionOverlay(itemContext, program),
                          child: SizedBox(
                            width: 200,
                            child: _buildCompanyCard(context, program: program),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final List<String> headerImages = [
      "assets/images/busheader3.jpg",
      "assets/images/busheader4.jpg",
      "assets/images/busheader5.jpg",
    ];

    final hasActiveTrip = activeReservations.isNotEmpty;
    final headerHeight = 340.0;
    final searchCardOffset = 60.0;

    return SizedBox(
      height: 340,
      width: MediaQuery.of(context).size.width,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // --- 1. ARRIÈRE-PLAN ---
          SimpleHeaderBackground(height: 340, images: headerImages),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // --- 2. CONTENU (AppBar Custom) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              // 🟢 CORRECTION 1 : J'ai réduit le padding à droite (right: 10 au lieu de 20)
              // Ça rapproche naturellement tout le bloc de droite vers le bord
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 20.0,
                  right: 20,
                  top: 15.0,
                  bottom: 15.0,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // 1. AVATAR
                    Consumer<UserProvider>(
                      builder: (context, provider, child) {
                        final user = provider.user;
                        return GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ProfileScreen(),
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: CircleAvatar(
                              radius: 22,
                              backgroundColor: Colors.white24,
                              backgroundImage: user != null
                                  ? NetworkImage(user.fullPhotoUrl)
                                  : const AssetImage("assets/images/ci.jpg")
                                        as ImageProvider,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(width: 12),

                    // 2. WALLET
                    Flexible(
                      fit: FlexFit.loose,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.5,
                        ),
                        child: GestureDetector(
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const WalletScreen(),
                              ),
                            );
                            _fetchWalletBalance();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ), // Padding légèrement augmenté
                            decoration: BoxDecoration(
                              // 🟢 CHANGEMENT 1 : Fond noir semi-transparent au lieu de blanc pour maximiser le contraste
                              color: Colors.black.withOpacity(0.45),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.15),
                              ),
                              // 🟢 CHANGEMENT 2 : Ajout d'une ombre douce pour détacher le bloc de l'image
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(
                                    5,
                                  ), // Icône très légèrement plus grande
                                  decoration: const BoxDecoration(
                                    color: AppColors.secondary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        "CarPay",
                                        style: TextStyle(
                                          // 🟢 CHANGEMENT 3 : Blanc pur, plus grand, plus gras
                                          color: Colors.white,
                                          fontSize: 11, // Passé de 9 à 11
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 0.5,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                      const SizedBox(
                                        height: 1,
                                      ), // Petit espace de respiration
                                      isLoadingWallet
                                          ? const SizedBox(
                                              width: 10,
                                              height: 10,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 1,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              walletBalance != null
                                                  ? _formatCurrency(
                                                      walletBalance!,
                                                    )
                                                  : "0 F",
                                              style: const TextStyle(
                                                // 🟢 CHANGEMENT 4 : Solde plus lisible
                                                color: Colors.white,
                                                fontSize:
                                                    13, // Passé de 11 à 13
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                              softWrap: false,
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 3. SPACER
                    const Spacer(),

                    // 4. NOTIFICATION
                    // 🟢 CORRECTION 2 : Transform.translate force le bouton à se décaler.
                    // J'ai mis 8 pixels vers la droite. Si tu veux le coller encore plus, augmente ce chiffre (ex: 12).
                    Transform.translate(
                      offset: const Offset(8, 0),
                      child: const NotificationIconBtn(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- 3. BADGE LIVE TRIP au centre bas du header ---
          if (liveTrip != null) _buildLiveTripPulseBadgeFromLocation(liveTrip!),
        ],
      ),
    );
  }

  Widget _buildLiveTripPulseBadgeFromLocation(LiveTripLocation trip) {
    // ✅ On retire le Positioned, on retourne directement le Center
    return Center(
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          final scale = isLiveExpanded ? 1.0 : _pulseAnimation.value;
          return Transform.scale(scale: scale, child: child);
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              setState(() {
                isLiveExpanded = !isLiveExpanded;
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              width: isLiveExpanded ? 240 : 85,
              height: isLiveExpanded ? 90 : 36,
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.6),
                    blurRadius: isLiveExpanded ? 5 : 10,
                    spreadRadius: isLiveExpanded ? 0 : 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "LIVE",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Icon(
                            isLiveExpanded
                                ? Icons.close
                                : Icons.arrow_drop_down,
                            color: Colors.white,
                            size: isLiveExpanded ? 14 : 16,
                          ),
                        ],
                      ),
                      if (isLiveExpanded) ...[
                        const SizedBox(height: 8),
                        Container(height: 1, color: Colors.white24),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                trip.depart,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 5),
                              child: Icon(
                                Icons.directions_bus,
                                color: Colors.white,
                                size: 14,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                trip.arrivee,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.right,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          trip.tempsRestant,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletButton() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const WalletScreen()),
        );
        _fetchWalletBalance();
      },
      child: Container(
        // ✅ STOP OVERFLOW : On limite physiquement la largeur max
        constraints: const BoxConstraints(maxWidth: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min, // Le bouton prend le minimum de place
          children: [
            // Icône
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.secondary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 10,
              ),
            ),

            const SizedBox(width: 8),

            // Texte + Montant
            // 2. WALLET (CORRIGÉ)
            Flexible(
              // FlexFit.loose permet au bouton de garder sa taille naturelle (petite)
              // mais de rétrécir si l'espace manque.
              fit: FlexFit.loose,
              child: GestureDetector(
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const WalletScreen(),
                    ),
                  );
                  _fetchWalletBalance();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min, // Important : le Row colle au contenu
                    children: [
                      // Icône Wallet
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 10,
                        ),
                      ),

                      const SizedBox(
                        width: 8,
                      ), // Préférable à Gap ici pour éviter des soucis de layout
                      // TEXTE + MONTANT
                      // C'est ce Flexible interne qui résout l'overflow du texte
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "CarPay",
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              softWrap: false, // Force une seule ligne
                            ),
                            isLoadingWallet
                                ? const SizedBox(
                                    width: 10,
                                    height: 10,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    walletBalance != null
                                        ? _formatCurrency(walletBalance!)
                                        : "0 F",
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    softWrap: false,
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeeAllCard() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AllItinerariesScreen()),
        );
      },
      child: Container(
        width: 160, // Un peu plus petit que les cartes normales
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_forward,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const Gap(10),
            const Text(
              "Voir tous\nles trajets",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final hasActiveTrip = activeReservations.isNotEmpty;

    // 🔒 LOGIQUE DE VERROUILLAGE
    // Est verrouillé SI : On est en mode modif ET que le ticket original était un Aller-Retour
    bool isRouteLocked =
        widget.isModificationMode && widget.ticketWasAllerRetour;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
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
              // --- 1. TITRE ---
              Padding(
                padding: EdgeInsets.only(right: hasActiveTrip ? 60.0 : 0),
                child: Text(
                  widget.isModificationMode
                      ? "Modifier votre voyage"
                      : "Où souhaitez-vous voyager ?",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // --- 2. SOUS-TITRE (Alerte si bloqué) ---
              if (isRouteLocked)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Row(
                    children: const [
                      Icon(Icons.lock, size: 12, color: Colors.orange),
                      SizedBox(width: 5),
                      Text(
                        "Trajet non modifiable pour un Aller-Retour",
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              else
                const Text(
                  "Trouvez votre bus en quelques clics",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),

              const Gap(20),

              // --- 3. LES DROPDOWNS (VILLES) ---
              isLoadingCities
                  ? const Center(child: LinearProgressIndicator())
                  : Row(
                      children: [
                        // VILLE DÉPART
                        /*Expanded(
                              child: _buildRealDropdown(
                                  context,
                                  "Départ",
                                  departureCity,
                                  cities,
                                  "assets/images/map.png",
                                  // 🔒 SI BLOQUÉ : on passe null (ce qui désactive le clic)
                                  // SINON : on passe la fonction normale
                                  isRouteLocked ? null : (val) => setState(() => departureCity = val)
                              )
                          ),
                          const Gap(10),
                          // VILLE ARRIVÉE
                          Expanded(
                              child: _buildRealDropdown(
                                  context,
                                  "Destination",
                                  arrivalCity,
                                  cities,
                                  "assets/images/map.png",
                                  // 🔒 IDEM ICI
                                  isRouteLocked ? null : (val) => setState(() => arrivalCity = val),
                                  isGreen: true
                              )
                          )*/
                        Expanded(
                          child: _buildCitySearchSelector(
                            context: context,
                            label: "Départ",
                            value: departureCity,
                            cities: cities,
                            icon: Icons.location_on,
                            enabled: !isRouteLocked,
                            onSelected: (val) =>
                                setState(() => departureCity = val),
                          ),
                        ),
                        const Gap(10),
                        Expanded(
                          child: _buildCitySearchSelector(
                            context: context,
                            label: "Destination",
                            value: arrivalCity,
                            cities: cities,
                            icon: Icons.flag,
                            enabled: !isRouteLocked,
                            isGreen: true,
                            onSelected: (val) =>
                                setState(() => arrivalCity = val),
                          ),
                        ),
                      ],
                    ),

              const Gap(15),

              // --- 4. DATE (Toujours modifiable) ---
              GestureDetector(
                onTap: _selectDepartureDate,
                child: SizedBox(
                  width: double.infinity,
                  child: _buildDateField(
                    context,
                    "Date du voyage",
                    departureDate,
                  ),
                ),
              ),

              const Gap(20),

              // --- 5. BOUTON RECHERCHER ---
              Container(
                width: double.infinity,
                height: 50,
                clipBehavior: Clip.hardEdge,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  image: const DecorationImage(
                    image: AssetImage("assets/images/tabaa.jpg"),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _onSearchPressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
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
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Badge pulse si voyage en cours (Masqué en mode modif pour épurer)
      ],
    );
  }

  Widget _buildCitySearchSelector({
    required BuildContext context,
    required String label,
    required String? value,
    required List<String> cities,
    required IconData icon,
    required bool enabled,
    required Function(String) onSelected,
    bool isGreen = false,
  }) {
    final color = isGreen ? Colors.green : AppColors.primary;

    return GestureDetector(
      onTap: !enabled
          ? null
          : () => _openCitySearchSheet(
              context: context,
              title: label,
              cities: cities,
              onSelected: onSelected,
            ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: enabled ? Colors.grey.shade100 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value ?? label,
                style: TextStyle(
                  color: value == null ? Colors.grey : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, size: 18),
          ],
        ),
      ),
    );
  }

  void _openCitySearchSheet({
    required BuildContext context,
    required String title,
    required List<String> cities,
    required Function(String) onSelected,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        List<String> filteredCities = List.from(cities);
        final TextEditingController controller = TextEditingController();

        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // 🔍 Champ de recherche
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Rechercher une ville...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          filteredCities = cities
                              .where(
                                (c) => c.toLowerCase().contains(
                                  value.toLowerCase(),
                                ),
                              )
                              .toList();
                        });
                      },
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 📜 Liste filtrée
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredCities.length,
                      itemBuilder: (context, index) {
                        final city = filteredCities[index];
                        return ListTile(
                          title: Text(city),
                          onTap: () {
                            Navigator.pop(context);
                            onSelected(city);
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLiveTripPulseBadge(ActiveReservationModel trip) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          setState(() {
            isLiveExpanded = !isLiveExpanded;
          });
        },
        child: AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isLiveExpanded ? 1.0 : _pulseAnimation.value,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                width: isLiveExpanded ? 220 : 85,
                height: isLiveExpanded ? 90 : 36,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.6),
                      blurRadius: isLiveExpanded
                          ? 5
                          : 10 * _pulseAnimation.value,
                      spreadRadius: isLiveExpanded ? 0 : 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              "LIVE",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          isLiveExpanded ? Icons.close : Icons.arrow_drop_down,
                          color: Colors.white,
                          size: isLiveExpanded ? 14 : 16,
                        ),
                      ],
                    ),
                    if (isLiveExpanded) ...[
                      const SizedBox(height: 8),
                      Container(height: 1, color: Colors.white24),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              trip.pointDepart,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AnimatedBuilder(
                            animation: _busAnimation,
                            builder: (context, child) {
                              return Transform.translate(
                                offset: Offset(_busAnimation.value, 0),
                                child: const Icon(
                                  Icons.directions_bus,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              );
                            },
                          ),
                          Expanded(
                            child: Text(
                              trip.pointArrive,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildRealDropdown(
    BuildContext context,
    String label,
    String? currentValue,
    List<String> items,
    String iconPath,
    Function(String?)? onChanged, { // Peut être null
    bool isGreen = false,
  }) {
    // ✅ DÉTECTION : Si onChanged est null, le champ est désactivé
    final bool isDisabled = onChanged == null;
    final cardColor = Theme.of(context).cardColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            // 🎨 COULEUR : Gris clair si désactivé, couleur carte si actif
            color: isDisabled ? Colors.grey.shade200 : cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              // Icône grisée si désactivé
              Image.asset(
                iconPath,
                width: 20,
                color: isDisabled
                    ? Colors.grey
                    : (isGreen ? Colors.green : Colors.blue),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentValue,
                    // Texte grisé si désactivé
                    hint: Text(
                      "Choisir",
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                    isExpanded: true,
                    // On cache la flèche si désactivé
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: isDisabled ? Colors.transparent : Colors.grey,
                    ),

                    // ⚡ C'est ici que Flutter bloque l'interaction si c'est null
                    onChanged: onChanged,

                    items: items.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: TextStyle(
                            fontSize: 14,
                            // Texte grisé dans la liste aussi si jamais
                            color: isDisabled ? Colors.grey : Colors.black,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // 🔒 PETIT CADENAS VISUEL À DROITE
              if (isDisabled)
                const Icon(Icons.lock, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateField(
    BuildContext context,
    String label,
    DateTime? date, {
    bool isOptional = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    String text = date == null
        ? "Sélectionner une date"
        : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
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
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: isOptional ? Colors.orange.withOpacity(0.5) : borderColor,
            ),
            borderRadius: BorderRadius.circular(10),
            color: isOptional ? Colors.orange.withOpacity(0.05) : null,
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: isOptional ? Colors.orange : Colors.grey,
                size: 18,
              ),
              const Gap(10),
              Expanded(
                child: Text(
                  text,
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

  Color _getCompanyColor(String name) {
    if (name.toLowerCase().contains("utb")) return const Color(0xFFCA8A04);
    if (name.toLowerCase().contains("fabiola")) return const Color(0xFF15803D);
    return AppColors.primary;
  }

  Widget _buildCompanyCard(
    BuildContext context, {
    required ProgramModel program,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark
        ? Colors.black.withOpacity(0.3)
        : Colors.grey.withOpacity(0.1);

    final List<String> busImages = [
      "assets/images/busheader.jpg",
      "assets/images/busheader1.jpg",
      "assets/images/busheader2.jpg",
    ];

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
          // =========================================================
          // PARTIE 1 : IMAGE, BADGES ET NOM COMPAGNIE (HAUT)
          // =========================================================
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(15),
              topRight: Radius.circular(15),
            ),
            child: SizedBox(
              height: 100,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Image de fond (Slider)
                  SlidingHeaderBackground(height: 100, images: busImages),

                  // 2. Filtre sombre pour lisibilité
                  Container(color: Colors.black.withOpacity(0.3)),

                  // 3. Contenu par-dessus l'image
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ligne du haut : Badge "Standard" et Note Étoile
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Badge Standard
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                ),
                              ),
                              child: const Text(
                                "Standard",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                            // Badge Note (Étoile)
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
                                children: const [
                                  Icon(
                                    Icons.star,
                                    color: Colors.orange,
                                    size: 10,
                                  ),
                                  Gap(2),
                                  Text(
                                    "4.5",
                                    style: TextStyle(
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

                        // Ligne du bas : Point de couleur et Nom Compagnie
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: _getCompanyColor(program.compagnieName),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Gap(6),
                            Expanded(
                              child: Text(
                                program.compagnieName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 2),
                                  ],
                                ),
                                overflow: TextOverflow.ellipsis,
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
          ),

          // =========================================================
          // PARTIE 2 : DÉTAILS TRAJET ET PRIX (BAS)
          // =========================================================
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Trajet (Ville A -> Ville B)
                  Text(
                    "${program.villeDepart} ➝ ${program.villeArrivee}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textColor,
                    ),
                  ),

                  // Prix et Heure
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${program.prix} F",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        "Départ: ${program.heureDepart}",
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
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
}

// ===========================================================================
// 🖌️ CLASSES UTILITAIRES POUR L'OVERLAY (BRANCHE + BOUTON)
// ===========================================================================

class _BranchAndButtonWidget extends StatelessWidget {
  final VoidCallback onBookPressed;
  final double cardWidth;

  const _BranchAndButtonWidget({
    required this.onBookPressed,
    required this.cardWidth,
  });

  /*  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomPaint(
          size: Size(cardWidth, 80),
          painter: _BranchPainter(color: AppColors.primary),
        ),
        Positioned(
          top: 50,
          left: (cardWidth / 2) - 70, // Centré
          child: ScaleTransition(
            scale: const AlwaysStoppedAnimation(1.0),
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
  }*/

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
              // ✅ Coupe l'image selon l'arrondi
              clipBehavior: Clip.hardEdge,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                // ✅ L'image de fond
                image: const DecorationImage(
                  image: AssetImage("assets/images/tabaa.jpg"),
                  fit: BoxFit.cover,
                ),
                // On recrée l'ombre ici car le bouton sera transparent
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: onBookPressed,
                style: ElevatedButton.styleFrom(
                  // ✅ Fond transparent
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  elevation: 0,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Réserver",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Gap(8),
                    Icon(Icons.arrow_forward, size: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

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
    double startX = size.width / 2;
    double startY = -5; // Connecté au bas de la carte
    double endX = size.width / 2;
    double endY = 50;

    path.moveTo(startX, startY);
    path.quadraticBezierTo(startX - 20, (endY - startY) / 2, endX, endY);
    canvas.drawCircle(Offset(startX, startY), 4, Paint()..color = color);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
