import 'package:car225/features/home/presentation/screens/ticket_detail_screen.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:open_filex/open_filex.dart'; // Assure-toi d'avoir open_filex dans pubspec.yaml
import 'package:provider/provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';


// --- TES IMPORTS ---
// Vérifie bien que ces chemins correspondent à ton projet
import '../../../../common/widgets/local_badge.dart';
import '../../../../common/widgets/ticket_card.dart';
import '../../../../core/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../booking/data/models/ticket_model.dart';
import '../../../booking/domain/repositories/ticket_repository.dart';
import '../utils/ticket_layout_widget.dart';
import 'all_ticket_search_screen.dart';
import 'notification_screen.dart';
import 'profil_screen.dart';



class MyTicketsTabScreen extends StatefulWidget {
  const MyTicketsTabScreen({super.key});

  @override
  State<MyTicketsTabScreen> createState() => _MyTicketsTabScreenState();
}

class _MyTicketsTabScreenState extends State<MyTicketsTabScreen> {
  // --- ÉTAT ---
  List<TicketModel> allTickets = [];
  List<TicketModel> displayedTickets = [];
  bool isLoading = true;
  String selectedFilter = "Total";

  late TicketRepository _ticketRepository;


  // Set pour stocker les IDs des tickets en cours de téléchargement
  final Set<String> _downloadingTicketIds = {};


  @override
  void initState() {
    super.initState();
    // On lance l'initialisation asynchrone
    _initData();
  }



  Future<void> _initData() async {
    // 1. Récupération du Token
    final prefs = await SharedPreferences.getInstance();

    // 👇 CORRECTION ICI : 'auth_token' au lieu de 'token'
    final String token = prefs.getString('auth_token') ?? '';

    debugPrint("🔑 Token lu depuis SharedPreferences : '$token'");

    if (token.isEmpty) {
      debugPrint("⚠️ ATTENTION : Le token est vide ! L'utilisateur est-il bien connecté ?");
      // Tu pourrais rediriger vers le login ici si tu voulais
    }

    // 2. Configuration de Dio AVEC le token
    final dio = Dio(BaseOptions(
      baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $token', // Le token est maintenant correct
      },
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
    ));

    // Logs pour le debug
    dio.interceptors.add(LogInterceptor(request: true, requestHeader: true, error: true));

    // 3. Initialisation du Repository
    _ticketRepository = TicketRepository(dio: dio);

