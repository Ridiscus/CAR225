import 'dart:async';
import 'dart:math' as dart_math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:car225/core/theme/app_colors.dart';
import 'package:car225/core/services/networking/api_config.dart';
import '../../data/models/voyage_model.dart';

/// Type de trajet suivi par l'écran de tracking.
/// - [voyage] : trajet d'un voyage classique (mise à jour via /chauffeur/voyages/{id}/update-location)
/// - [convoi] : trajet d'un convoi (mise à jour via /chauffeur/convois/{id}/update-location)
enum TrackedTripKind { voyage, convoi }

class DriverTrackingScreen extends StatefulWidget {
  final int voyageId;
  final TrackedTripKind tripKind;
  final String gareDepartNom;
  final String gareArriveeNom;
  final double? gareDepartLat;
  final double? gareDepartLng;
  final double? gareArriveeLat;
  final double? gareArriveeLng;
  final String vehiculeImmat;
  final String dateVoyage;

  const DriverTrackingScreen({
    super.key,
    required this.voyageId,
    this.tripKind = TrackedTripKind.voyage,
    required this.gareDepartNom,
    required this.gareArriveeNom,
    this.gareDepartLat,
    this.gareDepartLng,
    this.gareArriveeLat,
    this.gareArriveeLng,
    this.vehiculeImmat = '',
    this.dateVoyage = '',
  });

  /// Construit une instance pour le suivi d'un convoi.
  const DriverTrackingScreen.convoi({
    super.key,
    required int convoiId,
    required this.gareDepartNom,
    required this.gareArriveeNom,
    this.gareDepartLat,
    this.gareDepartLng,
    this.gareArriveeLat,
    this.gareArriveeLng,
    this.vehiculeImmat = '',
    this.dateVoyage = '',
  })  : voyageId = convoiId,
        tripKind = TrackedTripKind.convoi;

