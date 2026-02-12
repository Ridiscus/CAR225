import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:dio/dio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Adapte ces imports selon l'emplacement réel de tes fichiers
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

class _AlertsTabScreenState extends State<AlertsTabScreen> {
  bool _isLoading = true;
  List<ActiveReservationModel> _reservations = [];
  String? _errorMessage;

  // Déclaration du Repository
  late AlertRepository _alertRepository;

  @override
  void initState() {
    super.initState();
    // On lance la récupération dès l'ouverture
    _fetchReservations();
  }

  Future<void> _fetchReservations() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      // ✅ CORRECTION ICI : On cherche le token sous tous les noms possibles
      // Le Login le sauvegarde sous 'auth_token', donc on doit le chercher là.
      final String? token = prefs.getString('auth_token') ??
          prefs.getString('access_token') ??
          prefs.getString('token');

      // Debug pour vérifier
      print("🔍 Token récupéré dans AlertsTabScreen : $token");

      if (token == null || token.isEmpty) {
        throw Exception("Non connecté (Token manquant)");
      }

      // 3. Configuration de Dio
      final dio = Dio(BaseOptions(
        baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token', // ✅ Token injecté
        },
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));

      // 4. Appel via le Repository
      final repository = AlertRepository(dio: dio);
      final reservations = await repository.getActiveReservations();

      if (mounted) {
        setState(() {
          _reservations = reservations;
          _isLoading = false;
        });
      }
    } catch (e) {
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
                        itemBuilder: (context, index) {
                          return _buildReservationCard(context, _reservations[index]);
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
            // Ligne Haut: Compagnie & Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.directions_bus, color: Colors.orange, size: 20),
                    ),
                    const Gap(10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reservation.compagnieName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("Ref: ${reservation.reference.length > 8 ? reservation.reference.substring(0, 8) : reservation.reference}...", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                      ],
                    )
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("En cours", style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                )
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

  Widget _buildHeader(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user; // ✅ On prend l'objet user entier
    final userPhotoUrl = userProvider.user?.photoUrl;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 260,
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? Colors.black : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
        image: const DecorationImage(
          image: AssetImage("assets/images/busheader1.jpg"),
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
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen())),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
                    const LocationBadge(),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const NotificationScreen())),
                  child: Container(
                    height: 45, width: 45,
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
            ),
          ),
        ),
      ),
    );
  }
}

