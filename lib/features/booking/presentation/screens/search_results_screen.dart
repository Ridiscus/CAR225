/*import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../../onboarding/presentation/bando.dart';
import 'seat_selection_screen.dart';
import 'booking_summary_screen.dart';

// ON PASSE EN STATEFULWIDGET POUR GÉRER LE NOMBRE DE PASSAGERS
class SearchResultsScreen extends StatefulWidget {
  final bool isGuestMode;

  const SearchResultsScreen({
    super.key,
    this.isGuestMode = false
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  // Variable d'état pour le nombre de passagers (Initialisé à 1)
  int passengerCount = 1;

  void _incrementPassengers() {
    if (passengerCount < 5) { // Limite arbitraire à 5 pour l'exemple
      setState(() => passengerCount++);
    }
  }

  void _decrementPassengers() {
    if (passengerCount > 1) {
      setState(() => passengerCount--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background, // Gris clair du thème
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
                "Trajets disponibles",
                style: TextStyle(color: AppColors.black, fontWeight: FontWeight.bold, fontSize: 18)
            ),
            const ScrollingSubtitle(
              texts: [
                "Abidjan ➔ Bouaké",
                "Départ : 30 Janvier",
                "3 Compagnies trouvées",
                "Meilleur prix : 6 000 F"
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [

          // --- NOUVEAU : SÉLECTEUR DE PASSAGERS (Style Capture) ---
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PASSAGERS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.grey)),
                    const Gap(5),
                    Text(
                        "Vendredi 30 janvier • $passengerCount passager${passengerCount > 1 ? 's' : ''}",
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)
                    ),
                  ],
                ),

                // Boutons + et -
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _decrementPassengers,
                        icon: const Icon(Icons.remove, size: 18),
                        color: passengerCount > 1 ? AppColors.black : Colors.grey,

                      ),
                      Text(
                          "$passengerCount",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      IconButton(
                        onPressed: _incrementPassengers,
                        icon: const Icon(Icons.add, size: 18),
                        color: AppColors.primary, // Orange pour inciter à ajouter
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          // --- LISTE DES TICKETS ---
          _buildTicketCard(context, "UTB", "8 000 F", "06:00", "10:30", AppColors.primary,
              seats: 5, isRoundTrip: true),

          _buildTicketCard(context, "AVS", "7 500 F", "07:30", "12:00", Colors.purple,
              seats: 12, isRoundTrip: false),

          _buildTicketCard(context, "ST Transport", "6 000 F", "08:00", "13:00", Colors.blue,
              seats: 20, isRoundTrip: true),
        ],
      ),
    );
  }

  // --- LOGIQUE DE NAVIGATION ---
  void _handleTicketAction(BuildContext context, {required bool isDirectBooking}) {
    // CAS 1 : "Voir les sièges"
    if (!isDirectBooking) {
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SeatSelectionScreen(
              isGuestMode: widget.isGuestMode,
              passengerCount: passengerCount, // <--- ON PASSE LE NOMBRE DE PASSAGERS ICI
            ),
          )
      );
      return;
    }

    // CAS 2 : "Réserver" direct
    if (widget.isGuestMode) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingSummaryScreen()));
    }
  }

  Widget _buildTicketCard(BuildContext context, String company, String price, String departTime, String arriveTime, Color brandColor, {required int seats, required bool isRoundTrip}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
          ]
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
                    decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset("assets/images/bus.png", color: brandColor, fit: BoxFit.contain),
                    ),
                  ),
                  const Gap(10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(isRoundTrip ? "Aller - Retour" : "Aller Simple",
                          style: const TextStyle(color: AppColors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),

                  Text("$seats places dispo",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                          color: seats < 10 ? Colors.red : AppColors.secondary)),
                ],
              ),
            ],
          ),
          const Divider(height: 30, color: AppColors.greyLight),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn(departTime, "Départ"),
              Image.asset(isRoundTrip ? "assets/images/swap.png" : "assets/images/right-arrow.png", width: 20, color: AppColors.grey),
              Row(children: [
                Image.asset("assets/images/clock.png", width: 14, color: AppColors.grey),
                const Gap(5),
                const Text("4h 30m", style: TextStyle(fontSize: 12, color: AppColors.black))
              ]),
              Image.asset(isRoundTrip ? "assets/images/swap.png" : "assets/images/right-arrow.png", width: 20, color: AppColors.grey),
              _buildTimeColumn(arriveTime, "Arrivée"),
            ],
          ),
          const Gap(15),
          Row(
            children: [
              Image.asset("assets/images/wi-fi.png", width: 16, color: Colors.blue),
              const Gap(5),
              const Text("Wifi", style: TextStyle(fontSize: 12)),
              const Gap(15),
              Image.asset("assets/images/usb.png", width: 16, color: Colors.purple),
              const Gap(5),
              const Text("Prise USB", style: TextStyle(fontSize: 12)),
            ],
          ),
          const Gap(20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleTicketAction(context, isDirectBooking: false),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  child: const Text("Voir les sièges", style: TextStyle(color: AppColors.black)),
                ),
              ),
              const Gap(10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleTicketAction(context, isDirectBooking: true),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  child: const Text("Réserver", style: TextStyle(color: AppColors.white)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildTimeColumn(String time, String label) {
    return Column(
      children: [
        Text(time, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        Text(label, style: const TextStyle(color: AppColors.grey, fontSize: 12)),
      ],
    );
  }
}*/




