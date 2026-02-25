import 'dart:convert';
import 'package:car225/features/home/presentation/screens/home_tab_screen.dart';
import 'package:flutter/material.dart';
import '../../../booking/data/models/ticket_model.dart';
import '../../../booking/domain/repositories/ticket_repository.dart';
import '../../../booking/presentation/screens/search_results_screen.dart';

class TicketDetailScreen extends StatefulWidget {
  final TicketModel initialTicket;
  final TicketRepository repository;

  const TicketDetailScreen({
    Key? key,
    required this.initialTicket,
    required this.repository
  }) : super(key: key);

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  late TicketModel ticket;
  bool isLoading = true;

  // 🟢 AJOUT : Cette variable retient si on a touché au ticket
  bool hasChanged = false;

  @override
  void initState() {
    super.initState();
    ticket = widget.initialTicket;
    _loadFullDetails();
  }

  // 🔄 CHARGEMENT INTELLIGENT (Fix des villes qui disparaissent)
  Future<void> _loadFullDetails() async {
    try {
      final fullTicket = await widget.repository.getTicketDetails(widget.initialTicket.id.toString());

      if (mounted) {
        setState(() {
          // On garde les villes d'avant si le nouveau ticket a perdu l'info (bug API courant)
          String finalDepart = fullTicket.departureCity;
          String finalArrive = fullTicket.arrivalCity;

          if (finalDepart == "Départ" && widget.initialTicket.departureCity != "Départ") {
            finalDepart = widget.initialTicket.departureCity;
          }
          if (finalArrive == "Arrivée" && widget.initialTicket.arrivalCity != "Arrivée") {
            finalArrive = widget.initialTicket.arrivalCity;
          }

          // On met à jour le ticket avec les meilleures infos des deux mondes
          ticket = fullTicket.copyWith(
              departureCity: finalDepart,
              arrivalCity: finalArrive,
              // On force le statut si nécessaire pour qu'il soit propre
              status: fullTicket.status.isEmpty ? widget.initialTicket.status : fullTicket.status
          );

          isLoading = false;
        });
      }
    } catch (e) {
      print("Erreur reload details: $e");
      if (mounted) {
        setState(() {
          isLoading = false;
          // En cas d'erreur, on reste sur les données initiales qui fonctionnent
        });
      }
    }
  }

  // ------------------------------------------------------------------------
  // 🧮 LOGIQUE DATES & STATUTS (CORRIGÉE & SOUPLE)
  // ------------------------------------------------------------------------

  // 1. Calcul précis de la date et l'heure de départ
  DateTime? get _departureDateTime {
    try {
      final datePart = ticket.date;
      // On nettoie l'heure (parfois "14:30:00", on veut juste "14" et "30")
      final cleanTime = ticket.departureTimeRaw.trim();
      final timeParts = cleanTime.split(':');

      if (timeParts.length < 2) return datePart.add(const Duration(hours: 23, minutes: 59));

      return DateTime(
        datePart.year,
        datePart.month,
        datePart.day,
        int.parse(timeParts[0]), // Heures
        int.parse(timeParts[1]), // Minutes
      );
    } catch (e) {
      return ticket.date.add(const Duration(hours: 23, minutes: 59));
    }
  }

  // 2. CORRECTION DU PROBLÈME "Confirmée" vs "Confirmé"
  bool get _isStatusValid {
    final s = ticket.status.toLowerCase().trim();
    // On utilise contains pour accepter "confirmé", "confirmée", "confirmed", etc.
    return s.contains("confirm") || s.contains("valid") || s.contains("pay") || s.contains("success");
  }

  // 3. LA LOGIQUE FINALE pour afficher les boutons
  bool get _isActionPossible {
    // Si statut invalide (Annulé, Terminé...) -> NON
    if (!_isStatusValid) return false;

    final departure = _departureDateTime;
    if (departure == null) return false;

    final now = DateTime.now();

    // Si bus déjà parti -> NON
    if (now.isAfter(departure)) return false;

    // Si départ dans moins de 15 min -> NON
    return departure.difference(now).inMinutes > 15;
  }



