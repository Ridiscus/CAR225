import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Imports Clean Architecture & Models
import '../../../../common/widgets/cube_magic.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';

// Booking Imports
import '../../../booking/data/datasources/booking_remote_data_source.dart';
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
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> with TickerProviderStateMixin {
  // --- ETAT FORMULAIRE ---
  String? departureCity;
  String? arrivalCity;
  DateTime? departureDate;

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
    _initData();


    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Déclencher l'animation dès que l'écran est chargé
    _entranceController.forward();

    // 1. Animation du petit bus
    _busController = AnimationController(duration: const Duration(seconds: 2), vsync: this);
    _busAnimation = Tween<double>(begin: -3.0, end: 3.0).animate(
      CurvedAnimation(parent: _busController, curve: Curves.easeInOut),
    );
    _busController.repeat(reverse: true);

    // 2. Animation de Pulsation
    _pulseController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);
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
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _busController.dispose();
    _pulseController.dispose();
    _removeOverlay(); // Important de nettoyer l'overlay
    super.dispose();
  }

  void _initData() async {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
      headers: {'Content-Type': 'application/json'},
    ));

    final bookingDataSource = BookingRemoteDataSourceImpl(dio: dio);
    _bookingRepository = BookingRepositoryImpl(remoteDataSource: bookingDataSource);

    _loadBookingData();
    _fetchWalletBalance();
    _fetchActiveReservations();
  }

  Future<void> _loadBookingData() async {
    try {
      final loadedCities = await _bookingRepository.getCities();
      if (mounted) setState(() { cities = loadedCities; isLoadingCities = false; });
    } catch (e) { if(mounted) setState(() => isLoadingCities = false); }

    try {
      final trips = await _bookingRepository.getAllTrips();
      if (mounted) setState(() { weeklyItineraries = trips.take(2).toList(); isLoadingTrips = false; });
    } catch (e) { if(mounted) setState(() => isLoadingTrips = false); }
  }

  Future<void> _fetchWalletBalance() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');
      if (token != null) {
        final dioWallet = Dio(BaseOptions(baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api', headers: {'Authorization': 'Bearer $token'}));
        final walletRepo = WalletRepository(remoteDataSource: WalletRemoteDataSourceImpl(dio: dioWallet));
        final walletData = await walletRepo.getWalletData();
        if (mounted) setState(() { walletBalance = walletData.solde; isLoadingWallet = false; });
      }
    } catch (e) { if (mounted) setState(() => isLoadingWallet = false); }
  }

  Future<void> _fetchActiveReservations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('auth_token');

      if (token != null) {
        final dioAlert = Dio(BaseOptions(
          baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
          headers: {'Authorization': 'Bearer $token'},
        ));
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

  String _formatCurrency(int amount) => NumberFormat.currency(locale: 'fr_FR', symbol: 'F', decimalDigits: 0).format(amount).trim();

  Future<void> _selectDepartureDate() async {
    final DateTime now = DateTime.now();
    final DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);
    DateTime initialDateToShow = departureDate ?? tomorrow;
    if (initialDateToShow.isBefore(tomorrow)) initialDateToShow = tomorrow;

    final DateTime? picked = await showDatePicker(
      context: context, initialDate: initialDateToShow, firstDate: tomorrow, lastDate: DateTime(now.year + 1),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
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
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isError ? Icons.info_outline : Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
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




  void _onSearchPressed() {
    // ⚠️ ICI : On utilise la Top Notification au lieu du SnackBar
    if (departureCity == null || arrivalCity == null || departureDate == null) {
      _showTopNotification("Veuillez remplir tous les champs", isError: true);
      return;
    }

    String dateDepartApi = DateFormat('yyyy-MM-dd').format(departureDate!);
    final searchParams = {"depart": departureCity, "arrivee": arrivalCity, "date": dateDepartApi};
    Navigator.push(context, MaterialPageRoute(builder: (context) => SearchResultsScreen(isGuestMode: false, searchParams: searchParams)));
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
            offset: Offset(0, 50 * (1 - animation.value)), // Glisse de 50px vers le haut
            child: child,
          ),
        );
      },
      child: child,
    );
  }









  // Modifie ton _buildAnimatedBlock pour qu'il ne bloque pas les clics
  /*Widget _buildAnimatedBlock({
    required Widget child,
    required double delay,
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
            // On garde l'animation de montée, mais on s'assure qu'elle finit à 0
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }*/