  @override
  State<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends State<DriverTrackingScreen>
    with TickerProviderStateMixin {
  final MapController _mapController = MapController();

  StreamSubscription<Position>? _positionSub;
  late AnimationController _pulseController;

  LatLng? _driverPosition;
  double? _currentSpeed;
  double? _currentHeading;
  bool _gpsActive = false;
  bool _gpsDenied = false;
  int _updateCount = 0;
  String _etaText = '—';
  List<LatLng> _routePoints = [];
  bool _mapReady = false;
  DateTime? _lastSent;
  // When true, map camera follows the driver; false = stay on route overview
  bool _followDriver = false;

  // ── Recalcul d'itinéraire dynamique ────────────────────────────────────────
  bool _isRerouting = false;                          // Verrou anti-requêtes simultanées
  DateTime? _lastRerouteTime;                         // Cooldown : min 30s entre deux recalculs
  static const double _rerouteThresholdM = 100.0;    // Seuil de déviation en mètres
  static const Duration _rerouteCooldown = Duration(seconds: 30); // Délai minimum entre recalculs

  // Coordonnées effectives des gares (widget ou récupérées via API)
  double? _deptLat;
  double? _deptLng;
  double? _arrivLat;
  double? _arrivLng;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    // Initialise depuis les paramètres du widget
    _deptLat = widget.gareDepartLat;
    _deptLng = widget.gareDepartLng;
    _arrivLat = widget.gareArriveeLat;
    _arrivLng = widget.gareArriveeLng;

    _initGps();
    _drawRoute();

    // Force une remontée GPS immédiate dès l'ouverture (sans attendre le 1er
    // déclenchement du distanceFilter du stream). Le serveur reçoit ainsi
    // tout de suite la position courante du chauffeur.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshGps();
    });
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  // ── GPS ────────────────────────────────────────────────────────────────────

  Future<void> _initGps() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _gpsDenied = true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      setState(() => _gpsDenied = true);
      return;
    }

    _positionSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(_onPosition, onError: (_) => setState(() => _gpsActive = false));
  }

  void _onPosition(Position pos) {
    // Garde-fou : sur certains appareils Android, lat/lng/speed/heading
    // peuvent être NaN ou Infinity quand la donnée est indisponible. On
    // ignore tout point invalide pour éviter le crash « Infinity or NaN
    // toInt » dans flutter_map et les HUD.
    if (!pos.latitude.isFinite || !pos.longitude.isFinite) return;

    final latLng = LatLng(pos.latitude, pos.longitude);
    final rawSpeed = pos.speed;
    final speedKmh = (rawSpeed.isFinite && rawSpeed >= 0) ? rawSpeed * 3.6 : 0.0;
    final heading = (pos.heading.isFinite) ? pos.heading : null;

    setState(() {
      _driverPosition = latLng;
      _currentSpeed = speedKmh;
      _currentHeading = heading;
      _gpsActive = true;
    });

    // Follow driver only when user explicitly requested it via recenter button
    if (_mapReady && _followDriver) {
      _mapController.move(latLng, _mapController.camera.zoom);
    }

    // ── Détection de déviation & recalcul d'itinéraire ──────────────────────
    // Conditions : gare d'arrivée connue + pas déjà en recalcul + cooldown respecté
    if (_arrivLat != null && _arrivLng != null && !_isRerouting) {
      final now = DateTime.now();
      final cooldownOk = _lastRerouteTime == null ||
          now.difference(_lastRerouteTime!) >= _rerouteCooldown;

      if (cooldownOk) {
        final deviation = _distanceToRoute(pos.latitude, pos.longitude);
        if (deviation > _rerouteThresholdM) {
          _lastRerouteTime = now;
          _drawRoute(fromLat: pos.latitude, fromLng: pos.longitude, fitView: false);
        }
      }
    }

    // Send to server max every 5 seconds
    final now = DateTime.now();
    if (_lastSent == null ||
        now.difference(_lastSent!) >= const Duration(seconds: 5)) {
      _sendLocation(pos.latitude, pos.longitude, speedKmh, heading);
      _lastSent = now;
    }
  }

  /// Calcule la distance minimale en mètres entre un point et le tracé actuel.
  /// Utilise la formule de Haversine pour éviter toute dépendance externe.
  /// Retourne [double.infinity] si le tracé est vide (premier calcul).
  double _distanceToRoute(double lat, double lng) {
    if (_routePoints.isEmpty) return double.infinity;
    double minDist = double.infinity;
    for (final routePoint in _routePoints) {
      final d = _haversineM(lat, lng, routePoint.latitude, routePoint.longitude);
      if (d < minDist) minDist = d;
    }
    return minDist;
  }

  /// Formule de Haversine : distance en mètres entre deux points GPS.
  double _haversineM(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0; // Rayon de la Terre en mètres
    final dLat = _deg2rad(lat2 - lat1);
    final dLon = _deg2rad(lon2 - lon1);
    final a = (dLat / 2).abs() < 1e-10 && (dLon / 2).abs() < 1e-10
        ? 0.0
        : (1 - dart_math.cos(dLat)) / 2 +
        dart_math.cos(_deg2rad(lat1)) *
            dart_math.cos(_deg2rad(lat2)) *
            (1 - dart_math.cos(dLon)) /
            2;
    return 2 * r * dart_math.asin(dart_math.sqrt(a.clamp(0.0, 1.0)));
  }

  double _deg2rad(double deg) => deg * (dart_math.pi / 180);

  Future<void> _sendLocation(
      double lat, double lng, double speed, double? heading) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
      ));

      final endpoint = widget.tripKind == TrackedTripKind.convoi
          ? 'chauffeur/convois/${widget.voyageId}/update-location'
          : 'chauffeur/voyages/${widget.voyageId}/update-location';

      final response = await dio.post(
        endpoint,
        data: {
          'latitude': lat,
          'longitude': lng,
          'speed': speed,
          if (heading != null) 'heading': heading,
        },
      );

      if (response.data['success'] == true && mounted) {
        setState(() {
          _updateCount++;
          final eta = response.data['temps_restant'];
          if (eta != null) _etaText = eta.toString();
        });
      }
    } catch (_) {
      // Fail silently — GPS will retry on next position update
    }
  }

  /// Force une récupération immédiate de la position GPS actuelle
  Future<void> _refreshGps() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _onPosition(pos);
    } catch (_) {}
  }

  // ── Route OSRM ─────────────────────────────────────────────────────────────

  /// Calcule et affiche l'itinéraire depuis [fromLat,fromLng] jusqu'à la gare d'arrivée.
  /// Si [fromLat] / [fromLng] sont null, utilise la gare de départ (appel initial).
  /// [fitView] = true lors du premier tracé pour zoomer sur l'ensemble de l'itinéraire.
  Future<void> _drawRoute({
    double? fromLat,
    double? fromLng,
    bool fitView = true,
  }) async {
    if (_isRerouting) return;
    if (mounted) setState(() => _isRerouting = true);

    double? dLat = fromLat ?? widget.gareDepartLat;
    double? dLng = fromLng ?? widget.gareDepartLng;
    double? aLat = widget.gareArriveeLat ?? _arrivLat;
    double? aLng = widget.gareArriveeLng ?? _arrivLng;

    // Fallback: fetch voyage/convoi details from API when coordinates are missing (premier appel uniquement)
    if (fromLat == null && (dLat == null || dLng == null || aLat == null || aLng == null)) {
      final coords = widget.tripKind == TrackedTripKind.convoi
          ? await _fetchConvoiCoords()
          : await _fetchVoyageCoords();
      if (coords != null) {
        dLat ??= coords['depart_lat'];
        dLng ??= coords['depart_lng'];
        aLat ??= coords['arrivee_lat'];
        aLng ??= coords['arrivee_lng'];
        if (mounted) {
          setState(() {
            _deptLat  = dLat;
            _deptLng  = dLng;
            _arrivLat = aLat;
            _arrivLng = aLng;
          });
        }
      }
    }

    if (dLat == null || dLng == null || aLat == null || aLng == null) {
      if (mounted) setState(() => _isRerouting = false);
      return;
    }

    // Garde-fou : départ == arrivée → pas de route, et fitCamera sur 1 point
    // unique provoque un zoom infini → crash « Infinity or NaN toInt ».
    if ((dLat - aLat).abs() < 1e-7 && (dLng - aLng).abs() < 1e-7) {
      if (mounted) setState(() => _isRerouting = false);
      return;
    }

    try {
      final res = await Dio().get(
        'https://router.project-osrm.org/route/v1/driving/$dLng,$dLat;$aLng,$aLat?overview=full&geometries=geojson',
        options: Options(receiveTimeout: const Duration(seconds: 10)),
      );
      final routes = res.data['routes'] as List?;
      if (routes == null || routes.isEmpty) {
        _isRerouting = false;
        return;
      }
      final coords = routes[0]['geometry']['coordinates'] as List;
      final points =
      coords.map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble())).toList();

      if (!mounted) {
        _isRerouting = false;
        return;
      }

      // Mise à jour du tracé + fin du recalcul
      setState(() {
        _routePoints = points;
        _isRerouting = false;
      });

      if (fitView && _mapReady && points.isNotEmpty) {
        _fitRoute(points);
      }
    } catch (_) {
      // Route unavailable — map still works without it
      if (mounted) setState(() => _isRerouting = false);
    }
  }

  /// Fetch gare coordinates from the voyages API when the dashboard didn't provide them.
  Future<Map<String, double>?> _fetchVoyageCoords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      final response = await dio.get('chauffeur/voyages');
      final data = response.data;
      if (data['success'] != true) return null;

      final voyages = (data['voyages'] ?? data['data'] ?? []) as List;
      // Find the matching voyage by ID
      final match = voyages.cast<Map<String, dynamic>>().where(
            (v) => (int.tryParse(v['id']?.toString() ?? '') ?? 0) == widget.voyageId,
      ).firstOrNull;

      if (match == null) return null;

      final programme = match['programme'];
      if (programme == null) return null;

      final parsed = VoyageProgrammeModel.fromJson(programme as Map<String, dynamic>);
      if (parsed.gareDepartLat == null || parsed.gareDepartLng == null ||
          parsed.gareArriveeLat == null || parsed.gareArriveeLng == null) return null;

      return {
        'depart_lat': parsed.gareDepartLat!,
        'depart_lng': parsed.gareDepartLng!,
        'arrivee_lat': parsed.gareArriveeLat!,
        'arrivee_lng': parsed.gareArriveeLng!,
      };
    } catch (_) {
      return null;
    }
  }

  /// Fetch gare coordinates from the convois API when the dashboard didn't provide them.
  /// Le convoi n'a en général que la gare de départ géolocalisée — l'arrivée
  /// est un point libre (adresse). On retourne ce qu'on a.
  Future<Map<String, double>?> _fetchConvoiCoords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
      ));

      final response = await dio.get('chauffeur/convois/${widget.voyageId}');
      final data = response.data;
      if (data['success'] != true) return null;

      final convoi = (data['convoi'] as Map?)?.cast<String, dynamic>();
      if (convoi == null) return null;

      final gare = (convoi['gare'] as Map?)?.cast<String, dynamic>();
      if (gare == null) return null;

      final lat = double.tryParse(gare['latitude']?.toString() ?? '');
      final lng = double.tryParse(gare['longitude']?.toString() ?? '');
      if (lat == null || lng == null) return null;

      // On ne dispose que des coordonnées de la gare ; le lieu de retour
      // est un point libre. On renvoie uniquement le départ ; le tracking
      // sautera le tracé OSRM (pas de coords arrivée → bail) et n'appellera
      // pas fitCamera avec des bornes dégénérées.
      return {
        'depart_lat': lat,
        'depart_lng': lng,
      };
    } catch (_) {
      return null;
    }
  }

  void _fitRoute(List<LatLng> points) {
    if (points.isEmpty) return;

    // Garde-fou : si tous les points sont (quasi) identiques, fitCamera
    // produit un zoom infini → « Unsupported operation: Infinity or NaN
    // toInt ». On préfère un simple `move` centré sur le point unique.
    final first = points.first;
    final allIdentical = points.every((p) =>
        (p.latitude - first.latitude).abs() < 1e-7 &&
        (p.longitude - first.longitude).abs() < 1e-7);

    if (allIdentical) {
      try {
        _mapController.move(first, 14);
      } catch (_) {}
      return;
    }

    try {
      _mapController.fitCamera(
        CameraFit.coordinates(
          coordinates: points,
          padding: const EdgeInsets.fromLTRB(40, 120, 40, 180),
        ),
      );
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final initLat = widget.gareDepartLat ?? 5.3484;
    final initLng = widget.gareDepartLng ?? -4.0083;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(initLat, initLng),
              initialZoom: 10,
              onMapReady: () {
                setState(() => _mapReady = true);
                if (_routePoints.isNotEmpty) _fitRoute(_routePoints);
              },
            ),
            children: [
              // Tiles — CartoDB Voyager (clair + routes bien visibles)
              TileLayer(
                urlTemplate:
                'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.car225.app',
                maxZoom: 19,
                retinaMode: RetinaMode.isHighDensity(context),
              ),

              // Route ombre
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 9,
                      color: Colors.black.withValues(alpha: 0.15),
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),

              // Route principale (orange Car225)
              if (_routePoints.isNotEmpty)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      strokeWidth: 5,
                      color: AppColors.primary,
                      strokeCap: StrokeCap.round,
                    ),
                  ],
                ),

              // Marqueurs gares + chauffeur
              MarkerLayer(
                markers: [
                  // Gare de départ (vert — icône départ)
                  if (_deptLat != null && _deptLng != null)
                    Marker(
                      point: LatLng(_deptLat!, _deptLng!),
                      width: 44,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: const _GareMarker(isDepart: true),
                    ),
                  // Gare d'arrivée (rouge — drapeau)
                  if (_arrivLat != null && _arrivLng != null)
                    Marker(
                      point: LatLng(_arrivLat!, _arrivLng!),
                      width: 44,
                      height: 52,
                      alignment: Alignment.topCenter,
                      child: const _GareMarker(isDepart: false),
                    ),
                  // Position du chauffeur
                  if (_driverPosition != null)
                    Marker(
                      point: _driverPosition!,
                      width: 58,
                      height: 58,
                      child: _DriverMarker(pulseController: _pulseController),
                    ),
                ],
              ),

              // Attribution
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('© CartoDB © OpenStreetMap'),
                ],
              ),
            ],
          ),

          // ── Top Bar ────────────────────────────────────────────────────────
          _TopBar(
            gareDepartNom: widget.gareDepartNom,
            gareArriveeNom: widget.gareArriveeNom,
            vehiculeImmat: widget.vehiculeImmat,
            dateVoyage: widget.dateVoyage,
          ),

          // ── Banner recalcul d'itinéraire ───────────────────────────────────
          if (_isRerouting)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70,
              left: 16,
              right: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF1e3a5f),
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Recalcul de l\'itinéraire...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 200.ms),
            ),

          // ── HUD + contrôles (responsive : au-dessus de la nav système) ───────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: _buildHud(),
              ),
            ),
          ),

          // ── Panneau de contrôles (droite) ─────────────────────────────────
          Positioned(
            right: 12,
            bottom: 0,
            child: SafeArea(
              top: false,
              left: false,
              right: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Refresh GPS
                    _MapBtn(
                      heroTag: 'refreshgps',
                      icon: Icons.gps_fixed_rounded,
                      color: _gpsActive ? const Color(0xFF22c55e) : Colors.grey,
                      tooltip: 'Actualiser GPS',
                      onPressed: _refreshGps,
                    ),
                    const SizedBox(height: 6),

                    // Route overview
                    if (_routePoints.isNotEmpty) ...[
                      _MapBtn(
                        heroTag: 'fitroute',
                        icon: Icons.route_rounded,
                        color: AppColors.primary,
                        tooltip: 'Voir tout le tracé',
                        onPressed: () {
                          setState(() => _followDriver = false);
                          _fitRoute(_routePoints);
                        },
                      ),
                      const SizedBox(height: 6),
                    ],

                    // Recentrer sur chauffeur
                    _MapBtn(
                      heroTag: 'recenter',
                      icon: Icons.my_location_rounded,
                      color: _followDriver ? Colors.white : AppColors.primary,
                      bgColor: _followDriver ? AppColors.primary : Colors.white,
                      tooltip: 'Centrer sur ma position',
                      onPressed: _driverPosition == null
                          ? null
                          : () {
                        setState(() => _followDriver = true);
                        _mapController.move(_driverPosition!, 15);
                      },
                    ),
                    const SizedBox(height: 6),

                    // Zoom +
                    _MapBtn(
                      heroTag: 'zoomin',
                      icon: Icons.add_rounded,
                      onPressed: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom + 1,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Zoom -
                    _MapBtn(
                      heroTag: 'zoomout',
                      icon: Icons.remove_rounded,
                      onPressed: () => _mapController.move(
                        _mapController.camera.center,
                        _mapController.camera.zoom - 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── HUD ────────────────────────────────────────────────────────────────────

  Widget _buildHud() {
    final speedText = (_currentSpeed != null && _currentSpeed!.isFinite)
        ? _currentSpeed!.round().toString()
        : '—';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Vitesse
        _HudCard(
          value: speedText,
          label: 'KM/H',
          valueColor: const Color(0xFF3b82f6),
        ),
        const SizedBox(width: 8),
        // GPS
        _HudCard(
          icon: _gpsDenied
              ? Icons.gps_off
              : _gpsActive
              ? Icons.satellite_alt
              : Icons.gps_not_fixed,
          label: _gpsDenied
              ? 'GPS REFUSÉ'
              : _gpsActive
              ? 'GPS ACTIF'
              : 'GPS INACTIF',
          valueColor: _gpsDenied
              ? Colors.redAccent
              : _gpsActive
              ? const Color(0xFF22c55e)
              : Colors.grey,
        ),
        const SizedBox(width: 8),
        // ETA (plus large)
        Expanded(
          flex: 2,
          child: _HudCard(
            value: _etaText,
            label: 'ARRIVÉE EST.',
            valueColor: const Color(0xFFa78bfa),
            compact: true,
          ),
        ),
        const SizedBox(width: 8),
        // Mises à jour
        _HudCard(
          value: '$_updateCount',
          label: 'MÀJ GPS',
          valueColor: const Color(0xFFf59e0b),
        ),
      ],
    );
  }
}

// ── Widgets séparés ──────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final String gareDepartNom;
  final String gareArriveeNom;
  final String vehiculeImmat;
  final String dateVoyage;

  const _TopBar({
    required this.gareDepartNom,
    required this.gareArriveeNom,
    required this.vehiculeImmat,
    required this.dateVoyage,
  });

  @override
  Widget build(BuildContext context) {
    final formattedDate = dateVoyage.isNotEmpty
        ? (() {
      try {
        return DateFormat('dd/MM/yyyy')
            .format(DateTime.parse(dateVoyage));
      } catch (_) {
        return dateVoyage;
      }
    })()
        : '';

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.only(
          top: MediaQuery.of(context).padding.top + 6,
          left: 8,
          right: 16,
          bottom: 10,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0f172a), Color(0xFF1e3a5f)],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Retour
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios_new,
                  color: Colors.white, size: 18),
              padding: const EdgeInsets.all(8),
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 4),
            // Icone bus
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(Icons.directions_bus,
                  color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 10),
            // Itinéraire
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          gareDepartNom,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: Icon(Icons.arrow_forward,
                            color: AppColors.primary, size: 13),
                      ),
                      Flexible(
                        child: Text(
                          gareArriveeNom,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  if (formattedDate.isNotEmpty || vehiculeImmat.isNotEmpty)
                    Text(
                      [
                        if (formattedDate.isNotEmpty) formattedDate,
                        if (vehiculeImmat.isNotEmpty) vehiculeImmat,
                      ].join(' · '),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // EN COURS badge
            _LiveBadge(),
          ],
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .scale(
            begin: const Offset(0.7, 0.7),
            end: const Offset(1.4, 1.4),
            duration: 900.ms,
            curve: Curves.easeInOut,
          )
              .then()
              .scale(
            begin: const Offset(1.4, 1.4),
            end: const Offset(0.7, 0.7),
            duration: 900.ms,
          ),
          const SizedBox(width: 5),
          const Text(
            'EN COURS',
            style: TextStyle(
              color: Color(0xFFF87171),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverMarker extends StatelessWidget {
  final AnimationController pulseController;
  const _DriverMarker({required this.pulseController});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anneau pulsant
        AnimatedBuilder(
          animation: pulseController,
          builder: (_, __) {
            final scale = 0.6 + pulseController.value * 0.8;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary
                      .withValues(alpha: 0.25 * (1 - pulseController.value)),
                ),
              ),
            );
          },
        ),
        // Marqueur central
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFFF9A3C), Color(0xFFFF5500)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.55),
                blurRadius: 14,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.directions_bus, color: Colors.white, size: 20),
        ),
      ],
    );
  }
}

