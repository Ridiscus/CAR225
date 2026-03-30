
// -------------------------------------------------------------------------
// ⚙️ MODAL DE CONFIGURATION MISE À JOUR (POUR ALL ITINERARIES)
// -------------------------------------------------------------------------
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../features/booking/data/models/program_model.dart';
import '../../features/booking/domain/repositories/booking_repository.dart';
import '../../features/booking/presentation/screens/seat_selection_screen.dart';

class BookingConfigurationSheet extends StatefulWidget {
  final ProgramModel program;
  final BookingRepositoryImpl repository; // Nécessaire pour chercher le retour

  const BookingConfigurationSheet({
    super.key,
    required this.program,
    required this.repository,
  });

  @override
  State<BookingConfigurationSheet> createState() => _BookingConfigurationSheetState();
}

class _BookingConfigurationSheetState extends State<BookingConfigurationSheet> {
  // État
  late bool isAllerRetour;
  late DateTime dateAller;

  // Retour
  DateTime? dateRetour;
  ProgramModel? selectedReturnProgram;
  List<ProgramModel> availableReturnTrips = [];
  bool isLoadingReturn = false;

  int passengerCount = 1;

  // 🟢 NOUVEAU : Variable pour stocker si la sélection est automatique ou manuelle
  bool isAutomaticSeatSelection = true;

  @override
  void initState() {
    super.initState();
    isAllerRetour = widget.program.isAllerRetour;

    // --- RÈGLE DES 24H MINIMUM ---
    // La date de départ par défaut est demain si la date du programme est passée ou aujourd'hui
    DateTime now = DateTime.now();
    DateTime tomorrow = DateTime(now.year, now.month, now.day + 1);

    try {
      DateTime progDate = DateTime.parse(widget.program.dateDepart);
      if (progDate.isBefore(tomorrow)) {
        dateAller = tomorrow;
      } else {
        dateAller = progDate;
      }
    } catch (_) {
      dateAller = tomorrow;
    }
  }

  // --- LOGIQUE API RETOUR ---
  Future<void> _fetchReturnTrips(DateTime date) async {
    setState(() {
      isLoadingReturn = true;
      availableReturnTrips = [];
      selectedReturnProgram = null;
    });

    try {
      String dateStr = DateFormat('yyyy-MM-dd').format(date);

      // On inverse ville départ et arrivée pour trouver le retour
      // Ajout de "Côte d'Ivoire" si manquant pour matcher ton API si besoin
      String formatCity(String city) => city.contains("Côte d'Ivoire") ? city : "$city, Côte d'Ivoire";

      final results = await widget.repository.searchTrips(
        formatCity(widget.program.villeArrivee), // Départ du retour = Arrivée de l'aller
        formatCity(widget.program.villeDepart), // Arrivée du retour = Départ de l'aller
        dateStr,
        false,
      );

      if (mounted) {
        setState(() {
          availableReturnTrips = results;
          isLoadingReturn = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => isLoadingReturn = false);
      print("Erreur retour: $e");
    }
  }

  // --- SÉLECTEURS ---
  Future<void> _pickDateAller() async {
    // RÈGLE 24H : On ne peut pas réserver pour aujourd'hui
    DateTime now = DateTime.now();
    DateTime minDate = now.add(const Duration(days: 1));

    final picked = await showDatePicker(
      context: context,
      initialDate: dateAller.isBefore(minDate) ? minDate : dateAller,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() {
        dateAller = picked;
        // Si la date aller dépasse la date retour, on reset le retour
        if (dateRetour != null && dateRetour!.isBefore(picked)) {
          dateRetour = null;
          selectedReturnProgram = null;
        }
      });
    }
  }

  Future<void> _pickDateRetour() async {
    // Le retour doit être après ou le même jour que l'aller
    final picked = await showDatePicker(
      context: context,
      initialDate: dateRetour ?? dateAller.add(const Duration(days: 1)),
      firstDate: dateAller,
      lastDate: DateTime.now().add(const Duration(days: 180)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );

    if (picked != null) {
      setState(() => dateRetour = picked);
      _fetchReturnTrips(picked);
    }
  }

  void _validateAndGoToSeats() {
    if (isAllerRetour) {
      if (dateRetour == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez choisir une date de retour")));
        return;
      }
      if (selectedReturnProgram == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez choisir un horaire de retour")));
        return;
      }
    }

    Navigator.pop(context); // Fermer la modal

    // On prépare le modèle Aller avec une trou truoo^po
    final finalProgramAller = widget.program.copyWith(
        dateDepart: "${DateFormat('yyyy-MM-dd').format(dateAller)} ${widget.program.heureDepart}",
        isAllerRetour: isAllerRetour
    );

    // Navigation vers les sièges
    /*Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          program: finalProgramAller,
          returnProgram: isAllerRetour ? selectedReturnProgram : null,
          passengerCount: passengerCount,
          dateRetourChoisie: isAllerRetour ? DateFormat('yyyy-MM-dd').format(dateRetour!) : null,
        ),
      ),
    );*/

    // Navigation vers les sièges
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeatSelectionScreen(
          program: finalProgramAller,
          returnProgram: isAllerRetour ? selectedReturnProgram : null,
          passengerCount: passengerCount,
          dateRetourChoisie: isAllerRetour ? DateFormat('yyyy-MM-dd').format(dateRetour!) : null,

          // 🟢 NOUVEAU : On passe les paramètres obligatoires manquants
          isGuestMode: false, // ou la bonne valeur si tu l'as dans la modale
          isModificationMode: false, // Normalement false depuis une nouvelle réservation
          isAutomaticSeatSelection: isAutomaticSeatSelection, // La variable qu'on vient de créer
          seatSelectionFee: isAutomaticSeatSelection ? 0 : 100, // Le calcul du prix !
        ),
      ),
    );

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(20),
          child: ListView(
            controller: controller,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
              const Gap(20),

              Text("Planifiez votre départ", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const Gap(20),

              // 1. SWITCH TYPE
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: isDark ? Colors.grey.shade800 : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Expanded(child: _buildTabOption("Aller Simple", !isAllerRetour, () => setState(() { isAllerRetour = false; dateRetour = null; selectedReturnProgram = null; }))),
                    Expanded(child: _buildTabOption("Aller-Retour", isAllerRetour, () => setState(() => isAllerRetour = true))),
                  ],
                ),
              ),
              const Gap(20),