// DANS TON BUILD :
  /*@override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. HEADER
            _buildAnimatedBlock(
              delay: 0.0,
              child: _buildHeader(context),
            ),

            // 2. CARTE RECHERCHE
            // On applique le décalage de -80 ICI, en dehors de l'animation
            Transform.translate(
              offset: const Offset(0, -80),
              child: _buildAnimatedBlock(
                delay: 0.2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchCard(context),
                ),
              ),
            ),

            // 3. BANNIÈRE
            Transform.translate(
              offset: const Offset(0, -60),
              child: _buildAnimatedBlock(
                delay: 0.4,
                child: Container( /* ... ton code de bannière ... */ ),
              ),
            ),

            // 4. ITINÉRAIRES
            Transform.translate(
              offset: const Offset(0, -40),
              child: _buildAnimatedBlock(
                delay: 0.6,
                child: _buildItinerairesSection(textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }*/

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER (Arrive à 0ms)
            _buildAnimatedBlock(
              delay: 0.0,
              child: _buildHeader(context),
            ),

            // 2. CARTE RECHERCHE (Arrive à 200ms)
            // Le Transform est à l'extérieur pour ne pas casser le "HitTest"
            Transform.translate(
              offset: const Offset(0, -80),
              child: _buildAnimatedBlock(
                delay: 0.2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchCard(context),
                ),
              ),
            ),

            // 3. BANNIÈRE PUB (Arrive à 400ms)
            Transform.translate(
              offset: const Offset(0, -60),
              child: _buildAnimatedBlock(
                delay: 0.4,
                child: _buildPromoBanner(isDark), // Je te suggère d'extraire aussi ça si possible
              ),
            ),

            // 4. ITINÉRAIRES (Arrive à 600ms)
            Transform.translate(
              offset: const Offset(0, -40),
              child: _buildAnimatedBlock(
                delay: 0.6,
                child: _buildItinerairesSection(textColor),
              ),
            ),

            const Gap(65),
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
          borderRadius: BorderRadius.circular(15)
      ),
      child: Column(
        children: [
          const Text("Prêt à réserver ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
          const Text("Trouvez votre voyage parfait.", style: TextStyle(color: AppColors.grey)),
          const Gap(15),
          SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                  onPressed: _onSearchPressed,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Réserver maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))
              )
          ),
        ],
      ),
    );
  }




  // ===========================================================================

 /* @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final userProvider = context.watch<UserProvider>();
    final currentUser = userProvider.user;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER
            //_buildHeader(context),

            // 1. HEADER (Arrive en premier)
            _buildAnimatedBlock(
              delay: 0.0,
              child: _buildHeader(context),
            ),

            // 2. CARTE RECHERCHE
            /*Transform.translate(
              offset: const Offset(0, -80),
              child: Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: _buildSearchCard(context)),
            ),*/

            // 2. CARTE RECHERCHE (Arrive juste après)
            Transform.translate(
              offset: const Offset(0, -80),
              child: _buildAnimatedBlock(
                delay: 0.2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildSearchCard(context),
                ),
              ),
            ),

            // 3. BANNIÈRE PUB
            /*Transform.translate(
              offset: const Offset(0, -60),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF263238) : const Color(0xFF37474F), borderRadius: BorderRadius.circular(15)),
                child: Column(
                  children: [
                    const Text("Prêt à réserver ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text("Trouvez votre voyage parfait.", style: TextStyle(color: AppColors.grey)),
                    const Gap(15),
                    SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _onSearchPressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Réserver maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
                  ],
                ),
              ),
            ),*/


            // 3. BANNIÈRE PUB
            _buildAnimatedBlock(
              delay: 0.4,
              child: Transform.translate(
                offset: const Offset(0, -60),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF263238) : const Color(0xFF37474F), borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      const Text("Prêt à réserver ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text("Trouvez votre voyage parfait.", style: TextStyle(color: AppColors.grey)),
                      const Gap(15),
                      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _onSearchPressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Réserver maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
              ),
            ),

            Transform.translate(
              offset: const Offset(0, -60),
              child: _buildAnimatedBlock(
                delay: 0.4,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF263238) : const Color(0xFF37474F), borderRadius: BorderRadius.circular(15)),
                  child: Column(
                    children: [
                      const Text("Prêt à réserver ?", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      const Text("Trouvez votre voyage parfait.", style: TextStyle(color: AppColors.grey)),
                      const Gap(15),
                      SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _onSearchPressed, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF15803D), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text("Réserver maintenant", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
              ),
            ),


            // 4. ITINÉRAIRES AVEC LE NOUVEAU DESIGN
            /*Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Itinéraire de la semaine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),

                          // --- NOUVEAU BOUTON "VOIR TOUT" STYLÉ ---
                          InkWell(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllItinerariesScreen())),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                              ),
                              child: Row(
                                children: const [
                                  Text("Voir tout", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                  Gap(4),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                                ],
                              ),
                            ),
                          ),
                        ]
                    ),
                  ),
                  const Gap(10),
                  SizedBox(
                    height: 240,
                    child: isLoadingTrips
                        ? const Center(child: CircularProgressIndicator())
                        : weeklyItineraries.isEmpty
                        ? const Center(child: Text("Aucun itinéraire disponible"))
                        : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      scrollDirection: Axis.horizontal,
                      itemCount: weeklyItineraries.length,
                      separatorBuilder: (context, index) => const Gap(15),
                      // --- MODIFICATION ICI POUR L'OVERLAY ---
                      itemBuilder: (context, index) {
                        final program = weeklyItineraries[index];
                        return Builder(
                            builder: (itemContext) {
                              return GestureDetector(
                                onTap: () => _showSelectionOverlay(itemContext, program),
                                child: SizedBox(
                                    width: 200,
                                    child: _buildCompanyCard(context, program: program)
                                ),
                              );
                            }
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),*/



            // 4. ITINÉRAIRES (Arrive en dernier)
            /*_buildAnimatedBlock(
              delay: 0.6,
              child: Transform.translate(
                offset: const Offset(0, -40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Itinéraire de la semaine", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),

                            // --- NOUVEAU BOUTON "VOIR TOUT" STYLÉ ---
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AllItinerariesScreen())),
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                                ),
                                child: Row(
                                  children: const [
                                    Text("Voir tout", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                    Gap(4),
                                    Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ]
                      ),
                    ),
                    const Gap(10),
                    SizedBox(
                      height: 240,
                      child: isLoadingTrips
                          ? const Center(child: CircularProgressIndicator())
                          : weeklyItineraries.isEmpty
                          ? const Center(child: Text("Aucun itinéraire disponible"))
                          : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: weeklyItineraries.length,
                        separatorBuilder: (context, index) => const Gap(15),
                        // --- MODIFICATION ICI POUR L'OVERLAY ---
                        itemBuilder: (context, index) {
                          final program = weeklyItineraries[index];
                          return Builder(
                              builder: (itemContext) {
                                return GestureDetector(
                                  onTap: () => _showSelectionOverlay(itemContext, program),
                                  child: SizedBox(
                                      width: 200,
                                      child: _buildCompanyCard(context, program: program)
                                  ),
                                );
                              }
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),*/


            // 4. ITINÉRAIRES (Arrive à 600ms)
            Transform.translate(
              offset: const Offset(0, -40),
              child: _buildAnimatedBlock(
                delay: 0.6,
                child: _buildItinerairesSection(textColor),
              ),
            ),


            const Gap(65),
          ],
        ),
      ),
    );
  }*/




  Widget _buildItinerairesSection(Color? textColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Itinéraire de la semaine",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AllItinerariesScreen())
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: const [
                      Text("Voir tout",
                          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                      Gap(4),
                      Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Gap(10),
        SizedBox(
          height: 240,
          child: isLoadingTrips
              ? const Center(child: CircularProgressIndicator())
              : weeklyItineraries.isEmpty
              ? const Center(child: Text("Aucun itinéraire disponible"))
              : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            scrollDirection: Axis.horizontal,
            itemCount: weeklyItineraries.length,
            separatorBuilder: (context, index) => const Gap(15),
            itemBuilder: (context, index) {
              final program = weeklyItineraries[index];
              return Builder(builder: (itemContext) {
                return GestureDetector(
                  onTap: () => _showSelectionOverlay(itemContext, program),
                  child: SizedBox(
                      width: 200,
                      child: _buildCompanyCard(context, program: program)
                  ),
                );
              });
            },
          ),
        ),
      ],
    );
  }