class _GareMarker extends StatelessWidget {
  final bool isDepart;
  const _GareMarker({required this.isDepart});

  @override
  Widget build(BuildContext context) {
    final color = isDepart ? const Color(0xFF22c55e) : const Color(0xFFef4444);
    final icon  = isDepart ? Icons.subdirectory_arrow_right_rounded : Icons.flag_rounded;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Bulle principale
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(isDepart ? 20 : 10),
            border: Border.all(color: Colors.white, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.55),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        // Pointe vers le bas
        CustomPaint(
          size: const Size(14, 8),
          painter: _PinTipPainter(color: color),
        ),
      ],
    );
  }
}

/// Dessine un triangle pointé vers le bas (comme un pin de carte)
class _PinTipPainter extends CustomPainter {
  final Color color;
  const _PinTipPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTipPainter old) => old.color != color;
}

class _HudCard extends StatelessWidget {
  final String? value;
  final IconData? icon;
  final String label;
  final Color valueColor;
  final bool compact;

  const _HudCard({
    this.value,
    this.icon,
    required this.label,
    required this.valueColor,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
      constraints: const BoxConstraints(minWidth: 60),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border:
        Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, color: valueColor, size: 20)
          else
            Text(
              value ?? '—',
              style: TextStyle(
                color: valueColor,
                fontSize: compact ? 12 : 18,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontSize: 8,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Bouton carte générique (remplace FAB + ZoomControls)
class _MapBtn extends StatelessWidget {
  final String heroTag;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String? tooltip;
  final VoidCallback? onPressed;

  const _MapBtn({
    required this.heroTag,
    required this.icon,
    this.color = Colors.black87,
    this.bgColor = Colors.white,
    this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        elevation: 3,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(icon, size: 20, color: onPressed == null ? Colors.grey : color),
          ),
        ),
      ),
    );
  }
}