    // 4. Lancement de la récupération
    _fetchTickets();
  }



  Future<void> _fetchTickets() async {
    debugPrint("🟡 [UI] _fetchTickets : Démarrage...");
    try {
      // _ticketRepository est maintenant initialisé avec le bon Dio
      final tickets = await _ticketRepository.getMyTickets();

      if (mounted) {
        setState(() {
          allTickets = tickets;
          displayedTickets = tickets;
          isLoading = false;
        });
        debugPrint("🟢 [UI] _fetchTickets : Succès (${tickets.length} billets chargés)");
      }
    } catch (e) {
      debugPrint("🔴 [UI] _fetchTickets : Erreur -> $e");
      if (mounted) {
        setState(() => isLoading = false);
        // On n'affiche le toast que si ce n'est pas juste une initialisation vide
        if (allTickets.isEmpty) {
          _showTopNotification("Impossible de charger les billets ⚠️");
        }
      }
    }

  }




  // Mise à jour de la fonction de filtrage

  void _applyFilter(String filter) {
    setState(() {
      selectedFilter = filter;
      if (filter == "Total") {
        displayedTickets = allTickets;
      } else if (filter == "Terminé") {
        // L'onglet "Terminé" affiche les tickets scannés ET les expirés
        displayedTickets = allTickets.where((t) =>
        t.status == "Terminé" || t.status == "Expiré"
        ).toList();
      } else {
        // Pour "Confirmé", on cherche exact
        displayedTickets = allTickets.where((t) => t.status == filter).toList();
      }
    });
  }



  Future<void> _handleDownload(TicketModel ticket) async {
    debugPrint("🟡 [UI] Clic bouton Télécharger pour le ticket : ${ticket.ticketNumber}");

    setState(() {
      _downloadingTicketIds.add(ticket.id);
    });

    // Étape 1 : On prévient l'utilisateur
    _showTopNotification("Génération de votre billet personnalisé... 🎨");

    try {
      // -----------------------------------------------------------
      // 1. TÉLÉCHARGER LE QR CODE SEUL (Via le Repository corrigé)
      // -----------------------------------------------------------
      // Le repository télécharge le fichier (QR code) et nous donne son chemin temporaire
      final String tempQrPath = await _ticketRepository.downloadTicketImage(ticket.id);
      debugPrint("✅ QR Code temporaire téléchargé ici : $tempQrPath");

      // On lit le fichier téléchargé pour avoir les octets (nécessaire pour le widget suivant)
      final File qrFile = File(tempQrPath);
      if (!await qrFile.exists()) throw Exception("Le fichier QR code n'existe pas");
      final Uint8List qrBytes = await qrFile.readAsBytes();

      // -----------------------------------------------------------
      // 2. PRÉPARER LA CAPTURE D'IMAGE (Ton design)
      // -----------------------------------------------------------
      final screenshotController = ScreenshotController();

      // On capture ton widget personnalisé invisible.
      // Le pixelRatio assure une bonne qualité.
      // Le delay laisse le temps au QR code de s'afficher dans le widget.
      final Uint8List finalImageBytes = await screenshotController.captureFromWidget(
          TicketLayoutWidget(
              ticket: ticket,
              qrCodeBytes: qrBytes // On passe les bytes du QR code téléchargé
          ),
          pixelRatio: 3.0,
          delay: const Duration(milliseconds: 150),
          context: context // Parfois nécessaire pour les thèmes/fonts
      );

      // -----------------------------------------------------------
      // 3. SAUVEGARDER L'IMAGE FINALE (Le vrai billet complet)
      // -----------------------------------------------------------
      final directory = await getApplicationDocumentsDirectory();

      // Création d'un nom de fichier propre
      final String safeCompanyName = ticket.companyName.replaceAll(RegExp(r'[^\w\s]+'), '').replaceAll(' ', '_');
      final String safeTicketNum = ticket.ticketNumber.replaceAll(RegExp(r'[^\w\s]+'), '');
      final String fileName = "Billet_${safeCompanyName}_$safeTicketNum.png";

      final String finalFilePath = '${directory.path}/$fileName';
      final File finalFile = File(finalFilePath);

      // Écriture du résultat de la capture sur le disque
      await finalFile.writeAsBytes(finalImageBytes);
      debugPrint("🟢 [UI] Billet COMPLET généré et sauvegardé : $finalFilePath");

      // Optionnel : Supprimer le fichier QR code temporaire pour faire le ménage
      try { await qrFile.delete(); } catch (_) {}

      // -----------------------------------------------------------
      // 4. SUCCÈS ET OUVERTURE
      // -----------------------------------------------------------
      _showTopNotification("Billet prêt ! Ouverture... ✅");

      final openResult = await OpenFilex.open(finalFilePath);
      if (openResult.type != ResultType.done) {
        debugPrint("⚠️ Impossible d'ouvrir l'image automatiquement : ${openResult.message}");
        _showTopNotification("Billet enregistré dans vos documents 📁");
      }

    } catch (e) {
      debugPrint("🔴 [UI] Erreur génération billet complet : $e");
      if (mounted) _showTopNotification("Erreur technique lors de la création du billet ❌");
    } finally {
      if (mounted) {
        setState(() {
          _downloadingTicketIds.remove(ticket.id);
        });
      }
    }
  }



  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final secondaryTextColor = Colors.grey;

    // Calculs stats (inchangé)
    final int totalCount = allTickets.length;
    final int confirmCount = allTickets.where((t) => t.status == "Confirmé").length;
    final int termineCount = allTickets.where((t) => t.status == "Terminé" || t.status == "Expiré").length;

    // --- LOGIQUE D'AFFICHAGE LIMITÉ ---
    // On ne prend que les 3 premiers tickets pour l'aperçu
    final int previewCount = displayedTickets.length > 3 ? 3 : displayedTickets.length;
    final List<TicketModel> previewTickets = displayedTickets.take(previewCount).toList();
    final bool showViewAllButton = displayedTickets.length > 3;

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
                  Row(
                    children: [
                      Expanded(child: _buildStatFilterCard(context, "$totalCount", "Total", "Total", Colors.orange)),
                      const Gap(10),
                      Expanded(child: _buildStatFilterCard(context, "$confirmCount", "Confirmé", "Confirmé", Colors.green)),
                      const Gap(10),
                      Expanded(child: _buildStatFilterCard(context, "$termineCount", "Terminé", "Terminé", Colors.grey)),
                    ],
                  ),
                  const Gap(25),

                  // LISTE (APERÇU SEULEMENT)
                  if (isLoading)
                    SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
                  else if (displayedTickets.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 50), child: Text("Aucun billet", style: TextStyle(color: secondaryTextColor))))
                  else ...[
                      // On utilise le nouveau Widget TicketCard ici
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: previewTickets.length,
                        separatorBuilder: (context, index) => const Gap(20),
                        itemBuilder: (context, index) {
                          final ticket = previewTickets[index];
                          return TicketCard(
                            ticket: ticket,
                            isDownloading: _downloadingTicketIds.contains(ticket.id),
                            onDetailPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context) => TicketDetailScreen(initialTicket: ticket, repository: _ticketRepository)));
                            },
                            onDownloadPressed: () => _handleDownload(ticket),
                          );
                        },
                      ),

                      // BOUTON "VOIR TOUS LES TICKETS"
                      if (showViewAllButton) ...[
                        const Gap(20),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () {
                              // Navigation vers le nouvel écran de recherche
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => AllTicketsSearchScreen(
                                        allTickets: displayedTickets, // On passe la liste filtrée ou totale selon ton choix
                                        repository: _ticketRepository,
                                        onDownload: _handleDownload, // On passe la fonction de téléchargement
                                        downloadingIds: _downloadingTicketIds, // On passe l'état
                                      )
                                  )
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              backgroundColor: Theme.of(context).cardColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("Voir tous les tickets (${displayedTickets.length})", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                const Gap(8),
                                const Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
                              ],
                            ),
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




 /* Widget _buildHeader(BuildContext context) {
    // 1. Récupération des données utilisateur
    final userProvider = context.watch<UserProvider>();
    final userPhotoUrl = userProvider.user?.photoUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: const DecorationImage(
          image: AssetImage("assets/images/busheader4.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            stops: const [0.0, 0.6], // Légèrement ajusté pour la lisibilité
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center, // ✅ ALIGNEMENT PARFAIT ICI
              children: [
                // GROUPE GAUCHE : Avatar + Localisation
                Row(
                  children: [
                    // 1. Avatar
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(2), // Bordure blanche fine
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 24, // Légèrement plus grand pour l'impact
                          backgroundColor: Colors.grey[200],
                          backgroundImage: (userPhotoUrl != null && userPhotoUrl.isNotEmpty)
                              ? NetworkImage(userPhotoUrl) as ImageProvider
                              : const AssetImage("assets/images/ci.jpg"),
                        ),
                      ),
                    ),

                    const Gap(12),

                    // 2. Badge Localisation (Nouveau Design)
                    const LocationBadge(),
                  ],
                ),

                // GROUPE DROITE : Notification
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                  child: Container(
                    height: 45, // Taille fixe pour garantir l'alignement avec l'avatar
                    width: 45,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Image.asset(
                      "assets/icons/notification.png",
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }*/





  Widget _buildHeader(BuildContext context) {
    // 1. Récupération de l'USER complet (et non juste la photoUrl brute)
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user; // ✅ On prend l'objet user entier
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 260, // Hauteur ajustée pour ne pas couper
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: const DecorationImage(
          image: AssetImage("assets/images/busheader4.jpg"),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.7), Colors.transparent],
            stops: const [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // GROUPE GAUCHE : Avatar + Localisation
                Row(
                  children: [
                    // 1. Avatar
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.grey[200],
                          // ✅ C'EST ICI QUE TOUT SE JOUE :
                          // On utilise user.fullPhotoUrl (ton getter magique)
                          backgroundImage: user != null
                              ? NetworkImage(user.fullPhotoUrl)
                              : const AssetImage("assets/images/ci.jpg") as ImageProvider,

                          // Petit bonus : gestion d'erreur silencieuse
                          onBackgroundImageError: (_, __) {},
                        ),
                      ),
                    ),

                    const Gap(12),

                    // 2. Badge Localisation (Assure-toi que ce widget existe bien dans tes imports)
                    // Si LocationBadge n'est pas importé, remplace-le temporairement par un Container vide ou une Icone
                     const LocationBadge(), // J'ai corrigé le nom (souvent LocalBadge ou LocationBadge selon tes fichiers)
                  ],
                ),

                // GROUPE DROITE : Notification
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                  child: Container(
                    height: 45,
                    width: 45,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.1)),
                    ),
                    child: Image.asset(
                      "assets/icons/notification.png",
                      color: Colors.white,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }




  // Carte de filtre (Total, Valide, etc.)
  Widget _buildStatFilterCard(BuildContext context, String count, String label, String filterKey, MaterialColor baseColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bool isSelected = selectedFilter == filterKey;

    final bgColor = isSelected
        ? baseColor.withOpacity(isDark ? 0.2 : 0.1)
        : (isDark ? Colors.grey[900] : Colors.grey[100]);
    final borderColor = isSelected ? baseColor : Colors.transparent;

    return GestureDetector(
      onTap: () => _applyFilter(filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: borderColor!, width: 2)
        ),
        child: Column(
          children: [
            Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: label == "Terminé" ? Colors.red : (isSelected ? baseColor : (isDark ? Colors.white : Colors.black)))),
            const Gap(5),
            Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600], fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
          ],
        ),
      ),
    );
  }





  Widget _buildTicketCard(BuildContext context, {required TicketModel ticket}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Couleurs
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final primaryColor = AppColors.primary;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;

    // --- LOGIQUE DES BADGES ---
    Color badgeBg;
    Color badgeText;
    String badgeLabel = ticket.status.toUpperCase();

    if (ticket.status == "Confirmé") {
      badgeBg = isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
      badgeText = Colors.green[700]!;
    } else if (ticket.status == "Terminé") {
      badgeBg = isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade200;
      badgeText = Colors.grey[700]!;
    } else if (ticket.status == "Expiré") {
      badgeBg = isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50;
      badgeText = Colors.red[700]!;
    } else {
      badgeBg = Colors.orange.withOpacity(0.1);
      badgeText = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25), // Padding vertical augmenté pour l'aération
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, 5))
        ],
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // =========================================================
          // ZONE 1 : EN-TÊTE (PAYÉ + BADGE STATUT)
          // =========================================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Mention PAYÉ (Remontée ici car on a enlevé la date en bas)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, size: 14, color: primaryColor),
                    const SizedBox(width: 4),
                    Text(
                      "PAYÉ",
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),

              /* // --- ANCIENNE VERSION : NOM COMPAGNIE ---
              Text(ticket.companyName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              */

              // Badge Statut (Confirmé/Terminé)
              Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeLabel,
                      style: TextStyle(
                          color: badgeText,
                          fontSize: 10,
                          fontWeight: FontWeight.bold))),
            ],
          ),

          const Gap(20), // Espace avant le gros numéro

          // =========================================================
          // ZONE 2 : LE CŒUR (NUMÉRO DE SIÈGE GÉANT)
          // =========================================================
          Column(
            children: [
              Text(
                "N° SIÈGE",
                style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w600),
              ),
              const Gap(5),

              // Affichage du siège (Gère le cas simple et le cas Aller/Retour)
              if (ticket.isAllerRetour && ticket.returnSeatNumber != null)
              // CAS ALLER-RETOUR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      ticket.seatNumber,
                      style: TextStyle(
                          fontSize: 42, // Très grand
                          fontWeight: FontWeight.w900,
                          color: textColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text("/", style: TextStyle(fontSize: 30, color: Colors.grey[300])),
                    ),
                    Text(
                      "${ticket.returnSeatNumber}",
                      style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.orange), // Orange pour différencier le retour
                    ),
                  ],
                )
              else
              // CAS SIMPLE (ALLER SIMPLE)
                Text(
                  ticket.seatNumber,
                  style: TextStyle(
                      fontSize: 56, // Enorme pour bien voir
                      fontWeight: FontWeight.w900,
                      color: textColor),
                ),
            ],
          ),

          const Gap(20),

          // =========================================================
          // ZONE 3 : INFOS MASQUÉES (EN COMMENTAIRE)
          // =========================================================

          /* // --- ANCIENNE VERSION : TRAJET ---
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.route,
                  style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (ticket.isAllerRetour) ...[
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.swap_horiz, size: 12, color: Colors.orange),
                      SizedBox(width: 3),
                      Text("A/R", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ]
            ],
          ),

          const Gap(15),
          Divider(color: borderColor, thickness: 1),
          const Gap(15),

          // --- ANCIENNE VERSION : HEURE + PLACES ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.access_time, size: 16, color: subTextColor),
                const Gap(5),
                Text(ticket.departureTime, style: TextStyle(color: subTextColor, fontWeight: FontWeight.w500))
              ]),
              // ... ancien rich text siège ...
            ],
          ),

          const Gap(10),

          // --- ANCIENNE VERSION : DATE ---
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ticket.departureDate, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: textColor)),
                // const Text("Payé", ...) // Déplacé en haut
              ]
          ),
          */

          // =========================================================
          // ZONE 4 : BOUTONS (INCHANGÉS)
          // =========================================================
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => TicketDetailScreen(
                                    initialTicket: ticket,
                                    repository: _ticketRepository)));
                      },
                      icon: Icon(Icons.info_outline, size: 16, color: textColor),
                      label: Text("Détails",
                          style: TextStyle(color: textColor, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))))),
              const Gap(10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadingTicketIds.contains(ticket.id)
                      ? null
                      : () => _handleDownload(ticket),
                  icon: const Icon(Icons.download, size: 16, color: Colors.white),
                  label: const Text("Télécharger",
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }








  /*Widget _buildTicketCard(BuildContext context, {required TicketModel ticket}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Couleurs
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final subTextColor = Colors.grey;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey.shade200;

    // -------------------------------------------------------------------------
    // 🕵️ ZONE DE DÉBOGAGE (Placé ici pour s'exécuter avant l'affichage)
    // -------------------------------------------------------------------------
    print("🎫 DEBUG TICKET ID:${ticket.id} | Aller: ${ticket.seatNumber} | A/R (bool): ${ticket.isAllerRetour} | Retour: ${ticket.returnSeatNumber}");
    // -------------------------------------------------------------------------

    // --- LOGIQUE DES BADGES ---
    Color badgeBg;
    Color badgeText;
    String badgeLabel = ticket.status.toUpperCase();

    if (ticket.status == "Confirmé") {
      badgeBg = isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50;
      badgeText = Colors.green[700]!;
    } else if (ticket.status == "Terminé") {
      badgeBg = isDark ? Colors.grey.withOpacity(0.2) : Colors.grey.shade200;
      badgeText = Colors.grey[700]!;
    } else if (ticket.status == "Expiré") {
      badgeBg = isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50;
      badgeText = Colors.red[700]!;
    } else {
      badgeBg = Colors.orange.withOpacity(0.1);
      badgeText = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
        border: Border.all(color: Colors.transparent),
      ),
      child: Column(
        children: [
          // Ligne 1 : Compagnie + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ticket.companyName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
              Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
                  child: Text(badgeLabel, style: TextStyle(color: badgeText, fontSize: 10, fontWeight: FontWeight.bold))
              ),
            ],
          ),
          const Gap(5),

          // Ligne 2 : Trajet
          Row(
            children: [
              Expanded(
                child: Text(
                  ticket.route,
                  style: TextStyle(color: subTextColor, fontSize: 13, fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (ticket.isAllerRetour) ...[
                const Gap(8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.orange.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.swap_horiz, size: 12, color: Colors.orange),
                      SizedBox(width: 3),
                      Text("A/R", style: TextStyle(fontSize: 10, color: Colors.orange, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ]
            ],
          ),

          const Gap(15),
          Divider(color: borderColor, thickness: 1),
          const Gap(15),

          // --- LIGNE 3 : HEURE + PLACES (Avec ta logique mise à jour) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(Icons.access_time, size: 16, color: subTextColor),
                const Gap(5),
                Text(ticket.departureTime, style: TextStyle(color: subTextColor, fontWeight: FontWeight.w500))
              ]),

              // AFFICHAGE INTELLIGENT DES SIÈGES
              RichText(
                  textAlign: TextAlign.end,
                  text: TextSpan(
                      style: TextStyle(fontSize: 14, color: textColor),
                      children: [
                        TextSpan(text: "Siège: ", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                        // Siège Aller
                        TextSpan(text: ticket.seatNumber, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),

                        // Si c'est un A/R et qu'on a le siège retour
                        // Note: J'ai ajouté un toString() pour être sûr de ne pas crasher sur un null check
                        if (ticket.isAllerRetour && ticket.returnSeatNumber != null && ticket.returnSeatNumber.toString() != "1") ...[
                          TextSpan(text: " / ", style: TextStyle(color: Colors.grey.shade400)),
                          TextSpan(text: ticket.returnSeatNumber.toString(), style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                          TextSpan(text: " (Ret.)", style: TextStyle(fontSize: 10, color: subTextColor)),
                        ]
                      ]
                  )
              ),
            ],
          ),
          // -----------------------------------------------------------

          const Gap(10),

          // Ligne 4 : Date + Prix
          Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(ticket.departureDate, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: textColor)),
                const Text("Payé", style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 16))
              ]
          ),

          const Gap(20),

          // Ligne 5 : Boutons
          Row(
            children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => TicketDetailScreen(initialTicket: ticket, repository: _ticketRepository)));
                      },
                      icon: Icon(Icons.info_outline, size: 14, color: textColor),
                      label: Text("Détails", style: TextStyle(color: textColor, fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: borderColor),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                      )
                  )
              ),
              const Gap(10),

              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadingTicketIds.contains(ticket.id) ? null : () => _handleDownload(ticket),
                  icon: const Icon(Icons.download, size: 14, color: Colors.white),
                  label: const Text("Télécharger", style: TextStyle(color: Colors.white, fontSize: 12)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }*/










  // Système de Notification en haut (Overlay)
  void _showTopNotification(String message) {
    if (!mounted) return;

    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0, left: 20.0, right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Opacity(opacity: value, child: child),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
              decoration: BoxDecoration(
                color: const Color(0xFF222222),
                borderRadius: BorderRadius.circular(25),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13), textAlign: TextAlign.center, maxLines: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }
}