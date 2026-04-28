import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

// --- TES IMPORTS (Vérifie les chemins) ---
import '../../../../common/widgets/NotificationIconBtn.dart';
import '../../../../common/widgets/local_badge.dart'; // Vérifie le nom
import '../../../../common/widgets/ticket_card.dart'; // Si tu l'utilises
import '../../../../core/providers/user_provider.dart';
import '../../../../core/services/networking/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/data/models/ticket_model.dart';
import '../../../booking/data/repositories/ticket_repository_impl.dart';
import '../../../booking/domain/repositories/ticket_repository.dart';
import '../utils/ticket_layout_widget.dart';
import 'all_ticket_search_screen.dart';
import 'notification_screen.dart';
import 'profil_screen.dart';
import 'ticket_detail_screen.dart'; // Ajouté pour la navigation

class MyTicketsTabScreen extends StatefulWidget {
  final VoidCallback? onGoHome; // 🟢 1. Ajout du callback

  const MyTicketsTabScreen({super.key, this.onGoHome});

  @override
  State<MyTicketsTabScreen> createState() => _MyTicketsTabScreenState();
}

class _MyTicketsTabScreenState extends State<MyTicketsTabScreen>  with SingleTickerProviderStateMixin {
  // --- ÉTAT ---
  List<TicketModel> allTickets = [];
  List<TicketModel> displayedTickets = [];
  bool isLoading = true;
  String selectedFilter = "Total";
  late TicketRepository _ticketRepository;
  final Set<String> _downloadingTicketIds = {};


  // 🟢 2. DECLARATION DU CONTROLLER D'ANIMATION
  late AnimationController _entranceController;

