import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../booking/data/datasources/booking_remote_data_source.dart';
import '../../data/models/program_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'booking_summary_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final bool isGuestMode;
  final int passengerCount;
  final ProgramModel program; // Programme Aller
  final String? dateRetourChoisie; // Date retour formatée YYYY-MM-DD
  final ProgramModel? returnProgram; // Programme Retour

  const SeatSelectionScreen({
    super.key,
    this.isGuestMode = false,
    required this.passengerCount,
    required this.program,
    this.dateRetourChoisie,
    this.returnProgram,
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  // --- GESTION ALLER / RETOUR ---
  bool isSelectingReturnPhase = false; // False = Aller, True = Retour

  // On stocke séparément les sièges
  final Set<int> selectedSeatsAller = {};
  final Set<int> selectedSeatsRetour = {};

  // Getter intelligent pour savoir sur quelle liste on travaille actuellement
  Set<int> get currentSelectedSeats => isSelectingReturnPhase ? selectedSeatsRetour : selectedSeatsAller;

  List<int> occupiedSeats = [];
  bool isLoadingSeats = true;

  final _formKey = GlobalKey<FormState>();
  final List<Map<String, TextEditingController>> _passengerControllers = [];

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchReservedSeats(); // Charge les sièges de l'Aller au démarrage
  }

  @override
  void dispose() {
    for (var map in _passengerControllers) {
      map.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }

  void _initControllers() {
    for (int i = 0; i < widget.passengerCount; i++) {
      _passengerControllers.add({
        "nom": TextEditingController(),
        "prenom": TextEditingController(),
        "telephone": TextEditingController(),
        "email": TextEditingController(),
        "urgence": TextEditingController(),
      });
    }
  }

  // ---------------------------------------------------------------------------
  // 🔄 CHARGEMENT DES SIÈGES (DYNAMIQUE ALLER OU RETOUR)
  // ---------------------------------------------------------------------------
  Future<void> _fetchReservedSeats() async {
    setState(() {
      isLoadingSeats = true;
      occupiedSeats = []; // On vide pour éviter d'afficher les sièges occupés de l'aller sur le retour
    });

    final dio = Dio(BaseOptions(
      baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final dataSource = BookingRemoteDataSourceImpl(dio: dio);

    try {
      // 1. DÉTERMINER QUEL PROGRAMME ET QUELLE DATE UTILISER
      ProgramModel targetProgram;
      String targetDateStr;

      if (isSelectingReturnPhase) {
        // C'est le retour
        targetProgram = widget.returnProgram!;
        // Si une date spécifique a été choisie via le calendar, on l'utilise, sinon celle du programme
        targetDateStr = widget.dateRetourChoisie ?? targetProgram.dateDepart.split(' ')[0];
      } else {
        // C'est l'aller
        targetProgram = widget.program;
        targetDateStr = targetProgram.dateDepart; // DateTime.parse gérera l'heure
      }

      // 2. FORMATAE DATE
      DateTime dateObj = DateTime.parse(targetDateStr.contains(' ') ? targetDateStr : "$targetDateStr 00:00:00");
      String datePropre = DateFormat('yyyy-MM-dd').format(dateObj);

      print("🔍 REQUÊTE SIÈGES (${isSelectingReturnPhase ? 'RETOUR' : 'ALLER'}) -> ID: ${targetProgram.id}, DATE: $datePropre");

      final seats = await dataSource.getReservedSeats(targetProgram.id, datePropre);

      print("✅ SIÈGES OCCUPÉS REÇUS : $seats");

      if (mounted) {
        setState(() {
          occupiedSeats = seats;
          isLoadingSeats = false;
        });
      }
    } catch (e) {
      print("❌ ERREUR FETCH SEATS : $e");
      if (mounted) setState(() => isLoadingSeats = false);
      _showTopNotification("Impossible de charger les sièges occupés");
    }
  }

  void _toggleSeat(int seatNumber) {
    setState(() {
      // On travaille sur la liste courante via le getter
      if (currentSelectedSeats.contains(seatNumber)) {
        currentSelectedSeats.remove(seatNumber);
      } else {
        if (currentSelectedSeats.length < widget.passengerCount) {
          currentSelectedSeats.add(seatNumber);
        } else {
          _showTopNotification("Maximum de ${widget.passengerCount} passager(s) atteint.");
        }
      }
    });
  }

  // ---------------------------------------------------------------------------
  // 🔘 LOGIQUE DU BOUTON PRINCIPAL (TRANSITION)
  // ---------------------------------------------------------------------------
  void _handleMainButtonPress() {
    // 1. Validation du nombre de sièges pour l'étape en cours
    if (currentSelectedSeats.length != widget.passengerCount) {
      _showTopNotification("Veuillez sélectionner ${widget.passengerCount} siège(s).");
      return;
    }

    // 2. Gestion de la transition Aller -> Retour
    if (widget.returnProgram != null && !isSelectingReturnPhase) {
      // On a fini l'aller, on passe au retour
      setState(() {
        isSelectingReturnPhase = true;
      });
      // On lance le chargement des sièges pour le retour
      _fetchReservedSeats();

      // Petit effet visuel ou message
      _showTopNotification("Sélectionnez maintenant vos places pour le RETOUR", isError: false);
    }
    // 3. Fin de la sélection (soit Aller simple fini, soit Retour fini)
    else {
      _showPassengerInfoModal(context);
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
              color: isError ? const Color(0xFF222222) : Colors.green.shade700,
              borderRadius: BorderRadius.circular(25),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isError ? Icons.info_outline : Icons.check_circle, color: Colors.white, size: 20),
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
// ---------------------------------------------------------------------------
// 📝 MODAL PASSAGERS & SUBMIT (VERSION FLATICON)
// ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
// 📝 MODAL PASSAGERS & SUBMIT (CORRIGÉ)
// ---------------------------------------------------------------------------
  void _showPassengerInfoModal(BuildContext context) {
    final sortedSeatsAller = selectedSeatsAller.toList()..sort();
    final sortedSeatsRetour = selectedSeatsRetour.toList()..sort();

    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
          final textColor = Theme.of(context).textTheme.bodyLarge?.color;
          final cardColor = Theme.of(context).cardColor;

          return Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(color: cardColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(25))),
              child: Column(
                children: [
                  const Gap(15),
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const Gap(15),

                  // --- HEADER ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text("Infos Passagers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Image.asset(
                            "assets/images/close.png",
                            width: 24, height: 24,
                            color: textColor
                        ),
                      )
                    ]),
                  ),
                  const Divider(),

                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: widget.passengerCount,
                        separatorBuilder: (c, i) => const Divider(height: 40, thickness: 1),
                        itemBuilder: (context, index) {
                          final controllers = _passengerControllers[index];

                          final seatAller = sortedSeatsAller[index];
                          final seatRetour = (widget.returnProgram != null && sortedSeatsRetour.length > index)
                              ? sortedSeatsRetour[index]
                              : null;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Titre Passager
                              Row(children: [
                                Image.asset(
                                  "assets/images/user.png",
                                  width: 24, height: 24,
                                  color: AppColors.primary,
                                ),
                                const Gap(10),
                                Text("Passager ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                                  child: Text(
                                      seatRetour != null
                                          ? "Aller: #$seatAller | Retour: #$seatRetour"
                                          : "Siège #$seatAller",
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)
                                  ),
                                )
                              ]),
                              const Gap(15),

                              Row(children: [
                                Expanded(
                                    child: _buildTextField(
                                        context, "Nom",
                                        controller: controllers["nom"]!,
                                        imagePath: "assets/images/user.png"
                                    )
                                ),
                                const Gap(10),
                                Expanded(
                                    child: _buildTextField(
                                      context, "Prénom",
                                      controller: controllers["prenom"]!,
                                    )
                                ),
                              ]),
                              const Gap(15),

                              _buildTextField(
                                  context, "Email",
                                  controller: controllers["email"]!,
                                  imagePath: "assets/images/email.png",
                                  keyboardType: TextInputType.emailAddress,
                                  hint: "exemple@email.com"
                              ),
                              const Gap(15),

                              _buildTextField(
                                  context, "Téléphone",
                                  controller: controllers["telephone"]!,
                                  imagePath: "assets/images/phone-call.png",
                                  keyboardType: TextInputType.phone
                              ),
                              const Gap(15),

                              _buildTextField(
                                  context, "Contact d'urgence",
                                  controller: controllers["urgence"]!,
                                  imagePath: "assets/images/health-insurance.png"
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  // ---------------------------------------------------------
                  // ✅ CORRECTION ICI : Ajout du SafeArea autour du bouton
                  // ---------------------------------------------------------
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: SizedBox(
                        width: double.infinity, height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              _submitDataAndNavigate();
                            }
                          },
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          child: const Text("Continuer vers le résumé", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        }
    );
  }

