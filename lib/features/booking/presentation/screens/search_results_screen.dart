import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

// --- IMPORTS CORE & THEME ---
import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/presentation/bando.dart';

// --- IMPORTS CLEAN ARCHITECTURE ---
import '../../data/datasources/booking_remote_data_source.dart';
import '../../data/models/program_model.dart';
import '../../domain/repositories/booking_repository.dart';
import 'seat_selection_screen.dart';

class SearchResultsScreen extends StatefulWidget {
  final bool isGuestMode;
  final Map<String, dynamic>? searchParams;

  const SearchResultsScreen({
    super.key,
    this.isGuestMode = false,
    this.searchParams,
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  int passengerCount = 1;
  bool isLoading = true;
  String? errorMessage;
  List<ProgramModel> programs = [];

  late BookingRepositoryImpl _repository;

  @override
  void initState() {
    super.initState();
    _setupDependenciesAndFetch();
  }

  void _setupDependenciesAndFetch() {
    final dio = Dio(BaseOptions(
      baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
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

      if (mounted) {
        setState(() { programs = results; isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = e.toString().replaceAll("Exception:", "").trim();
          isLoading = false;
        });
      }
    }
  }

  void _incrementPassengers() { if (passengerCount < 5) setState(() => passengerCount++); }
  void _decrementPassengers() { if (passengerCount > 1) setState(() => passengerCount--); }

  void _showBookingOptionsModal(BuildContext context, ProgramModel program) {
    showModalBottomSheet(
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
              program: program,
              passengerCount: passengerCount,
              isGuestMode: widget.isGuestMode,
              repository: _repository,
            );
          },
        );
      },
    );
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
              itemCount: programs.length,
              itemBuilder: (context, index) {
                return _buildTicketCard(context, programs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(BuildContext context, ProgramModel program) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: Padding(padding: const EdgeInsets.all(8.0), child: Image.asset("assets/images/bus.png", color: AppColors.primary, fit: BoxFit.contain)),
                  ),
                  const Gap(10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(program.compagnieName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled, size: 12, color: AppColors.primary),
                        const Gap(4),
                        Text("Départ : ${program.heureDepart}", style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ]),
                ],
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("${program.prix} F", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                Text("${program.placesDisponibles} places dispo", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: program.placesDisponibles < 5 ? Colors.red : AppColors.secondary)),
              ]),
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                String searchDate = widget.searchParams?['date'] ?? program.dateDepart.split(' ')[0];
                String timeOnly = program.heureDepart;
                String correctDateDepart = "$searchDate $timeOnly";
                ProgramModel programCorrige = program.copyWith(dateDepart: correctDateDepart);
                _showBookingOptionsModal(context, programCorrige);
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12)),
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
  final ProgramModel program;
  final int passengerCount;
  final bool isGuestMode;
  final BookingRepositoryImpl repository;

  const _BookingConfigModalContent({
    super.key,
    required this.program,
    required this.passengerCount,
    required this.isGuestMode,
    required this.repository,
  });

  @override
  State<_BookingConfigModalContent> createState() => _BookingConfigModalContentState();
}

class _BookingConfigModalContentState extends State<_BookingConfigModalContent> {
  bool isRoundTrip = false;
  late String selectedDepartureTime;
  DateTime? selectedReturnDate;
  bool isLoadingReturnTrips = false;
  List<ProgramModel> availableReturnTrips = [];
  ProgramModel? selectedReturnProgram;

  @override
  void initState() {
    super.initState();
    selectedDepartureTime = widget.program.heureDepart;
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
      final villeDepartRetour = formatCity(widget.program.villeArrivee.trim());
      final villeArriveeRetour = formatCity(widget.program.villeDepart.trim());

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
    DateTime departureDate = DateTime.tryParse(widget.program.dateDepart) ?? DateTime.now();
    DateTime initialDate = selectedReturnDate ?? departureDate.add(const Duration(days: 1));
    if (initialDate.isBefore(departureDate)) initialDate = departureDate;

    final picked = await showDatePicker(
      context: context, initialDate: initialDate, firstDate: departureDate, lastDate: DateTime(departureDate.year + 1),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
    );

    if (picked != null) {
      setState(() => selectedReturnDate = picked);
      _fetchReturnTrips(picked);
    }
  }

  void _onValidate() {
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
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => SeatSelectionScreen(isGuestMode: widget.isGuestMode, passengerCount: widget.passengerCount, program: widget.program.copyWith(isAllerRetour: isRoundTrip), returnProgram: isRoundTrip ? selectedReturnProgram : null, dateRetourChoisie: isRoundTrip && selectedReturnDate != null ? DateFormat('yyyy-MM-dd').format(selectedReturnDate!) : null)));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
            const Gap(20),
            Text("Configuration du voyage", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
            const Gap(20),

            // TYPE DE TRAJET
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100, borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  _buildTypeOption("Aller Simple", !isRoundTrip, () { setState(() { isRoundTrip = false; selectedReturnProgram = null; selectedReturnDate = null; }); }),
                  _buildTypeOption("Aller - Retour", isRoundTrip, () => setState(() => isRoundTrip = true)),
                ],
              ),
            ),
            const Gap(20),

            // RÉCAP ALLER
            Text("Aller : ${widget.program.villeDepart} ➔ ${widget.program.villeArrivee}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
            const Gap(8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: AppColors.primary)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                  const Gap(5),
                  Text(DateFormat("d MMM yyyy", "fr_FR").format(DateTime.parse(widget.program.dateDepart.split(' ')[0])), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                  Container(height: 15, width: 1, color: AppColors.primary, margin: const EdgeInsets.symmetric(horizontal: 8)),
                  const Icon(Icons.access_time, size: 14, color: AppColors.primary),
                  const Gap(5),
                  Text(widget.program.heureDepart, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13)),
                ],
              ),
            ),

            if (isRoundTrip) ...[
              const Gap(25),
              const Divider(),
              const Gap(10),
              Text("Retour : ${widget.program.villeArrivee} ➔ ${widget.program.villeDepart}", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey)),
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

            const Spacer(),

            // -----------------------------------------------------------
            // 🆕 NOUVEAU BLOC INFO FLEXIBILITÉ
            // -----------------------------------------------------------
            Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFCA8A04).withOpacity(0.1), // Fond Orange subtil
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCA8A04).withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFCA8A04), size: 22), // Icône Info
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
            // -----------------------------------------------------------

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _onValidate,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text("Choisir les sièges", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const Gap(10),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeOption(String label, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : [],
          ),
          child: Text(label, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.grey, fontSize: 13)),
        ),
      ),
    );
  }
}