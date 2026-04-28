import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:car225/core/theme/app_colors.dart';
import '../providers/driver_provider.dart';
import 'driver_dashboard_screen.dart';
import 'driver_trips_screen.dart';
import 'driver_convois_screen.dart';
import 'driver_scanner_screen.dart';
import 'driver_messages_screen.dart';
import 'driver_reports_screen.dart';
import 'driver_profile_screen.dart';
import 'driver_history_screen.dart';
import 'driver_notification_screen.dart';

// Couleurs navy (inspiré du web chauffeur)
const _kNavy = Color(0xFF0f172a);
const _kNavyMid = Color(0xFF1e3a5f);

class DriverMainWrapper extends StatefulWidget {
  const DriverMainWrapper({super.key});

  @override
  State<DriverMainWrapper> createState() => _DriverMainWrapperState();
}

class _DriverMainWrapperState extends State<DriverMainWrapper>
    with WidgetsBindingObserver {
  final List<Widget> _screens = const [
    DriverDashboardScreen(),
    _TripsAndConvoisTab(),
    DriverScannerScreen(),
    DriverMessagesScreen(),
    DriverReportsScreen(),
  ];

  bool _gpsDialogVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Vérifie le GPS dès l'ouverture du wrapper chauffeur
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkGps());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Appelé à chaque fois que l'app revient au premier plan
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkGps();
    }
  }

  /// Vérifie si le GPS est actif ET si la permission est accordée.
  /// Affiche un dialog bloquant si ce n'est pas le cas.
  Future<void> _checkGps() async {
    if (!mounted) return;

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showGpsDialog(locationDisabled: true);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showGpsDialog(locationDisabled: false, permissionDenied: true);
      return;
    }

    // GPS actif + permission OK → ferme le dialog s'il était ouvert
    if (_gpsDialogVisible && mounted) {
      Navigator.of(context, rootNavigator: true).pop();
      _gpsDialogVisible = false;
    }
  }

  void _showGpsDialog({
    bool locationDisabled = false,
    bool permissionDenied = false,
  }) {
    if (_gpsDialogVisible || !mounted) return;
    _gpsDialogVisible = true;

    final String title =
    permissionDenied ? 'Permission GPS refusée' : 'GPS désactivé';

    final String message = permissionDenied
        ? 'L\'application nécessite l\'accès à votre position pour fonctionner correctement.\n\nVeuillez autoriser la localisation dans les paramètres de votre téléphone.'
        : 'Votre GPS est désactivé.\n\nEn tant que chauffeur, vous devez activer le GPS pour permettre le suivi de votre position en temps réel.';

    final String btnLabel =
    permissionDenied ? 'Ouvrir les paramètres' : 'Activer le GPS';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => WillPopScope(
        onWillPop: () async => false, // empêche le retour arrière
        child: AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_off_rounded,
                    color: Colors.orange, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          content: Text(message,
              style: const TextStyle(fontSize: 14, color: Color(0xFF475569))),
          actions: [
            // Bouton secondaire : vérifier à nouveau sans ouvrir paramètres
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _gpsDialogVisible = false;
                _checkGps();
              },
              child: const Text('Vérifier à nouveau',
                  style: TextStyle(color: Color(0xFF64748B))),
            ),
            // Bouton principal : ouvre les paramètres système
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              icon: const Icon(Icons.settings_rounded, size: 18),
              label: Text(btnLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                _gpsDialogVisible = false;
                if (permissionDenied) {
                  await Geolocator.openAppSettings();
                } else {
                  await Geolocator.openLocationSettings();
                }
                // Re-vérifie après retour des paramètres
                // (didChangeAppLifecycleState resumed s'en chargera aussi)
              },
            ),
          ],
        ),
      ),
    ).then((_) {
      // Si l'utilisateur ferme d'une façon inattendue
      _gpsDialogVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DriverProvider>();
    final currentIndex = provider.currentIndex;
    final isScannerTab = currentIndex == 2;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      extendBody: false,
      body: Column(
        children: [
          // ── Navbar top (cachée sur le scanner pour plein écran caméra) ──
          if (!isScannerTab) _DriverTopNavbar(provider: provider),

          // ── Contenu de l'onglet actif ──
          Expanded(
            child: IndexedStack(
              index: currentIndex,
              children: _screens,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _DriverBottomNav(
        currentIndex: currentIndex,
        unreadMessages: provider.unreadMessagesCount,
        onTap: (i) => provider.setIndex(i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NAVBAR TOP
// ─────────────────────────────────────────────────────────────────────────────
class _DriverTopNavbar extends StatelessWidget {
  final DriverProvider provider;

  const _DriverTopNavbar({required this.provider});

  @override
  Widget build(BuildContext context) {
    final profile = provider.profile;
    final profileImageFile = provider.profileImage;
    final unreadNotifs = provider.unreadNotificationsCount;
    final isInitializing = provider.isInitializing;

    // Nom à afficher : priorité au profil chargé, puis au cache local
    final displayPrenom = profile?.prenom ?? provider.cachedPrenom;
    final displayName   = profile?.name   ?? provider.cachedName;
    final displayCodeId = profile?.codeId ?? provider.cachedCodeId;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kNavy, _kNavyMid],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 58,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // ── Photo de profil cliquable ──
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverProfileScreen(),
                    ),
                  ),
                  child: _ProfileAvatar(
                    profileImageFile: profileImageFile,
                    profilePictureUrl: profile?.fullProfilePictureUrl,
                    prenom: displayPrenom,
                    name: displayName,
                    isLoading: isInitializing && displayPrenom == null,
                  ),
                ),
                const SizedBox(width: 12),

                // ── Nom / CodeId ──
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Si on initialise et qu'on n'a aucun cache : shimmer
                      if (isInitializing && displayPrenom == null)
                        _ShimmerLine(width: 120, height: 14)
                      else
                        Text(
                          '${displayPrenom ?? ''} ${displayName ?? ''}'.trim().isEmpty
                              ? 'Chauffeur'
                              : '${displayPrenom ?? ''} ${displayName ?? ''}'.trim(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 2),
                      if (isInitializing && displayCodeId == null)
                        _ShimmerLine(width: 60, height: 10)
                      else if (displayCodeId != null)
                        Text(
                          displayCodeId,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Logo CAR225 ──
                const _Car225Badge(),

                const SizedBox(width: 8),

                // ── Historique ──
                _NavIconBtn(
                  icon: Icons.history_rounded,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DriverHistoryScreen(),
                    ),
                  ),
                ),

                // ── Cloche avec badge ──
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    _NavIconBtn(
                      icon: Icons.notifications_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DriverNotificationScreen(),
                        ),
                      ),
                    ),
                    if (unreadNotifs > 0)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              unreadNotifs > 9 ? '9+' : '$unreadNotifs',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final File? profileImageFile;
  final String? profilePictureUrl;
  final String? prenom;
  final String? name;
  final bool isLoading;

  const _ProfileAvatar({
    this.profileImageFile,
    this.profilePictureUrl,
    this.prenom,
    this.name,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final initials = _buildInitials();
    final initialsWidget = isLoading
        ? _ShimmerCircle(size: 40)
        : Center(
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );

    Widget? imageWidget;
    if (profileImageFile != null) {
      imageWidget = Image.file(profileImageFile!, fit: BoxFit.cover,
          width: 40, height: 40, errorBuilder: (_, __, ___) => initialsWidget);
    } else if (profilePictureUrl != null && profilePictureUrl!.isNotEmpty) {
      imageWidget = Image.network(profilePictureUrl!, fit: BoxFit.cover,
          width: 40, height: 40, errorBuilder: (_, __, ___) => initialsWidget);
    }

    return Container(
      width: 40,
      height: 40,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 2),
        color: _kNavyMid,
      ),
      child: isLoading ? _ShimmerCircle(size: 40) : (imageWidget ?? initialsWidget),
    );
  }

  String _buildInitials() {
    final p = prenom?.isNotEmpty == true ? prenom![0].toUpperCase() : '';
    final n = name?.isNotEmpty == true ? name![0].toUpperCase() : '';
    return '$p$n'.isNotEmpty ? '$p$n' : 'CH';
  }
}

class _Car225Badge extends StatelessWidget {
  const _Car225Badge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
      ),
      child: const Text(
        'CAR225',
        style: TextStyle(
          color: AppColors.primary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────────
// SHIMMER (animation de chargement)
// ────────────────────────────────────────────────────────────────────────────────
class _ShimmerLine extends StatefulWidget {
  final double width;
  final double height;
  const _ShimmerLine({required this.width, required this.height});

  @override
  State<_ShimmerLine> createState() => _ShimmerLineState();
}

class _ShimmerLineState extends State<_ShimmerLine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_anim.value),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _ShimmerCircle extends StatefulWidget {
  final double size;
  const _ShimmerCircle({required this.size});

  @override
  State<_ShimmerCircle> createState() => _ShimmerCircleState();
}

class _ShimmerCircleState extends State<_ShimmerCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.15, end: 0.45).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(_anim.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _NavIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, color: Colors.white.withOpacity(0.85), size: 24),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV
// ─────────────────────────────────────────────────────────────────────────────
class _DriverBottomNav extends StatelessWidget {
  final int currentIndex;
  final int unreadMessages;
  final ValueChanged<int> onTap;

  const _DriverBottomNav({
    required this.currentIndex,
    required this.unreadMessages,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
      _NavItem(icon: Icons.directions_bus_rounded, label: 'Voyages'),
      _NavItem(icon: Icons.qr_code_scanner_rounded, label: 'Scanner'),
      _NavItem(
        icon: Icons.chat_bubble_outline_rounded,
        label: 'Messages',
        badge: unreadMessages,
      ),
      _NavItem(icon: Icons.warning_amber_rounded, label: 'Signalements'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: _kNavy,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Scanner : bouton circulaire surélevé ──
                      if (i == 2)
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? AppColors.primary : const Color(0xFF1e293b),
                            boxShadow: isActive
                                ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              )
                            ]
                                : null,
                          ),
                          child: Icon(
                            item.icon,
                            color: Colors.white,
                            size: 22,
                          ),
                        )
                      else
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.primary.withOpacity(0.15)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.icon,
                                color: isActive
                                    ? AppColors.primary
                                    : Colors.white54,
                                size: 22,
                              ),
                            ),
                            if ((item.badge ?? 0) > 0)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      item.badge! > 9 ? '9+' : '${item.badge}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 3),
                      if (i != 2)
                        Text(
                          item.label,
                          style: TextStyle(
                            color: isActive ? AppColors.primary : Colors.white38,
                            fontSize: 10,
                            fontWeight: isActive
                                ? FontWeight.w700
                                : FontWeight.normal,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final int? badge;

  const _NavItem({required this.icon, required this.label, this.badge});
}

// ─────────────────────────────────────────────────────────────────────────────
// TAB : Voyages + Convois (switch au sommet)
// ─────────────────────────────────────────────────────────────────────────────
class _TripsAndConvoisTab extends StatefulWidget {
  const _TripsAndConvoisTab();

  @override
  State<_TripsAndConvoisTab> createState() => _TripsAndConvoisTabState();
}

class _TripsAndConvoisTabState extends State<_TripsAndConvoisTab> {
  // 0 = Voyages, 1 = Convois
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Switch Voyages / Convois
        Container(
          color: _kNavy,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: _SegmentBtn(
                  icon: Icons.directions_bus_rounded,
                  label: 'Voyages',
                  active: _index == 0,
                  onTap: () => setState(() => _index = 0),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SegmentBtn(
                  icon: Icons.airport_shuttle_rounded,
                  label: 'Convois',
                  active: _index == 1,
                  onTap: () => setState(() => _index = 1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _index,
            children: const [
              DriverTripsScreen(),
              DriverConvoisScreen(),
            ],
          ),
        ),
      ],
    );
  }
}

class _SegmentBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SegmentBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active
              ? AppColors.primary
              : Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: active
                ? AppColors.primary
                : Colors.white.withOpacity(0.15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 16,
                color: active ? Colors.white : Colors.white70),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