  // ------------------------------------------------------------------------
// 💰 CALCUL REMBOURSEMENT (CORRIGÉ POUR GÉRER LES DÉCIMALES)
// ------------------------------------------------------------------------
  Map<String, dynamic> _calculateRefundInfo() {
    final departure = _departureDateTime; // Assure-toi que cette variable est bien définie dans ta classe
    final now = DateTime.now();

    // 1. Récupération et Nettoyage Intelligent du Prix
    double price = 0.0;
    try {
      String rawPrice = ticket.price.toString().trim();

      // DEBUG : Regarde ça dans ta console pour comprendre
      debugPrint("💰 PRIX BRUT AVANT NETTOYAGE : '$rawPrice'");

      // ÉTAPE CLÉ : Si le prix contient des décimales nulles (.00 ou ,00), on les retire d'abord
      // Sinon "100.00" devient "10000" après le nettoyage des symboles
      if (rawPrice.endsWith('.00')) {
        rawPrice = rawPrice.substring(0, rawPrice.length - 3);
      } else if (rawPrice.endsWith(',00')) {
        rawPrice = rawPrice.substring(0, rawPrice.length - 3);
      }

      // Maintenant on garde uniquement les chiffres
      String cleanPrice = rawPrice.replaceAll(RegExp(r'[^0-9]'), '');

      if (cleanPrice.isEmpty) {
        price = 0.0;
      } else {
        price = double.parse(cleanPrice);
      }

      debugPrint("✅ PRIX NETTOYÉ UTILISÉ : $price");

    } catch (e) {
      debugPrint("🔴 Erreur parsing prix: $e");
      price = 0.0;
    }

    // 2. Si le bus est déjà parti ou date invalide
    if (departure == null || now.isAfter(departure)) {
      return {
        'refund': 0,
        'penalty': price.toInt(),
        'label': 'Départ passé (Non remboursable)',
        'total_price': price.toInt()
      };
    }

    // 3. Calcul de la pénalité selon le temps restant
    final difference = departure.difference(now);
    final int minutesBefore = difference.inMinutes;

    int penalty = 0;
    String label = "";

    // --- RÈGLES DE REMBOURSEMENT ---
    if (minutesBefore >= 180) { // Plus de 3h avant
      penalty = 0;
      label = "Annulation gratuite (> 3h avant)";
    } else if (minutesBefore >= 120) { // Entre 2h et 3h
      int fraisFixes = 250;
      // Sécurité : Si le billet coûte 100F, on ne peut pas retenir 250F
      penalty = (price < fraisFixes) ? price.toInt() : fraisFixes;
      label = "Frais d'annulation : $penalty F (< 3h)";
    } else { // Moins de 2h
      int fraisFixes = 500;
      penalty = (price < fraisFixes) ? price.toInt() : fraisFixes;
      label = "Frais d'annulation : $penalty F (< 2h)";
    }

    // Calcul final
    double refund = (price - penalty);
    if (refund < 0) refund = 0;

    return {
      'refund': refund.toInt(),
      'penalty': penalty,
      'label': label,
      'total_price': price.toInt()
    };
  }

