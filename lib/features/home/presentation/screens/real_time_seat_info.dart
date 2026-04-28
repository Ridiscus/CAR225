import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
// Adapte les imports selon ton projet
import '../../../../core/services/networking/api_config.dart';
import '../../../booking/data/datasources/booking_remote_data_source.dart';
import '../../../booking/data/models/program_model.dart';
import '../../../../core/theme/app_colors.dart';

class RealTimeSeatInfo extends StatefulWidget {
  final ProgramModel program;

  const RealTimeSeatInfo({super.key, required this.program});

  @override
  State<RealTimeSeatInfo> createState() => _RealTimeSeatInfoState();
}

class _RealTimeSeatInfoState extends State<RealTimeSeatInfo> {
  // On utilise un Future pour stocker l'état de la requête
  late Future<int> _reservedCountFuture;

  @override
  void initState() {
    super.initState();
    _reservedCountFuture = _fetchReservedCount();
  }


  /*Future<int> _fetchReservedCount() async {
    // ... initialisation dio ...
    //final dio = Dio(BaseOptions(baseUrl: 'https://car225.com/api/'));
    final dio = Dio(BaseOptions(baseUrl: 'https://jingly-lindy-unminding.ngrok-free.dev/api/'));
    final dataSource = BookingRemoteDataSourceImpl(dio: dio);

    try {
      // 1. EXTRACTION ROBUSTE DE LA DATE
      // On s'assure qu'on prend la partie date '2026-02-20' même si c'est '2026-02-20 08:00:00'
      String dateRaw = widget.program.dateDepart;
      String dateClean = dateRaw;

      if (dateRaw.contains(' ')) {
        dateClean = dateRaw.split(' ')[0];
      } else if (dateRaw.contains('T')) {
        dateClean = dateRaw.split('T')[0];
      }

      // DEBUG : Vérifie que cette date correspond bien à celle de ton SeatSelectionScreen
      print("🚀 APPEL API LISTE -> ID: ${widget.program.id} | DATE CIBLE: $dateClean");

      final seats = await dataSource.getReservedSeats(
        widget.program.id,
        dateClean,
      );

      return seats.length;
    } catch (e) {
      print("❌ ERREUR: $e");
      return 0;
    }
  }*/

  Future<int> _fetchReservedCount() async {
    // 🟢 UTILISATION DE L'INTERRUPTEUR MAGIQUE
    final dio = Dio(BaseOptions(baseUrl: ApiConfig.baseUrl));
    final dataSource = BookingRemoteDataSourceImpl(dio: dio);

    try {
      // 1. EXTRACTION ROBUSTE DE LA DATE
      String dateRaw = widget.program.dateDepart;
      String dateClean = dateRaw;

      if (dateRaw.contains(' ')) {
        dateClean = dateRaw.split(' ')[0];
      } else if (dateRaw.contains('T')) {
        dateClean = dateRaw.split('T')[0];
      }

      print("🚀 APPEL API LISTE -> ID: ${widget.program.id} | DATE CIBLE: $dateClean");

      final seats = await dataSource.getReservedSeats(
        widget.program.id,
        dateClean,
      );

      return seats.length;
    } catch (e) {
      print("❌ ERREUR: $e");
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _reservedCountFuture,
      builder: (context, snapshot) {
        // 1. Pendant le chargement, on affiche une info "en attente"
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text(
            "Vérification des places...",
            style: TextStyle(fontSize: 9, color: Colors.grey, fontStyle: FontStyle.italic),
          );
        }

        // 2. Une fois chargé, on a le VRAI nombre de réservés
        final int reservedCount = snapshot.data ?? 0;
        final int capacity = widget.program.capacity;

        // Calcul des vraies places restantes
        int remaining = capacity - reservedCount;
        if (remaining < 0) remaining = 0;

        // Calcul pourcentage pour la barre
        double progress = capacity > 0 ? reservedCount / capacity : 0.0;

        // Couleur selon l'urgence
        Color statusColor = remaining < 5 ? Colors.red : Colors.green;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Texte Gauche : Réservés (Venant de l'API seats)
                Flexible( // 🟢 1. On enveloppe avec Flexible
                  child: Text(
                    "$reservedCount réservés",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis, // 🟢 2. Ajoute "..." si c'est trop long
                  ),
                ),

                const SizedBox(width: 5), // 🟢 3. Un tout petit espace de sécurité au milieu

                // Texte Droite : Restants (Calculé)
                Flexible( // 🟢 1. On enveloppe avec Flexible
                  child: Text(
                    "$remaining places restantes",
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor
                    ),
                    textAlign: TextAlign.right, // 🟢 4. On aligne à droite pour faire propre
                    overflow: TextOverflow.ellipsis, // 🟢 2. Ajoute "..." si c'est trop long
                  ),
                ),
              ],
            ),
            const Gap(4),
            // Barre de progression
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade200,
                color: progress > 0.8 ? Colors.orange : AppColors.primary.withOpacity(0.6),
                minHeight: 3,
              ),
            ),
          ],
        );
      },
    );
  }
}