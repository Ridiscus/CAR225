import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:gap/gap.dart';
import '../../../../core/theme/app_colors.dart'; // Adapte ton import

class LocationBadge extends StatefulWidget {
  const LocationBadge({super.key});

  @override
  State<LocationBadge> createState() => _LocationBadgeState();
}

class _LocationBadgeState extends State<LocationBadge> {
  String _currentAddress = "Abidjan"; // Valeur par défaut
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getUserLocation(); // On lance la récup au démarrage
  }

  Future<void> _getUserLocation() async {
    setState(() => _isLoading = true);

    try {
      // 1. Vérifier si le service GPS est activé
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Le service de localisation est désactivé.');
      }

      // 2. Vérifier les permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Les permissions de localisation sont refusées');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Les permissions sont refusées définitivement.');
      }

      // 3. Obtenir la position actuelle
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // 4. Convertir (Geocoding inverse)
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        // On essaie d'abord la localité (ville) ou la sous-localité (commune/quartier)
        // ex: SubLocality souvent = Cocody, Koumassi...
        setState(() {
          _currentAddress = place.subLocality ?? place.locality ?? "Abidjan";
        });
      }
    } catch (e) {
      debugPrint("Erreur GPS: $e");
      // On garde "Abidjan" par défaut si erreur, ou on met "Inconnu"
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _getUserLocation, // Relancer si on clique dessus
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset("assets/icons/pin.png", width: 16, color: AppColors.primary),
            const Gap(6),
            _isLoading
                ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
            )
                : Text(
                _currentAddress, // Affiche "Cocody", "Koumassi", etc.
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14
                )
            ),
          ],
        ),
      ),
    );
  }
}