              // 2. DATE ALLER (Avec règle 24h)
              Text("Date Aller (min. 24h à l'avance)", style: theme.textTheme.bodySmall),
              const Gap(5),
              _buildDateSelector("Date de départ", dateAller, _pickDateAller, true),
              const Gap(20),

              // 3. RETOUR (Si activé)
              if (isAllerRetour) ...[
                const Divider(),
                Text("Retour", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const Gap(10),
                _buildDateSelector("Date de retour", dateRetour, _pickDateRetour, dateRetour != null),

                const Gap(15),
                // Liste des bus retour
                if (isLoadingReturn)
                  const Center(child: CircularProgressIndicator())
                else if (dateRetour != null && availableReturnTrips.isEmpty)
                  const Text("Aucun bus disponible ce jour-là.", style: TextStyle(color: Colors.red))
                else if (availableReturnTrips.isNotEmpty) ...[
                    const Text("Choisir l'heure de retour :"),
                    const Gap(10),
                    Wrap(
                      spacing: 10, runSpacing: 10,
                      children: availableReturnTrips.map((p) {
                        bool isSelected = selectedReturnProgram?.id == p.id;
                        return ChoiceChip(
                          label: Text(p.heureDepart),
                          selected: isSelected,
                          onSelected: (v) => setState(() => selectedReturnProgram = v ? p : null),
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color),
                        );
                      }).toList(),
                    )
                  ]
              ],

              const Gap(20),

              // 4. PASSAGERS
              Text("Passagers", style: theme.textTheme.titleSmall?.copyWith(color: Colors.grey)),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(15)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("$passengerCount personne(s)", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Row(
                      children: [
                        IconButton(icon: const Icon(Icons.remove), onPressed: () { if (passengerCount > 1) setState(() => passengerCount--); }),
                        IconButton(icon: const Icon(Icons.add), onPressed: () { if (passengerCount < widget.program.placesDisponibles) setState(() => passengerCount++); }),
                      ],
                    )
                  ],
                ),
              ),

              const Gap(30),

              // 🟢 NOUVEAU : SÉLECTION DU MODE DE SIÈGE
              Text("Choix des sièges", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const Gap(10),

              // Option Automatique (Gratuit)
              GestureDetector(
                onTap: () => setState(() => isAutomaticSeatSelection = true),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: isAutomaticSeatSelection ? AppColors.primary : Colors.grey.shade300, width: isAutomaticSeatSelection ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                    color: isAutomaticSeatSelection ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(isAutomaticSeatSelection ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isAutomaticSeatSelection ? AppColors.primary : Colors.grey),
                      const Gap(10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Placement Automatique", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Attribution aléatoire", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Text("Gratuit", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ],
                  ),
                ),
              ),
              const Gap(10),

              // Option Manuelle (Payant : 100 FCFA)
              GestureDetector(
                onTap: () => setState(() => isAutomaticSeatSelection = false),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: !isAutomaticSeatSelection ? AppColors.primary : Colors.grey.shade300, width: !isAutomaticSeatSelection ? 2 : 1),
                    borderRadius: BorderRadius.circular(12),
                    color: !isAutomaticSeatSelection ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
                  ),
                  child: Row(
                    children: [
                      Icon(!isAutomaticSeatSelection ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: !isAutomaticSeatSelection ? AppColors.primary : Colors.grey),
                      const Gap(10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Choix Manuel", style: TextStyle(fontWeight: FontWeight.bold)),
                            Text("Choisissez vos places préférées", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Text("+100 FCFA", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
              ),
              const Gap(30),

              // 5. BOUTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _validateAndGoToSeats,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                  child: const Text("Choisir les sièges", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const Gap(20),
            ],
          ),
        );
      },
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
        child: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.black : Colors.grey)),
      ),
    );
  }

  Widget _buildDateSelector(String label, DateTime? date, VoidCallback onTap, bool isSelected) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 19, color: isSelected ? AppColors.primary : Colors.grey),
            const Gap(8),
            Text(
              date != null ? DateFormat('dd MMM yyyy', 'fr_FR').format(date) : label,
              style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.black),
            ),
          ],
        ),
      ),
    );
  }
}