// ---------------------------------------------------------------------------
// 👇 WIDGET HELPER MIS À JOUR (VERSION IMAGE)
// ---------------------------------------------------------------------------
  Widget _buildTextField(BuildContext context, String label, {
    required TextEditingController controller,
    String? imagePath, // ✅ Changé de IconData à String
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? Colors.grey[800] : Colors.grey[100]; // Un peu plus clair que blanc pur souvent mieux
    final borderColor = isDark ? Colors.transparent : Colors.grey.shade300;
    final iconColor = Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
        const Gap(6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(color: textColor),
          validator: (value) => value == null || value.isEmpty ? "Requis" : null,
          decoration: InputDecoration(
            // ✅ Image à la place de l'icône
            prefixIcon: imagePath != null
                ? Padding(
              padding: const EdgeInsets.all(12.0),
              child: Image.asset(imagePath, width: 20, height: 20, color: iconColor),
            )
                : null,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            filled: true,
            fillColor: fillColor,
          ),
        ),
      ],
    );
  }

  void _submitDataAndNavigate() {
    final sortedSeatsAller = selectedSeatsAller.toList()..sort();
    final sortedSeatsRetour = selectedSeatsRetour.toList()..sort();

    List<Map<String, dynamic>> passengersData = [];

    for (int i = 0; i < widget.passengerCount; i++) {
      final controllers = _passengerControllers[i];

      // On prépare l'objet passager avec les sièges
      final Map<String, dynamic> passager = {
        "nom": controllers["nom"]!.text,
        "prenom": controllers["prenom"]!.text,
        "email": controllers["email"]!.text,
        "telephone": controllers["telephone"]!.text,
        "urgence": controllers["urgence"]!.text,
        "seat_number": sortedSeatsAller[i], // Siège Aller standard
      };

      // Si retour, on ajoute le champ spécifique pour le siège retour
      if (widget.program.isAllerRetour && i < sortedSeatsRetour.length) {
        passager["seat_number_return"] = sortedSeatsRetour[i];
      }

      passengersData.add(passager);
    }

    String? dateRetourFinal;
    if (widget.program.isAllerRetour) {
      dateRetourFinal = widget.dateRetourChoisie;
      // Fallback de sécurité si la date est nulle
      if (dateRetourFinal == null) {
        DateTime dateDepart = DateTime.parse(widget.program.dateDepart);
        DateTime retour = dateDepart.add(const Duration(days: 7));
        dateRetourFinal = DateFormat('yyyy-MM-dd').format(retour);
      }
    }

    // CONSTRUCTION DU PAYLOAD FINAL
    final bookingData = {
      "programme_id": widget.program.id,
      "date_voyage": widget.program.dateDepart,
      "nombre_places": widget.passengerCount,

      // On envoie les listes brutes
      "seats": sortedSeatsAller,
      if (widget.program.isAllerRetour) "seats_retour": sortedSeatsRetour,
      if (widget.returnProgram != null) "return_programme_id": widget.returnProgram!.id, // Utile pour le backend

      "passagers": passengersData,
      "is_aller_retour": widget.program.isAllerRetour,
      if (dateRetourFinal != null) "date_retour": dateRetourFinal,
    };

    if (widget.isGuestMode) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => BookingSummaryScreen(
                bookingData: bookingData,
                program: widget.program,
              )
          )
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 🖥 UI PRINCIPALE
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    // Calcul du prix total
    int ticketPrice = widget.program.isAllerRetour
        ? (widget.program.prix * 2)
        : widget.program.prix;
    int totalPrice = widget.passengerCount * ticketPrice;

    // L'état courant pour l'affichage
    final currentProgram = isSelectingReturnPhase ? widget.returnProgram! : widget.program;
    final String titrePhase = isSelectingReturnPhase ? "RETOUR" : "ALLER";

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final cardColor = Theme.of(context).cardColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: textColor), onPressed: () {
          // Si on est en phase retour et qu'on fait retour, on revient à la phase aller
          if (isSelectingReturnPhase) {
            setState(() {
              isSelectingReturnPhase = false;
              _fetchReservedSeats(); // On recharge les places aller
            });
          } else {
            Navigator.pop(context);
          }
        }),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("Choix place", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Gap(5),
                // Badge "ALLER" ou "RETOUR"
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                      color: isSelectingReturnPhase ? Colors.orange : AppColors.primary,
                      borderRadius: BorderRadius.circular(4)
                  ),
                  child: Text(titrePhase, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
            Text("${currentProgram.compagnieName} • ${widget.passengerCount} passager(s)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(context, totalPrice),
      body: isLoadingSeats
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // BANDEAU TRAJET DYNAMIQUE
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                decoration: BoxDecoration(
                    color: isSelectingReturnPhase ? Colors.orange.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: isSelectingReturnPhase ? Colors.orange : AppColors.primary)
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(currentProgram.villeDepart, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                    const Gap(10),
                    Icon(Icons.arrow_forward, size: 16, color: isSelectingReturnPhase ? Colors.orange : AppColors.primary),
                    const Gap(10),
                    Text(currentProgram.villeArrivee, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  ],
                ),
              ),

              const Gap(20),

              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                _buildLegendItem(context, "Libre", isDark ? Colors.white10 : Colors.white, borderColor: Colors.grey),
                const Gap(10),
                _buildLegendItem(context, "Choisi", AppColors.primary),
                const Gap(10),
                _buildLegendItem(context, "Occupé", Colors.grey),
              ]),
              const Gap(20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
                child: Column(children: [
                  _buildBusLayout(context),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGETS DE CONSTRUCTION (INCHANGÉS MAIS UTILISENT LE NOUVEL ÉTAT) ---

  Widget _buildBusLayout(BuildContext context) {
    return Column(
      children: List.generate(12, (rowIndex) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildSeatItem(context, (rowIndex * 4) + 1),
              _buildSeatItem(context, (rowIndex * 4) + 2),
              const SizedBox(width: 20),
              _buildSeatItem(context, (rowIndex * 4) + 3),
              _buildSeatItem(context, (rowIndex * 4) + 4),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSeatItem(BuildContext context, int seatNumber) {
    // Utilise le getter currentSelectedSeats pour savoir si c'est sélectionné dans la phase actuelle
    bool isSelected = currentSelectedSeats.contains(seatNumber);
    bool isOccupied = occupiedSeats.contains(seatNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bgColor = isDark ? Colors.white10 : Colors.white;
    Color borderColor = isDark ? Colors.transparent : Colors.grey.shade300;
    Color textColor = isDark ? Colors.white : Colors.black;

    if (isOccupied) {
      bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
      borderColor = Colors.transparent;
      textColor = Colors.grey;
    } else if (isSelected) {
      // Change la couleur si c'est le retour pour bien différencier
      bgColor = isSelectingReturnPhase ? Colors.orange : AppColors.primary;
      borderColor = isSelectingReturnPhase ? Colors.orange : AppColors.primary;
      textColor = Colors.white;
    }

    return GestureDetector(
      onTap: () {
        if (isOccupied) return;
        _toggleSeat(seatNumber);
      },
      child: Container(
        width: 45, height: 45,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
        ),
        child: Text("$seatNumber", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, {Color? borderColor}) {
    return Row(children: [
      Container(width: 20, height: 20, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5), border: borderColor != null ? Border.all(color: borderColor) : null)),
      const Gap(5),
      Text(label, style: const TextStyle(fontSize: 12))
    ]);
  }


  Widget _buildBottomBar(BuildContext context, int totalPrice) {
    bool isComplete = currentSelectedSeats.length == widget.passengerCount;

    String buttonText;
    if (widget.returnProgram != null && !isSelectingReturnPhase) {
      // On est à l'aller, et il y a un retour prévu
      buttonText = isComplete ? "Continuer vers le retour ➔" : "Sélectionnez ${widget.passengerCount} siège(s)";
    } else {
      // Fin (Aller simple ou fin du retour)
      buttonText = isComplete ? "Confirmer pour $totalPrice FCFA" : "Sélectionnez ${widget.passengerCount} siège(s)";
    }

    return Container(
      padding: const EdgeInsets.all(20),
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: SizedBox(
          width: double.infinity, height: 55,
          child: ElevatedButton(
            onPressed: isComplete ? _handleMainButtonPress : null,
            style: ElevatedButton.styleFrom(
                backgroundColor: isSelectingReturnPhase ? Colors.orange : AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
            child: Text(
                buttonText,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ),
    );
  }
}