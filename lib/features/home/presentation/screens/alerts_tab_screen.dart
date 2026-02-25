import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Adapte ces imports selon l'emplacement réel de tes fichiers
import '../../../../common/widgets/NotificationIconBtn.dart';
import '../../../../common/widgets/local_badge.dart';
import '../../../../core/providers/user_provider.dart';
// import '../../../../core/theme/app_colors.dart';
import '../../../booking/data/models/active_reservation_model.dart';
import '../../../booking/domain/repositories/alert_repository.dart';   // ⚠️ Vérifie ce chemin

import 'alert_detail_screen.dart';
import 'notification_screen.dart';
import 'profil_screen.dart';


class AlertsTabScreen extends StatefulWidget {
  const AlertsTabScreen({super.key});

  @override
  State<AlertsTabScreen> createState() => _AlertsTabScreenState();
}



  class _AlertsTabScreenState extends State<AlertsTabScreen> with SingleTickerProviderStateMixin { // 👈 1. AJOUT DU MIXIN
  bool _isLoading = true;
  List<ActiveReservationModel> _reservations = [];
  String? _errorMessage;

  late AlertRepository _alertRepository;

  // 🟢 2. DÉCLARATION DU CONTROLLER
  late AnimationController _entranceController;



  @override
  void initState() {
    super.initState();

    // 🟢 3. INITIALISATION DU CONTROLLER (Sans le lancer !)
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // On lance la récupération dès l'ouverture
    _fetchReservations();
  }

  // 🟢 4. AJOUT DU DISPOSE
  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }


  Map<String, dynamic> _getStatusStyle(String status) {
    final s = status.toLowerCase();

    if (s.contains("cours") || s.contains("active")) {
      return {
        "label": "En cours",
        "bg": Colors.green.withOpacity(0.1),
        "color": Colors.green,
      };
    } else if (s.contains("confirm")) {
      return {
        "label": "Confirmé",
        "bg": Colors.blue.withOpacity(0.1),
        "color": Colors.blue,
      };
    } else if (s.contains("annul")) {
      return {
        "label": "Annulé",
        "bg": Colors.red.withOpacity(0.1),
        "color": Colors.red,
      };
    } else if (s.contains("termin") || s.contains("arriv")) {
      return {
        "label": "Terminé",
        "bg": Colors.grey.withOpacity(0.2),
        "color": Colors.grey,
      };
    } else {
      return {
        "label": status.isNotEmpty ? status : "Inconnu",
        "bg": Colors.orange.withOpacity(0.1),
        "color": Colors.orange,
      };
    }
  }



  /*Future<void> _fetchReservations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final String? token = prefs.getString('auth_token') ??
          prefs.getString('access_token') ??
          prefs.getString('token');

      if (token == null || token.isEmpty) {
        throw Exception("Non connecté (Token manquant)");
      }

      final dio = Dio(BaseOptions(
        baseUrl: 'https://car225.com/api/',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final repository = AlertRepository(dio: dio);

      // 1. On récupère TOUTES les réservations renvoyées par le backend
      final allReservations = await repository.getActiveReservations();

      // 2. 🔴 FILTRAGE MAGIQUE ICI 🔴
      // On ne garde que les voyages qui NE SONT PAS terminés, annulés ou arrivés.
      final activeOnly = allReservations.where((res) {
        // ⚠️ ASSURE-TOI QUE "displayStatut" EST BIEN LE NOM DE TA VARIABLE DANS LE MODEL
        // Si tu l'as appelé autrement (ex: res.statut), change-le ici.
        final status = (res.displayStatut ?? "").toLowerCase();

        return !status.contains("termin") &&
            !status.contains("annul") &&
            !status.contains("arriv");
      }).toList();

      if (mounted) {
        setState(() {
          // On passe la liste filtrée à l'UI
          _reservations = activeOnly;
          _isLoading = false;
        });
      }
      // 🟢 5. ON LANCE L'ANIMATION ICI !
      _entranceController.forward(from: 0.0);
    }
    catch (e) {
      debugPrint("Erreur fetch: $e");

      if (mounted) {
        setState(() {
          if (e.toString().contains("Non connecté")) {
            _errorMessage = "Vous n'êtes pas connecté.";
          } else if (e is DioException && e.response?.statusCode == 401) {
            _errorMessage = "Session expirée. Veuillez vous reconnecter.";
          } else {
            _errorMessage = "Impossible de charger les voyages.";
          }
          _isLoading = false;
        });
      }
    }
  }*/


  Future<void> _fetchReservations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    debugPrint("🚀 [FETCH] Début récupération des réservations");

    try {
      final prefs = await SharedPreferences.getInstance();

      final String? token = prefs.getString('auth_token') ??
          prefs.getString('access_token') ??
          prefs.getString('token');

      debugPrint("🔐 [FETCH] Token présent : ${token != null && token.isNotEmpty}");

      if (token == null || token.isEmpty) {
        throw Exception("Non connecté (Token manquant)");
      }

      final dio = Dio(BaseOptions(
        baseUrl: 'https://car225.com/api/',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      final repository = AlertRepository(dio: dio);

      debugPrint("📡 [FETCH] Appel API /user/signalements/active-reservations");

      // 1️⃣ Récupération brute
      final allReservations = await repository.getActiveReservations();

      debugPrint("📦 [FETCH] Réservations reçues : ${allReservations.length}");

      // 🔍 DEBUG CONTENU
      for (final res in allReservations) {
        debugPrint(
          "➡️ ID:${res.id} | Prog:${res.programmeId} | Veh:${res.vehiculeId} | Statut:${res.displayStatut}",
        );
      }

      // 2️⃣ FILTRAGE
      final activeOnly = allReservations.where((res) {
        final status = res.displayStatut.toLowerCase();

        final isActive = !status.contains("termin") &&
            !status.contains("annul") &&
            !status.contains("arriv");

        debugPrint(
          "🔎 [FILTER] ID:${res.id} | statut='$status' | gardé=$isActive",
        );

        return isActive;
      }).toList();

      debugPrint("✅ [FETCH] Réservations actives après filtre : ${activeOnly.length}");

      if (mounted) {
        setState(() {
          _reservations = activeOnly;
          _isLoading = false;
        });
      }

      debugPrint("🎬 [FETCH] Lancement animation UI");
      _entranceController.forward(from: 0.0);

    } catch (e) {
      debugPrint("❌ [FETCH] Erreur attrapée : $e");

      if (mounted) {
        setState(() {
          if (e.toString().contains("Non connecté")) {
            _errorMessage = "Vous n'êtes pas connecté.";
          } else if (e is DioException && e.response?.statusCode == 401) {
            _errorMessage = "Session expirée. Veuillez vous reconnecter.";
          } else {
            _errorMessage = "Impossible de charger les voyages.";
          }
          _isLoading = false;
        });
      }
    }
  }




  @override
  Widget build(BuildContext context) {
    final scaffoldColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;

    return Scaffold(
      backgroundColor: scaffoldColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER ---
            _buildHeader(context),

            // --- CONTENU ---
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Voyages en cours",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text(
                    "Sélectionnez votre trajet actuel pour signaler un problème",
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  const Gap(20),

                  // --- ETAT LISTE ---
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 50.0),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_errorMessage != null)
                  // ✅ AJOUT DU BOUTON REESSAYER ICI
                    _buildErrorState(context)
                  else if (_reservations.isEmpty)
                      _buildEmptyState(context)
                    else
                      ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _reservations.length,
                        separatorBuilder: (context, index) => const Gap(15),
                        /*itemBuilder: (context, index) {
                          return _buildReservationCard(context, _reservations[index]);
                        },*/

                        itemBuilder: (context, index) {
                          // 🟢 6. CALCUL DU DÉLAI EN CASCADE
                          final double startDelay = (index % 10) * 0.1;
                          final double endDelay = (startDelay + 0.5).clamp(0.0, 1.0);

                          final animation = CurvedAnimation(
                            parent: _entranceController,
                            curve: Interval(startDelay, endDelay, curve: Curves.easeOutCubic),
                          );

                          // 🟢 7. APPLICATION DES TRANSITIONS
                          return SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.3), // Glisse vers le haut
                              end: Offset.zero,
                            ).animate(animation),
                            child: FadeTransition(
                              opacity: animation,
                              child: _buildReservationCard(context, _reservations[index]),
                            ),
                          );
                        },

                      ),

                  const Gap(100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }




  // --- CARTE DE RÉSERVATION ---
  Widget _buildReservationCard(BuildContext context, ActiveReservationModel reservation) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        _showAlertTypeSelection(context, reservation);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_bus,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const Gap(10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              reservation.compagnieName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              "Ref: ${reservation.reference.length > 8 ? reservation.reference.substring(0, 8) : reservation.reference}...",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                /*Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "En cours",
                    style: TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),*/
                _buildStatusChip(reservation.displayStatut),
              ],
            ),
            const Divider(height: 30),

            // Ligne Trajet
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ✅ CORRECTION ICI : utilisation de pointDepart
                _buildTripPoint(reservation.heureDepart, reservation.pointDepart, CrossAxisAlignment.start),
                const Icon(Icons.arrow_forward, color: Colors.grey, size: 16),
                // ✅ CORRECTION ICI : utilisation de pointArrive
                _buildTripPoint(reservation.heureArrive, reservation.pointArrive, CrossAxisAlignment.end),
              ],
            ),

            const Gap(15),
            // Info véhicule
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                // ✅ CORRECTION ICI : utilisation de vehiculeInfo
                "Véhicule: ${reservation.vehiculeInfo} • Place N°${reservation.seatNumber}",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    final style = _getStatusStyle(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style["bg"],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        style["label"],
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: style["color"],
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTripPoint(String time, String city, CrossAxisAlignment align) {
    String displayTime = "--:--";

    if (time.isNotEmpty && time.length >= 5) {
      displayTime = time.substring(0, 5);
    } else if (time.isNotEmpty) {
      displayTime = time;
    }

    return Column(
      crossAxisAlignment: align,
      children: [
        Text(displayTime, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(city, style: const TextStyle(color: Colors.grey, fontSize: 13)),
      ],
    );
  }


  // --- WIDGET D'ERREUR AVEC BOUTON REESSAYER ---
  Widget _buildErrorState(BuildContext context) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 50, color: Colors.red),
          const Gap(10),
          Text(
            _errorMessage ?? "Une erreur est survenue",
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const Gap(20),
          ElevatedButton.icon(
            onPressed: _fetchReservations, // 🔄 Relance la fonction
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text("Réessayer", style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
            ),
          )
        ],
      ),
    );
  }


  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(30),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.commute_outlined, size: 60, color: Colors.grey.shade300),
          const Gap(15),
          const Text("Aucun voyage actif", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Gap(5),
          const Text("Vous ne pouvez signaler un problème que lors d'un voyage en cours.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          const Gap(20),
          // Petit bouton refresh aussi ici au cas où
          TextButton.icon(
            onPressed: _fetchReservations,
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text("Actualiser"),
          )
        ],
      ),
    );
  }



  void _showAlertTypeSelection(BuildContext context, ActiveReservationModel reservation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)))),
              const Gap(20),
              const Text("Quel est le problème ?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const Gap(20),
              Expanded(
                child: ListView(
                  children: [
                    _buildAlertOption(context, reservation, "Accident", "Urgence, collision...", "assets/icons/accident.png", Colors.red),
                    const Gap(15),
                    _buildAlertOption(context, reservation, "Problème chauffeur", "Conduite dangereuse...", "assets/icons/driver_alert.png", Colors.orange),
                    const Gap(15),
                    _buildAlertOption(context, reservation, "Panne véhicule", "Climatisation, moteur...", "assets/icons/bus_issue.png", Colors.blue),
                    const Gap(15),
                    _buildAlertOption(context, reservation, "Retard", "Départ tardif...", "assets/icons/time_alert.png", Colors.amber.shade700),
                    const Gap(15),
                    _buildAlertOption(context, reservation, "Autre", "Signaler autre chose", "assets/icons/chat.png", Colors.grey),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildAlertOption(BuildContext context, ActiveReservationModel reservation, String title, String subtitle, String iconPath, Color color) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AlertDetailScreen(
              alertType: title,
              alertColor: color,
              iconPath: iconPath,
              reservation: reservation,
            ),
          ),
        );
      },
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Image.asset(iconPath, width: 24, color: color),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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



}