// 1. On retire "String? photoUrl" des arguments car le Provider s'en occupe
  Widget _buildHeader(BuildContext context) {
    final List<String> headerImages = [
      "assets/images/busheader3.jpg",
      "assets/images/busheader4.jpg",
      "assets/images/busheader5.jpg"
    ];

    return SizedBox(
      height: 340,
      width: double.infinity,
      child: Stack(
        children: [
          // --- ARRIÈRE-PLAN ---
          SimpleHeaderBackground(height: 340, images: headerImages),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.7),
                  Colors.transparent,
                  Colors.black.withOpacity(0.6)
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // --- CONTENU SAFE AREA ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 15.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // =====================================================
                          // ✅ MODIFICATION ICI : CONSUMER POUR L'IMAGE
                          // =====================================================
                          Consumer<UserProvider>(
                            builder: (context, provider, child) {
                              final user = provider.user;

                              // Logique de sécurité pour l'image
                              ImageProvider imageProvider;
                              if (user != null) {
                                // Utilise ton getter intelligent (fullPhotoUrl)
                                imageProvider = NetworkImage(user.fullPhotoUrl);
                              } else {
                                // Image par défaut si pas connecté
                                imageProvider = const AssetImage("assets/images/ci.jpg");
                              }

                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ProfileScreen()),
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2), // Petit bord blanc joli
                                  ),
                                  child: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: imageProvider,
                                    // Évite le crash si l'URL est cassée
                                    onBackgroundImageError: (_, __) {
                                      print("Erreur chargement image header");
                                    },
                                  ),
                                ),
                              );
                            },
                          ),
                          // =====================================================

                          const Gap(12),

                          // --- BOUTON WALLET ---
                          GestureDetector(
                            onTap: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const WalletScreen()),
                              );
                              _fetchWalletBalance();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.secondary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 12),
                                  ),
                                  const Gap(8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text("CarPay", style: TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.bold)),
                                      isLoadingWallet
                                          ? const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white))
                                          : Text(
                                        walletBalance != null ? _formatCurrency(walletBalance!) : "0 F",
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          )
                        ],
                      ),

                      // --- BOUTON NOTIFICATION ---
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationScreen()),
                        ),
                        child: Container(
                          height: 45,
                          width: 45,
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
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSearchCard(BuildContext context) {
    final cardColor = Theme.of(context).cardColor;
    final hasActiveTrip = activeReservations.isNotEmpty;
    return Stack(clipBehavior: Clip.none, children: [
      Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 5))]), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: EdgeInsets.only(right: hasActiveTrip ? 60.0 : 0), child: const Text("Où souhaitez-vous voyager ?", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))), const Text("Trouvez votre bus en quelques clics", style: TextStyle(color: Colors.grey, fontSize: 12)), const Gap(20), isLoadingCities ? const Center(child: LinearProgressIndicator()) : Row(children: [Expanded(child: _buildRealDropdown(context, "Départ", departureCity, cities, "assets/images/map.png", (val) => setState(() => departureCity = val))), const Gap(10), Expanded(child: _buildRealDropdown(context, "Destination", arrivalCity, cities, "assets/images/map.png", (val) => setState(() => arrivalCity = val), isGreen: true))]), const Gap(15), GestureDetector(onTap: _selectDepartureDate, child: SizedBox(width: double.infinity, child: _buildDateField(context, "Date du voyage", departureDate))), const Gap(20), SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _onSearchPressed, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 0), child: const Text("Rechercher des trajets", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))))])),
      if (hasActiveTrip) Positioned(top: 15, right: 15, child: _buildLiveTripPulseBadge(activeReservations.first)),
    ]);
  }

  Widget _buildLiveTripPulseBadge(ActiveReservationModel trip) {
    return GestureDetector(onTap: () { setState(() { isLiveExpanded = !isLiveExpanded; }); }, child: AnimatedBuilder(animation: _pulseAnimation, builder: (context, child) { return Transform.scale(scale: isLiveExpanded ? 1.0 : _pulseAnimation.value, child: AnimatedContainer(duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack, width: isLiveExpanded ? 220 : 85, height: isLiveExpanded ? 90 : 36, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: isLiveExpanded ? 5 : 10 * _pulseAnimation.value, spreadRadius: isLiveExpanded ? 0 : 2)]), child: SingleChildScrollView(physics: const NeverScrollableScrollPhysics(), child: Column(mainAxisSize: MainAxisSize.min, children: [Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)), const Gap(6), const Text("LIVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10))]), if (!isLiveExpanded) const Icon(Icons.arrow_drop_down, color: Colors.white, size: 16), if (isLiveExpanded) const Icon(Icons.close, color: Colors.white, size: 14)]), if (isLiveExpanded) ...[const Gap(8), Container(height: 1, color: Colors.white24), const Gap(8), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: Text(trip.pointDepart, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), overflow: TextOverflow.ellipsis)), AnimatedBuilder(animation: _busAnimation, builder: (context, child) => Transform.translate(offset: Offset(_busAnimation.value, 0), child: const Icon(Icons.directions_bus, color: Colors.white, size: 14))), Expanded(child: Text(trip.pointArrive, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis))])]]))), ); }, ));
  }

  Widget _buildRealDropdown(BuildContext context, String label, String? value, List<String> items, String imagePath, Function(String?) onChanged, {bool isGreen = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    final imageColor = isGreen ? AppColors.secondary : AppColors.primary;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)), const Gap(5), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0), decoration: BoxDecoration(border: Border.all(color: borderColor), borderRadius: BorderRadius.circular(10), color: isDark ? Colors.white.withOpacity(0.05) : Colors.transparent), child: Row(children: [Image.asset(imagePath, width: 20, height: 20, color: imageColor, fit: BoxFit.contain), const Gap(10), Expanded(child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: items.contains(value) ? value : null, hint: Text("Sélectionner", style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 13)), isExpanded: true, icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey, size: 18), dropdownColor: Theme.of(context).cardColor, style: TextStyle(color: textColor, fontWeight: FontWeight.w500), items: items.map((String item) => DropdownMenuItem<String>(value: item, child: Text(item))).toList(), onChanged: onChanged)))]))]);
  }

  Widget _buildDateField(BuildContext context, String label, DateTime? date, {bool isOptional = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;
    String text = date == null ? "Sélectionner une date" : DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(date);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)), const Gap(5), Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(border: Border.all(color: isOptional ? Colors.orange.withOpacity(0.5) : borderColor), borderRadius: BorderRadius.circular(10), color: isOptional ? Colors.orange.withOpacity(0.05) : null), child: Row(children: [Icon(Icons.calendar_today, color: isOptional ? Colors.orange : Colors.grey, size: 18), const Gap(10), Expanded(child: Text(text, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: textColor), overflow: TextOverflow.ellipsis))]))]);
  }

  Color _getCompanyColor(String name) {
    if (name.toLowerCase().contains("utb")) return const Color(0xFFCA8A04);
    if (name.toLowerCase().contains("fabiola")) return const Color(0xFF15803D);
    return AppColors.primary;
  }

  Widget _buildCompanyCard(BuildContext context, {required ProgramModel program}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1);

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
          )
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
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: const Text(
                                "Standard",
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                            // Badge Note (Étoile)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: const [
                                  Icon(Icons.star, color: Colors.orange, size: 10),
                                  Gap(2),
                                  Text(
                                    "4.5",
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                                  ),
                                ],
                              ),
                            )
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
                                  shadows: [Shadow(color: Colors.black, blurRadius: 2)],
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
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    ],
                  )
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

  const _BranchAndButtonWidget({required this.onBookPressed, required this.cardWidth});

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