  @override
  void initState() {
    super.initState();


    // 🟢 3. INITIALISATION DE L'ANIMATION
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2000), // La durée que tu as choisie
      vsync: this,
    );

    // Déclencher l'animation
    //_entranceController.forward();

    _initData();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }


  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    final String token = prefs.getString('auth_token') ?? '';

    final dio = Dio(BaseOptions(
      // 🟢 ApiConfig centralisé
      baseUrl: ApiConfig.baseUrl,

      // ✅ HEADERS DÉCOMMENTÉS ET ACTIFS
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json', // Oblige Laravel à renvoyer du JSON et non une redirection 302 HTML
        'Authorization': 'Bearer $token'
      },
    ));

    _ticketRepository = TicketRepositoryImpl(dio: dio);
    _fetchTickets();
  }





  Future<void> _fetchTickets() async {
    debugPrint("🟡 [UI] _fetchTickets : Démarrage...");

    try {
      // 1. On récupère les données brutes de l'API (avec display_statut géré par le repo)
      final List<TicketModel> rawTickets = await _ticketRepository.getMyTickets();

      final List<TicketModel> processedTickets = [];
      final DateTime now = DateTime.now();

      // 2. BOUCLE DE TRAITEMENT UI (Nettoyage + Expiration)
      for (var ticket in rawTickets) {

        // A. On récupère le statut brut venant du Repository (ex: "confirmee", "arrive", "en_voyage")
        String rawBackendStatus = ticket.status;

        // B. On le passe au nettoyeur (ex: devient "Confirmé", "Arrivé", "En voyage")
        String cleanStatus = _normalizeStatus(rawBackendStatus);

        // C. LOGIQUE D'EXPIRATION
        // On calcule la fin de validité (23h59 le jour du voyage)
        DateTime expirationDate = ticket.date.add(const Duration(hours: 23, minutes: 59));

        // Si la date est passée...
        // ... ET que le ticket n'est pas dans un état final spécifique (Annulé, Terminé, Arrivé)
        // Alors on le force en "Terminé".
        // Note: On garde "Arrivé" tel quel car c'est plus précis que "Terminé".
        if (now.isAfter(expirationDate) &&
            cleanStatus != "Annulé" &&
            cleanStatus != "Terminé" &&
            cleanStatus != "Arrivé") {
          cleanStatus = "Terminé";
        }

        // D. CRÉATION DU TICKET FINAL POUR L'AFFICHAGE
        processedTickets.add(TicketModel(
          id: ticket.id,
          transactionId: ticket.transactionId,
          ticketNumber: ticket.ticketNumber,
          passengerName: ticket.passengerName,
          seatNumber: ticket.seatNumber,
          returnSeatNumber: ticket.returnSeatNumber,
          departureCity: ticket.departureCity,
          arrivalCity: ticket.arrivalCity,
          companyName: ticket.companyName,
          departureTimeRaw: ticket.departureTimeRaw,
          date: ticket.date,

          // ✅ ICI : Le statut propre et corrigé
          status: cleanStatus,

          pdfBase64: ticket.pdfBase64,
          qrCodeUrl: ticket.qrCodeUrl,
          price: ticket.price,
          isAllerRetour: ticket.isAllerRetour,
          returnDate: ticket.returnDate,
          isReturnLeg: ticket.isReturnLeg, // Important pour ne pas perdre l'info
        ));
      }

      if (mounted) {
        setState(() {
          allTickets = processedTickets;

          // --- 🔢 CALCUL DES COMPTEURS (CORRIGÉ) ---

          // 1. Total
          int totalCount = allTickets.length;

          // 2. Confirmé (On compte tout ce qui tombe dans la catégorie "Confirmé")
          int confirmedCount = allTickets.where((t) =>
          _getCategoryForStatus(t.status) == "Confirmé"
          ).length;

          // 3. Terminé (On compte tout ce qui tombe dans la catégorie "Terminé")
          // Cela va inclure : "Terminé", "Annulé" ET "Arrivé" ✅
          int finishedCount = allTickets.where((t) =>
          _getCategoryForStatus(t.status) == "Terminé"
          ).length;

          // Si tu as des variables d'état pour l'affichage, mets-les à jour ici :
          // exemple : this.nbTermines = finishedCount;

          debugPrint("📊 STATS : Total=$totalCount | Confirmé=$confirmedCount | Terminé=$finishedCount");

          // On réapplique le filtre actuel
          _applyFilter(selectedFilter);
          isLoading = false;
        });
        // ✅ DÉCLENCHE L'ANIMATION ICI (depuis le début à chaque chargement)
        _entranceController.forward(from: 0.0);
      }


    } catch (e) {
      debugPrint("🔴 [UI] _fetchTickets : Erreur -> $e");
      if (mounted) setState(() => isLoading = false);
    }
  }


  String _getCategoryForStatus(String cleanStatus) {
    // Ici cleanStatus vaut déjà "Confirmé", "Arrivé", "Annulé"... grâce à l'étape 1

    // 1. Tout ce qui est FINI ou NÉGATIF -> Onglet Terminé
    if (cleanStatus == "Terminé" ||
        cleanStatus == "Arrivé" ||
        cleanStatus == "Annulé") {
      return "Terminé";
    }

    // 2. Tout le reste est ACTIF -> Onglet Confirmé
    // (Cela inclut : Confirmé, Enregistré, En voyage)
    return "Confirmé";
  }


  // 🧹 LE NETTOYEUR : Transforme le charabia du backend en beau Français
  String _normalizeStatus(String rawStatus) {
    String s = rawStatus.toLowerCase().trim();

    // 🔴 Annulations (annulee, annule, cancel...)
    if (s.contains("annul") || s.contains("cancel")) {
      return "Annulé";
    }

    // 🟢 Confirmations (confirmee, confirme, paye, valide...)
    if (s.contains("confirm") || s.contains("valid") || s.contains("pay")) {
      return "Confirmé";
    }

    // 🔵 Actions en cours
    if (s.contains("enregistre")) {
      return "Enregistré";
    }
    if (s.contains("voyage")) {
      return "En voyage";
    }

    // ⚫ Fin de parcours (arrive, termine...)
    if (s.contains("arriv")) {
      return "Arrivé";
    }
    if (s.contains("termin") || s.contains("util") || s.contains("scan")) {
      return "Terminé";
    }

    // Par défaut, on met une majuscule au début
    if (rawStatus.isNotEmpty) {
      return "${rawStatus[0].toUpperCase()}${rawStatus.substring(1)}";
    }
    return rawStatus;
  }

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == "Total") {
        displayedTickets = allTickets;
      } else {
        // On filtre selon la CATEGORIE, pas le texte exact
        displayedTickets = allTickets.where((t) => _getCategoryForStatus(t.status) == filter).toList();
      }
    });
  }

  Future<void> _handleDownload(TicketModel ticket) async {
    debugPrint("🟡 Téléchargement ticket : ${ticket.ticketNumber}");
    setState(() => _downloadingTicketIds.add(ticket.id.toString()));
    _showTopNotification("Génération du billet... 🎨");

    try {
      final String tempQrPath = await _ticketRepository.downloadTicketImage(ticket.id.toString());
      final File qrFile = File(tempQrPath);
      final Uint8List qrBytes = await qrFile.readAsBytes();

      final screenshotController = ScreenshotController();
      final Uint8List finalImageBytes = await screenshotController.captureFromWidget(
          TicketLayoutWidget(ticket: ticket, qrCodeBytes: qrBytes),
          pixelRatio: 3.0,
          delay: const Duration(milliseconds: 150),
          context: context
      );

      final directory = await getApplicationDocumentsDirectory();
      final String fileName = "Ticket_${ticket.ticketNumber.replaceAll(' ', '_')}.png";
      final String finalFilePath = '${directory.path}/$fileName';
      final File finalFile = File(finalFilePath);
      await finalFile.writeAsBytes(finalImageBytes);

      _showTopNotification("Billet prêt ! ✅");
      await OpenFilex.open(finalFilePath);

    } catch (e) {
      debugPrint("🔴 Erreur download : $e");
      _showTopNotification("Erreur lors du téléchargement ❌");
    } finally {
      if (mounted) setState(() => _downloadingTicketIds.remove(ticket.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = Colors.grey;


    //final int previewCount = displayedTickets.length > 3 ? 3 : displayedTickets.length;
    final int previewCount = displayedTickets.length > 3 ? 3 : displayedTickets.length;
    final List<TicketModel> previewTickets = displayedTickets.take(previewCount).toList();
    final bool showViewAllButton = displayedTickets.length > 3;


    // 1. Total
    final int totalCount = allTickets.length;

    // 2. Confirmé : On utilise _getCategoryForStatus pour inclure "En voyage", "Enregistré", etc.
    final int confirmCount = allTickets.where((t) =>
    _getCategoryForStatus(t.status) == "Confirmé"
    ).length;

    // 3. Terminé : On utilise _getCategoryForStatus pour inclure "Annulé", "Arrivé", "Terminé"
    final int finishedCount = allTickets.where((t) =>
    _getCategoryForStatus(t.status) == "Terminé"
    ).length;


    return Scaffold(
      backgroundColor: scaffoldColor,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Mes Réservations", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor)),
                  Text("Gérez vos voyages confirmés et passés", style: TextStyle(color: secondaryTextColor, fontSize: 13)),
                  const Gap(20),

                  // FILTRES
                  /*Row(
                    children: [
                      Expanded(child: _buildStatFilterCard(context, "$totalCount", "Total", "Total", Colors.orange)),
                      const Gap(10),
                      Expanded(child: _buildStatFilterCard(context, "$confirmCount", "Confirmé", "Confirmé", Colors.green)),
                      const Gap(10),
                      Expanded(child: _buildStatFilterCard(context, "$finishedCount", "Terminé", "Terminé", Colors.grey)),
                    ],
                  ),*/


                  // FILTRES ANIMÉS
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnimatedElement(
                          index: 0,
                          child: _buildStatFilterCard(context, "$totalCount", "Total", "Total", Colors.orange),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: _buildAnimatedElement(
                          index: 1,
                          child: _buildStatFilterCard(context, "$confirmCount", "Confirmé", "Confirmé", Colors.green),
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: _buildAnimatedElement(
                          index: 2,
                          child: _buildStatFilterCard(context, "$finishedCount", "Terminé", "Terminé", Colors.grey),
                        ),
                      ),
                    ],
                  ),



                  const Gap(25),

                  // LISTE
                  if (isLoading)
                    SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                  else if (displayedTickets.isEmpty)
                  // 🟢 ICI ON APPELLE NOTRE NOUVELLE INTERFACE ÉLÉGANTE
                    _buildEmptyState(context)
                  else ...[
                      // Utilisation de TA fonction _buildTicketCard intégrée avec l'animation
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: previewTickets.length,
                        separatorBuilder: (context, index) => const Gap(20),
                        itemBuilder: (context, index) {

                          // 🟢 1. CALCUL DE L'ANIMATION EN CASCADE
                          final double startDelay = (index % 10) * 0.1;
                          final double endDelay = (startDelay + 0.5).clamp(0.0, 1.0);

                          final animation = CurvedAnimation(
                            parent: _entranceController,
                            curve: Interval(
                              startDelay,
                              endDelay,
                              curve: Curves.easeOutCubic,
                            ),
                          );

                          // 🟢 2. APPLICATION DE LA TRANSITION
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3), // Commence légèrement plus bas
                              end: Offset.zero,            // Finit à sa position normale
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,          // Apparition en fondu
                              child: _buildTicketCard(context, ticket: previewTickets[index]),
                            ),
                          );
                        },
                      ),

                      if (showViewAllButton) ...[
                        const Gap(20),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => AllTicketsSearchScreen(
                                allTickets: displayedTickets,
                                repository: _ticketRepository,
                                onDownload: _handleDownload,
                                downloadingIds: _downloadingTicketIds,
                              )));
                            },
                            style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15), backgroundColor: Theme.of(context).cardColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Voir tous les tickets (${displayedTickets.length})", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)), const Gap(8), const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary)]),
                          ),
                        ),
                      ],
                    ],
                  const Gap(100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ÉTAT VIDE (Empty State) ---
  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brandColor = const Color(0xFFE34001); // 🟢 1. Uniformisé avec l'orange des Convois

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Gap(5), // 🟢 2. Espace du haut réduit pour faire remonter le bloc

        // Titre et sous-titre
        Text(
          "Aucune réservation",
          style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87
          ),
        ),
        const Gap(8),
        Text(
          "Vous n'avez pas encore de billets de bus. Recherchez un trajet et planifiez votre prochain voyage !",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),

        const Gap(20), // 🟢 Espace réduit (était 30)

        // Le "Sticker" élégant pour les tickets
        Container(
          padding: const EdgeInsets.all(20), // 🟢 Padding réduit (était 25)
          decoration: BoxDecoration(
            color: brandColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.confirmation_number_outlined, size: 65, color: brandColor), // 🟢 Taille de l'icône réduite (était 80)
        ),

        const Gap(25), // 🟢 Espace réduit (était 35)

        // Le bouton d'action
        // Le bouton d'action
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              // 🟢 3. On déclenche le changement d'onglet vers l'accueil !
              if (widget.onGoHome != null) {
                widget.onGoHome!();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: brandColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.search, size: 20),
            label: const Text("Rechercher un trajet", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ),
      ],
    );
  }


  // --- FONCTION POUR ANIMER UN ELEMENT (Filtres ou autres) ---
  Widget _buildAnimatedElement({required int index, required Widget child}) {
    // Calcul de l'animation en cascade : le premier (0) commence de suite, le 2ème (1) un peu après, etc.
    final double startDelay = index * 0.10;
    final double endDelay = (startDelay + 0.1).clamp(0.0, 1.0);

    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(startDelay, endDelay, curve: Curves.easeOutCubic),
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5), // Glisse du bas vers le haut
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }


  // --- TON WIDGET HEADER CORRIGÉ ---
  Widget _buildHeader(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // ✅ CORRECTION 1 : On récupère la hauteur exacte de la barre d'état (encoche)
    final double topPadding = MediaQuery.of(context).padding.top;

    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: const DecorationImage(
            image: AssetImage("assets/images/busheader4.jpg"),
            fit: BoxFit.cover
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withOpacity(0.7), Colors.transparent],
              stops: const [0.0, 0.6]
          ),
        ),
        // ✅ CORRECTION 2 : On remplace le widget SafeArea par un Padding manuel
        child: Padding(
          padding: EdgeInsets.only(
            // On pousse le contenu vers le bas : Hauteur barre d'état + 15px de marge
              top: topPadding + 15,
              left: 20,
              right: 20,
              bottom: 20
          ),
          child: Column(
            // On utilise une Column pour être sûr que le contenu commence en haut
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center, // Important pour l'alignement vertical
                children: [
                  // GAUCHE : Avatar + Localisation
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: CircleAvatar(
                              radius: 24, // Taille fixe garantie
                              backgroundColor: Colors.grey[200],
                              backgroundImage: user != null ? NetworkImage(user.fullPhotoUrl) : const AssetImage("assets/images/ci.jpg") as ImageProvider
                          ),
                        ),
                      ),
                      const Gap(12),
                      // Si ton LocationBadge est coupé, c'est souvent qu'il manque de place en hauteur
                      // On s'assure qu'il est bien centré dans la Row
                      const LocationBadge(),
                    ],
                  ),

                  // DROITE : Notification
                  const NotificationIconBtn(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- FILTRES ---
  Widget _buildStatFilterCard(BuildContext context, String count, String label, String filterKey, MaterialColor baseColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = selectedFilter == filterKey;
    final bgColor = isSelected ? baseColor.withOpacity(isDark ? 0.2 : 0.1) : (isDark ? Colors.grey[900] : Colors.grey[100]);
    final borderColor = isSelected ? baseColor : Colors.transparent;

    return GestureDetector(
      onTap: () => _applyFilter(filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(15), border: Border.all(color: borderColor!, width: 2)),
        child: Column(children: [Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: label == "Terminé" ? Colors.grey : (isSelected ? baseColor : (isDark ? Colors.white : Colors.black)))), const Gap(5), Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.w500))]),
      ),
    );
  }

  // --- CARTE TICKET AVEC LOGIQUE TERMINÉ CORRIGÉE ---
  Widget _buildTicketCard(BuildContext context, {required TicketModel ticket}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final primaryColor = AppColors.primary;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;

    // --- LOGIQUE DES COULEURS DYNAMIQUE ---
    Color badgeBg;
    Color badgeText;
    String badgeLabel = ticket.status; // On affiche le TEXTE EXACT du backend (ex: "En voyage")

    String category = _getCategoryForStatus(ticket.status); // On utilise la fonction d'aide créée plus haut

    if (category == "Confirmé") {
      // Vert pour Confirmé, Enregistré, En voyage...
      badgeBg = Colors.green.withOpacity(0.1);
      badgeText = Colors.green[700]!;
    } else if (category == "Annulé") {
      badgeBg = Colors.red.withOpacity(0.1);
      badgeText = Colors.red;
    } else {
      // Gris pour Terminé, Arrivé...
      badgeBg = Colors.grey.withOpacity(0.2);
      badgeText = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))], border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Badge PAYÉ seulement si c'est Confirmé ou Terminé (pas annulé)
              if(ticket.status != "Annulé")
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(Icons.check_circle, size: 14, color: primaryColor), const SizedBox(width: 4), Text("PAYÉ", style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12))])),
              if(ticket.status == "Annulé")
                const SizedBox(), // Spacer vide

              // Badge Statut
              Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)), child: Text(badgeLabel, style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const Gap(20),

          // SIÈGE
          Column(
            children: [
              const Text("N° SIÈGE", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w600)),
              const Gap(5),
              if (ticket.isAllerRetour && ticket.returnSeatNumber != null)
                Row(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [Text(ticket.seatNumber, style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: textColor)), Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text("/", style: TextStyle(fontSize: 30, color: Colors.grey[300]))), Text("${ticket.returnSeatNumber}", style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: Colors.orange))])
              else
                Text(ticket.seatNumber, style: TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: textColor)),
            ],
          ),
          const Gap(20),
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                    // 🔴 C'EST ICI LA CLÉ DU PROBLÈME 🔴
                      onPressed: () async {
                        // 1. On attend (await) le résultat de l'écran détails
                        // result sera 'true' si on a annulé ou modifié (grâce à l'étape 1)
                        final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TicketDetailScreen(
                                    initialTicket: ticket,
                                    repository: _ticketRepository
                                )
                            )
                        );

                        // 2. Si on revient et que quelque chose a changé (ou même dans le doute)
                        // On recharge la liste !
                        if (result == true) {
                          debugPrint("♻️ Retour des détails avec changement -> RECHARGEMENT");
                          _fetchTickets(); // Cela va mettre à jour le statut en "Annulé" ou "Modifié"
                        }
                      },

                      icon: Icon(Icons.info_outline, size: 16, color: textColor),
                      label: Text("Détails", style: TextStyle(color: textColor, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      )
                  )
              ),

              const Gap(10),

              // --- Bouton TÉLÉCHARGER (Modifié avec Image) ---
              Expanded(
                child: Container(
                  // Pas de hauteur fixe ici, on laisse le padding du bouton définir la hauteur
                  // pour qu'il fasse exactement la même taille que le bouton "Détails" à côté.
                  clipBehavior: Clip.hardEdge,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),

                    // ✅ LOGIQUE IMAGE :
                    // Si le statut est "Confirmé", on met l'image. Sinon (Annulé, etc.), on met null.
                    image: ticket.status == "Confirmé"
                        ? const DecorationImage(
                      image: AssetImage("assets/images/tabaa.jpg"),
                      fit: BoxFit.cover,
                    )
                        : null,

                    // ✅ LOGIQUE COULEUR :
                    // Si pas d'image (donc pas confirmé), on met du gris.
                    color: ticket.status == "Confirmé" ? null : Colors.grey,
                  ),

                  child: ElevatedButton.icon(
                    // Condition d'activation (inchangée)
                    onPressed: (ticket.status == "Confirmé" && !_downloadingTicketIds.contains(ticket.id))
                        ? () => _handleDownload(ticket)
                        : null,

                    icon: const Icon(Icons.download, size: 16, color: Colors.white),
                    label: const Text("Télécharger", style: TextStyle(color: Colors.white, fontSize: 14)),

                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14), // Même padding que "Détails"

                      // ✅ TOUT TRANSPARENT pour voir le Container derrière
                      backgroundColor: Colors.transparent,
                      disabledBackgroundColor: Colors.transparent, // Important : même désactivé (ex: en cours de téléchargement), on voit l'image
                      shadowColor: Colors.transparent,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTopNotification(String message) {
    if (!mounted) return;
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(builder: (context) => Positioned(top: 60.0, left: 20.0, right: 20.0, child: Material(color: Colors.transparent, child: TweenAnimationBuilder<double>(tween: Tween(begin: 0.0, end: 1.0), duration: const Duration(milliseconds: 300), curve: Curves.easeOutBack, builder: (context, value, child) => Transform.scale(scale: value, child: Opacity(opacity: value, child: child)), child: Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15), decoration: BoxDecoration(color: const Color(0xFF222222), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))]), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.info_outline, color: Colors.white, size: 20), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center, maxLines: 2))]))))));
    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () { if (overlayEntry.mounted) overlayEntry.remove(); });
  }
}