  // ------------------------------------------------------------------------
  // 🔔 NOTIFICATION TOP (Custom)
  // ------------------------------------------------------------------------
  void _showTopNotification(String message, {bool isError = true}) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 50.0, // Ajusté légèrement pour ne pas coller à la status bar
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: isError ? const Color(0xFFD32F2F) : const Color(0xFF388E3C), // Rouge erreur / Vert succès
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4)
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                    isError ? Icons.error_outline : Icons.check_circle_outline,
                    color: Colors.white,
                    size: 24
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
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
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }

  // ------------------------------------------------------------------------
  // 🗑️ ACTION D'ANNULATION (AVEC TOP NOTIFICATION)
  // ------------------------------------------------------------------------
  Future<void> _cancelTicket() async {
    // 1. Calculer les montants avant d'ouvrir le dialogue
    final info = _calculateRefundInfo();

    final int totalPrice = info['total_price'];
    final int penalty = info['penalty'];
    final int refundAmount = info['refund'];
    final String labelCondition = info['label'];

    // 2. Afficher le dialogue détaillé
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text("Annulation", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Détail du remboursement :",
              style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            ),
            const SizedBox(height: 15),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Prix du billet :"),
                Text("$totalPrice F", style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Frais / Pénalité :"),
                Text("- $penalty F", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),

            const Divider(thickness: 1, height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Net à rembourser :", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text("$refundAmount F", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),

            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(5)
              ),
              child: Text(
                "Condition appliquée : $labelCondition",
                style: const TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Retour", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Confirmer l'annulation", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    // Si l'utilisateur annule ou clique à côté
    if (confirm != true) return;

    // 3. Appel API
    setState(() => isLoading = true);

    try {
      final result = await widget.repository.cancelTicket(ticket.id.toString());

      if (!mounted) return;

      if (result['success'] == true) {
        // ✅ SUCCÈS : Top Notification VERTE
        _showTopNotification(
            "Billet annulé. ${result['refund_amount']} F remboursés.",
            isError: false
        );
        Navigator.pop(context, true);
      } else {
        // ❌ ERREUR API : Top Notification ROUGE
        _showTopNotification(
            result['message'] ?? "Erreur lors de l'annulation",
            isError: true
        );
      }
    } catch (e) {
      if (mounted) {
        // ❌ ERREUR TECHNIQUE : Top Notification ROUGE
        _showTopNotification("Erreur technique: $e", isError: true);
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }



  // ------------------------------------------------------------------------
  // ✏️ ACTION DE MODIFICATION
  // ------------------------------------------------------------------------
  void _startModificationProcess() async {
    // 1. Vérifications (Déjà fait)
    if (!_isActionPossible) {
      _showTopNotification("Modification impossible...", isError: true);
      return;
    }


    // 🟢 2. NOUVEAU : On demande confirmation avant de partir
    bool confirm = await _showModificationDialog();
    if (!confirm) {
      // Si l'utilisateur clique sur "Retour" ou à côté, on ne fait rien.
      return;
    }

    // 3. Préparation de la date (Code existant)
    // Utilisation de ticket.date directement car c'est déjà un DateTime
    DateTime? datePrevue = ticket.date;

    // 4. Navigation vers l'écran de recherche
    if (!mounted) return; // Sécurité si le widget est fermé entre temps


    // 2. 🚀 NAVIGATION VERS LE CHOIX DU NOUVEAU VOYAGE
    // On ouvre l'écran de recherche de bus (ou directement la liste des programmes)
    // On passe un argument 'isModificationMode: anntrue' pour dire à l'écran :
    // "Eh, quand l'utilisateur choisit, ne lance pas le paiement, renvoie juste les données !"

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HomeTabScreen( // ⚠️ Mets le nom de ton écran de recherche ici
          isModificationMode: true,
          // Tu peux aussi pré-remplir la ville de départ/arrivée si tu veux restreindre
          initialDepart: ticket.departureCity,
          initialArrivee: ticket.arrivalCity,
          initialDate: datePrevue,
          // 🟢 C'est ici qu'on passe l'info pour verrouiller le type
          ticketWasAllerRetour: ticket.isAllerRetour,
        ),
      ),
    );

    // 3. RETOUR DE L'UTILISATEUR
    // Si 'result' est null, c'est que l'utilisateur a fait "Retour" sans choisir.
    if (result == null) {
      debugPrint("❌ Modification annulée par l'utilisateur.");
      return;
    }

    debugPrint("✅ L'utilisateur a choisi : $result");

    // 4. ON ENVOIE LES DONNÉES CHOISIES À L'API
    // On cast le résultat en Map car Navigator renvoie un 'dynamic'
    if (result is Map<String, dynamic>) {
      _submitModification(result);
    }
  }



  Future<void> _submitModification(Map<String, dynamic> newBusData) async {
    setState(() => isLoading = true);

    try {
      debugPrint("📡 Envoi des données à l'API via Repository...");

      final Map<String, dynamic> apiBody = {
        "programme_id": newBusData['programme_id'],
        "date_voyage": newBusData['date_voyage'],
        "seat_number": newBusData['seat_number'],
        "heure_depart": newBusData['heure_depart'],
      };

      // Si c'est un aller-retour
      if (newBusData.containsKey('return_programme_id')) {
        apiBody.addAll({
          "return_programme_id": newBusData['return_programme_id'],
          "return_date_voyage": newBusData['return_date_voyage'],
          "return_seat_number": newBusData['return_seat_number'],
          "return_heure_depart": newBusData['return_heure_depart'],
        });
      }

      // Appel API
      // N'oublie pas le .toString() qu'on a vu tout à l'heure ;)
      final result = await widget.repository.modifyTicket(ticket.id.toString(), apiBody);

      debugPrint("📥 Résultat API reçu : $result");

      if (!mounted) return;

      if (result['success'] == true) {
        // ✅ SUCCÈS : C'est ici qu'on applique la logique de fusion Aller/Retour

        // 1. Récupération de la liste des tickets retournés par l'API
        // L'API renvoie souvent { "success": true, "data": [ ...tickets... ] }
        final List<dynamic> resultsList = (result['data'] is List) ? result['data'] : [];

        if (resultsList.isNotEmpty) {
          // --- DÉBUT DE LA LOGIQUE INTELLIGENTE ---

          // A. On cherche les infos globales (Date Aller vs Date Retour)
          DateTime? dateAllerGlobal;
          DateTime? dateRetourGlobal;
          String? heureAllerGlobal;
          String? heureRetourGlobal;
          String? siegeAllerGlobal;
          String? siegeRetourGlobal;

          for (var r in resultsList) {
            // On essaie de deviner si c'est le retour via un flag ou 'is_retour'
            // Si ton API ne renvoie pas 'is_retour', adapte ici.
            bool isThisRetour = r['is_retour'] == true || (r['reference'].toString().toLowerCase().contains("retour"));

            if (isThisRetour) {
              dateRetourGlobal = DateTime.tryParse(r['date_voyage']);
              heureRetourGlobal = r['heure_depart'];
              siegeRetourGlobal = r['seat_number'].toString();
            } else {
              dateAllerGlobal = DateTime.tryParse(r['date_voyage']);
              heureAllerGlobal = r['heure_depart'];
              siegeAllerGlobal = r['seat_number'].toString();
            }
          }

          // Sécurité : si on n'a pas trouvé de date aller, on prend le premier
          if (dateAllerGlobal == null && resultsList.isNotEmpty) {
            dateAllerGlobal = DateTime.tryParse(resultsList[0]['date_voyage']);
          }

          // B. On reconstruit les objets TicketModel
          List<TicketModel> newTickets = [];

          for (var r in resultsList) {
            bool isRetourItem = r['is_retour'] == true || (r['reference'].toString().toLowerCase().contains("retour"));

            newTickets.add(TicketModel(
              id: int.tryParse(r['id'].toString()) ?? 0,
              transactionId: r['reference'] ?? "",
              ticketNumber: "${r['reference']}",
              passengerName: "${r['passager_prenom']} ${r['passager_nom']}",

              // ⚡️ LA FUSION MAGIQUE ⚡️
              // 1. Infos Aller (Colonne Gauche) -> Toujours l'aller
              date: dateAllerGlobal ?? DateTime.now(),
              departureTimeRaw: heureAllerGlobal ?? "00:00",
              seatNumber: siegeAllerGlobal ?? "??",

              // 2. Infos Retour (Colonne Droite) -> Toujours le retour
              // C'est ça qui force l'affichage de la colonne retour !
              returnDate: dateRetourGlobal,
              returnTimeRaw: heureRetourGlobal,
              returnSeatNumber: siegeRetourGlobal,

              // 3. Flags
              isAllerRetour: true, // On sait que c'est un A/R modifié
              isReturnLeg: isRetourItem, // Pour le badge "RETOUR"

              // Reste des données
              departureCity: r['point_depart'] ?? "Départ",
              arrivalCity: r['point_arrive'] ?? "Arrivée",
              companyName: r['company_name'] ?? "Compagnie",
              status: r['statut'] ?? "Confirmé",
              qrCodeUrl: r['qr_code'],
              price: r['montant']?.toString() ?? "0",
            ));
          }

          // --- FIN DE LA LOGIQUE INTELLIGENTE ---

          // C. Mise à jour de l'UI immédiate
          if (mounted) {
            setState(() {
              // On affiche le ticket Aller par défaut (celui qui n'est pas le retour)
              ticket = newTickets.firstWhere((t) => !t.isReturnLeg, orElse: () => newTickets.first);
              isLoading = false;
            });

            _showTopNotification("Billet modifié avec succès ! 🎉", isError: false);
          }

        } else {
          // Cas rare : succès mais pas de données renvoyées ? On recharge tout au cas où
          _loadFullDetails();
        }

      } else {
        // ECHEC API
        _showTopNotification(result['message'] ?? "Échec modification", isError: true);
        setState(() => isLoading = false);
      }

    } catch (e) {
      debugPrint("🔴 CRASH DANS _submitModification : $e");
      if (mounted) {
        _showTopNotification("Erreur: $e", isError: true);
        setState(() => isLoading = false);
      }
    }
  }


  Future<bool> _showModificationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: const [
            Icon(Icons.edit_calendar_rounded, color: Colors.blueAccent), // Icône modif
            SizedBox(width: 10),
            Text("Modifier le voyage", style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Procédure de modification :",
              style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
            ),
            const SizedBox(height: 15),

            const Text("Vous allez être redirigé pour choisir un nouveau trajet (Date ou Horaire)."),
            const SizedBox(height: 10),

            // Petit récapitulatif du billet actuel
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3))
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Valeur actuelle :", style: TextStyle(fontSize: 12)),
                      Text("${ticket.price} F", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),
            const Text(
              "⚠️ Des frais de modification peuvent s'appliquer selon le nouveau trajet choisi.",
              style: TextStyle(fontSize: 12, color: Colors.orange, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Annuler
            child: const Text("Retour", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), // Confirmer
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text("Choisir un nouveau trajet", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ) ?? false; // Retourne false si on clique à côté
  }



  // ------------------------------------------------------------------------
  // 🖥 UI BUILD
  // ------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    String formatDate(DateTime d) => "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";

    // Calcul sécurité pour QR Code
    final bool isDepartPasse = _departureDateTime != null && DateTime.now().isAfter(_departureDateTime!);

    return WillPopScope(
        onWillPop: () async {
          // On quitte l'écran en renvoyant l'info : "Est-ce que ça a changé ?"
          Navigator.pop(context, hasChanged);
          return false; // false car on a géré le pop manuellement juste au-dessus
        },
    child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
          title: const Text("Détails du Billet"),
          elevation: 0,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (isLoading) const LinearProgressIndicator(),

            // ---------------------------------------------------------
            // 🎫 LA CARTE PRINCIPALE (Détails + Boutons intégrés)
            // ---------------------------------------------------------
            Card(
              elevation: 4,
              // ✅ IMPORTANT : Coupe tout ce qui dépasse des bords arrondis
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Column(
                children: [
                  // --- PARTIE HAUTE : CONTENU DU TICKET ---
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                ticket.companyName.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _buildStatusChip(ticket.status),
                          ],
                        ),
                        const Divider(height: 25),

                        _buildTripDetails(ticket, formatDate),

                        const Divider(height: 30),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: _buildCityInfo(ticket.departureCity, "Départ")),
                              const Icon(Icons.arrow_forward, color: Colors.blue, size: 24),
                              Expanded(child: _buildCityInfo(ticket.arrivalCity, "Arrivée"))
                            ]
                        ),
                        const Divider(height: 30),
                        _buildRow("Passager", ticket.passengerName),
                        _buildRow("Siège", ticket.isAllerRetour && ticket.returnSeatNumber != null ? "${ticket.seatNumber} / ${ticket.returnSeatNumber}" : ticket.seatNumber),
                        _buildRow("Prix", "${ticket.price} F"),
                        _buildRow("Réf", ticket.ticketNumber),
                      ],
                    ),
                  ),

                  // --- PARTIE BASSE : LES BOUTONS "PINCEAUX" ---
                  if (_isActionPossible) ...[
                    // Une ligne de séparation fine
                    const Divider(height: 1, thickness: 1),

                    SizedBox(
                      height: 55, // Hauteur fixe pour les boutons
                      child: Row(
                        children: [
                          // 🔴 BOUTON ANNULER (Gauche)
                          Expanded(
                            child: InkWell(
                              onTap: _cancelTicket,
                              // Effet visuel au clic
                              splashColor: Colors.red.withOpacity(0.2),
                              child: Container(
                                color: Colors.red.withOpacity(0.05), // Fond très léger rouge
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: const [
                                    Icon(Icons.cancel_outlined, color: Colors.red, size: 20),
                                    SizedBox(width: 8),
                                    Text("Annuler", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Petit trait vertical entre les deux
                          Container(width: 1, color: Colors.grey.shade300),

                          // 🔵 BOUTON MODIFIER (Droite)
                          Expanded(
                            child: InkWell(
                              onTap: _startModificationProcess,
                              splashColor: Colors.blue.withOpacity(0.2),
                              child: Container(
                                // On peut mettre un fond bleu plein ou léger, ici léger pour l'harmonie
                                color: Colors.blue.withOpacity(0.05),
                                alignment: Alignment.center,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.edit_outlined, color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Text("Modifier", style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  ]
                ],
              ),
            ),

            const SizedBox(height: 20),

            // --- CAS OU MODIFICATION IMPOSSIBLE (Message d'info) ---
            if (!_isActionPossible && _isStatusValid && !isDepartPasse) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                child: Row(children: const [Icon(Icons.lock_clock, color: Colors.orange, size: 20), SizedBox(width: 10), Expanded(child: Text("Modifications verrouillées (-15 min).", style: TextStyle(color: Colors.orange, fontSize: 12)))]),
              ),
              const SizedBox(height: 30),
            ],

            // --- QR CODE ---
            if (_isStatusValid && !isDepartPasse)
              _buildActiveQRCodeView(context)
            else
              _buildExpiredOrUsedView(),

            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
    );
  }

  // --- WIDGETS ---

  Widget _buildStatusChip(String status) {
    String s = status.toLowerCase();
    Color color = Colors.blue;
    if (s.contains("valid") || s.contains("confirm") || s.contains("pay") || s.contains("success")) color = Colors.green;
    else if (s.contains("annul")) color = Colors.red;
    else if (s.contains("termin") || s.contains("util")) color = Colors.grey;

    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12))
    );
  }

  Widget _buildActiveQRCodeView(BuildContext context) {
    return Column(children: [
      const Text("Présentez ce code à l'embarquement", style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      if (ticket.qrCodeUrl != null && ticket.qrCodeUrl!.isNotEmpty)
        GestureDetector(
            onTap: () => showModalBottomSheet(context: context, builder: (_) => Center(child: Image.memory(base64Decode(ticket.qrCodeUrl!), width: 300))),
            child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.blue.withOpacity(0.3)), borderRadius: BorderRadius.circular(15)),
                child: Column(children: [
                  Image.memory(base64Decode(ticket.qrCodeUrl!), height: 180, width: 180, errorBuilder: (c,e,s) => const Icon(Icons.qr_code, size: 100)),
                  const SizedBox(height: 10),
                  const Text("Cliquez pour agrandir", style: TextStyle(color: Colors.blue, fontSize: 12))
                ])
            )
        )
      else
        const Text("QR code indisponible")
    ]);
  }

  Widget _buildExpiredOrUsedView() {
    return Container(
        width: double.infinity, padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(20)),
        child: Column(children: const [Icon(Icons.event_busy, size: 60, color: Colors.grey), SizedBox(height: 15), Text("Billet non valide (Expiré/Annulé)", style: TextStyle(fontSize: 16, color: Colors.grey))])
    );
  }

  Widget _buildTripDetails(TicketModel t, Function(DateTime) fmt) {
    return Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(12)),
        child: Row(children: [
          Expanded(child: Column(children: [const Text("ALLER", style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)), Text(fmt(t.date), style: const TextStyle(fontWeight: FontWeight.bold)), Text(t.departureTimeRaw)])),
          if (t.isAllerRetour && t.returnDate != null) ...[
            Container(width: 1, height: 40, color: Colors.grey.shade300, margin: const EdgeInsets.symmetric(horizontal: 10)),
            Expanded(child: Column(children: [const Text("RETOUR", style: TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.bold)), Text(fmt(t.returnDate!), style: const TextStyle(fontWeight: FontWeight.bold)), Text(t.returnTimeRaw ?? "--:--")]))
          ]
        ])
    );
  }

  Widget _buildCityInfo(String city, String label) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      const SizedBox(height: 4),
      Text(city.isEmpty ? "--" : city.replaceAll(", Côte d'Ivoire", ""), textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)
    ]);
  }

  /*Widget _buildRow(String label, String value) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: const TextStyle(color: Colors.grey)), Text(value, style: const TextStyle(fontWeight: FontWeight.bold))]));
  }*/

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start, // ✅ Important pour l'alignement vertical si ça passe à la ligne
        children: [
          // Le Label (à gauche)
          Text(
              label,
              style: const TextStyle(color: Colors.grey)
          ),

          const SizedBox(width: 10), // ✅ Petit espace de sécurité

          // La Valeur (à droite)
          Expanded( // ✅ Expanded force le texte à prendre la place restante sans déborder
            child: Text(
              value,
              textAlign: TextAlign.end, // ✅ On aligne à droite comme avant
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}