import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../onboarding/presentation/bando.dart';
import 'seat_selection_screen.dart';
// Note : On n'a plus besoin d'importer LoginScreen ou BookingSummaryScreen ici
// car c'est SeatSelectionScreen qui s'en chargera après le choix des places.

class SearchResultsScreen extends StatefulWidget {
  final bool isGuestMode;

  const SearchResultsScreen({
    super.key,
    this.isGuestMode = false
  });

  @override
  State<SearchResultsScreen> createState() => _SearchResultsScreenState();
}

class _SearchResultsScreenState extends State<SearchResultsScreen> {
  int passengerCount = 1;

  void _incrementPassengers() {
    if (passengerCount < 5) {
      setState(() => passengerCount++);
    }
  }

  void _decrementPassengers() {
    if (passengerCount > 1) {
      setState(() => passengerCount--);
    }
  }


  @override
  Widget build(BuildContext context) {
    // --- 1. RÉCUPÉRATION DU THÈME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor; // Blanc ou Gris Foncé
    final textColor = Theme.of(context).textTheme.bodyLarge?.color; // Noir ou Blanc
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Scaffold(
      // Fond dynamique
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: AppBar(
        // Fond AppBar dynamique
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), // Flèche retour dynamique
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Trajets disponibles",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18)
            ),
            // Note: Pour ScrollingSubtitle, assure-toi qu'il utilise aussi Theme.of(context) à l'intérieur
            // ou passe-lui la couleur si possible.
            const ScrollingSubtitle(
              texts: [
                "Abidjan ➔ Bouaké",
                "Départ : 30 Janvier",
                "3 Compagnies trouvées",
                "Meilleur prix : 6 000 F"
              ],
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- 1. SÉLECTEUR DE PASSAGERS ---
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
                color: cardColor, // <--- FOND CARTE
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4))
                ]
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PASSAGERS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const Gap(5),
                    Text(
                        "Vendredi 30 janvier • $passengerCount passager${passengerCount > 1 ? 's' : ''}",
                        // Texte dynamique
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    // Le fond du petit compteur doit être contrasté
                    color: isDark ? Colors.white.withOpacity(0.05) : AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _decrementPassengers,
                        icon: const Icon(Icons.remove, size: 18),
                        // Couleur icône dynamique sauf si désactivé (gris)
                        color: passengerCount > 1 ? textColor : Colors.grey,
                      ),
                      Text(
                          "$passengerCount",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
                      ),

                      IconButton(
                        onPressed: _incrementPassengers,
                        icon: const Icon(Icons.add, size: 18),
                        color: AppColors.primary, // Orange reste Orange
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),

          // --- 2. LISTE DES TICKETS ---
          _buildTicketCard(context, "UTB", "8 000 F", "06:00", "10:30", AppColors.primary,
              seats: 5, isRoundTrip: true),

          _buildTicketCard(context, "AVS", "7 500 F", "07:30", "12:00", Colors.purple,
              seats: 12, isRoundTrip: false),

          _buildTicketCard(context, "ST Transport", "6 000 F", "08:00", "13:00", Colors.blue,
              seats: 20, isRoundTrip: true),

          const Gap(45),
        ],
      ),
    );
  }

  // --- LOGIQUE DE NAVIGATION CORRIGÉE ---

  // Que l'utilisateur clique sur "Voir les sièges" ou "Réserver",
  // l'étape suivante OBLIGATOIRE est de choisir sa place.
  // On redirige donc toujours vers SeatSelectionScreen.
  void _goToSeatSelection(BuildContext context) {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SeatSelectionScreen(
            isGuestMode: widget.isGuestMode, // On passe l'info
            passengerCount: passengerCount,  // On passe le nombre de passagers
          ),
        )
    );
  }

  Widget _buildTicketCard(BuildContext context, String company, String price, String departTime, String arriveTime, Color brandColor, {required int seats, required bool isRoundTrip}) {
    // Récupération locale du thème
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);
    final borderColor = isDark ? Colors.white24 : Colors.grey.shade300;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
          color: cardColor, // <--- FOND CARTE
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 10, offset: const Offset(0, 4))
          ]
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
                    decoration: BoxDecoration(
                        color: brandColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.asset("assets/images/bus.png", color: brandColor, fit: BoxFit.contain),
                    ),
                  ),
                  const Gap(10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(company, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
                      Text(isRoundTrip ? "Aller - Retour" : "Aller Simple",
                          style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(price, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 18)),
                  Text("$seats places dispo",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                          color: seats < 10 ? Colors.red : AppColors.secondary)),
                ],
              ),
            ],
          ),
          // Divider : gris clair le jour, gris foncé transparent la nuit
          Divider(height: 30, color: isDark ? Colors.white10 : AppColors.greyLight),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTimeColumn(context, departTime, "Départ"), // Ajout context
              Image.asset(isRoundTrip ? "assets/images/swap.png" : "assets/images/right-arrow.png", width: 20, color: Colors.grey),
              Row(children: [
                Image.asset("assets/images/clock.png", width: 14, color: Colors.grey),
                const Gap(5),
                // Texte durée : doit être visible
                const Text("4h 30m", style: TextStyle(fontSize: 12, color: Colors.grey))
                // J'ai mis gris ici car c'est une métadonnée, mais tu peux mettre `textColor`
              ]),
              Image.asset(isRoundTrip ? "assets/images/swap.png" : "assets/images/right-arrow.png", width: 20, color: Colors.grey),
              _buildTimeColumn(context, arriveTime, "Arrivée"), // Ajout context
            ],
          ),
          const Gap(15),

          // Icônes services
          Row(
            children: [
              Image.asset("assets/images/wi-fi.png", width: 16, color: Colors.blue),
              const Gap(5),
              Text("Wifi", style: TextStyle(fontSize: 12, color: textColor)), // <--- Texte
              const Gap(15),
              Image.asset("assets/images/usb.png", width: 16, color: Colors.purple),
              const Gap(5),
              Text("Prise USB", style: TextStyle(fontSize: 12, color: textColor)), // <--- Texte
            ],
          ),
          const Gap(20),

          // BOUTONS D'ACTION
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _goToSeatSelection(context),
                  style: OutlinedButton.styleFrom(
                      side: BorderSide(color: borderColor), // <--- Bordure dynamique
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  child: Text("Voir les sièges", style: TextStyle(color: textColor)), // <--- Texte dynamique
                ),
              ),
              const Gap(10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _goToSeatSelection(context),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 12)
                  ),
                  child: const Text("Réserver", style: TextStyle(color: Colors.white)), // Reste blanc sur fond orange
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // J'ai ajouté le context pour récupérer la couleur du texte
  Widget _buildTimeColumn(BuildContext context, String time, String label) {
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Column(
      children: [
        Text(time, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ],
    );
  }
}