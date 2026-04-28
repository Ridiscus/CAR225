import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/networking/api_config.dart';
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

  final int seatSelectionFee;
  final bool isAutomaticSeatSelection;

  const SeatSelectionScreen({
    super.key,
    this.isGuestMode = false,
    this.isModificationMode = false,
    required this.passengerCount,
    required this.program,
    this.dateRetourChoisie,
    this.returnProgram,
    this.isAutomaticSeatSelection = false, // 🟢 Par défaut à false
    required this.seatSelectionFee,
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

  // 🟢 NOUVEAU : On gère le mode localement pour pouvoir le désactiver
  late bool _isModeAuto;
  late int _currentSeatFee; // Pour gérer les frais dynamiquement

  @override
  void initState() {
    super.initState();
    _initControllers();
    _fetchReservedSeats(); // Charge les sièges de l'Aller au démarrage
    _isModeAuto = widget.isAutomaticSeatSelection;
    _currentSeatFee = widget.seatSelectionFee;
  }

  @override
  void dispose() {
    for (var map in _passengerControllers) {
      map.values.forEach((controller) => controller.dispose());
    }
    super.dispose();
  }


  void _initControllers() {
    // 1. On récupère l'utilisateur connecté
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    for (int i = 0; i < widget.passengerCount; i++) {
      // Les contrôleurs classiques
      final nomCtrl = TextEditingController();
      final prenomCtrl = TextEditingController();
      final telCtrl = TextEditingController();
      final emailCtrl = TextEditingController();

      // 👇 2. LES 3 NOUVEAUX CONTRÔLEURS D'URGENCE 👇
      final nomUrgenceCtrl = TextEditingController();
      final lienUrgenceCtrl = TextEditingController();
      final telUrgenceCtrl = TextEditingController();

      if (user != null) {
        // On pré-remplit les infos d'urgence pour TOUS les passagers
        nomUrgenceCtrl.text = user.nomUrgence ?? "";
        lienUrgenceCtrl.text = user.lienParenteUrgence ?? "";
        telUrgenceCtrl.text = user.contactUrgence ?? "";

        if (i == 0) {
          // 🙎‍♂️ PASSAGER 1 : On pré-remplit aussi ses infos personnelles
          nomCtrl.text = user.name;
          prenomCtrl.text = user.prenom;
          telCtrl.text = user.contact;
          emailCtrl.text = user.email;
        }
      }

      // 3. On ajoute le tout dans la liste avec les BONNES clés
      _passengerControllers.add({
        "nom": nomCtrl,
        "prenom": prenomCtrl,
        "telephone": telCtrl,
        "email": emailCtrl,
        // 👇 MAPTAGE EXACT ATTENDU PAR L'UI 👇
        "nom_urgence": nomUrgenceCtrl,
        "lien_urgence": lienUrgenceCtrl,
        "tel_urgence": telUrgenceCtrl,
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

    print("===================================================");
    print("🔄 DÉBUT CHARGEMENT DES SIÈGES : ${isSelectingReturnPhase ? 'RETOUR' : 'ALLER'}");

    final dio = Dio(BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      //baseUrl: 'https://car225.com/api/',
      //baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    final dataSource = BookingRemoteDataSourceImpl(dio: dio);

    try {
      ProgramModel targetProgram;
      String targetDateStr;

      if (isSelectingReturnPhase) {
        targetProgram = widget.returnProgram!;
        // Pour le retour, on prend la date choisie, sinon celle du programme retour
        targetDateStr = widget.dateRetourChoisie ?? targetProgram.dateDepart;
      } else {
        targetProgram = widget.program;
        targetDateStr = targetProgram.dateDepart;
      }

      print("📅 [DEBUG] Date brute récupérée (targetDateStr) : $targetDateStr");

      // ✅ FORMATAGE DATE ROBUSTE
      // On extrait directement les 10 premiers caractères (YYYY-MM-DD).
      // Ça marche pour "2026-03-24 15:00:00" ET pour "2026-03-24T00:00:00.000Z"
      String datePropre = targetDateStr.length >= 10 ? targetDateStr.substring(0, 10) : targetDateStr;

      print("🔍 [DEBUG] REQUÊTE API -> ID Programme: ${targetProgram.id}, Date propre extraite: $datePropre");

      final seats = await dataSource.getReservedSeats(targetProgram.id, datePropre);

      print("✅ [DEBUG] SIÈGES OCCUPÉS REÇUS : $seats");

      if (mounted) {
        setState(() {
          occupiedSeats = seats;
          isLoadingSeats = false;
        });

        // 🟢 Déclenchement de l'algorithme si on est en automatique
        if (widget.isAutomaticSeatSelection) {
          print("🤖 [DEBUG] Mode Automatique activé. Déclenchement de _autoSelectSeatsAndProceed()...");
          _autoSelectSeatsAndProceed();
        } else {
          print("👤 [DEBUG] Mode Manuel. En attente de la sélection de l'utilisateur.");
        }
      }
      print("===================================================");

    } catch (e, stacktrace) {
      print("❌ [ERREUR] FETCH SEATS ÉCHOUÉ : $e");
      print("❌ [STACKTRACE] : $stacktrace");
      if (mounted) {
        setState(() => isLoadingSeats = false);
        _showTopNotification("Impossible de charger les sièges occupés.");
      }
      print("===================================================");
    }
  }

  /*void _toggleSeat(int seatNumber) {
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
  }*/

  void _toggleSeat(int seatNumber) {
    // 🟢 SÉCURITÉ : On empêche le clic manuel si le mode Auto est actif
    if (_isModeAuto) {
      _showTopNotification("Cliquez d'abord sur 'Je veux choisir manuellement' pour modifier vos sièges.");
      return;
    }

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
  void _autoSelectSeatsAndProceed() {
    // 1. 🟢 RÉCUPÉRATION DYNAMIQUE DE LA CAPACITÉ TOTALE
    // On récupère le nombre de places totales du programme actuel (Aller ou Retour)
    int totalBusSeats = isSelectingReturnPhase
        ? (widget.returnProgram?.capacity ?? 30) // Fallback à 30 si null par sécurité
        : widget.program.capacity;

    print("🎲 [DEBUG] Tentative d'attribution automatique pour ${widget.passengerCount} passagers sur un bus de $totalBusSeats places...");
    print("📋 [DEBUG] Sièges occupés actuels (occupiedSeats): $occupiedSeats");

    // 2. On crée une liste avec TOUS les sièges POSSIBLES (de 1 à totalBusSeats)
    List<int> allSeats = List.generate(totalBusSeats, (index) => index + 1);

    // 3. On retire les sièges qui sont déjà occupés (on garde que les libres)
    List<int> availableSeats = allSeats.where((seat) => !occupiedSeats.contains(seat)).toList();

    print("🔓 [DEBUG] Sièges disponibles trouvés (availableSeats count): ${availableSeats.length}");

    // 4. 🎲 LA MAGIE EST ICI : On mélange les sièges libres de façon aléatoire !
    availableSeats.shuffle();

    // 5. On pioche le nombre de sièges nécessaires (passengerCount)
    // On s'assure de ne pas piocher plus que ce qui est disponible
    int numToSelect = widget.passengerCount > availableSeats.length ? availableSeats.length : widget.passengerCount;

    for (int i = 0; i < numToSelect; i++) {
      // On prend le premier siège de notre liste mélangée
      currentSelectedSeats.add(availableSeats.removeAt(0));
    }

    // 6. On rafraîchit l'interface pour afficher les sièges sélectionnés
    /*setState(() {});

    // 7. Si on a bien le bon nombre de sièges, on passe à l'étape suivante
    if (currentSelectedSeats.length == widget.passengerCount) {
      print("🎲 [DEBUG] Sièges attribués aléatoirement : $currentSelectedSeats");
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          _handleMainButtonPress();
        }
      });
    } else {
      // Sécurité si le bus est trop plein
      _showTopNotification("Il n'y a pas assez de places disponibles dans ce bus.");
    }*/

    // 6. On rafraîchit l'interface pour afficher les sièges sélectionnés
    setState(() {});

    // 7. 🟢 MODIFICATION : On affiche juste un message au lieu de forcer le passage à la suite
    if (currentSelectedSeats.length == widget.passengerCount) {
      print("🎲 [DEBUG] Sièges attribués aléatoirement : $currentSelectedSeats");
      _showTopNotification("Sièges attribués automatiquement.", isError: false);
    } else {
      _showTopNotification("Il n'y a pas assez de places disponibles dans ce bus.");
    }

  }



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
// 📝 MODAL PASSAGERS & SUBMIT (CORRIGÉ AVEC LE TOGGLE)
// ---------------------------------------------------------------------------
  void _showPassengerInfoModal(BuildContext context) {
    final sortedSeatsAller = selectedSeatsAller.toList()..sort();
    final sortedSeatsRetour = selectedSeatsRetour.toList()..sort();

    // On récupère le user depuis le provider pour pouvoir le lire dans la modale
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;

    // État initial du toggle : on part du principe que si les champs sont pleins (remplis au initState), c'est "vrai"
    bool isForMe = _passengerControllers[0]["nom"]!.text.isNotEmpty;

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
                      // 🟢 AJOUT : StatefulBuilder pour rafraîchir uniquement la liste de la modale quand on clique sur le toggle
                      child: StatefulBuilder(
                          builder: (BuildContext context, StateSetter setModalState) {
                            return ListView.separated(
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
                                    // Titre Passager & Toggle "Pour moi" (Seulement pour Passager 1)
                                    Row(children: [
                                      Image.asset(
                                        "assets/images/user.png",
                                        width: 24, height: 24,
                                        color: AppColors.primary,
                                      ),
                                      const Gap(10),
                                      Text("Passager ${index + 1}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                                      const Spacer(),

                                      // 🟢 AJOUT DU TOGGLE POUR LE PASSAGER 1
                                      if (index == 0 && user != null) ...[
                                        const Text("Pour moi", style: TextStyle(fontSize: 12, color: Colors.grey)),
                                        Switch(
                                          value: isForMe,
                                          activeColor: AppColors.primary,
                                          onChanged: (bool value) {
                                            setModalState(() {
                                              isForMe = value;
                                              if (isForMe) {
                                                // On REMPLIT avec les infos du user
                                                controllers["nom"]!.text = user.name;
                                                controllers["prenom"]!.text = user.prenom;
                                                controllers["telephone"]!.text = user.contact;
                                                controllers["email"]!.text = user.email;
                                                controllers["nom_urgence"]!.text = user.nomUrgence ?? "";
                                                controllers["lien_urgence"]!.text = user.lienParenteUrgence ?? "";
                                                controllers["tel_urgence"]!.text = user.contactUrgence ?? "";
                                              } else {
                                                // On VIDE les champs
                                                controllers["nom"]!.clear();
                                                controllers["prenom"]!.clear();
                                                controllers["telephone"]!.clear();
                                                controllers["email"]!.clear();
                                                controllers["nom_urgence"]!.clear();
                                                controllers["lien_urgence"]!.clear();
                                                controllers["tel_urgence"]!.clear();
                                              }
                                            });
                                          },
                                        ),
                                      ],

                                      // Badge du siège (affiché en dessous si on est sur le Passager 1 pour ne pas surcharger la ligne)
                                      if (index != 0 || user == null)
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

                                    // Badge du siège pour le Passager 1 (placé ici car la ligne du haut est occupée par le toggle)
                                    if (index == 0 && user != null)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          margin: const EdgeInsets.only(bottom: 15),
                                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                                          child: Text(
                                              seatRetour != null
                                                  ? "Aller: #$seatAller | Retour: #$seatRetour"
                                                  : "Siège #$seatAller",
                                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)
                                          ),
                                        ),
                                      )
                                    else
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
                                        context, "Email (Optionnel)",
                                        controller: controllers["email"]!,
                                        imagePath: "assets/images/email.png",
                                        keyboardType: TextInputType.emailAddress,
                                        isRequired: false,
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

                                    // --- SECTION URGENCE ---
                                    const Gap(10),
                                    Text(
                                        "CONTACT D'URGENCE (SOS)",
                                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.0)
                                    ),
                                    const Gap(15),

                                    Row(
                                      children: [
                                        Expanded(
                                            flex: 3,
                                            child: _buildTextField(
                                                context,
                                                "Nom & Prénom",
                                                controller: controllers["nom_urgence"]!, // Nouveau contrôleur
                                                imagePath: "assets/images/health-insurance.png"
                                            )
                                        ),
                                      ],
                                    ),
                                    const Gap(15),

                                    _buildTextField(
                                        context,
                                        "Numéro d'urgence",
                                        controller: controllers["tel_urgence"]!, // Nouveau contrôleur
                                        imagePath: "assets/images/phone-call.png",
                                        isPhone: true,
                                        keyboardType: TextInputType.phone
                                    ),

                                  ],
                                );
                              },
                            );
                          }
                      ),
                    ),
                  ),

                  // ---------------------------------------------------------
                  // ✅ BOUTON DE VALIDATION
                  // ---------------------------------------------------------
                  SafeArea(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Container(
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

  // 🟢 NOUVEAU WIDGET : Dropdown pour la modale passagers
  Widget _buildModalDropdown(BuildContext context, TextEditingController controller) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillColor = isDark ? Colors.grey[800] : const Color(0xFFF5F5F5);
    final iconColor = Colors.grey[500];

    final List<String> liensParente = [
      'Père', 'Mère', 'Frère', 'Soeur', 'Conjoint(e)', 'Enfant', 'Ami(e)', 'Autre'
    ];

    return Container(
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          prefixIcon: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Image.asset("assets/images/user.png", width: 18, height: 18, color: iconColor),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        ),
        hint: Text("Lien", style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        // Si le contrôleur a déjà une valeur valide, on l'affiche, sinon null
        value: controller.text.isNotEmpty && liensParente.contains(controller.text) ? controller.text : null,
        dropdownColor: fillColor,
        icon: Icon(Icons.keyboard_arrow_down, color: iconColor, size: 20),
        style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87, fontSize: 13),
        isExpanded: true,
        items: liensParente.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (newValue) {
          if (newValue != null) {
            // On met à jour le contrôleur directement quand l'utilisateur choisit une option
            controller.text = newValue;
          }
        },
      ),
    );
  }

// ---------------------------------------------------------------------------
// 👇 WIDGET HELPER MIS À JOUR (VERSION IMAGE)
// ---------------------------------------------------------------------------

  /*Widget _buildTextField(
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
  }*/


  Widget _buildTextField(
      BuildContext context,
      String label, {
        required TextEditingController controller,
        String? imagePath,
        TextInputType keyboardType = TextInputType.text,
        String? hint,
        bool isPhone = false,
        bool isRequired = true, // 🟢 1. AJOUT DU PARAMÈTRE ICI (vrai par défaut)
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
            // 🟢 NOUVELLE LOGIQUE : Si c'est PAS obligatoire ET que c'est vide -> on valide directement
            if (!isRequired && (value == null || value.trim().isEmpty)) {
              return null;
            }

            // 🔴 Sinon, si c'est vide (alors que c'est obligatoire) -> erreur
            if (value == null || value.trim().isEmpty) {
              return "Requis";
            }

            if (isPhone && value.length != 10) {
              return "10 chiffres requis";
            }

            // J'ai mis "contains('email')" au cas où tu écris "Email (Optionnel)" dans le label
            if (label.toLowerCase().contains("email") && !value.contains("@")) {
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



  /*void _submitDataAndNavigate() {
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

    List<Map<String, dynamic>> passengersData = [];

    for (int i = 0; i < widget.passengerCount; i++) {
      final controllers = _passengerControllers[i];

      // Comme l'API n'a pas de champ "lien_urgence", on fusionne le nom et le lien.
      // Exemple : "DOE Bob (Père)"
      String nomUrgenceComplet = "${controllers["nom_urgence"]!.text} (${controllers["lien_urgence"]!.text})";

      final Map<String, dynamic> passager = {
        "nom": controllers["nom"]!.text,
        "prenom": controllers["prenom"]!.text,
        "email": controllers["email"]!.text,
        "telephone": controllers["telephone"]!.text,

        // 👇 MAPTAGE EXACT POUR L'API 👇
        "urgence": controllers["tel_urgence"]!.text, // Le numéro
        "nom_passager_urgence": nomUrgenceComplet, // Le nom + le lien

        "seat_number": sortedSeatsAller[i],
      };

      if (widget.program.isAllerRetour && i < sortedSeatsRetour.length) {
        passager["return_seat_number"] = sortedSeatsRetour[i]; // Bien utiliser return_seat_number
      }
      passengersData.add(passager);
    }

    String? dateRetourFinal;
    if (widget.program.isAllerRetour) {
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
      "seats": sortedSeatsAller, // Utile pour le résumé/aller simple
      if (widget.program.isAllerRetour && widget.returnProgram != null)
        "programme_retour_id": widget.returnProgram!.id, // ⚠️ CORRIGÉ ICI (programme_retour_id)
      "passagers": passengersData,
      "is_aller_retour": widget.program.isAllerRetour,
      if (dateRetourFinal != null) "date_retour": dateRetourFinal,
      // 🟢 LA PIÈCE MANQUANTE EST ICI : On ajoute les frais de siège !
      "seatSelectionFee": widget.seatSelectionFee,
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
                returnProgram: widget.returnProgram, // 🟢 AJOUT ICI
              )
          )
      );
    }
  }*/


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

    // 🟢 NOUVEAU : CALCUL DES FRAIS DYNAMIQUES
    // On utilise _currentSeatFee (qui change si l'utilisateur repasse en manuel)
    int trajetMultiplier = widget.returnProgram != null ? 2 : 1;
    int totalSeatFees = _currentSeatFee * widget.passengerCount * trajetMultiplier;

    // -----------------------------------------------------------
    // 2. 🟢 INTERCEPTION : MODE MODIFICATION
    // -----------------------------------------------------------
    if (widget.isModificationMode) {
      // On prépare uniquement les données nécessaires pour l'API "modify"
      Map<String, dynamic> modificationData = {
        "programme_id": widget.program.id,
        "date_voyage": widget.program.dateDepart.split(' ')[0],
        "heure_depart": widget.program.heureDepart,
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
      Navigator.pop(context, modificationData);
      return; // ⛔ ON ARRÊTE TOUT ICI POUR LE MODE MODIF
    }

    // -----------------------------------------------------------
    // 3. 🔴 LOGIQUE NORMALE (RÉSERVATION CLASSIQUE)
    // -----------------------------------------------------------

    List<Map<String, dynamic>> passengersData = [];

    /*for (int i = 0; i < widget.passengerCount; i++) {
      final controllers = _passengerControllers[i];

      // On fusionne le nom et le lien. Exemple : "DOE Bob (Père)"
      String nomUrgenceComplet = "${controllers["nom_urgence"]!.text} (${controllers["lien_urgence"]!.text})";

      final Map<String, dynamic> passager = {
        "nom": controllers["nom"]!.text,
        "prenom": controllers["prenom"]!.text,
        "email": controllers["email"]!.text,
        "telephone": controllers["telephone"]!.text,
        "urgence": controllers["tel_urgence"]!.text,
        "nom_passager_urgence": nomUrgenceComplet,
        "seat_number": sortedSeatsAller[i],
      };

      if (widget.program.isAllerRetour && i < sortedSeatsRetour.length) {
        passager["return_seat_number"] = sortedSeatsRetour[i];
      }
      passengersData.add(passager);
    }*/

    for (int i = 0; i < widget.passengerCount; i++) {
      final controllers = _passengerControllers[i];

      // On fusionne le nom et le lien. Exemple : "DOE Bob (Père)"
      String nomUrgenceComplet = "${controllers["nom_urgence"]!.text} (${controllers["lien_urgence"]!.text})";

      // On récupère ce que l'utilisateur a tapé
      String emailSaisi = controllers["email"]!.text.trim();

      final Map<String, dynamic> passager = {
        "nom": controllers["nom"]!.text,
        "prenom": controllers["prenom"]!.text,

        // 🟢 SOLUTION RADICALE : Si c'est vide, on envoie un faux email par défaut
        "email": emailSaisi.isEmpty ? "contact@car225.com" : emailSaisi,

        "telephone": controllers["telephone"]!.text,
        "urgence": controllers["tel_urgence"]!.text,
        "nom_passager_urgence": nomUrgenceComplet,
        "seat_number": sortedSeatsAller[i],
      };

      if (widget.program.isAllerRetour && i < sortedSeatsRetour.length) {
        passager["return_seat_number"] = sortedSeatsRetour[i];
      }
      passengersData.add(passager);
    }

    String? dateRetourFinal;
    if (widget.program.isAllerRetour) {
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
      if (widget.program.isAllerRetour && widget.returnProgram != null)
        "programme_retour_id": widget.returnProgram!.id,
      "passagers": passengersData,
      "is_aller_retour": widget.program.isAllerRetour,
      if (dateRetourFinal != null) "date_retour": dateRetourFinal,

      // 🟢 On inclut les frais dynamiques dans le payload (par sécurité)
      "seatSelectionFee": totalSeatFees,
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
                returnProgram: widget.returnProgram,
              )));
    }
  }


  /*@override
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
  }*/

  @override
  Widget build(BuildContext context) {
    // Calcul du prix total
    int ticketPrice = widget.program.isAllerRetour
        ? (widget.program.prix * 2)
        : widget.program.prix;
    //int totalPrice = widget.passengerCount * ticketPrice;
    // 🟢 NOUVEAU : Calcul des frais de choix de siège
    // Si _isModeAuto est false, _currentSeatFee vaut 100. Sinon 0.
    // On multiplie par le nombre de passagers (et par 2 si Aller-Retour)
    int trajetMultiplier = widget.returnProgram != null ? 2 : 1;
    int totalSeatFees = _currentSeatFee * widget.passengerCount * trajetMultiplier;

    // 🟢 On ajoute les frais au prix total
    int totalPrice = (widget.passengerCount * ticketPrice) + totalSeatFees;

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
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () {
            // Si on est en phase retour et qu'on fait retour, on revient à la phase aller
            if (isSelectingReturnPhase) {
              setState(() {
                isSelectingReturnPhase = false;
                _fetchReservedSeats(); // On recharge les places aller
              });
            } else {
              Navigator.pop(context);
            }
          },
        ),
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
                      borderRadius: BorderRadius.circular(4)),
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
                    border: Border.all(color: isSelectingReturnPhase ? Colors.orange : AppColors.primary)),
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

              // LÉGENDE DES SIÈGES
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLegendItem(context, "Libre", isDark ? Colors.white10 : Colors.white, borderColor: Colors.grey),
                  const Gap(10),
                  _buildLegendItem(context, "Choisi", AppColors.primary),
                  const Gap(10),
                  _buildLegendItem(context, "Occupé", Colors.grey),
                ],
              ),
              const Gap(20),

              // 🟢 NOUVEAU : ENCART MODE AUTOMATIQUE -> PASSAGE MANUEL
              if (_isModeAuto)
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.blue),
                          const Gap(10),
                          Expanded(
                            child: Text(
                              "Des sièges vous ont été attribués automatiquement et gratuitement.",
                              style: TextStyle(color: textColor, fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isModeAuto = false; // On désactive le mode auto
                              _currentSeatFee = 100; // On applique les frais
                              currentSelectedSeats.clear(); // On vide les sièges générés
                            });
                            _showTopNotification("Mode manuel activé. Choisissez vos sièges (Frais: 100 FCFA).", isError: false);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.blue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text("Je veux choisir manuellement (+100 FCFA)", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                ),

              // PLAN DU BUS
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(30)),
                child: Column(
                  children: [
                    _buildBusLayout(context),
                  ],
                ),
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