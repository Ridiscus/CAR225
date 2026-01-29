import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import 'booking_summary_screen.dart';

class SeatSelectionScreen extends StatefulWidget {
  final bool isGuestMode;
  final int passengerCount;

  const SeatSelectionScreen({
    super.key,
    this.isGuestMode = false,
    required this.passengerCount
  });

  @override
  State<SeatSelectionScreen> createState() => _SeatSelectionScreenState();
}

class _SeatSelectionScreenState extends State<SeatSelectionScreen> {
  final Set<int> selectedSeats = {};
  final List<int> occupiedSeats = [3, 4, 12, 13, 30, 31, 40, 44];
  final int seatPrice = 5000;
  final _formKey = GlobalKey<FormState>();

  void _toggleSeat(int seatNumber) {
    setState(() {
      if (selectedSeats.contains(seatNumber)) {
        selectedSeats.remove(seatNumber);
      } else {
        if (selectedSeats.length < widget.passengerCount) {
          selectedSeats.add(seatNumber);
        } else {
          _showTopNotification("Maximum de ${widget.passengerCount} passager(s) atteint.");
        }
      }
    });
  }

  void _showTopNotification(String message) {
    // La notification reste noire/sombre dans les deux modes (standard UI)
    // Pas besoin de gros changements ici.
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 60.0,
        left: 20.0,
        right: 20.0,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              color: const Color(0xFF222222), // Toujours sombre pour le contraste
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    Future.delayed(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }

  // --- MODAL ADAPTÉ ---
  void _showPassengerInfoModal(BuildContext context) {
    showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;

          // Récupération des couleurs
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final cardColor = Theme.of(context).cardColor;
          final textColor = Theme.of(context).textTheme.bodyLarge?.color;
          final dividerColor = isDark ? Colors.grey[800] : const Color(0xFFF5F5F5);

          return Padding(
            padding: EdgeInsets.only(bottom: keyboardHeight),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: cardColor, // <--- Fond du modal dynamique
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  const Gap(15),
                  Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10))),
                  const Gap(15),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Infos Passagers", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor)),
                        IconButton(icon: Icon(Icons.close, color: textColor), onPressed: () => Navigator.pop(context))
                      ],
                    ),
                  ),
                  const Divider(),

                  Expanded(
                    child: Form(
                      key: _formKey,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: widget.passengerCount,
                        // Séparateur dynamique
                        separatorBuilder: (c, i) => Divider(height: 40, thickness: 5, color: dividerColor),
                        itemBuilder: (context, index) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person, color: AppColors.primary), const Gap(10),
                                  Text(
                                      "Passager ${index + 1}",
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)
                                  ),
                                  const Spacer(),
                                  if (selectedSeats.length > index)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(5)),
                                      child: Text("Siège #${selectedSeats.toList()[index]}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
                                    )
                                ],
                              ),
                              const Gap(15),

                              Row(
                                children: [
                                  Expanded(child: _buildTextField(context, "Nom", icon: Icons.person_outline)),
                                  const Gap(10),
                                  Expanded(child: _buildTextField(context, "Prénom")),
                                ],
                              ),
                              const Gap(15),
                              _buildTextField(context, "Téléphone", icon: Icons.phone_outlined, keyboardType: TextInputType.phone, hint: "Ex: 07 00 00 00 00"),
                              const Gap(15),
                              _buildTextField(context, "Email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, hint: "Ex: email@exemple.com"),
                              const Gap(15),
                              _buildTextField(context, "Contact d'urgence", icon: Icons.health_and_safety_outlined, hint: "Ex: Papa - 01020304"),
                            ],
                          );
                        },
                      ),
                    ),
                  ),

                  Container(
                    decoration: BoxDecoration(
                        color: cardColor, // Fond derrière le bouton
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -4))]
                    ),
                    child: SafeArea(
                      top: false,
                      bottom: keyboardHeight == 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                Navigator.pop(context);
                                _navigateToNextScreen();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                            ),
                            child: const Text("Continuer vers le résumé", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
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

  // --- TEXTFIELD ADAPTÉ ---
  // Ajout du context pour lire le thème
  Widget _buildTextField(BuildContext context, String label, {IconData? icon, TextInputType keyboardType = TextInputType.text, String? hint}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    // Fond du champ : blanc le jour, gris foncé la nuit
    final fillColor = isDark ? Colors.grey[800] : Colors.white;
    final borderColor = isDark ? Colors.transparent : Colors.grey.shade300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: textColor)),
        const Gap(6),
        TextFormField(
          keyboardType: keyboardType,
          style: TextStyle(color: textColor), // Couleur du texte tapé
          validator: (value) => value == null || value.isEmpty ? "Requis" : null,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, size: 20, color: Colors.grey) : null,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: borderColor)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary)),
            filled: true,
            fillColor: fillColor, // <--- Couleur de fond dynamique
          ),
        ),
      ],
    );
  }

  void _navigateToNextScreen() {
    if (widget.isGuestMode) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (context) => const BookingSummaryScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    int totalPrice = selectedSeats.length * seatPrice;
    bool isSelectionComplete = selectedSeats.length == widget.passengerCount;

    // --- VARIABLES DE THEME ---
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.05);

    return Scaffold(
      backgroundColor: backgroundColor, // <--- DYNAMIQUE
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor, // <--- DYNAMIQUE
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor), // <--- DYNAMIQUE
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Choix de la place", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)),
            Text("UTB • 06:30 • ${widget.passengerCount} passager(s)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 20),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
            child: const Text("UTB", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          )
        ],
      ),

      bottomNavigationBar: _buildBottomBar(context, totalPrice, isSelectionComplete),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 16),
                  const Gap(5),
                  Text("Abidjan", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)), // <--- DYNAMIQUE
                  const Gap(10),
                  const Icon(Icons.arrow_forward, size: 16, color: Colors.grey),
                  const Gap(10),
                  const Icon(Icons.location_on_outlined, color: Colors.green, size: 16),
                  const Gap(5),
                  Text("Yamoussoukro", style: TextStyle(fontWeight: FontWeight.bold, color: textColor)), // <--- DYNAMIQUE
                ],
              ),
              const Gap(20),

              Text("Choisissez votre siège", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
              Text("Sélectionnez ${widget.passengerCount} siège(s)", style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const Gap(20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // LIBRE : Blanc jour / Gris foncé Nuit
                  _buildLegendItem(context, "Libre", isDark ? Colors.white10 : Colors.white, borderColor: isDark ? Colors.transparent : Colors.grey.shade300),
                  const Gap(15),
                  _buildLegendItem(context, "Choisi", AppColors.primary, textColor: isDark ? Colors.white : Colors.black),
                  const Gap(15),
                  // OCCUPÉ : Gris clair jour / Gris moyen Nuit
                  _buildLegendItem(context, "Occupé", isDark ? Colors.grey.shade800 : Colors.grey.shade300, textColor: Colors.grey),
                ],
              ),
              const Gap(30),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: cardColor, // <--- CARTE DYNAMIQUE
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: shadowColor, blurRadius: 20, offset: const Offset(0, 5))
                    ]
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.primary)
                              ),
                              child: const Icon(Icons.circle_outlined, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(height: 4),
                            Text("Chauffeur", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: textColor))
                          ],
                        ),
                        Container(width: 40, height: 5, decoration: BoxDecoration(color: isDark ? Colors.grey[800] : Colors.grey.shade300, borderRadius: BorderRadius.circular(5))),
                      ],
                    ),
                    Divider(height: 40, color: isDark ? Colors.white10 : Colors.grey.shade300),
                    _buildBusLayout(context), // Passer context
                  ],
                ),
              ),
              const Gap(80),
            ],
          ),
        ),
      ),
    );
  }

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

  // --- LOGIQUE DES SIEGES ADAPTEE ---
  Widget _buildSeatItem(BuildContext context, int seatNumber) {
    bool isSelected = selectedSeats.contains(seatNumber);
    bool isOccupied = occupiedSeats.contains(seatNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Couleurs par défaut (LIBRE)
    // Jour : Blanc avec bordure grise
    // Nuit : Gris foncé transparent sans bordure (plus élégant)
    Color bgColor = isDark ? Colors.white10 : Colors.white;
    Color borderColor = isDark ? Colors.transparent : Colors.grey.shade300;
    Color textColor = isDark ? Colors.white : Colors.black;

    if (isOccupied) {
      // OCCUPÉ
      bgColor = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
      borderColor = Colors.transparent;
      textColor = Colors.grey;
    } else if (isSelected) {
      // CHOISI (Reste orange)
      bgColor = AppColors.primary;
      borderColor = AppColors.primary;
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
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: isSelected ? [
            BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))
          ] : null,
        ),
        child: Text(
          "$seatNumber",
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, Color color, {Color? borderColor, Color? textColor}) {
    final defaultTextColor = Theme.of(context).textTheme.bodyLarge?.color;
    return Row(
      children: [
        Container(
          width: 20, height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
        ),
        const Gap(8),
        Text(label, style: TextStyle(fontSize: 12, color: textColor ?? defaultTextColor)),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, int totalPrice, bool isSelectionComplete) {
    final sortedSeats = selectedSeats.toList()..sort();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = Theme.of(context).cardColor;
    final shadowColor = isDark ? Colors.black26 : Colors.black.withOpacity(0.1);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: cardColor, // <--- FOND DYNAMIQUE
          boxShadow: [
            BoxShadow(color: shadowColor, blurRadius: 20, offset: const Offset(0, -5))
          ]
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selectedSeats.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(bottom: 15),
                child: Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: sortedSeats.map((seatNum) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        // Orange très léger (marche sur fond noir aussi)
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset(
                            "assets/images/seat.png",
                            width: 20,
                            height: 20,
                            color: AppColors.primary,
                          ),
                          const Gap(8),
                          Text(
                            "$seatNum",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: AppColors.primary
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: !isSelectionComplete ? null : () {
                  _showPassengerInfoModal(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: isDark ? Colors.grey[800] : AppColors.grey.withOpacity(0.3),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: Text(
                  !isSelectionComplete
                      ? "Sélectionnez ${widget.passengerCount} siège(s)"
                      : "Confirmer pour $totalPrice FCFA",
                  style: TextStyle(
                      color: !isSelectionComplete ? Colors.grey : Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}