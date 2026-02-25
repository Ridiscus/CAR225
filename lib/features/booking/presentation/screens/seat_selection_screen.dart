import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/data/datasources/booking_remote_data_source.dart';
import '../../data/models/program_model.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'booking_summary_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final bool isGuestMode;
  // 1️⃣ AJOUTE CETTE LIGNE
  final bool isModificationMode;
  final int passengerCount;
  final ProgramModel program; // Programme Aller
  final String? dateRetourChoisie; // Date retour formatée YYYY-MM-DD
  final ProgramModel? returnProgram; // Programme Retour

  const SeatSelectionScreen({
    super.key,
    this.isGuestMode = false,
    this.isModificationMode = false,
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
    // 1. On récupère l'utilisateur connecté avec context.read (méthode moderne sans erreur)
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    for (int i = 0; i < widget.passengerCount; i++) {
      final nomCtrl = TextEditingController();
      final prenomCtrl = TextEditingController();
      final telCtrl = TextEditingController();
      final emailCtrl = TextEditingController();
      final urgenceCtrl = TextEditingController();

      if (user != null) {
        // 2. On gère les nulls proprement grâce à tes champs de UserModel
        String nomU = user.nomUrgence ?? "";
        String prenomU = user.lienParenteUrgence ?? "";
        String contactU = user.contactUrgence ?? "";

        String contactUrgenceComplet = "$nomU $prenomU $contactU".trim();

        if (i == 0) {
          // 🙎‍♂️ PASSAGER 1 : On pré-remplit tout
          nomCtrl.text = user.name;
          prenomCtrl.text = user.prenom;
          telCtrl.text = user.contact;
          emailCtrl.text = user.email;
          urgenceCtrl.text = contactUrgenceComplet;
        } else {
          // 👥 AUTRES PASSAGERS : Uniquement le contact d'urgence
          urgenceCtrl.text = contactUrgenceComplet;
        }
      }

      _passengerControllers.add({
        "nom": nomCtrl,
        "prenom": prenomCtrl,
        "telephone": telCtrl,
        "email": emailCtrl,
        "urgence": urgenceCtrl,
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
      baseUrl: 'https://car225.com/api/',
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
                                  isPhone: true,
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
                      child: Container( // On remplace le SizedBox par Container
                        width: double.infinity,
                        height: 55,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          image: const DecorationImage(
                            image: AssetImage("assets/images/tabaa.jpg"),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              Navigator.pop(context);
                              _submitDataAndNavigate();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent, // Transparent
                              shadowColor: Colors.transparent,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
                          ),
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
  /*Widget _buildTextField(BuildContext context, String label, {
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
  }*/


  Widget _buildTextField(
      BuildContext context,
      String label, {
        required TextEditingController controller,
        String? imagePath,
        TextInputType keyboardType = TextInputType.text,
        String? hint,
        bool isPhone = false, // 🟢 Le nouveau paramètre est bien intégré
      }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final fillColor = isDark ? Colors.grey[800] : Colors.grey[100];
    final borderColor = isDark ? Colors.transparent : Colors.grey.shade300;
    final iconColor = Colors.grey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // --- LE LABEL AU DESSUS DU CHAMP ---
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
        const Gap(6),

        // --- LE CHAMP DE TEXTE ---
        TextFormField(
          controller: controller,
          // 💡 Astuce : force le clavier numérique automatiquement si c'est un téléphone
          keyboardType: isPhone ? TextInputType.phone : keyboardType,
          style: TextStyle(color: textColor, fontSize: 14),

          // 🛡️ 1. BLOQUER LA SAISIE PHYSIQUEMENT (Chiffres uniquement et 10 max)
          inputFormatters: isPhone
              ? [
            FilteringTextInputFormatter.digitsOnly, // Que des chiffres
            LengthLimitingTextInputFormatter(10),   // Pas plus de 10
          ]
              : null,

          // 🛡️ 2. VALIDATION LORS DU CLIC SUR LE BOUTON
          validator: (value) {
            if (value == null || value.isEmpty) {
              return "Requis";
            }
            if (isPhone && value.length != 10) {
              return "10 chiffres requis"; // Bloque si < 10
            }
            if (label.toLowerCase() == "email" && !value.contains("@")) {
              return "Email invalide";
            }
            return null;
          },

          // 🎨 3. TON DESIGN INTACT (Couleurs, bordures, image)
          decoration: InputDecoration(
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
    // -----------------------------------------------------------
    // 1. VALIDATION PRÉLIMINAIRE (Commune aux deux modes)
    // -----------------------------------------------------------
    if (selectedSeatsAller.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner au moins une place aller.")),
      );
      return;
    }

    // On trie les sièges pour être propre
    final sortedSeatsAller = selectedSeatsAller.toList()..sort();
    final sortedSeatsRetour = selectedSeatsRetour.toList()..sort();

    // -----------------------------------------------------------
    // 2. 🟢 INTERCEPTION : MODE MODIFICATION
    // -----------------------------------------------------------
    if (widget.isModificationMode) {
      // On prépare uniquement les données nécessaires pour l'API "modify"
      Map<String, dynamic> modificationData = {
        "programme_id": widget.program.id,
        // On s'assure d'avoir le format YYYY-MM-DD
        "date_voyage": widget.program.dateDepart.split(' ')[0],
        "heure_depart": widget.program.heureDepart,
        // En modif, on considère souvent 1 seul ticket, donc on prend le 1er siège
        "seat_number": sortedSeatsAller.first,
      };

      // Gestion du Retour (si applicable)
      if (widget.program.isAllerRetour && widget.returnProgram != null) {
        modificationData["return_programme_id"] = widget.returnProgram!.id;
        modificationData["return_heure_depart"] = widget.returnProgram!.heureDepart;

        if (sortedSeatsRetour.isNotEmpty) {
          modificationData["return_seat_number"] = sortedSeatsRetour.first;
        }

        if (widget.dateRetourChoisie != null) {
          modificationData["return_date_voyage"] = widget.dateRetourChoisie;
        }
      }

      // 🚀 RETOUR VERS L'ÉCRAN PRÉCÉDENT AVEC LES DONNÉES
      // Cela va remonter la chaîne jusqu'à TicketDetailScreen
      Navigator.pop(context, modificationData);
      return; // ⛔ ON ARRÊTE TOUT ICI POUR LE MODE MODIF
    }

    // -----------------------------------------------------------
    // 3. 🔴 LOGIQUE NORMALE (RÉSERVATION CLASSIQUE)
    // -----------------------------------------------------------
    // Le code ci-dessous ne s'exécute que si isModificationMode == false

    List<Map<String, dynamic>> passengersData = [];

    for (int i = 0; i < widget.passengerCount; i++) {
      // ... Ta logique existante de boucle passagers ...
      final controllers = _passengerControllers[i];

      final Map<String, dynamic> passager = {
        "nom": controllers["nom"]!.text,
        "prenom": controllers["prenom"]!.text,
        "email": controllers["email"]!.text,
        "telephone": controllers["telephone"]!.text,
        "urgence": controllers["urgence"]!.text,
        "seat_number": sortedSeatsAller[i],
      };

      if (widget.program.isAllerRetour && i < sortedSeatsRetour.length) {
        passager["seat_number_return"] = sortedSeatsRetour[i];
      }
      passengersData.add(passager);
    }

    String? dateRetourFinal;
    if (widget.program.isAllerRetour) {
      // ... Ta logique existante de date retour ...
      dateRetourFinal = widget.dateRetourChoisie;
      if (dateRetourFinal == null) {
        DateTime dateDepart = DateTime.parse(widget.program.dateDepart);
        DateTime retour = dateDepart.add(const Duration(days: 7));
        dateRetourFinal = DateFormat('yyyy-MM-dd').format(retour);
      }
    }



    // PAYLOAD FINAL RÉSERVATION
    final bookingData = {
      "programme_id": widget.program.id,
      "date_voyage": widget.program.dateDepart,
      "nombre_places": widget.passengerCount,
      "seats": sortedSeatsAller,
      if (widget.program.isAllerRetour) "seats_retour": sortedSeatsRetour,
      if (widget.returnProgram != null) "return_programme_id": widget.returnProgram!.id,
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


  Widget _buildBusLayout(BuildContext context) {
    // 1. On récupère la capacité réelle du bus courant (Aller ou Retour)
    final currentProgram = isSelectingReturnPhase ? widget.returnProgram! : widget.program;
    int totalSeats = currentProgram.capacity;

    // Sécurité : si la capacité est bizarre (ex: 0), on met 48 par défaut
    if (totalSeats <= 0) totalSeats = 48;

    print("🚌 [DEBUG] Construction du bus : $totalSeats places au total.");

    // 2. On calcule le nombre de rangées nécessaires (4 sièges par rangée)
    // Ex: 30 places / 4 = 7.5 -> On arrondit à 8 rangées
    int rowCount = (totalSeats / 4).ceil();

    return Column(
      children: List.generate(rowCount, (rowIndex) {
        // Calcul des numéros de sièges pour cette rangée
        int seatA = (rowIndex * 4) + 1;
        int seatB = (rowIndex * 4) + 2;
        int seatC = (rowIndex * 4) + 3;
        int seatD = (rowIndex * 4) + 4;

        return Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // On affiche le siège seulement s'il existe (numéro <= capacité totale)
              // Sinon on affiche un espace vide (SizedBox) pour garder l'alignement
              seatA <= totalSeats
                  ? _buildSeatItem(context, seatA)
                  : const Expanded(child: SizedBox()),

              seatB <= totalSeats
                  ? _buildSeatItem(context, seatB)
                  : const Expanded(child: SizedBox()),

              const SizedBox(width: 20), // L'allée centrale

              seatC <= totalSeats
                  ? _buildSeatItem(context, seatC)
                  : const Expanded(child: SizedBox()),

              seatD <= totalSeats
                  ? _buildSeatItem(context, seatD)
                  : const Expanded(child: SizedBox()),
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
    // 1. Ta logique de validation
    bool isComplete = currentSelectedSeats.length == widget.passengerCount;

    // 2. Ta logique de texte
    String buttonText;
    if (widget.returnProgram != null && !isSelectingReturnPhase) {
      // On est à l'aller, et il y a un retour prévu
      buttonText = isComplete ? "Continuer vers le retour ➔" : "Sélectionnez ${widget.passengerCount} siège(s)";
    } else {
      // Fin (Aller simple ou fin du retour)
      buttonText = isComplete ? "Confirmer pour $totalPrice FCFA" : "Sélectionnez ${widget.passengerCount} siège(s)";
    }

    // 3. Le Rendu Visuel
    return Container(
      padding: const EdgeInsets.all(20),
      // Important : On garde la couleur de fond de la barre elle-même (sinon on voit la liste derrière)
      color: Theme.of(context).cardColor,
      child: SafeArea(
        child: Container(
          width: double.infinity,
          height: 55,
          // ✅ Coupe l'image pour qu'elle respecte les coins arrondis
          clipBehavior: Clip.hardEdge,

          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),

            // ✅ LOGIQUE IMAGE :
            // Si isComplete est VRAI -> On affiche l'image.
            // Si isComplete est FAUX -> On met null (pas d'image).
            image: isComplete
                ? const DecorationImage(
              image: AssetImage("assets/images/tabaa.jpg"),
              fit: BoxFit.cover,
            )
                : null,

            // Couleur de fond de secours (Gris si désactivé)
            color: isComplete ? null : Colors.grey.shade300,

            // Ombre seulement si le bouton est actif
            boxShadow: isComplete
                ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]
                : [],
          ),

          child: ElevatedButton(
            // ✅ J'ai remis ta fonction originale '_handleMainButtonPress'
            onPressed: isComplete ? _handleMainButtonPress : null,

            style: ElevatedButton.styleFrom(
              // ✅ TOUT TRANSPARENT (pour voir le Container décoré derrière)
                backgroundColor: Colors.transparent,
                disabledBackgroundColor: Colors.transparent, // Crucial pour le gris
                shadowColor: Colors.transparent,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),

            child: Text(
                buttonText,
                style: TextStyle(
                  // Blanc si actif, Gris foncé si inactif
                    color: isComplete ? Colors.white : Colors.grey.shade600,
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                )
            ),
          ),
        ),
      ),
    );
  }


}